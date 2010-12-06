// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
end

// Marine sounds
Structure.kMarineBuildSound = PrecacheAsset("sound/ns2.fev/marine/structures/mac/build")
Structure.kMarineKilledSound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_death")
Structure.kMarineSpawnSound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_spawn")
Structure.kMarineDeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_deploy")
Structure.kMarineRecycleSound = PrecacheAsset("sound/ns2.fev/marine/structures/recycle")
Structure.kPowerUpSound = PrecacheAsset("sound/ns2.fev/marine/structures/power_up")
Structure.kPowerDownSound = PrecacheAsset("sound/ns2.fev/marine/structures/power_down")

// Alien sounds
Structure.kAlienBuildSound = PrecacheAsset("sound/ns2.fev/alien/gorge/build")
Structure.kAlienAutoBuildSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_build")
Structure.kAlienKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_death_large")
Structure.kAlienSpawnSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_spawn_large")
Structure.kAlienKilledByAxeSound = PrecacheAsset("sound/ns2.fev/alien/structures/death_axe")
Structure.kAlienKilledByGrenadeSound = PrecacheAsset("sound/ns2.fev/alien/structures/death_grenade")
Structure.kAlienDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/deploy_large")
Structure.kAlienUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/structure_under_attack")

// Marine cinematics
Structure.kMarineHitEffect = PrecacheAsset("cinematics/marine/structures/hit.cinematic")
Structure.kMarineHitBigEffect = PrecacheAsset("cinematics/marine/structures/hit_big.cinematic")
Structure.kMarineHurtEffect = PrecacheAsset("cinematics/marine/structures/hurt.cinematic")
Structure.kMarineHurtSevereEffect = PrecacheAsset("cinematics/marine/structures/hurt_severe.cinematic")
Structure.kMarineDeathEffect = PrecacheAsset("cinematics/marine/structures/generic_death.cinematic")
Structure.kMarineSpawnBuildingEffect = PrecacheAsset("cinematics/marine/structures/spawn_building.cinematic")
Structure.kMarineRecycleEffect = PrecacheAsset("cinematics/marine/structures/recycle.cinematic")

// Alien cinematics
Structure.kAlienSpawnSmallEffect = PrecacheAsset("cinematics/alien/structures/spawn_small.cinematic")
Structure.kAlienSpawnLargeEffect = PrecacheAsset("cinematics/alien/structures/spawn_large.cinematic")
Structure.kAlienHitEffect = PrecacheAsset("cinematics/alien/structures/hit.cinematic")
Structure.kAlienHitBigEffect = PrecacheAsset("cinematics/alien/structures/hit_big.cinematic")
Structure.kAlienDeathSmallEffect = PrecacheAsset("cinematics/alien/structures/death_small.cinematic")
Structure.kAlienDeathLargeEffect = PrecacheAsset("cinematics/alien/structures/death_large.cinematic")
Structure.kAlienBuildEffect = PrecacheAsset("cinematics/alien/structures/build.cinematic")
Structure.kAlienCloakEffect = PrecacheAsset("cinematics/alien/structures/cloak.cinematic")
Structure.kAlienBurnEffect = PrecacheAsset("cinematics/alien/structures/burn.cinematic")
Structure.kAlienHurtEffect = PrecacheAsset("cinematics/alien/structures/hurt.cinematic")
Structure.kAlienHurtSevereEffect = PrecacheAsset("cinematics/alien/structures/hurt_severe.cinematic")

// Play construction sound every time structure has built this much (faster if multiple builders)
Structure.kBuildSoundInterval = .5

// Start with this percentage of health when spawned
Structure.kStartHealthScalar = .3

Structure.kDefaultBuildTime = 8.00

Structure.kBuildInterval = 0.65

// Played when structure is first created (includes tech points)
Structure.kAnimSpawn = "spawn"

// Played structure becomes fully built
Structure.kAnimDeploy = "deploy"

// Played when ARC, Extractor fully built 
Structure.kAnimActive = "active"

Structure.kAnimDeath = "death"

Structure.kAnimPowerDown = "power_down"
Structure.kAnimPowerUp = "power_up"

// At full health, get half the price back
Structure.kRecyclePaybackScalar = .5

Structure.kRandomDamageEffectNode = "fxnode_damage"     // Looks for 1-5 to find damage points

local networkVars =
{
    // Tech id of research this building is currently researching
    researchingId           = "enum kTechId",

    // 0 to 1 scalar of progress
    researchProgress        = "float",
        
    // Time we've spent building
    buildTime               = "float",
    
    // 0-1 scalar representing build completion time
    buildFraction           = "float",
    
    // true if structure finished building
    constructionComplete    = "boolean",
    
    powered                 = "boolean",
}

