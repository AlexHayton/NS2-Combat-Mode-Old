// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPoint.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Every room has a power point in it, which starts built. It is placed on the wall, around
// head height. When a power point is taking damage, lights nearby flicker. When a power point 
// is at 35% health or lower, the lights cycle dramatically. When a power point is destroyed, 
// the lights go completely black and all marine structures power down 5 long seconds later, the 
// aux. power comes on, fading the lights back up to ~%35. When down, the power point has 
// ambient electricity flowing around it intermittently, hinting at function. Marines can build 
// the power point by +using it, MACs can build it as well. When it comes back on, all 
// structures power back up and start functioning again and lights fade back up.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'PowerPoint' (Structure)

if Server then
    Script.Load("lua/PowerPoint_Server.lua")
else
    Script.Load("lua/PowerPoint_Client.lua")
end

PowerPoint.kMapName = "power_point"

PowerPoint.kOnModelName = PrecacheAsset("models/system/editor/power_node_on.model")
PowerPoint.kOffModelName = PrecacheAsset("models/system/editor/power_node_off.model")

PowerPoint.kDamagedEffect = PrecacheAsset("cinematics/common/powerpoint_damaged.cinematic")
PowerPoint.kOfflineEffect = PrecacheAsset("cinematics/common/powerpoint_offline.cinematic")

PowerPoint.kTakeDamageSound = PrecacheAsset("sound/ns2.fev/marine/power_node/take_damage")
PowerPoint.kDamagedSound = PrecacheAsset("sound/ns2.fev/marine/power_node/damaged")
PowerPoint.kDestroyedSound = PrecacheAsset("sound/ns2.fev/marine/power_node/destroyed")
PowerPoint.kDestroyedPowerDownSound = PrecacheAsset("sound/ns2.fev/marine/power_node/destroyed_powerdown")
PowerPoint.kAuxPowerBackupSound = PrecacheAsset("sound/ns2.fev/marine/power_node/backup")

PowerPoint.kHealth = kPowerPointHealth
PowerPoint.kArmor = kPowerPointArmor
PowerPoint.kAnimOn = "on"
PowerPoint.kAnimOff = "off"
PowerPoint.kDamagedPercentage = .4

PowerPoint.kPowerOnTime = .5
PowerPoint.kPowerDownTime = 1
PowerPoint.kOffTime = 5
PowerPoint.kPowerRecoveryTime = 5
PowerPoint.kPowerDownMaxIntensity = .7
PowerPoint.kLowPowerCycleTime = 1
PowerPoint.kLowPowerMinIntensity = .4
PowerPoint.kDamagedCycleTime = .8
PowerPoint.kDamagedMinIntensity = .7
PowerPoint.kAuxPowerCycleTime = 2
PowerPoint.kAuxPowerMinIntensity = .25

local networkVars =
{
    lightMode               = "enum kLightMode",
    timeOfLightModeChange   = "float",
    triggerName             = string.format("string (%d)", kMaxEntityStringLength)
}

// No spawn animation
function PowerPoint:GetSpawnAnimation()
    return ""
end

function PowerPoint:OnInit()

    self:SetModel(PowerPoint.kOnModelName)
    
    Structure.OnInit(self)
    
    self.lightMode = kLightMode.Normal
    
    self:SetAnimation(PowerPoint.kAnimOn)
    
    if Server then
    
        self.startsBuilt = true
        
        self:SetTeamNumber(kTeamReadyRoom)
    
        self:SetConstructionComplete()
        
        self:SetNextThink(.1)

    end
    
end

function PowerPoint:OnReset()

    self:OnInit()  
    
    Structure.OnReset(self)
    
end

function PowerPoint:GetTechId()
    return kTechId.PowerPoint
end

function PowerPoint:GetCanTakeDamage()
    return self.powered
end

function PowerPoint:GetIsBuilt()
    return true
end

function PowerPoint:GetIsPowered()
    return self.powered
end

// Used for efficiency, so we don't have iterate over lights unnecessarily
function PowerPoint:GetIsAffectingLights()

    local time = Shared.GetTime()
    
    // Add in some extra time to account for network latency
    local kBufferTime = .5
    
    if ((self.lightMode == kLightMode.Normal) or (self.lightMode == kLightMode.Damaged)) and (time < (self.timeOfLightModeChange + PowerPoint.kDamagedCycleTime*2 + kBufferTime)) then
        return true
    elseif self.lightMode == kLightMode.LowPower then
        return true
    elseif (self.lightMode == kLightMode.NoPower) then
        return true
    end
    
    return false
    
end

function PowerPoint:SetLightMode(lightMode)

    // Don't change light mode too often or lights will change too much
    if self.lightMode ~= lightMode or (not self.timeOfLightModeChange or (Shared.GetTime() > (self.timeOfLightModeChange + 1.0))) then
    
        self.lightMode = lightMode
        self.timeOfLightModeChange = Shared.GetTime()
        
    end
    
end

function PowerPoint:GetLightMode()
    return self.lightMode
end

function PowerPoint:GetTimeOfLightModeChange()
    return self.timeOfLightModeChange
end

function PowerPoint:ProcessEntityHelp(player)

    if self:GetIsPowered() then
        if self:GetHealthScalar() < PowerPoint.kDamagedPercentage then
            return player:AddTooltipOncePer("This power node in almost destroyed, which will disable nearby marine structures!")
        else
            if player:isa("Marine") then
                return player:AddTooltipOncePer("This power node powers nearby marine structures...protect it!")
            elseif player:isa("Alien") then
                return player:AddTooltipOncePer("This power node powers nearby marine structures...destroy it!")
            end
        end
    else
        if player:isa("Marine") then
            return player:AddTooltipOncePer("This power node is destroyed and must be repaired by the Commander before nearby structures work again.")
        elseif player:isa("Alien") then
            return player:AddTooltipOncePer("The marine power node has been destroyed!")
        end
    end
    
    return false
    
end

Shared.LinkClassToMap("PowerPoint", PowerPoint.kMapName, networkVars)