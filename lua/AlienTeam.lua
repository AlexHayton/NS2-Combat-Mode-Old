// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/TechData.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/InfestationManager.lua")

class 'AlienTeam' (PlayingTeam)

// Health to regen per second (like NS1)
AlienTeam.kAutoHealRate = kBalanceAutoHealPerSecond

// Innate alien regeneration
AlienTeam.kAutoHealInterval = 2
AlienTeam.kAutoHealPercent = .02
AlienTeam.kInfestationUpdateRate = 2
AlienTeam.kInfestationHurtInterval = 2

function AlienTeam:GetTeamType()
    return kAlienTeamType
end

function AlienTeam:GetIsAlienTeam()
    return true
end

function AlienTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Skulk.kMapName
    
end

function AlienTeam:SpawnInitialStructures(teamLocation)

    PlayingTeam.SpawnInitialStructures(self, teamLocation)
    
    // Aliens start the game with all their eggs
    local nearestTechPoint = GetNearestTechPoint(teamLocation:GetOrigin(), self:GetTeamType(), false)
    if(nearestTechPoint ~= nil) then
    
        local attached = nearestTechPoint:GetAttached()
        if(attached ~= nil) then

            if attached:isa("Hive") then
                attached:SpawnInitial()
            else
                Print("AlienTeam:SpawnInitialStructures(): Hive not attached to tech point, %s instead.", attached:GetClassName())
            end
            
        end
        
    end
    
end

function AlienTeam:GetHasAbilityToRespawn()
    
    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    return table.count(hives) > 0
    
end

function AlienTeam:Update(timePassed)

    PROFILE("AlienTeam:Update")

    PlayingTeam.Update(self, timePassed)

    self:UpdateAutoBuild(timePassed)
    
    self:UpdateTeamAutoHeal(timePassed)
    
    self:UpdateHiveSight()
    
    self:UpdateInfestation()
    
end

function AlienTeam:UpdateAutoBuild(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoBuild")

    // Update build fraction every tick to be smooth
    for index, structure in ipairs(self.structures) do
    
        if(not structure:GetIsBuilt()) then
        
            // Account for metabolize game effects
            local autoBuildTime = GetAlienEvolveResearchTime(timePassed, structure)
            structure:Construct(autoBuildTime)
        
        end
        
    end
    
end

// Small and silent innate health and armor regeneration for all alien players, similar to the 
// innate regeneration of all alien structures. NS1 healed 2% of alien max health every 2 seconds.
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil or (time > (self.timeOfLastAutoHeal + AlienTeam.kAutoHealInterval)) then
    
        // Heal all players by this amount
        local teamEnts = GetEntitiesForTeam("LiveScriptActor", self:GetTeamNumber())
        
        for index, entity in ipairs(teamEnts) do
        
            if entity:GetIsAlive() then
            
                if entity:isa("Drifter") or (entity:isa("Alien") and entity:GetGameEffectMask(kGameEffect.OnInfestation)) then
            
                    // Entities always get at least 1 point back
                    local healthBack = math.max(entity:GetMaxHealth() * AlienTeam.kAutoHealPercent, 1)
                    entity:AddHealth(healthBack, true)
                    
                end
                
            end
            
        end
        
        self.timeOfLastAutoHeal = time
        
    end
    
    // Auto-heal structures constantly, if they're on infestation
    for index, structure in ipairs(self.structures) do
    
        if structure:GetGameEffectMask(kGameEffect.OnInfestation) then
        
            // Cap it so eggs don't count up like 1-2% per second
            local maxHealth = structure:GetMaxHealth() * kBalanceAutoHealMaxPercentPerSecond/100 * timePassed
            local health = math.min(AlienTeam.kAutoHealRate * timePassed, maxHealth)
            structure:AddHealth(health, false)
            
        end 
       
    end
    
    // Hurt structures if they require infestation and aren't on it
    if self.timeOfLastInfestationHurt == nil or (time > (self.timeOfLastInfestationHurt + AlienTeam.kInfestationHurtInterval)) then
    
        for index, structure in ipairs(self.structures) do
        
            if LookupTechData(structure:GetTechId(), kTechDataRequiresInfestation) and not structure:GetGameEffectMask(kGameEffect.OnInfestation) then
            
                // Take damage!
                local damage = structure:GetMaxHealth() * kBalanceInfestationHurtPercentPerSecond/100 * AlienTeam.kInfestationHurtInterval               
                structure:TakeDamage(damage, nil, nil, structure:GetOrigin(), nil)
                
            end
            
        end
        
        self.timeOfLastInfestationHurt = time
        
    end
    
end

// Returns blipType if we should add a hive sight blip for this entity. Returns kBlipType.Undefined if 
// we shouldn't add one.
function AlienTeam:GetBlipType(entity)

    local blipType = kBlipType.Undefined
    
    if entity:isa("LiveScriptActor") and entity:GetIsVisible() and entity:GetIsAlive() and not entity:isa("Infestation") then
    
        if entity:GetTeamNumber() == self:GetTeamNumber() then
        
            blipType = kBlipType.Friendly
            
            local underAttack = false
            
            local damageTime = entity:GetTimeOfLastDamage()
            if damageTime ~= nil and (Shared.GetTime() < (damageTime + kHiveSightDamageTime)) then
            
                // Draw blip as under attack
                blipType = kBlipType.FriendlyUnderAttack
                
                underAttack = true
                
            end
            
            // If it's a hive or harvester, add special icon to show how important it is
            if entity:isa("Hive") or entity:isa("Harvester") then

                if not underAttack then            
                    blipType = kBlipType.TechPointStructure
                end
                
            end
            
        elseif(entity:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber()) and (entity.sighted or entity:GetGameEffectMask(kGameEffect.Parasite) or entity:GetGameEffectMask(kGameEffect.OnInfestation))) then
            blipType = kBlipType.Sighted
        end
        
        // Only send other structures if they are under attack or parasited
        if ((blipType == kBlipType.Sighted) or (blipType == kBlipType.Friendly)) and entity:isa("Structure") and (not underAttack) and not entity:GetGameEffectMask(kGameEffect.Parasite) then
            blipType = kBlipType.Undefined
        end
        
    end

    return blipType
    
