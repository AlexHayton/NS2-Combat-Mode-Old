// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

Rifle.kClipSize = kRifleClipSize
Rifle.kRange = 250
Rifle.kFireDelay = kRifleFireDelay
Rifle.kSpread = ClipWeapon.kCone3Degrees    // 4 degrees in NS1
Rifle.kDamage = kRifleDamage

Rifle.kButtDelay = kRifleMeleeFireDelay
Rifle.kButtDamage = kRifleMeleeDamage
Rifle.kButtRange = 1.5

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

function Rifle:GetDeathIconIndex()
    return ConditionalValue(self.lastAttackSecondary, kDeathMessageIcon.RifleButt, kDeathMessageIcon.Rifle)
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

function Rifle:GetReloadTime()
    return kRifleReloadTime
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

function Rifle:GetSecondaryAttackDelay()
    return Rifle.kButtDelay
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

    // Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()
    
    self.lastAttackSecondary = false

end

function Rifle:GetReloadCancellable()
    return true
end

function Rifle:OnHolster(player)

    //self:StopPrimaryAttackSound()
    
    ClipWeapon.OnHolster(self, player)
    
end

function Rifle:OnPrimaryAttack(player)

    if not player:GetPrimaryAttackLastFrame() then
        self.timeStartedAttack = Shared.GetTime()
    end
    
    ClipWeapon.OnPrimaryAttack(self, player)
    
end

function Rifle:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self:SetOverlayAnimation( nil )
    
    self.timeStartedAttack = nil
    
end

function Rifle:DoMelee(player)

    self.lastAttackSecondary = true
    
    self:PerformMeleeAttack(player)
    
    // Cancel reload if we're not done
    self.reloadTime = 0

end

function Rifle:PerformMeleeAttack(player)

    // Perform melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, Rifle.kButtDamage, Rifle.kButtRange)
    
    if didHit then
    
        local hitClassname = nil
        local isAlien = false
        
        if trace.entity then
            
            local hitObject = trace.entity
        
            hitClassname = hitObject:GetClassName()
            isAlien = (hitObject:GetTeamType() == kAlienTeamType)
            
            if hitObject:isa("Player") then
            
                // Take player mass into account 
                local direction = player:GetOrigin() - hitObject:GetOrigin()
                direction:Normalize()
                
                local targetVelocity = hitObject:GetVelocity() + direction * (300 / hitObject:GetMass())
                hitObject:SetVelocity(targetVelocity)
                    
            end
            
        end
        
        self:TriggerEffects("rifle_alt_attack_hit", {classname = hitClassname, isalien = isAlien, surface = GetSurfaceFromTrace(trace)})
        
    end
    
end

// Perform melee attack with rifle butt
function Rifle:OnSecondaryAttack(player)

    if ( player:GetCanNewActivityStart() ) then
    
        // Play view model effect
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        player:DeactivateWeaponLift()
        
        self:DoMelee(player)
        
        ClipWeapon.OnSecondaryAttack(self, player)
        
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

function Rifle:GetEffectParams(tableParams)

    ClipWeapon.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterVariant] = self.soundType
    
end

Shared.LinkClassToMap("Rifle", Rifle.kMapName, networkVars)