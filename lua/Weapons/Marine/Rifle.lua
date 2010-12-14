// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Rifle.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")

class 'Rifle' (ClipWeapon)

Rifle.kMapName = "rifle"

Rifle.kModelName = PrecacheAsset("models/marine/rifle/rifle.model")
Rifle.kViewModelName = PrecacheAsset("models/marine/rifle/rifle_view.model")

Rifle.drawSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/draw")
Rifle.reloadSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/reload")

// Three different variations of the rifle to make firefights sound a bit more diverse
Rifle.fireSingleSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single")
Rifle.fireSingle2SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single_2")
Rifle.fireSingle3SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single_3")

Rifle.fireSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_14_sec_loop")
Rifle.fire2SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_loop_2")
Rifle.fire3SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_loop_3")

Rifle.fireEndSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_14_sec_end")

Rifle.meleeSwingSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_swing")
Rifle.meleeHitHardSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_hit_hard")
Rifle.meleeHitLivingSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_hit_living")

Rifle.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
Rifle.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/rifle/barrel_smoke.cinematic")

Rifle.kShellEffect = PrecacheAsset("cinematics/marine/rifle/shell.cinematic")
Rifle.kShell2Effect = PrecacheAsset("cinematics/marine/rifle/shell2.cinematic")
Rifle.kShell3Effect = PrecacheAsset("cinematics/marine/rifle/shell3.cinematic")
Rifle.kShell4Effect = PrecacheAsset("cinematics/marine/rifle/shell4.cinematic")
Rifle.kShell5Effect = PrecacheAsset("cinematics/marine/rifle/shell5.cinematic")
Rifle.kShellEffectTable = { {1, Rifle.kShellEffect}, {1, Rifle.kShell2Effect}, {1, Rifle.kShell3Effect}, {1, Rifle.kShell4Effect}, {1, Rifle.kShell5Effect}}

Rifle.kBashEffect = "cinematics/materials/%s/bash.cinematic"
PrecacheMultipleAssets(Rifle.kBashEffect, kSurfaceList)

Rifle.kMuzzleNode = "fxnode_riflemuzzle"
Rifle.kCasingNode = "fxnode_riflecasing"
Rifle.kShellNode = "fxnode_rifleshell"

Rifle.kClipSize = kRifleClipSize
Rifle.kRange = 250
Rifle.kFireDelay = kRifleFireDelay
Rifle.kSpread = ClipWeapon.kCone4Degrees    // From NS1
Rifle.kDamage = kRifleDamage

Rifle.kButtDelay = kRifleMeleeFireDelay
Rifle.kButtDamage = kRifleMeleeDamage
Rifle.kButtRange = 1.5
Rifle.kMeleeAnims = { {.2, "attack_secondary", Rifle.meleeSwingSoundName}, {.2, "attack_secondary2", Rifle.meleeSwingSoundName}, {.2, "attack_secondary3", Rifle.meleeSwingSoundName}}

// Overlay on player
Rifle.kPlayerAnimSecondaryAttack = "alt"

// Rifle idle table. The animations here are listed with their relatively probabily of being played. 
Rifle.kAnimIdleTable = {{1.0, "idle"}, {.5, "idle3"}, {.05, "idle4"}, {.05, "idle5"}}
Rifle.kAnimPrimaryAttackTable = {{.5, "attack"}}

Rifle.fireSingleSoundTable = {Rifle.fireSingleSoundName, Rifle.fireSingle2SoundName, Rifle.fireSingle3SoundName}
Rifle.fireLoopSoundTable = {Rifle.fireSoundName, Rifle.fire2SoundName, Rifle.fire3SoundName}

local networkVars =
{
    timeOfLastPrimaryAttack     = "float",
    timeStartedAttack           = "float",
    soundType                   = "integer (1 to 3)"
}

function Rifle:OnInit()

    ClipWeapon.OnInit(self)
    
    self.soundType = Shared.GetRandomInt(1, 3)
    
end

function Rifle:GetViewModelName()
    return Rifle.kViewModelName
end

function Rifle:GetFireSoundName()
    // Play sound effect for hitting
    return Rifle.fireLoopSoundTable[self.soundType]
end

function Rifle:GetDeathIconIndex()
    return ConditionalValue(self.lastAttackSecondary, kDeathMessageIcon.RifleButt, kDeathMessageIcon.Rifle)
end

