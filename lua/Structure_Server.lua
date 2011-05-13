// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure_Server.lua
//
// Structures are the base class for all structures in NS2.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Balance.lua")
Script.Load("lua/Gamerules_Global.lua")

function Structure:SetEffectsActive(state)
    self.effectsActive = state
end

function Structure:GetCanResearch()

    return self:GetIsBuilt() and self:GetIsActive() and (self.timeResearchStarted == 0)

end

// Could be for research or upgrade
function Structure:SetResearching(techNode, player)

    self.researchingId = techNode.techId
    self.researchTime = techNode.time
    self.researchingPlayerId = player:GetId()
    
    self.timeResearchStarted = Shared.GetTime()
    self.timeResearchComplete = techNode.time
    self.researchProgress = 0
    
end

function Structure:OnResearch(techId)
end

function Structure:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    local used = false
    
    if self:GetCanConstruct(player) then        
    
        // Always build by set amount of time, for AV reasons
        // Calling code will put weapon away we return true
        if self:Construct(Structure.kUseInterval) then
        
            // Give points for building structures
            if self:GetIsBuilt() and not self:isa("Hydra") then                
                player:AddScore(kBuildPointValue)
            end
            
            self:TriggerEffects("construct", {effecthostcoords = BuildCoordsFromDirection(player:GetViewCoords().zAxis, usePoint), isalien = self:GetIsAlienStructure()})
            
            used = true
            
        end
                
    end
    
    return used
    
end

function Structure:UpdateResearch()

    if (self:GetIsBuilt() and (self.researchingId ~= kTechId.None)) then
    
        local timePassed = Shared.GetTime() - self.timeResearchStarted
        
        // Adjust for metabolize effects
        if self:GetTeam():GetTeamType() == kAlienTeamType then
            timePassed = GetAlienEvolveResearchTime(timePassed, self)
        end
        
        local researchTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, self.researchTime)
        self:SetResearchProgress( timePassed / researchTime )
            
    end
    
end

// returns nil if not researching
function Structure:GetResearchProgress()

    if (self:GetIsBuilt() and (self.researchingId ~= kTechId.None)) then
        return self.researchProgress
    end

    return nil
    
end

function Structure:AbortResearch()
    if(self.researchProgress > 0) then
        local researchNode = self:GetTeam():GetTechTree():GetTechNode(self.researchingId)
        if researchNode ~= nil then
            researchNode.researching = false
        end
    end
end

function Structure:GetDamagedAlertId()

    local team = self:GetTeam()
    
    if team:isa("PlayingTeam") then
    
        local teamType = team:GetTeamType()        
        if teamType == kAlienTeamType then
            return kTechId.AlienAlertStructureUnderAttack
        end
        
    end
    
    return kTechId.MarineAlertStructureUnderAttack

end

// Play hurt or wound effects
function Structure:OnTakeDamage(damage, doer, point)

    LiveScriptActor.OnTakeDamage(self, damage, doer, point)
    
    local team = self:GetTeam()
    if team.TriggerAlert then
        team:TriggerAlert(self:GetDamagedAlertId(), self)
    end
    
end

function Structure:SetResearchProgress(progress)

    progress = math.max(math.min(progress, 1), 0)
    
    if(progress ~= self.researchProgress) then
    
        self.researchProgress = progress
        
        // Update research in tech tree so player buy menus can display it easily
        local researchNode = self:GetTeam():GetTechTree():GetTechNode(self.researchingId)
        if researchNode ~= nil then
        
            researchNode:SetResearchProgress(self.researchProgress)
            
            self:GetTeam():GetTechTree():SetTechNodeChanged(researchNode)
            
            // Update research progress
            if(self.researchProgress == 1) then
        
                self:GetTeam():OnResearchComplete(self, self.researchingId) 
                
            end
            
        else
        
            Print("%s:SetResearchProgress(%.2f) - Couldn't find tech node to set research progress (techId: %s).", self:GetClassName(), self.researchProgress, ToString(self.researchingId))
            
        end
        
    end
    
end

function Structure:OnEntityChange(oldId, newId)

    LiveScriptActor.OnEntityChange(self, oldId, newId)
    
    if (oldId == self.researchingPlayerId) and (self.researchingPlayerId ~= Entity.invalidId) then
    
        self.researchingPlayerId = newId
        
    end
    
