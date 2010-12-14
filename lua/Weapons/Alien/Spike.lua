//=============================================================================
//
// lua\Weapons\Alien\Spike.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2010, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Spike' (Projectile)

Spike.kMapName            = "spike"
Spike.kModelName          = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")
Spike.kHitSound           = PrecacheAsset("sound/ns2.fev/alien/common/spikes_ricochet")

// Does full damage up close then falls off over time 
Spike.kMaxDamage             = kSpikeMaxDamage
Spike.kMinDamage             = kSpikeMinDamage

// Seconds
Spike.kDamageFalloffInterval = 1

function Spike:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( Spike.kModelName )    
    
    // Remember when we're created so we can fall off damage
    self.createTime = Shared.GetTime()
        
end

function Spike:SetDeathIconIndex(index)
    self.iconIndex = index
end

function Spike:GetDeathIconIndex()
    return self.iconIndex
end

if (Server) then

    function Spike:OnCollision(targetHit)

        // Don't hit owner - shooter
        if targetHit == nil or self:GetOwner() ~= targetHit then
        
            // Play sound and particle effect
            Shared.PlayWorldSound(nil, Spike.kHitSound, nil, self:GetOrigin())
            
            if targetHit == nil or (targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) then

                if targetHit ~= nil then
                
                    // Do max damage for short time and then fall off over time to encourage close quarters combat instead of 
                    // hanging back and sniping
                    local damageScalar = ConditionalValue(self:GetOwner():GetHasUpgrade(kTechId.Piercing), kPiercingDamageScalar, 1)
                    local damage = Spike.kMaxDamage - Clamp( (Shared.GetTime() - self.createTime) / Spike.kDamageFalloffInterval, 0, 1) * (Spike.kMaxDamage - Spike.kMinDamage)
                    targetHit:TakeDamage(damage * damageScalar, self:GetOwner(), self, self:GetOrigin(), nil)
                    
                end

            end            
            
            // Destroy first, just in case there are script errors below
            DestroyEntity(self)
                
        end    
        
    end
    
end

function Spike:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Server then
        self:SetOrientationFromVelocity()
    end
    
end

Shared.LinkClassToMap("Spike", Spike.kMapName, {})