function Rifle:GetDrawSound()
    return Rifle.drawSoundName
end

function Rifle:GetReloadSound()
    return Rifle.reloadSoundName
end

function Rifle:GetBaseIdleAnimation()
    return chooseWeightedEntry( Rifle.kAnimIdleTable )
end

function Rifle:GetRunIdleAnimation()
    // No run idle animation yet
    return self:GetBaseIdleAnimation()
end

function Rifle:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Rifle:GetClipSize()
    return Rifle.kClipSize
end

function Rifle:GetSpread()
    return Rifle.kSpread
end

function Rifle:GetBulletDamage(target, endPoint)
    return Rifle.kDamage
end

function Rifle:GetRange()
    return Rifle.kRange
end

function Rifle:GetPrimaryAttackDelay()
    return Rifle.kFireDelay
end

// Don't punish too badly for walking and moving
function Rifle:GetAccuracyRecoveryRate(player)
    local velocityScalar = player:GetVelocity():GetLength()/player:GetMaxSpeed()
    return 1.4 - .3*velocityScalar
end

// Used to affect spread and change the crosshair
function Rifle:GetInaccuracyScalar()
    return 1 + (1 - self.accuracy)*1.4
end

function Rifle:GetPrimaryAttackAnimation()
    return chooseWeightedEntry( Rifle.kAnimPrimaryAttackTable )
end

function Rifle:GetForcePrimaryAttackAnimation()
    // This is a looping attack animation, don't keep restarting it
    return false
end

function Rifle:GetSecondaryAttackDelay()
    return Rifle.kButtDelay
end

function Rifle:GetIsPrimaryAttackLooping()
    return true
end

function Rifle:GetMuzzleFlashEffect()
    return Rifle.kMuzzleFlashEffect
end

function Rifle:GetBarrelSmokeEffect()
    return Rifle.kBarrelSmokeEffect
end

function Rifle:GetShellEffect()
    return chooseWeightedEntry ( Rifle.kShellEffectTable )
end

function Rifle:GetTracerPercentage()
    return .2
end

function Rifle:CreatePrimaryAttackEffect(player)

    local shakeAmount = 0
    if self.timeStartedAttack then
        shakeAmount = Clamp(((Shared.GetTime() - self.timeStartedAttack) / .5) * .005, 0, .005)
    end
    
    self:SetCameraShake(.003 + NetworkRandom(string.format("%s:CreatePrimaryAttackEffect():SetCameraShake", self:GetClassName()))*shakeAmount, 1/self:GetPrimaryAttackDelay(), Rifle.kFireDelay)

    // Create the muzzle flash effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Rifle.kMuzzleNode, self:GetMuzzleFlashEffect())
    
    // Create the shell casing ejecting effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Rifle.kCasingNode, self:GetShellEffect())
    
    // Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()
    
    self.lastAttackSecondary = false

end

function Rifle:GetReloadCancellable()
    return true
end

function Rifle:OnDestroy()

    self:StopPrimaryAttackSound()
    
    ClipWeapon.OnDestroy(self)
    
end

function Rifle:OnHolster(player)

    self:StopPrimaryAttackSound()
    
    ClipWeapon.OnHolster(self, player)
    
end

function Rifle:OnPrimaryAttack(player)

    if not self.primaryAttackLastFrame then
        self.timeStartedAttack = Shared.GetTime()
    end
    
    ClipWeapon.OnPrimaryAttack(self, player)
    
end

function Rifle:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self:SetOverlayAnimation( nil )
    
    self:StopPrimaryAttackSound()
    
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Rifle.kMuzzleNode, self:GetBarrelSmokeEffect())
    
    self.timeStartedAttack = nil
    
end

function Rifle:DoMelee(player)

    self:StopPrimaryAttackSound()
    
    self.lastAttackSecondary = true
    
    self:PerformMeleeAttack(player)
    
    // Cancel reload if we're not done
    self.reloadTime = 0

end