end

function Structure:OnResearchComplete(structure, researchId)

    if structure and (structure:GetId() == self:GetId()) then
    
        local researchNode = self:GetTeam():GetTechTree():GetTechNode(researchId)
        if researchNode and researchNode:GetIsEnergyBuild() then        

            // Handle energybuild actions        
            local mapName = LookupTechData(researchId, kTechDataMapName)
            local energyBuildEntity = CreateEntity(mapName, self:GetOrigin(), structure:GetTeamNumber())
            
            // Set owner to commander that issued the order 
            local owner = Shared.GetEntity(self.researchingPlayerId)
            energyBuildEntity:SetOwner(owner)
            
        end
    
        self.researchingId = kTechId.None
        self.researchingPlayerId = Entity.invalidId
        self.researchTime = 0
        self.timeResearchStarted = 0
        self.timeResearchComplete = 0
        self.researchProgress = 0
        
        return true
        
    end
    
    return false
    
end

// Replace structure with new structure. Used when upgrading structures.
function Structure:Replace(className)

    local newStructure = CreateEntity(className, self:GetOrigin())
    
    // Copy over relevant fields 
    self:OnReplace(newStructure)
           
    // Now destroy old structure
    DestroyEntity(self)

    return newStructure

end

function Structure:OnInit()    

    LiveScriptActor.OnInit(self)
    
    self.researchingId = kTechId.None
    self.researchProgress = 0
    self.researchingPlayerId = Entity.invalidId
         
    self.buildTime = 0
    self.buildFraction = 0
    self.constructionComplete = (self.startsbuilt == 1)    
    
    self.powered = false

    // Structures start with a percentage of their full health and gain more as they're built.
    if self.startsBuilt then
        self:SetHealth( self:GetMaxHealth() )
    else
        self:SetHealth( self:GetMaxHealth() * kStartHealthScalar )
    end

    // Server-only data    
    self.timeResearchStarted = 0
    self.timeOfNextBuildEffects = 0
    self.deployed = false
    
    self:SetIsVisible(true)
    
    local spawnAnim = self:GetSpawnAnimation()
    if spawnAnim ~= "" then
        self:SetAnimation(spawnAnim)
    end
    
    self:TriggerEffects("spawn")
    
    // Make attachment before setting construction complete as the
    // construction complete callback may require the attachment.
    self:FindAndMakeAttachment()
    
    if GetGamerules():GetAutobuild() then
        self:SetConstructionComplete()
    end
    
    if self.startsBuilt and not self:GetIsBuilt() then
        self:SetConstructionComplete()
    end
    
end

/**
 * Find whatever this Structure should be attached to and attach to it.
 */
function Structure:FindAndMakeAttachment()
end

function Structure:OnLoad()

    LiveScriptActor.OnLoad(self)
    
    self.startsBuilt = GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false)
    
end

function Structure:OnReplace(newStructure)

    // Copy over relevant fields 
    newStructure:SetTeamNumber( self:GetTeamNumber() )
    newStructure:SetAngles( self:GetAngles() )

    // Copy attachments
    newStructure:SetAttached(self.attached)
    
    // TODO: Do we need to call down into LiveScriptActor?
    newStructure.buildTime = self.buildTime
    newStructure.buildFraction = self.buildFraction

end

// Change health and max health when changing techIds
function Structure:UpdateHealthValues(newTechId)

    // Change current and max hit points 
    local prevMaxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    local newMaxHealth = LookupTechData(newTechId, kTechDataMaxHealth)
    
    if prevMaxHealth == nil or newMaxHealth == nil then
    
        Print("%s:UpdateHealthValues(%d): Couldn't find health for id: %s = %s, %s = %s", self:GetClassName(), tostring(newTechId), tostring(self:GetTechId()), tostring(prevMaxHealth), tostring(newTechId), tostring(newMaxHealth))
        
        return false
        
    elseif(prevMaxHealth ~= newMaxHealth and prevMaxHealth > 0 and newMaxHealth > 0) then
    
        // Calculate percentage of max health and preserve it
        local percent = self.health/prevMaxHealth
        self.health = newMaxHealth * percent
        
        // Set new max health
        self.maxHealth = newMaxHealth
        
    end
    
    return true
        
end

