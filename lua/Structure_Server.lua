// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

function Structure:OnUse(player, elapsedTime, useAttachPoint)

    local used = false
    
    if not self:GetIsBuilt() and (player:GetTeamNumber() ~= GetEnemyTeamNumber(self:GetTeamNumber())) then
    
        if (player:isa("Marine") or player:isa("Gorge")) and player:GetCanNewActivityStart() then
        
            // Calling code will put weapon away we return true
            self:Construct(Structure.kBuildInterval)
            
            player:SetActivityEnd(Structure.kBuildInterval)

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
    
    local hurtEffect = nil    
    
    if self:GetHealthScalar() < .3 then
        hurtEffect = self:GetHurtSevereEffect()
    elseif self:GetHealthScalar() < .7 then
        hurtEffect = self:GetHurtEffect()
    end
    
    // If we haven't already played this effect, play it
    if hurtEffect and (hurtEffect ~= self.playingHurtEffect) and point ~= nil then

        Shared.CreateEffect(nil, hurtEffect, nil, Coords.GetTranslation(point))

        self.playingHurtEffect = hurtEffect
        
    end
    
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
        self:SetHealth( self:GetMaxHealth() * Structure.kStartHealthScalar )
    end

    // Server-only data    
    self.timeResearchStarted = 0
    self.timeOfNextBuildSound = 0
    self.deployed = false
    
    self:SetIsVisible(true)

    local spawnAnim = self:GetSpawnAnimation()
    if spawnAnim ~= "" then
        self:SetAnimation(spawnAnim)
    end
    
    self:PlaySound(self:GetSpawnSound())
    
end

function Structure:OnLoad()

    LiveScriptActor.OnLoad(self)
    
    self.startsBuilt = GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false)
    
    if self.startsBuilt then
        self:SetConstructionComplete()
    end
    
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

function Structure:Heal(amount) 

    local healed = false
    
    local newHealth = math.min( math.max(0, self.health + amount), self.maxHealth )
    if(self:GetIsAlive() and self.health ~= newHealth) then
    
        self.health = newHealth
        healed = true
        
    end    
    
    return healed
    
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

function Structure:OnKill(damage, killer, doer, point, direction)
    
    if(self:GetIsAlive()) then
    
        self.buildTime = 0
        self.buildFraction = 0
        self.constructionComplete = false
    
        self.alive = false
   
        local team = self:GetTeam()
        if(team ~= nil) then
            team:TechRemoved(self)
        end
        
        // Create death particle effect
        if point ~= nil then
        
            Shared.CreateEffect(nil, self:GetDeathEffect(), nil, self:GetCoords())
            
        end
        
        self:ClearAttached()
        
        LiveScriptActor.OnKill(self, damage, killer, doer, point, direction)
        
    end
    
end

function Structure:OnReset()

    Structure.OnCreate(self)
    
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
    
    if not self:GetRequiresPower() then
    
        self:PlaySound(self:GetDeploySound())

        local deployAnim = self:GetDeployAnimation()
        if deployAnim ~= "" then
            self:SetAnimation(deployAnim)
        end

    else
        self.powerPoint = self:FindPowerPoint()
    end
    
end

function Structure:FindPowerPoint()

    local structurePowerPoint = nil
    
    local powerPoints = GetGamerules():GetEntities("PowerPoint")
    
    for index, powerPoint in ipairs(powerPoints) do
    
        if powerPoint:GetLocationName() == self:GetLocationName() then
        
            structurePowerPoint = powerPoint
            
            break
            
        end
            
    end
       
    return structurePowerPoint
    
end

function Structure:GetPowerPoint()
    return self.powerPoint
end

function Structure:UpdatePoweredState()

    if self:GetRequiresPower() then
    
        local powered = false
        
        if self.powerPoint then
        
            if self.powerPoint:GetIsPowered()  then
            
                local powerTeamNumber = self.powerPoint:GetTeamNumber()            
                powered = ((self:GetTeamNumber() == powerTeamNumber) or (powerTeamNumber == kTeamReadyRoom))
                
            end
            
        // If no power point entity placed or no trigger found for it, let map function
        else 
            powered = true
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
        
            // Deploy instead of power up 
            self:PlaySound(self:GetDeploySound())

            local deployAnim = self:GetDeployAnimation()
            if deployAnim ~= "" then
                self:SetAnimation(deployAnim)
            end

        else
        
            // Power up
            self:PlaySound(Structure.kPowerUpSound)
            
            local powerUpAnim = self:GetPowerUpAnimation()
            if powerUpAnim ~= "" then
                self:SetAnimation(powerUpAnim)
            end
            
        end
    
    elseif not self.powered then
    
        // Power down
        self:PlaySound(Structure.kPowerDownSound)
        
        local powerDownAnim = self:GetPowerDownAnimation()
        if powerDownAnim ~= "" then
            self:SetAnimation(powerDownAnim)
        end
        
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
function Structure:Construct(elapsedTime, buildSound)

    if (not self.constructionComplete) then

        local startBuildFraction = self.buildFraction
        local newBuildTime = self.buildTime + elapsedTime
        local timeToComplete = LookupTechData(self:GetTechId(), kTechDataBuildTime, Structure.kDefaultBuildTime)
        
        if(Shared.GetDevMode()) then
            timeToComplete = .5
        end
        
        //if self:GetClassName() == "Harvester" then
        //    Print("Harvester:Construct(%.2f): %.2f, %.2f, %.2f", elapsedTime, startBuildFraction, newBuildTime, timeToComplete)
        //end

        if (newBuildTime >= timeToComplete) then
        
            self:SetConstructionComplete()
            
        else
        
            if ( (self.buildTime <= self.timeOfNextBuildSound) and (newBuildTime >= self.timeOfNextBuildSound) ) then
            
                if buildSound == nil then
                    buildSound = self:GetBuildSound()
                end
                
                self:PlaySound(buildSound)
                self.timeOfNextBuildSound = newBuildTime + Structure.kBuildSoundInterval
                
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
        self:AddHealth( scalar * (1 - Structure.kStartHealthScalar) * maxHealth )
    
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

function Structure:SetConstructionComplete()

    // Built structures need to belong to one team or the other, so give it to the builder's team if not set
    local teamNumber = self:GetTeamNumber()
    
    self.constructionComplete = true
    
    self:AddBuildHealth(1 - self.buildFraction)
    
    self.buildFraction = 1
    
    self.alive = true
    
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
    return Structure.kRecyclePaybackScalar
end

function Structure:PerformAction(techNode, position)

    if(techNode.techId == kTechId.Recycle) and self:GetIsValidForRecycle() then
    
        // Amount to get back at full health
        local carbonBack = LookupTechData(self:GetTechId(), kTechDataCostKey) * self:GetHealthScalar() * self:GetRecycleScalar()
        self:GetTeam():AddCarbon(carbonBack)
        
        Shared.PlayWorldSound(nil, Structure.kMarineRecycleSound, nil, self:GetOrigin())
        
        Shared.CreateEffect(nil, Structure.kMarineRecycleEffect, nil, self:GetCoords())
        
        local team = self:GetTeam()
        if(team ~= nil) then
            team:TechRemoved(self)
        end

        
        self:SafeDestroy()   
        
        return true
    
    else
    
        return LiveScriptActor.PerformAction(self, techNode, position)
        
    end
    
end

function Structure:OnAnimationComplete(animName)

    if(animName == Structure.kAnimDeploy) then
    
        local idleSound = self:GetIdleSound()
        if idleSound ~= nil then
        
            self:PlaySound(idleSound)
            
        end
        
    end

end
