// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Whip.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides attacks nearby players with area of effect ballistic attack.
// Also gives attack/hurt capabilities to the commander. Range should be just shorter than 
// marine sentries.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Whip' (Structure)

Whip.kMapName = "whip"

Whip.kModelName = PrecacheAsset("models/alien/whip/whip.model")

Whip.kAnimAttack = "attack"
Whip.kAnimIdleTable = {{1, "idle"}, {.4, "idle2"}, {.3, "idle3"}, {.2, "idle4"}}
Whip.kAnimFury = "enervate"

Whip.kFurySound = PrecacheAsset("sound/ns2.fev/alien/structures/whip/fury")
Whip.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/whip/idle")
Whip.kStrikeSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/attack")

Whip.kBombardFireEffect = PrecacheAsset("cinematics/alien/whip/bombard_fire.cinematic")
Whip.kBombardEffect = PrecacheAsset("cinematics/alien/whip/bombard.cinematic")
Whip.kBombardImpactEffect = PrecacheAsset("cinematics/alien/whip/bombard_impact.cinematic")
Whip.kAcidStrikeFireEffect = PrecacheAsset("cinematics/alien/whip/acidstrike_fire.cinematic")
Whip.kAcidStrikeEffect = PrecacheAsset("cinematics/alien/whip/acidstrike.cinematic")
Whip.kAcidStrikeImpactEffect = PrecacheAsset("cinematics/alien/whip/acidstrike_impact.cinematic")
Whip.kFuryEffect = PrecacheAsset("cinematics/alien/whip/fury.cinematic")

Whip.kScanThinkInterval = .3
Whip.kROF = 2.0
Whip.kFov = 360
Whip.kTargetCheckTime = .3
Whip.kRange = 6
Whip.kAreaEffectRadius = 3
Whip.kDamage = 50

// Fury
Whip.kFuryRadius = 6
Whip.kFuryDuration = 6
Whip.kFuryDamageBoost = .1          // 10% extra damage

local networkVars =
{
    attackYaw = "integer (0 to 360)"
}

if Server then
    Script.Load("lua/Whip_Server.lua")
end

function Whip:OnCreate()
    Structure.OnCreate(self)
    self.attackYaw = 0
end

function Whip:GetFov()
    return Whip.kFov
end

function Whip:GetIsAlienStructure()
    return true
end

function Whip:GetIdleSound()
    return Whip.kIdleSoundEffect
end

function Whip:GetIdleAnimation()
    return chooseWeightedEntry(Whip.kAnimIdleTable)
end

function Whip:GetDeathEffect()
    return Structure.kAlienDeathLargeEffect
end

function Whip:GetDamageEffectOffset()
    return Vector(0, 9, 10)
end

function Whip:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.WhipFury, kTechId.WhipAcidStrike, kTechId.Attack }
        
        // Allow structure to be ugpraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Whip) then
            techButtons[upgradeIndex] = kTechId.UpgradeWhip
        else
            techButtons[upgradeIndex] = kTechId.WhipBombard
        end
       
    elseif(techId == kTechId.UpgradesMenu) then 
        techButtons = {kTechId.LeapTech, kTechId.BloodThirstTech, kTechId.PiercingTech, kTechId.Melee1Tech, kTechId.Melee2Tech, kTechId.Melee3Tech, kTechId.None}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
    end
    
    return techButtons
    
end

function Whip:GetDeathIconIndex()
    return kDeathMessageIcon.Whip
end

function Whip:UpdatePoseParameters(deltaTime)

    Structure.UpdatePoseParameters(self, deltaTime)
    
    self:SetPoseParam("attack_yaw", self.attackYaw)
    
end

function Whip:GetCanDoDamage()
    return true
end

Shared.LinkClassToMap("Whip", Whip.kMapName, networkVars)

class 'MatureWhip' (Whip)

MatureWhip.kMapName = "maturewhip"

function MatureWhip:GetTechId()
    return kTechId.MatureWhip
end


Shared.LinkClassToMap("MatureWhip", MatureWhip.kMapName, networkVars)