function Structure:GetTeam()

    if not GetHasGameRules() then
        return nil
    end

    local teamNumber = self:GetTeamNumber()
    return GetGamerules():GetTeam(teamNumber)
    
end

function Structure:OnTeamChange(teamNumber)

    LiveScriptActor.OnTeamChange(self, teamNumber)
    
    // Remove tech from old team and add to new team (for autobuilding, etc.)
    local oldTeam = self:GetTeam()
    if(oldTeam ~= nil) then
        oldTeam:TechRemoved(self)
    end

    local newTeam = GetGamerules():GetTeam(teamNumber)
    if(newTeam ~= nil) then
        newTeam:TechAdded(self)
    end

end

function Structure:OnDestroy()

    local team = self:GetTeam()
    if(team ~= nil) then
        team:TechRemoved(self)
    end
    
    if self.structureInfestationId then
        Server.DestroyEntity(Shared.GetEntity(self.structureInfestationId))
        self.structureInfestationId = nil
    end
    
    LiveScriptActor.OnDestroy(self)
    
end

function Structure:OnKill(damage, killer, doer, point, direction)

    if(self:GetIsAlive()) then
    
        self.buildTime = 0
        self.buildFraction = 0
        self.constructionComplete = false
    
        self:SetIsAlive(false)
   
        self:ClearAttached()
        self:AbortResearch()
        
        LiveScriptActor.OnKill(self, damage, killer, doer, point, direction)
        
    end
    
end

function Structure:OnReset()

    // OnCreate will reset the team number, so preseve it here
    local teamNumber = self.teamNumber

    Structure.OnCreate(self)
    
    self.teamNumber = teamNumber
    
    self:ClearAttached()
    
    self:OnInit()
    
    LiveScriptActor.OnReset(self)
    
    if self.startsBuilt then
        self:SetConstructionComplete()
    end
    
end

// Override to allow players that are using a structure to send it commands
function Structure:OnCommand(activator, command)
end

/**
 * Called when structure is built
 */
function Structure:OnConstructionComplete()

    self.constructionComplete = true
    
    if self:GetTeamType() == kMarineTeamType then
        self:GetTeam():TriggerAlert(kTechId.MarineAlertConstructionComplete, self) 
    end
    
    self:TriggerEffects("construction_complete")   
    
    if self:GetRequiresPower() then
        self:UpdatePoweredState()
    end
    
    if not self:GetRequiresPower() or self.powered then
    
        local deployAnim = self:GetDeployAnimation()
        if deployAnim ~= "" then
            self:SetAnimation(deployAnim)
        end
        
        self:TriggerEffects("deploy")
        
    end
    
end

// Return alive power pack that's powering us, or power point in our location. 
function Structure:FindPowerSource()

    for index, powerPoint in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do
    
        if powerPoint:GetLocationName() == self:GetLocationName() and powerPoint:GetIsPowered() then

            return powerPoint        
            
        end
            
    end
    
    // Look for power packs
    local powerPacks = GetEntitiesForTeamWithinXZRange("PowerPack", self:GetTeamNumber(), self:GetOrigin(), PowerPack.kRange)
    
    for index, powerPack in ipairs(powerPacks) do
    
        if powerPack:GetIsAlive() then
        
            return powerPack
            
        end
            
    end
        
    return nil
    
end

function Structure:SetLocationName(name)

    LiveScriptActor.SetLocationName(self, name)
    self:UpdatePoweredState()

end

function Structure:UpdatePoweredState()

    if self:GetIsBuilt() and self:GetRequiresPower() then
    
        local powered = false
        local powerSource = self:FindPowerSource()
        
        if powerSource then
        
            local powerTeamNumber = powerSource:GetTeamNumber()            
            powered = ((self:GetTeamNumber() == powerTeamNumber) or (powerTeamNumber == kTeamReadyRoom))
                
        end        
        
        if self.powered ~= powered then

            self:OnPoweredChange(powered)
            
        end
        
    end
    
end

function Structure:OnPoweredChange(newPoweredState)

    self.powered = newPoweredState
    
    if self.powered then
    
        if not self.deployed then
        
            local deployAnim = self:GetDeployAnimation()
            if deployAnim ~= "" then
                self:SetAnimation(deployAnim)
            end

        else
        
            // Power up
            local powerUpAnim = self:GetPowerUpAnimation()
            if powerUpAnim ~= "" then
                self:SetAnimation(powerUpAnim)
            end
            
            self:TriggerEffects("power_up")
            
        end
    
    elseif not self.powered then
    
        local powerDownAnim = self:GetPowerDownAnimation()
        if powerDownAnim ~= "" then
            self:SetAnimation(powerDownAnim)
        end
        
        self:TriggerEffects("power_down")
        
    end
        