function Structure:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    // Make the structure kinematic so that the player will collide with it.
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)

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
    return self:GetIsPowered() or not self:GetRequiresPower()
end

function Structure:GetIdleSound()
    return nil
end

function Structure:GetResearchingId()
    return self.researchingId
end

function Structure:GetResearchProgress()
    return self.researchProgress
end

function Structure:GetDamageEffectOffset()
    return Vector(0, 1, 0)
end

function Structure:GetTechAllowed(techId, techNode, player)

    if(techNode == nil) then
        return false
    end

    // Allow upgrades and energy builds when we're not researching/building something else
    if(techNode:GetIsUpgrade() or techNode:GetIsEnergyBuild()) then
    
        // Let child override this
        return self:GetUpgradeTechAllowed(techId)
    
    // If tech is research
    elseif(techNode:GetIsResearch()) then
    
        // Return false if we're researching, or if tech is being researched
        return self:GetResearchTechAllowed(techNode)

    // If tech is action or buy action
    elseif(techNode:GetIsAction() or techNode:GetIsBuy()) then
    
        // Return false if we don't have enough plasma
        if(player:GetPlasma() < techNode:GetCost()) then
            return false
        end
        
    // If tech is activation
    elseif(techNode:GetIsActivation()) then
    
        // Return false if structure doesn't have enough energy
        if(techNode:GetCost() <= self:GetEnergy()) then
            return self:GetActivationTechAllowed(techId)
        else
            return false
        end
        
    // If tech is build
    elseif(techNode:GetIsBuild()) then
    
        // return false if we don't have enough carbon
        return (player:GetTeamCarbon() >= techNode:GetCost())
        
    end
    
    return true
    
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

// Children can decide not to allow certain activations at certain times (energy cost already considered)
function Structure:GetActivationTechAllowed(techId)
    return true
end

function Structure:GetCanBeUsed(player)
    return true
end

// Assumes all structure are marine or alien
function Structure:GetIsAlienStructure()
    return false
end

function Structure:GetKilledSound(doer)

    if self:GetIsAlienStructure() then
    
        if doer ~= nil then
            local doerClassName = doer:GetClassName()
            if doerClassName == "Axe" then 
                return Structure.kAlienKilledByAxeSound
            elseif doerClassName == "Grenade" then
                return Structure.kAlienKilledByGrenadeSound
            end
        end
        
        return Structure.kAlienKilledSound
        
    end
    return Structure.kMarineKilledSound
end

function Structure:GetSpawnSound()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienSpawnSound, Structure.kMarineSpawnSound)
end

function Structure:GetDeploySound()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienDeploySound, Structure.kMarineDeploySound)
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

function Structure:GetBuildSound()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienBuildSound, Structure.kMarineBuildSound)
end

function Structure:GetPlaceBuildingEffect()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienSpawnSmallEffect, Structure.kMarineSpawnBuildingEffect)
end

function Structure:GetFlinchEffect(damage)
    if damage > 20 then
        return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienHitBigEffect, Structure.kMarineHitBigEffect)
    end
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienHitEffect, Structure.kMarineHitEffect)
end

function Structure:GetHurtEffect()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienHurtEffect, Structure.kMarineHurtEffect)
end

function Structure:GetHurtSevereEffect()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienHurtSevereEffect, Structure.kMarineHurtSevereEffect)
end

function Structure:GetDeathEffect()
    return ConditionalValue(self:GetIsAlienStructure(), Structure.kAlienDeathSmallEffect, Structure.kMarineDeathEffect)
end

function Structure:GetDeathAnimation()
    return Structure.kAnimDeath
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

function Structure:GetIsBuilt()
    return self.constructionComplete and self:GetIsAlive()
end

if Client then
function Structure:OnUse(player, elapsedTime, useAttachPoint)
    return false
end
end

function Structure:GetSpawnAnimation()
    return Structure.kAnimSpawn
end

// If structure can be repaired by buildbot welder right now, along with whether it can be welded in the future
function Structure:GetCanBeWelded(entity)

    local canBeWeldedNow = self:GetIsBuilt() and entity:GetTeamNumber() == self:GetTeamNumber() and self:GetHealth() < self:GetMaxHealth()
    local canBeWeldedFuture = false
    
    return canBeWeldedNow, canBeWeldedFuture
    
end

function Structure:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)

    // Pose parameters calculated on server from current order
    if not Shared.GetIsRunningPrediction() then
        self:UpdatePoseParameters(deltaTime)
    end
    
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


Shared.LinkClassToMap("Structure", Structure.kMapName, networkVars)