function Rifle:PerformMeleeAttack(player)

    // Perform melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, Rifle.kButtDamage, Rifle.kButtRange)
    
    if ( didHit ) then

        // Hit the level
        local hitObject = trace.entity
        if(hitObject == nil) then        
        
            Shared.PlaySound(player, Rifle.meleeHitHardSoundName)
            
        elseif(hitObject:isa("Player") or (hitObject:GetTeamType() == kAlienTeamType)) then
        
            Shared.PlaySound(player, Rifle.meleeHitLivingSoundName)
            
            // Take player mass into account 
            local direction = player:GetOrigin() - hitObject:GetOrigin()
            direction:Normalize()
            
            if hitObject:isa("Player") then
            
                local targetVelocity = hitObject:GetVelocity() + direction * (300 / hitObject:GetMass())
                hitObject:SetVelocity(targetVelocity)
                
            end
            
        else
        
            Shared.PlaySound(player, Rifle.meleeHitHardSoundName)
            
        end
        
        local surface = GetSurfaceFromTrace(trace)
        if(surface ~= "" and surface ~= nil and surface ~= "unknown") then
            Shared.CreateEffect(nil, string.format(Rifle.kBashEffect, surface), nil, Coords.GetTranslation(trace.endPoint))
        end
        
    end
    
end

// Perform melee attack with rifle butt
function Rifle:OnSecondaryAttack(player)

    if ( player:GetCanNewActivityStart() ) then
    
        // Play view model effect
        local index = table.chooseWeightedIndex(Rifle.kMeleeAnims)
        local animName = Rifle.kMeleeAnims[index][2]
        
        player:SetViewAnimation(animName)
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        player:SetOverlayAnimation(Rifle.kPlayerAnimSecondaryAttack)
        player:DeactivateWeaponLift()
        
        self:DoMelee(player)
        
        Shared.PlaySound(player, Rifle.kMeleeAnims[index][3])

    end

end

function Rifle:ApplyMeleeHitEffects(player, damage, target, endPoint, direction)

    // Apply damage
    if target and target:isa("LiveScriptActor") then
    
        target:TakeDamage(damage, player, self, endPoint, direction)
        
    end
    
    if target then
    
        // Throw back (or stun?) target a bit        
        target:AddImpulse(endPoint, direction)
        
        //local targetVelocity = target:GetVelocity() + direction * (300 / target:GetMass())
        //target:SetVelocity(targetVelocity)

    end
    
end

function Rifle:PlayPrimaryAttackSound(player)

    // Don't play sounds if we have the silencer upgrade
    if(not GetTechSupported(player, kTechId.RifleUpgradeTech)) then
    
        // Play single shot (concurrently with loop) the first time we fire
        if self.loopingWeaponSoundPlaying == 0 then
        
            Shared.PlaySound(player, Rifle.fireSingleSoundTable[self.soundType])
            
        end
        
        ClipWeapon.PlayPrimaryAttackSound(self, player)    
        
    end
    
end

function Rifle:StopPrimaryAttackSound()

    local player = self:GetParent()    
    Shared.StopSound(player, self:GetFireSoundName())
    
    if self.loopingWeaponSoundPlaying == 1 then
    
        self.loopingWeaponSoundPlaying = 0     
        Shared.PlaySound(player, Rifle.fireEndSoundName)
        
    end
    
end

function Rifle:OnReload(player)

    if ( self:CanReload() ) then
    
        self:StopPrimaryAttackSound()
        
        ClipWeapon.OnReload(self, player)
        
    end
    
end

// Pass a time interval greater and get back 0-1. From last attack to interval is 0 to 1 0 means 2 x interval or more time has passed since
// our last attack and 1 is that we just attacked this frame.
function Rifle:GetGunLoopParam(interval)

    local desiredGunLoop = 0
    
    if self.timeOfLastPrimaryAttack ~= nil then
    
        local time = Shared.GetTime()
        if time - self.timeOfLastPrimaryAttack < interval then
            desiredGunLoop = (time - self.timeOfLastPrimaryAttack)/interval
        end
        
    end

    return desiredGunLoop
    
end

function Rifle:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    local new = Clamp(current + rateOfChange, 0, 1)
    viewModel:SetPoseParam(paramName, new)
    
end

function Rifle:UpdateViewModelPoseParameters(viewModel, input)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)

    local justAttacked = self.timeOfLastPrimaryAttack ~= nil and ((Shared.GetTime() - self.timeOfLastPrimaryAttack) < .2)
    local sign = ConditionalValue(justAttacked, 1, -1)

    self:SetGunLoopParam(viewModel, "gun_loop", sign*input.time*3)
    self:SetGunLoopParam(viewModel, "arm_loop", sign*input.time)
    
end

Shared.LinkClassToMap("Rifle", Rifle.kMapName, networkVars)