end

/**
 * Returns true if the specified player is able to use this structure.
 */
function Structure:CanPlayerUse(player)

    local structureTeam = self:GetTeamNumber()
    local activatorTeam = player:GetTeamNumber()

    // Allow the player to use structures on their team and neutral structures.
    return Shared.GetCheatsEnabled() and (activatorTeam > 0) and ((structureTeam == activatorTeam) or (structureTeam == 0))

end

/**
 * Build structure by elapsedTime amount and play construction sounds. Pass custom construction sound if desired, 
 * otherwise use Gorge build sound or Marine sparking build sounds.
 */
function Structure:Construct(elapsedTime)

    if (not self.constructionComplete) then

        local startBuildFraction = self.buildFraction
        local newBuildTime = self.buildTime + elapsedTime
        local timeToComplete = LookupTechData(self:GetTechId(), kTechDataBuildTime, Structure.kDefaultBuildTime)
        
        if(Shared.GetDevMode()) then
            timeToComplete = 1.0
        end
        
        if (newBuildTime >= timeToComplete) then
        
            self:SetConstructionComplete()
            
        else
        
            if ( (self.buildTime <= self.timeOfNextBuildEffects) and (newBuildTime >= self.timeOfNextBuildEffects) ) then
            
                self:TriggerEffects("construct")
                
                self.timeOfNextBuildEffects = newBuildTime + Structure.kBuildEffectsInterval
                
            end

            self.buildTime = newBuildTime
            self.buildFraction = math.max(math.min((self.buildTime / timeToComplete), 1), 0)
            
            self:AddBuildHealth( self.buildFraction - startBuildFraction )

        end
        
        return true

    end

    return false

end

// Add health to structure as it builds
function Structure:AddBuildHealth(scalar)

    // Add health according to build time
    if (scalar > 0) then
    
        local maxHealth = self:GetMaxHealth()        
        self:AddHealth( scalar * (1 - kStartHealthScalar) * maxHealth )
    
    end

end

function Structure:OnWeld(entity, elapsedTime)

    // MACs repair structures
    local health = 0
    
    if entity:isa("MAC") then
    
        health = self:AddHealth(MAC.kRepairHealthPerSecond * elapsedTime)
        
    end
    
    return (health > 0)
    
end

function Structure:OnWeldCanceled(entity)
    return true
end

function Structure:SetConstructionComplete()

    // Built structures need to belong to one team or the other, so give it to the builder's team if not set
    local teamNumber = self:GetTeamNumber()
    
    self.constructionComplete = true
    
    self:AddBuildHealth(1 - self.buildFraction)
    
    self.buildFraction = 1
    
    self:SetIsAlive(true)
    
    self:OnConstructionComplete()
    
    self:UpdatePoweredState()
    
    local team = self:GetTeam()
    if(team ~= nil) then
        team:TechBuilt(self)
    end
    
end

// How many resources does it cost?
function Structure:GetPointCost()

    return kDefaultStructureCost

end

function Structure:GetIsValidForRecycle()
    return true
end

function Structure:GetRecycleScalar()
    return kRecyclePaybackScalar
end

function Structure:PerformAction(techNode, position)

    if(techNode.techId == kTechId.Recycle) and self:GetIsValidForRecycle() then
    
        self:AbortResearch()
        
        self:TriggerEffects("recycle")
        
        local team = self:GetTeam()
        if(team ~= nil) then
            team:TechRemoved(self)
        end
        
        // Amount to get back, accounting for upgraded structures too
        local upgradeLevel = 0
        if self.GetUpgradeLevel then
            upgradeLevel = self:GetUpgradeLevel()
        end
        
        local amount = GetRecycleAmount(self:GetTechId(), upgradeLevel)
        local scalar = self:GetRecycleScalar()
        
        self:GetTeam():AddTeamResources(amount * scalar)
        
        self:SafeDestroy()   
        
        return true
    
    else
    
        return LiveScriptActor.PerformAction(self, techNode, position)
        
    end
    
end