end

function AlienTeam:UpdateHiveSight()

    PROFILE("AlienTeam:UpdateHiveSight")
    
    if(GetGamerules():GetGameStarted() and self:GetIsAlienTeam()) then
    
        // Loop through enemy entities, creating blips for ones that are sighted. Each entry is a pair with the entity and it's blip type
        local time = Shared.GetTime()
        
        local blips = EntityListToTable(Shared.GetEntitiesWithClassname("Blip"))
        
        local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
        for entIndex, entity in ientitylist(allScriptActors) do
        
            local blipType = self:GetBlipType(entity)
            
            if(blipType ~= kBlipType.Undefined) then
            
                CreateUpdateBlip(blips, entity, blipType, time)
                
            end        
            
        end
        
        // Now sync the sighted entities with the blip entities, creating or deleting them
        self:DeleteOldBlips(time)
        
    end
    
end

function AlienTeam:UpdateInfestation()

    // Update infestation connections
    if GetGamerules():GetGameStarted() and (self.timeLastInfestationUpdate == nil or (Shared.GetTime() > (self.timeLastInfestationUpdate + AlienTeam.kInfestationUpdateRate))) then
    
        UpdateInfestation(self:GetTeamNumber())
        
        self.timeLastInfestationUpdate = Shared.GetTime()
        
    end
    
end

function AlienTeam:DeleteOldBlips(time)

    PROFILE("AlienTeam:DeleteOldBlips")

    // We need to convert the EntityList to a table as we are destroying the entities
    // inside the EntityList.
    local entityTable = EntityListToTable(Shared.GetEntitiesWithClassname("Blip"))
    for index, blip in ipairs(entityTable) do
    
        if blip.timeOfUpdate < time then
        
            DestroyEntity(blip)
            
        end
        
    end
    
end

function AlienTeam:GetUmbraCrags()

    local crags = GetEntitiesForTeam("Crag", self:GetTeamNumber())
    
    local umbraCrags = {}    
    
    // Get umbraing crags
    for index, crag in ipairs(crags) do
    
        if crag:GetIsUmbraActive() then
        
            table.insert(umbraCrags, crag)
            
        end
        
    end
    
    return umbraCrags

end

function AlienTeam:GetFuryWhips()

    local whips = GetEntitiesForTeam("Whip", self:GetTeamNumber())
    
    local FuryWhips = {}    
    
    // Get furying whips
    for index, whip in ipairs(whips) do
    
        if whip:GetIsFuryActive() then
        
            table.insert(FuryWhips, whip)
            
        end
        
    end
    
    return FuryWhips

