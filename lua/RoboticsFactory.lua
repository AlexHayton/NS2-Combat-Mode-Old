// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RoboticsFactory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'RoboticsFactory' (Structure)

RoboticsFactory.kMapName = "roboticsfactory"

RoboticsFactory.kModelName = PrecacheAsset("models/marine/robotics_factory/robotics_factory.model")

RoboticsFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")

function RoboticsFactory:OnInit()

    self:SetModel(RoboticsFactory.kModelName)
    
    Structure.OnInit(self)
    
end

function RoboticsFactory:GetRequiresPower()
    return true
end

function RoboticsFactory:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        return {   kTechId.RoboticsFactoryMACUpgradesMenu, kTechId.RoboticsFactoryARCUpgradesMenu, kTechId.None, kTechId.None, 
                    kTechId.None, kTechId.ARC, kTechId.None, kTechId.None }
    
    elseif techId == kTechId.RoboticsFactoryARCUpgradesMenu then
        return {   kTechId.ARCArmorTech, kTechId.ARCSplashTech, kTechId.None, kTechId.None,
                    kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu }
                    
    elseif techId == kTechId.RoboticsFactoryMACUpgradesMenu then
        return {   kTechId.MACSpeedTech, kTechId.MACEMPTech, kTechId.MACMinesTech, kTechId.None,
                    kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu }
        
    end
    
    return nil
    
end

Shared.LinkClassToMap("RoboticsFactory", RoboticsFactory.kMapName, {})

