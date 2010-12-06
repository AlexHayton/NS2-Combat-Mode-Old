// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceTower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Generic resource structure that marine and alien structures inherit from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'ResourceTower' (Structure)

ResourceTower.kMapName = "resourcetower"

ResourceTower.kPlasmaInjection = 1
ResourceTower.kCarbonInjection = 1
ResourceTower.kMaxUpgradeLevel = 3

// Don't start generating resources right away, wait a short time
// (but not too long or it will feel like a bug). This is to 
// make it less advantageous for a team to build every nozzle
// they find. Same as in NS1.
ResourceTower.kBuildDelay = 4

local networkVars = 
{
    upgradeLevel = string.format("integer (0 to %d)", ResourceTower.kMaxUpgradeLevel)
}

if (Server) then
    Script.Load("lua/ResourceTower_Server.lua")
end

function ResourceTower:OnInit()

    Structure.OnInit(self)
    
    self.playingSound = false
    self.upgradeLevel = 0
    
end

function ResourceTower:GetUpgradeLevel()
    return self.upgradeLevel
end

function ResourceTower:SetUpgradeLevel(upgradeLevel)
    self.upgradeLevel = Clamp(upgradeLevel, 0, ResourceTower.kMaxUpgradeLevel)
end

function ResourceTower:GiveResourcesToTeam(player)

    local plasma = ResourceTower.kPlasmaInjection * (1 + self:GetUpgradeLevel() * kResourceUpgradeAmount)
    player:AddPlasma(plasma, true)

end

function ResourceTower:GetDescription()

    local description = Structure.GetDescription(self)
    
    // Add upgrade level
    local upgradeLevel = self:GetUpgradeLevel()
    if upgradeLevel == 0 then
        description = string.format("%s - Base production (+%d available)", description, ResourceTower.kMaxUpgradeLevel)
    else
        description = string.format("%s - Upgrade level +%d of %d", description, self:GetUpgradeLevel(), ResourceTower.kMaxUpgradeLevel)
    end
    
    return description
    
end


Shared.LinkClassToMap("ResourceTower", ResourceTower.kMapName, networkVars)
