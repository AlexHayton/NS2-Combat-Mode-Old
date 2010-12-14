// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Shotgun.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Balance.lua")
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")

class 'Shotgun' (ClipWeapon)

Shotgun.kMapName = "shotgun"

local kReloadPhase = enum( {'None', 'Start', 'LoadShell', 'End'} )

local networkVars =
    {
        reloadPhase         = string.format("integer (1 to %d)", kReloadPhase.End),
        reloadPhaseEnd      = "float",
        emptyPoseParam      = "compensated float"
    }

Shotgun.kModelName = PrecacheAsset("models/marine/shotgun/shotgun.model")
Shotgun.kViewModelName = PrecacheAsset("models/marine/shotgun/shotgun_view.model")

Shotgun.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/shotgun/muzzle_flash.cinematic")
Shotgun.kShellEffect = PrecacheAsset("cinematics/marine/shotgun/shell.cinematic")

Shotgun.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/fire")
Shotgun.kFireLastSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/fire_last")
Shotgun.kSecondaryFireSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/alt-fire")
Shotgun.kDeploySoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/deploy")
Shotgun.kStartReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/start_reload")
Shotgun.kLoadShellSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/load_shell")
Shotgun.kEndReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/end_reload")

Shotgun.kAnimPrimaryAttackTable = {{.5, "attack"} }
Shotgun.kAnimPrimaryAttackLast = "attack_last"
Shotgun.kAnimIdleTable = {{1.2, "idle"}, {.03, "idle2"}/*, {.05, "idle3"}*/}
Shotgun.kAnimReloadStart = "reload_start"
Shotgun.kAnimReloadShell = "reload_insert"
Shotgun.kAnimReloadEnd = {{1, "reload_end"}, {1, "reload_end2"}}
Shotgun.kAnimDrawTable = {{1, "draw"}, {1, "draw2"}}

Shotgun.kCasingAttachPoint = "fxnode_shotguncasing"
Shotgun.kMuzzleAttachPoint = "fxnode_shotgunmuzzle"

Shotgun.kClipSize = kShotgunClipSize
// Do max damage when within max damage range
Shotgun.kMaxDamage = kShotgunMaxDamage
Shotgun.kMinDamage = kShotgunMinDamage
Shotgun.kPrimaryRange = kShotgunMinDamageRange
Shotgun.kPrimaryMaxDamageRange = kShotgunMaxDamageRange
Shotgun.kSecondaryRange = 10
Shotgun.kFireDelay = kShotgunFireDelay
Shotgun.kSecondaryFireDelay = 0.5

function Shotgun:CreatePrimaryAttackEffect(player)

    ClipWeapon.CreatePrimaryAttackEffect(self, player)
    
    // Create the muzzle flash effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Shotgun.kMuzzleAttachPoint, Rifle.kMuzzleFlashEffect)
    
    // Create the shell casing ejecting effect.
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Shotgun.kCasingAttachPoint, Shotgun.kShellEffect)

end

function Shotgun:GetViewModelName()
    return Shotgun.kViewModelName
end

function Shotgun:GetInaccuracyScalar()
    return 1
end

function Shotgun:GetDeathIconIndex()
    return kDeathMessageIcon.Shotgun
end

function Shotgun:GetFireSoundName()
    if(self.clip == 0) then
        return Shotgun.kFireLastSoundName
    end
    return Shotgun.kFireSoundName
end

function Shotgun:GetDrawSound()
    return Shotgun.kDeploySoundName
end

// TODO: Add different sound effect
function Shotgun:GetSecondaryFireSoundName()
    return Shotgun.kSecondaryFireSoundName
end

function Shotgun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Shotgun:GetDrawAnimation(previousWeaponMapName)
    return Shotgun.kAnimDrawTable    
end

function Shotgun:GetPrimaryAttackAnimation()

    if(self.clip == 0) then
        return Shotgun.kAnimPrimaryAttackLast
    end

    return chooseWeightedEntry( Shotgun.kAnimPrimaryAttackTable )
    
end

function Shotgun:GetAttackEmpty()
    return chooseWeightedEntry( Shotgun.kAnimPrimaryAttackTable )
end

function Shotgun:GetClipSize()
    return Shotgun.kClipSize
end

function Shotgun:GetBulletsPerShot()
    return kShotgunBulletsPerShot
end

function Shotgun:GetSpread()

    // NS1 was 20 degrees for half the shots and 20 degrees plus 7 degrees for half the shots
    if NetworkRandom(string.format("%s:GetSpread():", self:GetClassName())) < .5 then
        return ClipWeapon.kCone20Degrees     
    else
        return ClipWeapon.kCone20Degrees + ClipWeapon.kCone7Degrees
    end
    
end

function Shotgun:GetRange()
    return Shotgun.kPrimaryRange
