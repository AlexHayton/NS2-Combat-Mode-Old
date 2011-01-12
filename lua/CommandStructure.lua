// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'CommandStructure' (Structure)
CommandStructure.kMapName = "commandstructure"

if (Server) then
    Script.Load("lua/CommandStructure_Server.lua")
end

local networkVars = 
{
    occupied            = "boolean",
    
    // Command Stations and Hives can have different levels
    // level 0 means it is unupgraded and can be upgraded to a 1, 2 or 3
    // 1/2/3 represents more advanced versions of the structure that
    // support higher-level tech
    level1TechId        = "integer (0 to " .. kTechIdMax .. ")",
    level2TechId        = "integer (0 to " .. kTechIdMax .. ")",
    level3TechId        = "integer (0 to " .. kTechIdMax .. ")"
}

function CommandStructure:OnCreate()

    Structure.OnCreate(self)
    
    self.maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    self.health = self.maxHealth
    
end

function CommandStructure:GetIsOccupied()
    return self.occupied
end

function CommandStructure:GetLevelTechId(level)

    if(level >= 1 and level <= 3) then
    
        if(level == 1) then
            return self.level1TechId
        elseif(level == 2) then
            return self.level2TechId
        elseif(level == 3) then
            return self.level3TechId
        end
        
    else
        Print("CommandStructure:GetLevelTechId(%d) - Level must be 1-3.", level)
    end
    
    return kTechId.None

end

function CommandStructure:SetLevelTechId(level, techId)

    if(level >= 1 and level <= 3) then
    
        if(level == 1) then
            self.level1TechId = techId
        elseif(level == 2) then
            self.level2TechId = techId
        elseif(level == 3) then
            self.level3TechId = techId
        end
        
    else
        Print("CommandStructure:SetLevelTechId(%d, %d) - Level must be 1-3.", level, techId)
    end
    
end

function CommandStructure:GetLevel()
    
    local techId = self:GetTechId()
    
    if(techId == self.level1TechId) then
        return 1
    elseif(techId == self.level2TechId) then
        return 2
    elseif(techId == self.level3TechId) then
        return 3
    end
    
    return nil        
    
end

function CommandStructure:GetEffectParams(tableParams)

    Structure.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterOccupied] = self.occupied
    
end

Shared.LinkClassToMap("CommandStructure", CommandStructure.kMapName, networkVars)