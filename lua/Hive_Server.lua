// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Hive:GetTeamType()
    return kAlienTeamType
end

// Aliens log in to hive instantly
function Hive:GetLoginTime()
    return 0
end

function Hive:OnCreate()

    CommandStructure.OnCreate(self)
    
    self:SetLevelTechId(1, kTechId.Hive)
    //self:SetLevelTechId(2, kTechId.HiveMass)
    //self:SetLevelTechId(3, kTechId.HiveColony)
    
    self.upgradeTechId = kTechId.None
    
    self:SetTechId(kTechId.Hive)
    
    self.maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    self.health = kHiveHealth
    
    self:SetModel(Hive.kModelName)

end

function Hive:OnDestroy()
    
    self:ClearInfestation()
    
    CommandStructure.OnDestroy(self)

end

function Hive:OnKill(damage, attacker, doer, point, direction)

    CommandStructure.OnKill(self, damage, attacker, doer, point, direction)
    
    if self:GetAttached() then
        self:GetAttached():SetTechLevel(1)
    end
    
end

function Hive:OnThink()

    CommandStructure.OnThink(self)   
    
    self:UpdateEggs()
    
    self:UpdateInfestation()
    
    self:UpdateHealing()
    
end

function Hive:GetNumEggs()

    local numEggs = 0
    local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())    
    for index, egg in ipairs(eggs) do
        if egg:GetLocationName() == self:GetLocationName() then
            numEggs = numEggs + 1
        end
    end
    
    return numEggs
end

function Hive:GetNumDesiredEggs()
    if self:GetTechId() == kTechId.Hive then
        return Hive.kHiveNumEggs
    /*
    elseif self:GetTechId() == kTechId.HiveMass then
        return Hive.kMassNumEggs
    elseif self:GetTechId() == kTechId.HiveColony then
        return Hive.kColonyNumEggs
    */
    end
    ASSERT(false, string.format("Hive tech id invalid: %s", EnumToString(kTechId, self:GetTechId())))
    return Hive.kHiveNumEggs 
end

// Make sure there's enough room here for an egg
function Hive:SpawnEgg()

    local success, spawn = GetRandomFreeEggSpawn(self:GetLocationName())

    if success then
    
        local egg = CreateEntity(Egg.kMapName, spawn:GetOrigin(), self:GetTeamNumber())
        
        if egg ~= nil then 
            
            egg:SetAngles(spawn:GetAngles())
            
            // To make sure physics model is updated without waiting a tick
            egg:UpdatePhysicsModel()
        
            self.timeOfLastEgg = Shared.GetTime()
            
            return egg
            
        end
        
    end
    
    return nil
    
end

function Hive:GetEggSpawnTime()
    return kAlienRespawnTime
end

function Hive:GetCanSpawnEgg()

    local canSpawnEgg = false
    
    if self:GetIsBuilt() then
    
        if self.timeOfLastEgg == nil or (Shared.GetTime() > (self.timeOfLastEgg + self:GetEggSpawnTime())) then
        
            canSpawnEgg = true
            
        end
        
    end
    
    return canSpawnEgg
    
end

function Hive:SpawnEggs()

    local numEggsSpawned = 0
    
    while ((self:GetNumEggs() < self:GetNumDesiredEggs())) do
    
        if self:SpawnEgg() ~= nil then
            numEggsSpawned = numEggsSpawned + 1
        else
            break
        end
        
    end
    
    return numEggsSpawned
    
end

function Hive:OnOverrideSpawnInfestation(infestation)
    infestation:SetGeneratorState(true)
    infestation:SetMaxRadius(kHiveInfestationRadius)
end

// Spawn initial eggs and infestation
function Hive:SpawnInitial()
    self:SpawnEggs()
    self:SpawnInitialInfestation()
end

