//=============================================================================
//
// lua\Weapons\Alien\Spike.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2010, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'HydraSpike' (Projectile)

HydraSpike.kMapName            = "hydraspike"
HydraSpike.kModelName          = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")
HydraSpike.kHitSound           = PrecacheAsset("sound/ns2.fev/alien/common/spikes_ricochet")
HydraSpike.kImpactEffect       = PrecacheAsset("cinematics/alien/lerk/spike_impact.cinematic")

HydraSpike.kDamage             = kHydraSpikeDamage

function HydraSpike:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( HydraSpike.kModelName )    
    self:SetUpdates(true)
    
end

function HydraSpike:GetTechId()
    return kTechId.HydraSpike
end

function HydraSpike:GetDeathIconIndex()
    return kDeathMessageIcon.HydraSpike
end

if (Server) then

    function HydraSpike:OnCollision(targetHit)

        // Don't hit parent - shooter
        if targetHit == nil or (targetHit ~= nil and self:GetParentId() ~= targetHit:GetId()) then

            if targetHit ~= nil and targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit) then

                targetHit:TakeDamage(HydraSpike.kDamage, self:GetOwner(), self, self:GetOrigin(), nil)                    

            end            

            // Play sound and particle effect
            Shared.PlayWorldSound(nil, HydraSpike.kHitSound, nil, self:GetOrigin())
            
            Shared.CreateEffect(nil, HydraSpike.kImpactEffect, nil, self:GetCoords())
            
            DestroyEntity(self)
                
        end    
        
    end
    
end

Shared.LinkClassToMap("HydraSpike", HydraSpike.kMapName, {})