// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\ClipWeapon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Basic bullet-based weapon. Handles primary firing only, as child classes have quite different
// secondary attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'ClipWeapon' (Weapon)

ClipWeapon.kMapName = "clipweapon"

local networkVars =
{
    ammo = "integer (0 to 255)",
    clip = "integer (0 to 200)",
    
    // Weapon-specific weapon state
    weaponState = "integer (0 to 5)",
    
    // 0 means not playing a sound, 1 is playing a sound
    loopingWeaponSoundPlaying = "integer (0 to 1)",
    reloadTime = "float",
    
    // 1 is most accurate, 0 is least accurate
    accuracy = "float"
}

ClipWeapon.kAnimIdle = "idle"
ClipWeapon.kAnimSwingUp = "swing_up"
ClipWeapon.kAnimSwingDown = "swing_down"
ClipWeapon.kAnimIdleUp = "idle_up"
ClipWeapon.kAnimReload = "reload"
ClipWeapon.kRicochetEffect = "cinematics/materials/%s/ricochet.cinematic"
ClipWeapon.kRicochetMaterialSound = "sound/ns2.fev/materials/%s/ricochet"

// Weapon spread - from NS1/Half-life
ClipWeapon.kCone0Degrees  = Vector( 0.0, 0.0, 0.0)
ClipWeapon.kCone1Degrees  = Vector( 0.00873, 0.00873, 0.00873 )
ClipWeapon.kCone2Degrees  = Vector( 0.01745, 0.01745, 0.01745 )
ClipWeapon.kCone3Degrees  = Vector( 0.02618, 0.02618, 0.02618 )
ClipWeapon.kCone4Degrees  = Vector( 0.03490, 0.03490, 0.03490 )
ClipWeapon.kCone5Degrees  = Vector( 0.04362, 0.04362, 0.04362 )
ClipWeapon.kCone6Degrees  = Vector( 0.05234, 0.05234, 0.05234 )
ClipWeapon.kCone7Degrees  = Vector( 0.06105, 0.06105, 0.06105 )
ClipWeapon.kCone8Degrees  = Vector( 0.06976, 0.06976, 0.06976 )
ClipWeapon.kCone9Degrees  = Vector( 0.07846, 0.07846, 0.07846 )
ClipWeapon.kCone10Degrees = Vector( 0.08716, 0.08716, 0.08716 )
ClipWeapon.kCone15Degrees = Vector( 0.13053, 0.13053, 0.13053 )
ClipWeapon.kCone20Degrees =Vector( 0.17365, 0.17365, 0.17365 )
                        
PrecacheMultipleAssets(ClipWeapon.kRicochetEffect, kSurfaceList)
PrecacheMultipleAssets(ClipWeapon.kRicochetMaterialSound, kSurfaceList)

function ClipWeapon:GetBulletsPerShot()
    return 1
end

function ClipWeapon:GetNumStartClips()
    return 4
end

function ClipWeapon:GetClipSize()
    return 10
end

function ClipWeapon:GetDrawSound()
    return ""
end

function ClipWeapon:GetDrawAnimationSpeed()
    return kMarineDrawSpeedScalar
end

function ClipWeapon:GetReloadSound()
    return ""
end

function ClipWeapon:GetFireEmptySound()
    return ""
end

function ClipWeapon:GetAccuracyRecoveryRate(player)
    local velocityScalar = player:GetVelocity():GetLength()/player:GetMaxSpeed()
    return 1.4 - .8*velocityScalar
end

function ClipWeapon:GetAccuracyLossPerShot(player)
    local scalar = ConditionalValue(player:GetCrouching(), .5, 1)
    return scalar*.2
end

// Used to affect spread and change the crosshair
function ClipWeapon:GetInaccuracyScalar()
    return 1 + (1 - self.accuracy)*1
end

function ClipWeapon:UpdateAccuracy(player, input)
    self.accuracy = self.accuracy + input.time*self:GetAccuracyRecoveryRate(player)
    self.accuracy = math.max(math.min(1, self.accuracy), 0)
end

// Return one of the ClipWeapon.kCone constants above
function ClipWeapon:GetSpread()
    return ClipWeapon.kCone0Degrees
end

function ClipWeapon:GetRange()
    return 8012
end

// Not currently used
function ClipWeapon:GetPenetration()
    return 1
end

function ClipWeapon:GetPrimaryAttackDelay()
    return .5
end

function ClipWeapon:GetAmmo()
    return self.ammo
end

function ClipWeapon:GetClip()
    return self.clip
end

function ClipWeapon:SetClip(clip)
    self.clip = clip
