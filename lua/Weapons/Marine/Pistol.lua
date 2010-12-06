// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Pistol.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")

class 'Pistol' (ClipWeapon)

Pistol.kMapName = "pistol"

Pistol.kModelName = PrecacheAsset("models/marine/pistol/pistol.model")
Pistol.kViewModelName = PrecacheAsset("models/marine/pistol/pistol_view.model")

Pistol.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/fire")
Pistol.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/draw")
Pistol.kReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/reload")
Pistol.kAltFireSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/press_button")

Pistol.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/pistol/muzzle_flash.cinematic")
Pistol.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/pistol/barrel_smoke.cinematic")
Pistol.kShellEffect = PrecacheAsset("cinematics/marine/pistol/shell.cinematic")

Pistol.kMuzzleNode = "fxnode_pistolmuzzle"
Pistol.kCasingNode = "fxnode_pistolcasing"

Pistol.kAnimIdleTable = {{.7, "idle"}, {.7, "idle2"}, {.05, "idle3"}, {.02, "idle4"}}
Pistol.kAnimIdleEmptyTable = {{.7, "idle"}}
Pistol.kAnimRunIdleTable = {{1, "run"}, {.5, "run2"}}
Pistol.kAnimPrimaryAttackTable = {{.5, "attack"}, {.5, "attack2"}}

// When firing with laser site
Pistol.kAnimAttackSecondary = "attack_secondary"
// When toggling laser site on/off
Pistol.kAnimToggleSecondary = "press_button"

Pistol.kClipSize = 10
Pistol.kDamage = kPistolDamage
Pistol.kAltDamage = kPistolAltDamage
Pistol.kRange = 200
Pistol.kFireDelay = kPistolFireDelay
Pistol.kAltFireDelay = kPistolAltFireDelay
Pistol.kSpread = ClipWeapon.kCone1Degrees
Pistol.kAltSpread = ClipWeapon.kCone0Degrees    // From NS1

local networkVars =
{
    altMode             = "boolean",
    emptyPoseParam      = "compensated float"
}
    
function Pistol:OnInit()

    ClipWeapon.OnInit(self)
    self.altMode = false
    self.emptyPoseParam = 0
    
end

function Pistol:GetRange()
    return Pistol.kRange
end

function Pistol:GetTechId()
    return kTechId.Pistol
end

function Pistol:GetDeathIconIndex()
    return kDeathMessageIcon.Pistol
end

function Pistol:GetViewModelName()
    return Pistol.kViewModelName
end

function Pistol:GetFireSoundName()
    return Pistol.kFireSoundName
end

function Pistol:GetReloadSound()
    return Pistol.kReloadSoundName
end

function Pistol:GetDrawSound()
    return Pistol.kDrawSoundName
end

function Pistol:GetTracerPercentage()
    return .3
end

// When in alt-fire mode, keep very accurate
function Pistol:GetInaccuracyScalar()
    local scalar = ConditionalValue(self.altMode, .5, 1)
    return 1 + (1 - self.accuracy)*scalar
end

function Pistol:GetHUDSlot()
    return kSecondaryWeaponSlot
end

function Pistol:GetPrimaryAttackRequiresPress()
    return true
end

function Pistol:GetBaseIdleAnimation()

    return chooseWeightedEntry( Pistol.kAnimIdleTable )
    
    /*
    local moving = false
    
    local parent = self:GetParent()
    if parent ~= nil and parent:GetVelocity():GetLength() > 2 then
        moving = true
    end
    
    // Don't be bad-ass when empty
    if self.clip == 0 then
        return chooseWeightedEntry( Pistol.kAnimIdleEmptyTable )
    end
    
    if moving then
        return chooseWeightedEntry( Pistol.kAnimRunIdleTable )
    else
        return chooseWeightedEntry( Pistol.kAnimIdleTable )
    end*/
    
end

function Pistol:GetPrimaryAttackAnimation()
    return chooseWeightedEntry( Pistol.kAnimPrimaryAttackTable )
end

function Pistol:CreatePrimaryAttackEffect(player)

    // Create the muzzle flash effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Pistol.kMuzzleNode, Pistol.kMuzzleFlashEffect)
    
    // Create the shell casing ejecting effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Pistol.kMuzzleNode, Pistol.kShellEffect)
    
    if not self.altMode then
    
        local delay = self:GetPrimaryAttackDelay()
        self:SetCameraShake(.003 + NetworkRandom()*.006, 1/delay, delay)
        
    end
    
end

function Pistol:GetSecondaryAttackAnimation()
    return Pistol.kAnimAttackSecondary
end

function Pistol:GetClipSize()
    return Pistol.kClipSize
end

function Pistol:GetSpread()
    return ConditionalValue(self.altMode, Pistol.kAltSpread, Pistol.kSpread)
end

function Pistol:GetBulletDamage(target, endPoint)
    return ConditionalValue(self.altMode, Pistol.kAltDamage, Pistol.kDamage)
end

function Pistol:GetPrimaryAttackDelay()
    return ConditionalValue(self.altMode, Pistol.kAltFireDelay, Pistol.kFireDelay)
end

function Pistol:OnPrimaryAttackEnd(player)
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Pistol.kMuzzleNode, Pistol.kBarrelSmokeEffect)
    ClipWeapon.OnPrimaryAttackEnd(self, player)
end

function Pistol:OnSecondaryAttack(player)

    ClipWeapon.OnSecondaryAttack(self, player)
    
    local length = player:SetViewAnimation( Pistol.kAnimToggleSecondary )
    player:SetActivityEnd(length)
    
    self.altMode = not self.altMode
    
    Shared.PlaySound(player, Pistol.kAltFireSoundName)    
    
end

function Pistol:GetBlendTime()
    return 0
end

function Pistol:GetSwingAmount()
    return 15
end

function Pistol:UpdateViewModelPoseParameters(viewModel, input)
    
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), input.time*2.5), 0, 1)
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
    
end

Shared.LinkClassToMap("Pistol", Pistol.kMapName, networkVars )