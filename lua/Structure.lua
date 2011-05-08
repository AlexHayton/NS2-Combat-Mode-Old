// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure.lua
//
// Structures are the base class for all structures in NS2.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Balance.lua")
Script.Load("lua/LiveScriptActor.lua")

class 'Structure' (LiveScriptActor)

Structure.kMapName                  = "structure"

if (Server) then
    Script.Load("lua/Structure_Server.lua")
else
    Script.Load("lua/Structure_Client.lua")
end

// Play construction effects every time structure has built this much (faster if multiple builders)
Structure.kBuildEffectsInterval = .5
Structure.kDefaultBuildTime = 8.00
Structure.kUseInterval = 0.65

// Played when structure is first created (includes tech points)
Structure.kAnimSpawn = "spawn"

// Played structure becomes fully built
Structure.kAnimDeploy = "deploy"

Structure.kAnimPowerDown = "power_down"
Structure.kAnimPowerUp = "power_up"

Structure.kRandomDamageEffectNode = "fxnode_damage"     // Looks for 1-5 to find damage points

local networkVars =
{
    // Tech id of research this building is currently researching
    researchingId           = "enum kTechId",

    // 0 to 1 scalar of progress
    researchProgress        = "float",
    
    // 0-1 scalar representing build completion time. Since we use this to blend
    // animations, it must be interpolated for the animations to appear smooth
    // on the client.
    buildFraction           = "interpolated float",
    
    // true if structure finished building
    constructionComplete    = "boolean",
    
    powered                 = "boolean",
    
    // Allows client-effects to be triggered
    effectsActive           = "boolean",
}

function Structure:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    // Make the structure kinematic so that the player will collide with it.
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)
    
    self.effectsActive = false

end
    
function Structure:GetEffectsActive()
    return self.effectsActive
end

// Use when structure is created and when it turns into another structure
function Structure:SetTechId(techId)

    local success = true
    
    if Server then
        success = self:UpdateHealthValues(techId)
    end
    
    if success then
        success = LiveScriptActor.SetTechId(self, techId)
    end
    
    return success
    
end

function Structure:GetIsActive()
    return self:GetIsAlive() and (self:GetIsPowered() or not self:GetRequiresPower())
end

function Structure:GetResearchingId()
    return self.researchingId
end

function Structure:GetResearchProgress()
    return self.researchProgress
end

function Structure:GetDescription()

    local description = LiveScriptActor.GetDescription(self)
    
    // Add "unpowered" if 
    if self:GetRequiresPower() and not self:GetIsPowered() then
        description = description .. " - Unpowered"
    end
    
    return description
    
end

function Structure:GetResearchTechAllowed(techNode)

    // Return false if we're researching, or if tech is being researched
    return not (self.researchingId ~= kTechId.None or techNode.researched or techNode.researching)
    
end

// Children should override this when they have upgrade tech attached to them. Allow upgrading
// if we're not busy researching something.
function Structure:GetUpgradeTechAllowed(techId)
    return (self.researchingId == kTechId.None)
end

function Structure:GetCanBeUsed(player)
    ASSERT(player ~= nil)
    return player:GetTeamNumber() == self:GetTeamNumber()
end

// Assumes all structures are marine or alien
function Structure:GetIsAlienStructure()
    return false
end

function Structure:GetDeployAnimation()
    return Structure.kAnimDeploy
end

function Structure:GetPowerDownAnimation()
    return Structure.kAnimPowerDown
end

function Structure:GetPowerUpAnimation()
    return Structure.kAnimPowerUp
end

function Structure:GetCanIdle()
    return self:GetIsBuilt() and self:GetIsActive()
end
    
function Structure:GetStatusDescription()

    if (not self:GetIsBuilt() ) then
    
        return "Constructing...", self:GetBuiltFraction()
        
    elseif (self:GetResearchProgress() ~= 0) then
    
        local name = LookupTechData(self:GetResearchingId(), kTechDataDisplayName, "<no display name>")
        
        return string.format("Researching %s...", name), self:GetResearchProgress()
    
    end
    
    return nil, nil
    
end

function Structure:GetBuiltFraction()
    return self.buildFraction
end

function Structure:GetCanConstruct(player)

    if not self:GetIsBuilt() and (player:GetTeamNumber() ~= GetEnemyTeamNumber(self:GetTeamNumber())) then
    
        if (player:isa("Marine") or player:isa("Gorge")) and player:GetCanNewActivityStart() then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Structure:GetIsBuilt()
    return self.constructionComplete and self:GetIsAlive()
end

if Client then
function Structure:OnUse(player, elapsedTime, useAttachPoint, usePoint)
    local success = self:GetCanConstruct(player)
    if success then
        player:SetActivityEnd(elapsedTime)
    end
    return success
end
end

function Structure:GetSpawnAnimation()
    return Structure.kAnimSpawn
end

// If structure can be repaired by buildbot welder right now, along with whether it can be welded in the future
function Structure:GetCanBeWelded(entity)

    local canBeWeldedNow = self:GetIsBuilt() and entity:GetTeamNumber() == self:GetTeamNumber() and
                           (self:GetHealth() < self:GetMaxHealth() or self:GetArmor() < self:GetMaxArmor())
    local canBeWeldedFuture = false
    
    return canBeWeldedNow, canBeWeldedFuture
    
end

function Structure:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)

    // Pose parameters calculated on server from current order
    self:UpdatePoseParameters(deltaTime)
    
end

function Structure:UpdatePoseParameters(deltaTime)

    if LookupTechData(self:GetTechId(), kTechDataGrows, false) then
    
        // This should depend on time passed
        local buildFraction = Slerp(self:GetPoseParam("grow"), self.buildFraction, deltaTime * .5)
        self:SetPoseParam("grow", buildFraction)    
        
    end
    
end

function Structure:GetRequiresPower()
    return false
end

function Structure:GetIsPowered()
    return self.powered
end

function Structure:GetEngagementPoint()

    local attachPoint, success = self:GetAttachPointOrigin("target")
    if not success then
        return LiveScriptActor.GetEngagementPoint(self)
    end
    return attachPoint
    
end

function Structure:GetEffectParams(tableParams)

    LiveScriptActor.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterBuilt] = self:GetIsBuilt()
    tableParams[kEffectFilterActive] = self:GetEffectsActive()
        
end

Shared.LinkClassToMap("Structure", Structure.kMapName, networkVars)