end

function ClipWeapon:GetAuxClip()
    return 0
end

function ClipWeapon:GetMaxAmmo()
    return 4 * self:GetClipSize()
end

// Return world position of gun barrel, used for weapon effects
function ClipWeapon:GetBarrelPoint(player)
    // TODO: Get this from the model and artwork
    return player:GetOrigin() + Vector(0, 2*Player.kYExtents*.8, 0)
end

// Add energy back over time, called from Player:OnProcessMove
function ClipWeapon:OnProcessMove(player, input)

    if((self.reloadTime ~= 0) and (Shared.GetTime() >= self.reloadTime)) then
    
        self:FillClip()
        self.reloadTime = 0
       
    end

    self:UpdateAccuracy(player, input)
    
    Weapon.OnProcessMove(self, player, input)
    
end

function ClipWeapon:OnHolster(player)
    Weapon.OnHolster(self, player)
    self.reloadTime = 0
end

function ClipWeapon:OnInit()

    local worldModel = LookupTechData(self:GetTechId(), kTechDataModel)
    if(worldModel ~= nil) then
    
        // Set model to be rendered in 3rd-person
        self:SetModel(worldModel)
        
    end
    
    self:SetMoveWithView(true)
    
    self.ammo = self:GetNumStartClips() * self:GetClipSize()
    self.clip = 0
    self.weaponState = 0
    self.loopingWeaponSoundPlaying = 0
    self.reloadTime = 0
    self.accuracy = 1

    self:FillClip()

    Weapon.OnInit(self)

end

function ClipWeapon:GetBaseIdleAnimation()
    return ClipWeapon.kAnimIdle
end

function ClipWeapon:GetSwingUpAnimation()
    return ClipWeapon.kAnimSwingUp
end

function ClipWeapon:GetIdleUpAnimation()
    return ClipWeapon.kAnimIdleUp
end

function ClipWeapon:GetSwingDownAnimation()
    return ClipWeapon.kAnimSwingDown
end

function ClipWeapon:GetBulletDamage(target, endPoint)
    Print("%s:GetBulletDamage() - Need to override GetBulletDamage()", self:GetClassName())
    return 0
end

function ClipWeapon:GetIdleAnimation()

    local idleAnimation = self:GetBaseIdleAnimation()
    local parent = self:GetParent()
    
    if parent ~= nil then    
    
        // If we're moving reasonably quickly, use the run version of the idle
        //if parent:GetVelocity():GetLengthXZ() > Player.kRunIdleSpeed then
        //    idleAnimation = self:GetRunIdleAnimation()
        //else
    
            local weaponLiftTime = parent:GetWeaponLiftTime()
            if(weaponLiftTime > 0) then
            
                idleAnimation = self:GetSwingUpAnimation()
            
                if(Shared.GetTime() > weaponLiftTime + parent:GetViewAnimationLength(idleAnimation)) then
                    idleAnimation = self:GetIdleUpAnimation()
                end
                
            else
            
                local weaponDropTime = self:GetParent():GetWeaponDropTime()
                if((weaponDropTime > 0) and (Shared.GetTime() < weaponDropTime + parent:GetViewAnimationLength(self:GetSwingDownAnimation()))) then
                
                    idleAnimation = self:GetSwingDownAnimation()
                    
                    // Don't allow us to swing up again for a bit to avoid craziness
                    parent:DeactivateWeaponLift(1)
                    
                end
                
            end
            
        //end
        
    else
        Print("%s:GetIdleAnimation(): parent is nil", self:GetClassName())
    end    
    
    return idleAnimation
    
end

function ClipWeapon:OnIdle()

    if (self.clip == 0 and self.ammo > 0) then
    
        // Try to reload if we're out of ammo and not doing anything
        self:GetParent():Reload()
        
    else
        Weapon.OnIdle(self)
    end
    
end

function ClipWeapon:GiveAmmo(numClips)

    // Fill reserves, never clip
    local bullets = numClips * self:GetClipSize()
    local bulletsToAmmo = math.min(bullets, self:GetMaxAmmo() - self:GetAmmo())
    
    self.ammo = self.ammo + bulletsToAmmo
    
    return (bulletsToAmmo > 0)
    
end

function ClipWeapon:GetNeedsAmmo()
    return self:GetClip() < self:GetClipSize() or self:GetAmmo() < self:GetMaxAmmo()
end

function ClipWeapon:GetIsPrimaryAttackLooping()
    return false
end

function ClipWeapon:GetWarmupTime()
    return 0
end

