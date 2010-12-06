// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Harvester.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ResourceTower.lua")

class 'Harvester' (ResourceTower)
Harvester.kMapName = "harvester"

Harvester.kModelName = PrecacheAsset("models/alien/harvester/harvester.model")

Harvester.kActiveSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_active")
Harvester.kHarvestedSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_harvested")
Harvester.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/deploy_small")
Harvester.kKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_death")
Harvester.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_wound")
Harvester.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/harvester_under_attack")

Harvester.kGlowEffect = PrecacheAsset("cinematics/alien/harvester/glow.cinematic")
Harvester.kIdleEffect = PrecacheAsset("cinematics/alien/harvester/resource_idle.cinematic")
Harvester.kCollectEffect = PrecacheAsset("cinematics/alien/harvester/resource_collect.cinematic")

Harvester.kAnimActiveTable = {{.4, "active1"}/*, {.7, "active2"}*/}

function Harvester:GetIsAlienStructure()
    return true
end

function Harvester:GetActiveSound()
    return Harvester.kActiveSound
end

function Harvester:GetDeploySound()
    return Harvester.kDeploySound
end

function Harvester:GetFlinchSound(damage)
    return Harvester.kWoundSound
end

function Harvester:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = { kTechId.None }
        
        if (self:GetResearchingId() == kTechId.None) and (self:GetUpgradeLevel() < ResourceTower.kMaxUpgradeLevel) then
            techButtons[1] = kTechId.HarvesterUpgrade
        end
        
        return techButtons
        
    end
    
    return nil
    
end

function Harvester:OnResearchComplete(structure, researchId)

    local success = ResourceTower.OnResearchComplete(self, structure, researchId)
    
    if success and structure == self and researchId == kTechId.HarvesterUpgrade then
    
        self:SetUpgradeLevel(self:GetUpgradeLevel() + 1)
        
    end
    
    return success   
    
end

function Harvester:GetKilledSound(doer)

    if doer ~= nil then
        local doerClassName = doer:GetClassName()
        if doerClassName == "Axe" then 
            return Structure.kAlienKilledByAxeSound
        elseif doerClassName == "Grenade" then
            return Structure.kAlienKilledByGrenadeSound
        end
    end

    return Harvester.kKilledSound
    
end

function Harvester:OnAnimationComplete(anim)

    if anim == Structure.kAnimDeploy then
    
        local activeAnimName = chooseWeightedEntry(Harvester.kAnimActiveTable)
        self:SetAnimationWithBlending(activeAnimName, self:GetBlendTime(), true)

        // Make sure we only have one copy playing
        local activeSound = self:GetActiveSound()
        self:StopSound(activeSound)
        self:PlaySound(activeSound)

    else
        ResourceTower.OnAnimationComplete(self, anim)
    end
    
end

function Harvester:GetHarvestedSound()
    return Harvester.kHarvestedSound
end

function Harvester:GetDamageEffectOffset()
    return Vector(-4, -8, 33)
end

function Harvester:GetDamagedAlertId()
    return kTechId.AlienAlertHarvesterUnderAttack
end

function Harvester:GetDeathAnimation()
    return "death"
end

Shared.LinkClassToMap("Harvester", Harvester.kMapName)