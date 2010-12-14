// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Extractor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Marine resource extractor. Gathers resources when built on a nozzle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ResourceTower.lua")

class 'Extractor' (ResourceTower)

Extractor.kMapName = "extractor"

Extractor.kModelName = PrecacheAsset("models/marine/extractor/extractor.model")

Extractor.kActiveSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_active")
Extractor.kDeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_deploy")
Extractor.kKilledSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_death")
Extractor.kHarvestedSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_harvested")

Extractor.kCollectionEffect = PrecacheAsset("cinematics/marine/extractor/collection_effect.cinematic")
Extractor.kDeathEffect = PrecacheAsset("cinematics/marine/extractor/death.cinematic")

Shared.PrecacheModel(Extractor.kModelName)

function Extractor:OnInit()

    ResourceTower.OnInit(self)
    
end

function Extractor:GetRequiresPower()
    return true
end

function Extractor:GetDeathEffect()
    return Extractor.kDeathEffect
end

function Extractor:GetActiveSound()
    return Extractor.kActiveSound
end

function Extractor:GetDeploySound()
    return Extractor.kDeploySound
end

function Extractor:GetKilledSound(doer)
    return Extractor.kKilledSound
end

function Extractor:GetHarvestedSound()
    return Extractor.kHarvestedSound
end

function Extractor:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = {   kTechId.None, kTechId.None, kTechId.None, kTechId.None,  
                                kTechId.None, kTechId.None, kTechId.Recycle, kTechId.None }
        
        if (self:GetResearchingId() == kTechId.None) and (self:GetUpgradeLevel() < ResourceTower.kMaxUpgradeLevel) then
            techButtons[kMarineUpgradeButtonIndex] = kTechId.ExtractorUpgrade
        end
        
        return techButtons
        
    end
    
    return nil
    
end

function Extractor:OnAnimationComplete(anim)

    if anim == Structure.kAnimDeploy or anim == self:GetPowerUpAnimation() then
    
        self:SetAnimationWithBlending(Structure.kAnimActive, self:GetBlendTime(), true)
        
        // Make sure we only have one copy playing
        local activeSound = self:GetActiveSound()
        self:StopSound(activeSound)
        self:PlaySound(activeSound)

    else
        ResourceTower.OnAnimationComplete(self, anim)
    end
    
end

function Extractor:OnResearchComplete(structure, researchId)

    local success = ResourceTower.OnResearchComplete(self, structure, researchId)
    
    if success and structure == self and researchId == kTechId.ExtractorUpgrade then
    
        self:SetUpgradeLevel(self:GetUpgradeLevel() + 1)
        
    end
    
    return success   
    
end

function Extractor:GetDeathAnimation()
    return ConditionalValue(self:GetIsBuilt(), "death_spawn", "death_deployed")   
end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end


Shared.LinkClassToMap("Extractor", Extractor.kMapName, {})