function ClipWeapon:PlayPrimaryAttackSound(player)

    local attackLoops = self:GetIsPrimaryAttackLooping()
    
    if not attackLoops or (self.loopingWeaponSoundPlaying == 0) then
    
        Shared.PlaySound(player, self:GetFireSoundName())
    
        if attackLoops then
        
            self.loopingWeaponSoundPlaying = 1 
            
        end
        
    end
        
end

function ClipWeapon:GetPrimaryAttackRequiresPress()
    return false
end

function ClipWeapon:GetForcePrimaryAttackAnimation()
    return true
end

function ClipWeapon:OnPrimaryAttack(player)
   
    if(not self:GetPrimaryAttackRequiresPress() or not self.primaryAttackLastFrame) then
    
        if (self.clip > 0 ) then
        
            // Allow the weapon to be fired again before the activity animation ends.
            // This allows us to have a fast rate of fire and still have nice animation
            // effects in the case of the final shot
            player:SetViewAnimation( self:GetPrimaryAttackAnimation(), not self:GetForcePrimaryAttackAnimation() )

            // Some weapons don't start firing right away
            local warmupTime = self:GetWarmupTime()
            
            if not self.primaryAttackLastFrame and warmupTime > 0 then
            
                player:SetActivityEnd(warmupTime)
                
            else
        
                self:FirePrimary(player, self:GetBulletsPerShot(), self:GetRange(), self:GetPenetration())
                
                // Don't decrement ammo in Darwin mode
                if(not Server or not GetGamerules():GetDarwinMode()) then
                    self.clip = self.clip - 1
                end
                            
                player:SetActivityEnd( self:GetPrimaryAttackDelay() * player:GetCatalystFireModifier() )
                
            end
            
            // Play the fire animation on the character.
            player:SetOverlayAnimation(Marine.kAnimOverlayFire)
            
            player:DeactivateWeaponLift()

            self:PlayPrimaryAttackSound(player)
            
            self:CreatePrimaryAttackEffect(player)
                    
        elseif (self.ammo > 0) then

            // Automatically reload if we're out of ammo
            player:Reload()
        
        else
        
            local emptySound = self:GetFireEmptySound()
            if emptySound ~= "" then
                Shared.PlaySound(player, emptySound)
            end
            
            // Totally out of ammo, so "dry fire"
            local time = player:SetViewAnimation( self:GetPrimaryAttackAnimation(), false, self:GetBlendTime(), 1.0)
            player:SetActivityEnd(time)
            
        end
        
    end
    
    Weapon.OnPrimaryAttack(self, player)
    
end

function ClipWeapon:CreatePrimaryAttackEffect(player)
end

function ClipWeapon:OnSecondaryAttack(player)
    Weapon.OnSecondaryAttack(self, player)
    player:DeactivateWeaponLift()
end

function ClipWeapon:FirePrimary(player, bullets, range, penetration)
    self:FireBullets(player, bullets, range, penetration)
end

// To create a tracer 20% of the time, return .2. 0 disables tracers.
function ClipWeapon:GetTracerPercentage()
    return 0
end

// Play ricochet sound/effect every %d bullets
function ClipWeapon:GetRicochetEffectFrequency()
    return 1
end

/**
 * Fires the specified number of bullets in a cone from the player's current view. Returns true if it hit.
 */