end

function Shotgun:GetBulletDamageForRange(distance)

    local damage = Shotgun.kMaxDamage
    if distance > Shotgun.kPrimaryMaxDamageRange then
    
        local distanceFactor = (distance - Shotgun.kPrimaryMaxDamageRange) / (Shotgun.kPrimaryRange - Shotgun.kPrimaryMaxDamageRange)
        local dmgScalar = 1 - Clamp(distanceFactor, 0, 1) 
        damage = Shotgun.kMinDamage + dmgScalar * (Shotgun.kMaxDamage - Shotgun.kMinDamage)
        
    end
    
    return damage

end

// Only play weapon effects every other bullet to avoid sonic overload
function Shotgun:GetRicochetEffectFrequency()
    return 2
end

function Shotgun:GetBulletDamage(target, endPoint)

    if target ~= nil then
    
        local distance = (endPoint - self:GetParent():GetOrigin()):GetLength()
        return self:GetBulletDamageForRange(distance)
        
    else
        Print("Shotgun:GetBulletDamage(target): target is nil, returning max damage.")
    end
    
    return Shotgun.kMaxDamage
    
end

function Shotgun:GetPrimaryAttackDelay()
    return Shotgun.kFireDelay
end

function Shotgun:GetSecondaryAttackDelay()
    return Shotgun.kSecondaryFireDelay
end

function Shotgun:GetBaseIdleAnimation()
    return chooseWeightedEntry( Shotgun.kAnimIdleTable )
end

function Shotgun:EnterReloadPhase(player, phase)

    local time = 0
    local blockActivity = true
    local soundName = ""

    if(phase == kReloadPhase.None) then
    
        blockActivity = false
        
    elseif(phase == kReloadPhase.Start) then
    
        time = player:SetViewAnimation(Shotgun.kAnimReloadStart)
        soundName = Shotgun.kStartReloadSoundName
        
        player:SetOverlayAnimation("reload_start")
        
    elseif(phase == kReloadPhase.LoadShell) then
    
        time = player:SetViewAnimation(Shotgun.kAnimReloadShell)
        
        soundName = Shotgun.kLoadShellSoundName
        
        player:SetOverlayAnimation("reload_insert")
        
        // We can cancel reloading of every bullet past the first            
        blockActivity = false
        
    elseif(phase == kReloadPhase.End) then
    
        time = player:SetViewAnimation(Shotgun.kAnimReloadEnd)
        soundName = Shotgun.kEndReloadSoundName
        
        player:SetOverlayAnimation("reload_end")

    end
    
    self.reloadPhase = phase
    
    self.reloadPhaseEnd = Shared.GetTime() + time
    
    if soundName ~= "" then
        Shared.PlaySound(player, soundName)
    end
    
    if(blockActivity) then
    
        player:SetActivityEnd(time)
        
    end

end

function Shotgun:OnPrimaryAttack(player)
    
    self:EnterReloadPhase(player, kReloadPhase.None)
    
    ClipWeapon.OnPrimaryAttack(self, player)
    
end

function Shotgun:GetSecondaryAttackAnimation()
    return self:GetPrimaryAttackAnimation()
end

/*
function Shotgun:OnSecondaryAttack(player)

    player:DeactivateWeaponLift()

    self:EnterReloadPhase(player, kReloadPhase.None)

    if (self.clip == 0 and self.ammo > 0) then

        // Automatically reload if we're out of ammo
        player:Reload()
    
    else
    
        self:FireSecondary(player, self:GetBulletsPerShot(), self:GetSpread(), Shotgun.kSecondaryRange, self:GetPenetration())
        self.clip = self.clip - 1
        
        // Allow the weapon to be fired again before the activity animation ends.
        // This allows us to have a fast rate of fire and still have nice animation
        // effects in the case of the final shot
        player:SetViewAnimation( self:GetSecondaryAttackAnimation() )
        player:SetActivityEnd( self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier() )
        
        // Play the fire animation on the character.
        player:SetOverlayAnimation(Marine.kAnimOverlayFire)

        Shared.PlaySound(player, self:GetFireSoundName())
        
    end
    
end

function Shotgun:FireSecondary(player, bullets, spread, range, penetration)
    self:FireFlechettes(player, bullets, spread, range, penetration)
end
*/

/**
 * Fires the specified number of bullets in a cone from the player's current view. These bullets bounce off walls
 * and continue until out of range or they hit a target.
 */