// Spawn a new egg around the hive if needed. Returns true if it did.
function Hive:UpdateEggs()

    local createdEgg = false

    // Count number of eggs nearby and see if we need to create more, but only every so often
    if self:GetCanSpawnEgg() and (self:GetNumEggs() < self:GetNumDesiredEggs()) then
    
        createdEgg = (self:SpawnEgg() ~= nil)
        
    end 

    // So we don't create a new egg instantly when an egg is killed (still takes build time)
    if self:GetNumEggs() == self:GetNumDesiredEggs() then
        self.timeOfLastEgg = Shared.GetTime()
    end   

    return createdEgg
    
end

function Hive:UpdateHealing()

    if self.timeOfLastHeal == nil or Shared.GetTime() > (self.timeOfLastHeal + Hive.kHealthUpdateTime) then
        
        local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
        
        for index, player in ipairs(players) do
        
            if player:GetIsAlive() and ((player:GetOrigin() - self:GetOrigin()):GetLength() < Hive.kHealRadius) then
            
                player:AddHealth( player:GetMaxHealth() * Hive.kHealthPercentage, true )
            
            end
            
        end
        
        self.timeOfLastHeal = Shared.GetTime()
        
    end
    
end

function Hive:GetDamagedAlertId()

    // Trigger "hive dying" on less than 40% health, otherwise trigger "hive under attack" alert every so often
    if self:GetHealth() / self:GetMaxHealth() < Hive.kHiveDyingThreshold then
        return kTechId.AlienAlertHiveDying
    else
        return kTechId.AlienAlertHiveUnderAttack
    end
    
end

function Hive:OnTakeDamage(damage, doer, point)

    CommandStructure.OnTakeDamage(self, damage, doer, point)
    
    if(self:GetIsAlive()) then

        // Play freaky sound for team mates
        local team = self:GetTeam()
        team:PlayPrivateTeamSound(Hive.kWoundAlienSound, self:GetModelOrigin())
        
        // ...and a different sound for enemies
        local enemyTeamNumber = GetEnemyTeamNumber(team:GetTeamNumber())    
        local enemyTeam = GetGamerules():GetTeam(enemyTeamNumber)
        if enemyTeam ~= nil then
            enemyTeam:PlayPrivateTeamSound(Hive.kWoundSound, self:GetModelOrigin())
        end
        
        // Trigger alert for Commander 
        team:TriggerAlert(kTechId.AlienAlertHiveUnderAttack, self)
        
    end
    
end

function Hive:OnConstructionComplete()

    CommandStructure.OnConstructionComplete(self)
    
    // Play special tech point animation at same time so it appears that we bash through it
    local attachedTechPoint = self:GetAttached()
    if attachedTechPoint then
        attachedTechPoint:SetAnimation(TechPoint.kAlienAnim, true)
    else
        Print("Hive not attached to tech point")
    end
    
    self:GetTeam():TriggerAlert(kTechId.AlienAlertHiveComplete, self)    
    
    self:SpawnInfestation()
end

/*
function Hive:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success and (structure and structure:GetId() == self:GetId()) then
    
        local techPoint = self:GetAttached()
        local techLevel = nil

        if(researchId == kTechId.HiveMassUpgrade) then
        
            success = self:Upgrade(kTechId.HiveMass)
            techLevel = 2
            
        elseif(researchId == kTechId.HiveColonyUpgrade) then
        
            success = self:Upgrade(kTechId.HiveColony)
            techLevel = 3
            
        end    
        
        if techPoint and techLevel then
            techPoint:SetTechLevel(techLevel)
        end
        
    end
    
    return success    
end
*/

function Hive:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Alien") and player:GetTeamNumber() == self:GetTeamNumber()
end

function Hive:GetCommanderClassName()
    return AlienCommander.kMapName   
end

function Hive:LoginPlayer(player)

    local commander = CommandStructure.LoginPlayer(self, player)

    if not self.hasBeenOccupied then
    
        // Create some initial Drifters
        for i = 1, kInitialDrifters do
            local drifter = CreateEntity(Drifter.kMapName, self:GetOrigin(), self:GetTeamNumber())
            drifter:SetOwner(commander)
        end
        
        self.hasBeenOccupied = true

    end  

end

function Hive:SetSupportingUpgradeTechId(techId)
    self.upgradeTechId = techId
end