function ClipWeapon:FireBullets(player, bulletsToShoot, range, penetration)

    local hitTarget = false
    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    local startPoint = player:GetViewOffset() + player:GetOrigin()
        
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    
    for bullet = 1, bulletsToShoot do
    
        // Calculate spread for each shot, in case they differ
        local spread = self:GetSpread() * self:GetInaccuracyScalar()

        // Gaussian distribution        
        local x = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 1)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 2)) - .5)
        local y = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 3)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 4)) - .5)
        
        local spreadDirection = viewCoords.zAxis + x * spread.x * viewCoords.xAxis + y * spread.y * viewCoords.yAxis
    
        local endPoint = startPoint + spreadDirection * range
        
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, filter)
        
        if (trace.fraction < 1) then
        
            local blockedByUmbra = GetBlockedByUmbra(trace.entity)
        
            self:CreateHitEffect(player, trace.endPoint - GetNormalizedVector(endPoint - startPoint) * Weapon.kHitEffectOffset, GetSurfaceFromTrace(trace))
            
            // Create local tracer effect, and send to other players
            if (NetworkRandom(string.format("%s:FireBullet():TracerCheck", self:GetClassName())) < self:GetTracerPercentage()) then
            
                local tracerStart = startPoint + player:GetViewAngles():GetCoords().zAxis
                local tracerVelocity = GetNormalizedVector(trace.endPoint - tracerStart) * 45
                TriggerTracer(player, tracerStart, trace.endPoint, tracerVelocity)
                
            end
            
            if (trace.entity and not blockedByUmbra) then
            
                local direction = (trace.endPoint - startPoint):GetUnit()
                self:ApplyBulletGameplayEffects(player, trace.entity, trace.endPoint, direction)
                hitTarget = true
                
            end
                        
            // Play ricochet sound for player locally for feedback, but not necessarily for every bullet
            local effectFrequency = self:GetRicochetEffectFrequency()
            
            if ((bullet % effectFrequency) == 0) then
            
                local surface = GetSurfaceFromTrace(trace)
                if(surface ~= "" and surface ~= nil and surface ~= "unknown" and not blockedByUmbra) then
                
                    local worldRicochetSound = string.format(ClipWeapon.kRicochetMaterialSound, surface)

                    // Play ricochet sound at world position for everyone else
                    Shared.PlayWorldSound(nil, worldRicochetSound, nil, trace.endPoint)
                        
                    // If we are far away from our target, trigger a private sound so we can hear we hit something
                    if (trace.endPoint - player:GetOrigin()):GetLength() > 5 then
                        Shared.PlayPrivateSound(player, worldRicochetSound, player, .3, Vector(0, 0, 0))
                    end
                    
                end
                
            end
            
            // Update accuracy
            self.accuracy = math.max(math.min(1, self.accuracy - self:GetAccuracyLossPerShot(player)), 0)

        end

    end
    
    return hitTarget

end

// If we hit something, create an effect 
function ClipWeapon:CreateHitEffect(player, origin, surface)
    if(surface ~= "" and surface ~= "unknown") then
        // Create ricochet just a hair closer to us so particles don't get obscured by surface
        Shared.CreateEffect(player, string.format(ClipWeapon.kRicochetEffect, surface), nil, Coords.GetTranslation(origin))
    end
end

function ClipWeapon:ApplyBulletGameplayEffects(player, target, endPoint, direction)

    if(Server) then
    
        if target:isa("LiveScriptActor") then
        
            target:TakeDamage(self:GetBulletDamage(target, endPoint), player, self, endPoint, direction)
            
        end
    
        self:GetParent():SetTimeTargetHit()
        
    end
    
end

/**
 * Returns the name of the reload sequence used for the weapon.
 */
function ClipWeapon:GetReloadSequence()
    return ClipWeapon.kAnimReload
end

function ClipWeapon:CanReload()
    return ((self.ammo > 0) and (self.clip < self:GetClipSize()) and (self.reloadTime == 0))
end

// Return true for weapons with melee as alt-fire
function ClipWeapon:GetReloadCancellable()
    return false
end

function ClipWeapon:OnReload(player)

    if ( self:CanReload() ) then
        
        // Play the reload sequence and optionally let it be interrupted before it finishes
        local length = player:SetViewAnimation(self:GetReloadSequence())
        
        if(not self:GetReloadCancellable()) then
            player:SetActivityEnd(length)
        end
        
        self.reloadTime = Shared.GetTime() + length
        
        // Play the reload animation on the character.
        player:SetOverlayAnimation(Player.kAnimReload)
        
        // Play reload sound 
        local reloadSound = self:GetReloadSound()
        if(reloadSound ~= "") then
            Shared.PlaySound(player, reloadSound)
        end
        
    end
    
end

function ClipWeapon:OnDraw(player, previousWeaponMapName)

    if (player:GetCanNewActivityStart() and player:CanDrawWeapon()) then

        Weapon.OnDraw(self, player, previousWeaponMapName)
        
        // Attach weapon to parent's hand
        self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
        local length = player:SetViewAnimation(self:GetDrawAnimation(previousWeaponMapName), nil, nil, self:GetDrawAnimationSpeed())
        
        player:SetActivityEnd(length)
        
        local drawSound = self:GetDrawSound()
        if(drawSound ~= "") then
            Shared.PlaySound(player, drawSound)
        end
        
    end
    
end

function ClipWeapon:FillClip()

    // Stick the bullets in the clip back into our pool so that we don't lose
    // bullets. Not realistic, but more enjoyable
    self.ammo = self.ammo + self.clip

    // Transfer bullets from our ammo pool to the weapon's clip
    self.clip = math.min(self.ammo, self:GetClipSize())
    self.ammo = self.ammo - self.clip

end

Shared.LinkClassToMap("ClipWeapon", ClipWeapon.kMapName, networkVars)