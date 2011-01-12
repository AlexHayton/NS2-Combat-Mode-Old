// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

Shared.PrecacheModel(Extractor.kModelName)

function Extractor:GetRequiresPower()
    return true
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

function Extractor:OnResearchComplete(structure, researchId)

    local success = ResourceTower.OnResearchComplete(self, structure, researchId)
    
    if success and structure == self and researchId == kTechId.ExtractorUpgrade then
    
        self:SetUpgradeLevel(self:GetUpgradeLevel() + 1)
        
    end
    
    return success   
    
end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end


Shared.LinkClassToMap("Extractor", Extractor.kMapName, {})