end

function AlienTeam:GetShades()
    return GetEntitiesForTeam("Shade", self:GetTeamNumber())
end

// Adds the InUmbra game effect to all specified entities within range of active crags. Returns
// the number of entities affected.
function AlienTeam:UpdateUmbraGameEffects(entities)

    local umbraCrags = self:GetUmbraCrags()
    
    if table.count(umbraCrags) > 0 then
    
        for index, entity in ipairs(entities) do
        
            // Get distance to crag
            for cragIndex, crag in ipairs(umbraCrags) do
            
                if (entity:GetOrigin() - crag:GetOrigin()):GetLengthSquared() < Crag.kUmbraRadius*Crag.kUmbraRadius then
                
                    entity:SetGameEffectMask(kGameEffect.InUmbra, true)
                
                end
                
            end
            
        end
    
    end

end

function AlienTeam:UpdateFuryGameEffects(entities)

    local FuryWhips = self:GetFuryWhips()
    
    if table.count(FuryWhips) > 0 then
    
        for index, entity in ipairs(entities) do
        
            // Live script actors (players, structures)
            if entity.SetFuryLevel then

                // Get distance to whip
                for index, whip in ipairs(FuryWhips) do
                
                    if (entity:GetOrigin() - whip:GetOrigin()):GetLengthSquared() < Whip.kFuryRadius*Whip.kFuryRadius then
                    
                        entity:SetGameEffectMask(kGameEffect.Fury, true)
                    
                        entity:AddStackableGameEffect(kFuryGameEffect, kFuryTime, whip)
                        
                    end
                    
                end
                
            end
            
        end
    
    end

end

// Update cloaking for friendlies and disorientation for enemies
function AlienTeam:UpdateShadeEffects(teamEntities, enemyPlayers)

    local shades = self:GetShades()
    
    if table.count(shades) > 0 then
    
        for index, entity in ipairs(teamEntities) do
        
            if ((entity:isa("Alien") or entity:isa("Structure")) and not entity:isa("Commander")) then

                // Get distance to shade
                for index, shade in ipairs(shades) do
                
                    if (shade:GetIsCloakActive() and (entity:GetOrigin() - shade:GetOrigin()):GetLengthSquared() < Shade.kCloakRadius*Shade.kCloakRadius) then
                    
                        entity:SetGameEffectMask(kGameEffect.Cloaked, true)
                    
                    end
                    
                end
                
            end
            
        end

        // Update disorient flag
        for index, entity in ipairs(enemyPlayers) do
        
            if not entity:isa("Commander") then

                for index, shade in ipairs(shades) do
                
                    if (entity:GetOrigin() - shade:GetOrigin()):GetLengthSquared() < Shade.kCloakRadius*Shade.kCloakRadius then
                    
                        entity:SetGameEffectMask(kGameEffect.Disorient, true)
                    
                    end
                    
                end
                
            end
            
        end
        
    end

end



