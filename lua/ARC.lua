// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'ARC' (LiveScriptActor)

ARC.kMapName = "arc"

ARC.kModelName = PrecacheAsset("models/marine/arc/arc.model")

// Animations
ARC.kMoveParam = "move_speed"

// Balance
ARC.kHealth = kARCHealth
ARC.kStartDistance = 4
ARC.kAttackInterval = 8.0               // Must be greater than fireToHitInterval
ARC.kFireToHitInterval = kARCFireDelay  // How long ARC must be on target before firing
ARC.kAttackDamage = kARCDamage
ARC.kFireRange = 22.86                  // 75 feet, from mockup
ARC.kSplashRadius = 10
ARC.kUpgradedSplashRadius = 13
ARC.kMoveSpeed = 2.5           // units per second

ARC.kMode = enum( {'UndeployedStationary', 'Moving', 'Deploying', 'Deployed', 'Targeting', 'Firing', 'FireCooldown', 'Undeploying'} )

if Server then
    Script.Load("lua/ARC_Server.lua")
end

local networkVars =
{
    // ARCs can only fire when deployed and can only move when not deployed
    mode            = "enum ARC.kMode",
    desiredMode     = "enum ARC.kMode",
}

function ARC:OnInit()

    self:SetModel(ARC.kModelName)

    LiveScriptActor.OnInit(self)

    // Move ARC away from factory so it can be selected
    local angle = NetworkRandom() * math.pi*2
    local startPoint = self:GetOrigin() + Vector( math.cos(angle)*ARC.kStartDistance, 0, math.sin(angle)*ARC.kStartDistance )
    self:SetOrigin(startPoint)
    
    self:TriggerEffects("arc_built")
    
    if Server then
    
        // Cannons start out mobile
        self:SetDesiredMode(ARC.kMode.UndeployedStationary)
        self:SetMode(ARC.kMode.UndeployedStationary)

        self:SetUpdates(true)
        
    end

end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

function ARC:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.ARCDeploy then

        self:SetDesiredMode(ARC.kMode.Deployed)
        
        return true

    elseif techId == kTechId.ARCUndeploy then

        if self:GetTarget() ~= nil then
            self:CompletedCurrentOrder()
        end

        self.timeOfNextHit = nil
        
        self:SetDesiredMode(ARC.kMode.UndeployedStationary)

        return true

    end

    return false

end

function ARC:GetActivationTechAllowed(techId)

    if(techId == kTechId.ARCDeploy or techId == kTechId.Move) then
        return self.mode == ARC.kMode.UndeployedStationary or self.mode == ARC.kMode.Moving
    elseif(techId == kTechId.ARCUndeploy or techId == kTechId.Attack) then
        return self:GetInAttackMode()   
    elseif(techId == kTechId.Stop) then
        return self.mode == ARC.kMode.Moving or self.mode == ARC.kMode.Firing
    end

    return true

end

function ARC:GetTechButtons(techId)
    if techId == kTechId.RootMenu then
        if self:GetInAttackMode() then
            return  {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCUndeploy, kTechId.None, kTechId.None, kTechId.None }
        else
            return  {   
                        kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCDeploy, kTechId.None, kTechId.None, kTechId.None }
        end
    else
        return nil
    end
end

function ARC:GetStatusDescription()

    local desc = EnumToString(ARC.kMode, self.mode)
    
    return string.format("ARC - %s", desc), nil
    
end

function ARC:GetInAttackMode()
    return (self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.Firing or self.mode == ARC.kMode.Targeting or self.mode == ARC.kMode.FireCooldown)
end

function ARC:GetCanDoDamage()
    return true
end

Shared.LinkClassToMap("ARC", ARC.kMapName, networkVars)
