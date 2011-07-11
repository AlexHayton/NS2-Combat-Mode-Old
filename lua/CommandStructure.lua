// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
    commanderId         = "entityid",
}

function CommandStructure:OnCreate()

    Structure.OnCreate(self)
    
    self.occupied = false
    self.commanderId = Entity.invalidId
    
    self.maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    self.health = self.maxHealth
    
end

function CommandStructure:GetIsOccupied()
    return self.occupied
end

function CommandStructure:GetTechAllowed(techId, techNode, player)

    // Can only perform actions on hives/command stations if you're occupying it
    if self.occupied and player and player:GetId() == self.commanderId then
        return Structure.GetTechAllowed(self, techId, techNode, player)
    end
    
    return false
    
end

function CommandStructure:GetEffectParams(tableParams)

    Structure.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterOccupied] = self.occupied
    
end

Shared.LinkClassToMap("CommandStructure", CommandStructure.kMapName, networkVars)