function AlienTeam:InitTechTree()
   
    PlayingTeam.InitTechTree(self)
    
    // Add special alien menus
    self.techTree:AddMenu(kTechId.MarkersMenu)
    self.techTree:AddMenu(kTechId.UpgradesMenu)
    self.techTree:AddMenu(kTechId.ShadePhantasmMenu)
    
    // Add markers (orders)
    self.techTree:AddOrder(kTechId.ThreatMarker)
    self.techTree:AddOrder(kTechId.LargeThreatMarker)
    self.techTree:AddOrder(kTechId.NeedHealingMarker)
    self.techTree:AddOrder(kTechId.WeakMarker)
    self.techTree:AddOrder(kTechId.ExpandingMarker)
    
    // Commander abilities
    self.techTree:AddTargetedActivation(kTechId.Grow,           kTechId.None,           kTechId.None)
    self.techTree:AddResearchNode(kTechId.MetabolizeTech,       kTechId.HiveMass,       kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Metabolize,     kTechId.MetabolizeTech, kTechId.None)
           
    // Tier 1
    self.techTree:AddBuildNode(kTechId.Hive,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Harvester,                 kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.HarvesterUpgrade,        kTechId.Harvester,           kTechId.None)
    self.techTree:AddEnergyBuildNode(kTechId.Drifter,             kTechId.None,                kTechId.None)
    
    self.techTree:AddBuyNode(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Gorge,                     kTechId.Crag,                kTechId.None)
    
    self.techTree:AddBuildNode(kTechId.Crag,                      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeCrag,            kTechId.Crag,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureCrag,                kTechId.None,                kTechId.None)
    
    self.techTree:AddBuildNode(kTechId.Whip,                      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeWhip,             kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureWhip,                 kTechId.None,                kTechId.None)
    self.techTree:AddActivation(kTechId.WhipAcidStrike,            kTechId.None,                kTechId.None)

    self.techTree:AddActivation(kTechId.WhipUnroot)
    self.techTree:AddActivation(kTechId.WhipRoot)
    
    // Tier 1 structure triggered abilities
    self.techTree:AddActivation(kTechId.CragHeal,                    kTechId.None,          kTechId.None)
    self.techTree:AddActivation(kTechId.CragUmbra,                    kTechId.Crag,          kTechId.None)
    self.techTree:AddActivation(kTechId.WhipFury,                 kTechId.None,          kTechId.None)
    
    // Drifter tech
    self.techTree:AddResearchNode(kTechId.DrifterFlareTech,       kTechId.HiveMass,                kTechId.None)
    self.techTree:AddActivation(kTechId.DrifterFlare,                 kTechId.DrifterFlareTech)
    
    self.techTree:AddResearchNode(kTechId.DrifterParasiteTech,    kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DrifterParasite,      kTechId.DrifterParasiteTech, kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.Melee1Tech,             kTechId.Whip,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor1Tech,        kTechId.Crag,                kTechId.None)
    
    // Tier 2
    self.techTree:AddBuildNode(kTechId.HiveMass,                kTechId.None,              kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.HiveMassUpgrade,      kTechId.None,               kTechId.None)
    self.techTree:AddBuyNode(kTechId.Lerk,                      kTechId.Whip,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.Fade,                      kTechId.HiveMass,          kTechId.None)
    
    // Tier 2 structures
    self.techTree:AddBuildNode(kTechId.Shift,                     kTechId.HiveMass,          kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeShift,            kTechId.Shift,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureShift,               kTechId.HiveMass,          kTechId.None)
    self.techTree:AddActivation(kTechId.ShiftRecall,              kTechId.None, kTechId.None)
    
    self.techTree:AddBuildNode(kTechId.Shade,                     kTechId.HiveMass,          kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeShade,           kTechId.Shade,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureShade,               kTechId.HiveMass,          kTechId.None)
    
    // Tier 2 structure triggered abilities
    self.techTree:AddActivation(kTechId.ShadeDisorient,               kTechId.None,         kTechId.None)
    self.techTree:AddActivation(kTechId.ShadeCloak,                   kTechId.None,         kTechId.None)

    // Crag targeted ability    
    self.techTree:AddResearchNode(kTechId.BabblerTech,            kTechId.MatureCrag,          kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.CragBabblers,     kTechId.BabblerTech,         kTechId.MatureCrag)

    // Whip targeted ability
    self.techTree:AddUpgradeNode(kTechId.LobTech,                kTechId.MatureWhip,          kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.WhipBombard,                  kTechId.LobTech,             kTechId.MatureWhip)
    
    self.techTree:AddResearchNode(kTechId.Melee2Tech,             kTechId.Melee1Tech,                kTechId.HiveMass)
    self.techTree:AddResearchNode(kTechId.AlienArmor2Tech,        kTechId.AlienArmor1Tech,          kTechId.HiveMass)
        
    // Tier 3
    self.techTree:AddBuildNode(kTechId.HiveColony,                kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.HiveColonyUpgrade,      kTechId.HiveMass,           kTechId.None)
    self.techTree:AddBuyNode(kTechId.Onos,                      kTechId.HiveColony,           kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.Melee3Tech,             kTechId.Melee2Tech,                kTechId.HiveColony)
    self.techTree:AddResearchNode(kTechId.AlienArmor3Tech,        kTechId.AlienArmor2Tech,          kTechId.HiveColony)
    
    // Shift targeted ability    
    self.techTree:AddResearchNode(kTechId.EchoTech,               kTechId.MatureShift,         kTechId.HiveColony)
    self.techTree:AddTargetedActivation(kTechId.ShiftEcho,        kTechId.EchoTech,            kTechId.MatureShift)
    
    self.techTree:AddActivation(kTechId.ShiftEnergize,            kTechId.None,         kTechId.None)

    // Shade targeted abilities - treat phantasms as build nodes so we show ghost and attach points for fake hive
    self.techTree:AddResearchNode(kTechId.PhantasmTech,             kTechId.MatureShade,         kTechId.HiveColony)
    self.techTree:AddBuildNode(kTechId.ShadePhantasmFade,           kTechId.PhantasmTech,        kTechId.MatureShade)
    self.techTree:AddBuildNode(kTechId.ShadePhantasmOnos,           kTechId.None,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShadePhantasmHive,           kTechId.PhantasmTech,        kTechId.MatureShade)
    
    // Creature upgrades. Make sure the first prerequisite is the main tech required for it, as this is 
    // what is used to display research % in the alien evolve menu.
    self.techTree:AddResearchNode(kTechId.CarapaceTech, kTechId.Crag, kTechId.HiveColony)
    self.techTree:AddBuyNode(kTechId.Carapace, kTechId.CarapaceTech, kTechId.None, kTechId.Skulk)
    self.techTree:AddResearchNode(kTechId.FeedTech, kTechId.Crag, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Feed, kTechId.FeedTech, kTechId.None, kTechId.Skulk)

    self.techTree:AddResearchNode(kTechId.BloodThirstTech, kTechId.Whip, kTechId.None)
    self.techTree:AddBuyNode(kTechId.BloodThirst, kTechId.BloodThirstTech, kTechId.None, kTechId.Skulk)

    self.techTree:AddResearchNode(kTechId.CorpulenceTech, kTechId.Whip, kTechId.HiveMass)
    self.techTree:AddBuyNode(kTechId.Corpulence, kTechId.CorpulenceTech, kTechId.None, kTechId.Gorge)
    self.techTree:AddResearchNode(kTechId.BacteriaTech, kTechId.Crag, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Bacteria, kTechId.BacteriaTech, kTechId.None, kTechId.Gorge)
    self.techTree:AddBuyNode(kTechId.HydraAbility, kTechId.None, kTechId.None, kTechId.Gorge)
    self.techTree:AddBuildNode(kTechId.Hydra,                     kTechId.None,           kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.PiercingTech, kTechId.HiveColony, kTechId.Whip)
    self.techTree:AddBuyNode(kTechId.Piercing, kTechId.PiercingTech, kTechId.None, kTechId.Lerk)
    self.techTree:AddResearchNode(kTechId.AdrenalineTech, kTechId.HiveMass, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Adrenaline, kTechId.AdrenalineTech, kTechId.None, kTechId.Lerk)
    
    self.techTree:AddResearchNode(kTechId.FeintTech, kTechId.HiveMass, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Feint, kTechId.FeintTech, kTechId.HiveMass, kTechId.Fade)
    self.techTree:AddResearchNode(kTechId.SapTech, kTechId.HiveMass, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Sap, kTechId.SapTech, kTechId.HiveMass, kTechId.Fade)
    
    self.techTree:AddResearchNode(kTechId.BoneShieldTech, kTechId.Crag, kTechId.HiveColony)
    self.techTree:AddBuyNode(kTechId.BoneShield, kTechId.BoneShieldTech, kTechId.None, kTechId.Onos)
    self.techTree:AddResearchNode(kTechId.StompTech, kTechId.HiveColony, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Stomp, kTechId.StompTech, kTechId.None, kTechId.Onos)

    self.techTree:SetComplete()
    
end

function AlienTeam:ProcessGeneralHelp(player)

    if(GetGamerules():GetGameStarted() and player:AddTooltipOncePer("Press your 'b' key to evolve.", 45)) then
        return true
    end
    
    return PlayingTeam.ProcessGeneralHelp(self, player)
    
end

function AlienTeam:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)

    PlayingTeam.UpdateTeamSpecificGameEffects(self, teamEntities, enemyPlayers)
    
    // Clear gameplay effect we're processing
    for index, entity in ipairs(teamEntities) do
    
        entity:SetGameEffectMask(kGameEffect.InUmbra, false)
        entity:SetGameEffectMask(kGameEffect.Cloaked, false)
                    
    end
    
    for index, entity in ipairs(enemyPlayers) do
        entity:SetGameEffectMask(kGameEffect.Disorient, false)
    end
    
    // Update umbra
    self:UpdateUmbraGameEffects(teamEntities)
    
    // Update Fury
    self:UpdateFuryGameEffects(teamEntities)
    
    // Update shades
    self:UpdateShadeEffects(teamEntities, enemyPlayers)

end
