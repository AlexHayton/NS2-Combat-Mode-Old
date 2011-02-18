// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

function Harvester:GetIsAlienStructure()
    return true
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


function Harvester:GetDamagedAlertId()
    return kTechId.AlienAlertHarvesterUnderAttack
end

Shared.LinkClassToMap("Harvester", Harvester.kMapName)