function Shotgun:FireFlechettes(player, bulletsToShoot, spread, range, penetration)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    
    for bullet = 1, bulletsToShoot do
    
        local startPoint = player:GetViewOffset() + player:GetOrigin()
        
        local xSpread = ((NetworkRandom() * 2 * spread) - spread) + ((NetworkRandom() * 2 * spread) - spread)
        local ySpread = ((NetworkRandom() * 2 * spread) - spread) + ((NetworkRandom() * 2 * spread) - spread) 
        local spreadDirection = viewCoords.zAxis + viewCoords.xAxis * xSpread + viewCoords.yAxis * ySpread
        
        local endPoint = startPoint + spreadDirection * range
    
        self:FireFlechetteRound(startPoint, endPoint, range, filter)
        
    end

end

// Fire bullet that bounces off walls until it hits a target or exceeds its range
function Shotgun:FireFlechetteRound(startPoint, endPoint, range, filter)

    local rangeTravelled = 0
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, filter)
    
    while (trace.fraction > 0.01) do

        local canDamageTarget = true
        
        self:CreateHitEffect(player, trace.endPoint - GetNormalizedVector(endPoint - startPoint) * Weapon.kHitEffectOffset, GetSurfaceFromTrace(trace))
        
        // Create line showing bullet from start to endpoint (TODO: Make networked)
        if(Client) then
        
            // Draw bounce
            if(trace.fraction == 1) then
                DebugLine(startPoint, endPoint, 1.5, 1, 1, 1, 1)
            else
                DebugLine(startPoint, trace.endPoint, 1.5, 1, 1, 1, 1)
            end
            
        end
        
        // Trace amount travelled so we can do less damage
        local lastTraceRange = trace.fraction * (endPoint - startPoint):GetLength()
        rangeTravelled = rangeTravelled + lastTraceRange
        
        if(trace.entity and canDamageTarget) then
            
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:ApplyFlechetteHitEffects(player, trace.entity, trace.endPoint, direction, rangeTravelled/range)
            
            // We hit a target, this bullet is done
            break
                
        else
        
            // Subtract out range
            range = range - lastTraceRange

            // Perform richochet            
            if(range > 0) then

                // Calculate reflection normal
                local bulletReflection = ReflectVector(Vector(endPoint - startPoint), trace.normal)
            
                // Trace from hit point to remaining range
                endPoint = trace.endPoint + bulletReflection * range
                VectorCopy(trace.endPoint, startPoint)
                
                trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, filter)
                
            else
            
                break
                
            end 
           
        end
        
    end
    
end

// Takes a fraction of range (0-1, 1 representing max range) that is applied to damage
function Shotgun:ApplyFlechetteHitEffects(player, target, endPoint, direction, rangeFraction)
    target:TakeDamage(self:GetBulletDamage(target, endPoint)*rangeFraction, player, self, endPoint, direction)
end

// Load bullet if we can. Returns true if there are still more to reload.
function Shotgun:LoadBullet(player)

    if(self.ammo > 0) and (self.clip < self:GetClipSize()) then
    
        self.clip = self.clip + 1
        self.ammo = self.ammo - 1
                        
    end
    
    return (self.ammo > 0) and (self.clip < self:GetClipSize())
    
end

function Shotgun:OnProcessMove(player, input)
    
    // We're ending a phase
    if (self.reloadPhase ~= kReloadPhase.None and Shared.GetTime() > self.reloadPhaseEnd) then
    
        // We just finished the start bullet load phase (also gives one shell), or the continues bullet load
        if (self.reloadPhase == kReloadPhase.Start or self.reloadPhase == kReloadPhase.LoadShell) then
        
            // Give back one bullet because that's part of the anim
            if self:LoadBullet(player) then
            
                // Load another
                self:EnterReloadPhase(player, kReloadPhase.LoadShell)
                
            else
            
                // Out of ammo or clip full
                self:EnterReloadPhase(player, kReloadPhase.End)
                
            end
            
        else
        
            self.reloadPhase = kReloadPhase.None
            
        end

    end
    
    self:UpdateAccuracy(player, input)
    
    // Don't call into ClipWeapon because we're overriding reload
    Weapon.OnProcessMove(self, player, input)

end

function Shotgun:OnReload(player)

    if (self.ammo > 0 and self.clip < self:GetClipSize() and self.reloadPhase == kReloadPhase.None) then
        
        // Play the reload sequence and don't let it be interrupted until it finishes playing.
        self:EnterReloadPhase(player, kReloadPhase.Start)
        
    end
    
end

function Shotgun:OnHolster(player)

    self.reloadPhase = kReloadPhase.None
    self.reloadPhaseEnd = 0
    ClipWeapon.OnHolster(self, player)
    
end

function Shotgun:OnInit()

    self.reloadPhase = kReloadPhase.None
    self.reloadPhaseEnd = 0
    self.emptyPoseParam = 0
    
    ClipWeapon.OnInit(self)
    
end

function Shotgun:UpdateViewModelPoseParameters(viewModel, input)
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), 0, 1, input.time*1), 0, 1)
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
end


Shared.LinkClassToMap("Shotgun", Shotgun.kMapName, networkVars )