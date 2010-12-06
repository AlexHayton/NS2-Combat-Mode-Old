//=============================================================================
//
// lua\Weapons\Marine\Grenade.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2010, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Grenade' (Projectile)

Grenade.kMapName            = "grenade"
Grenade.kModelName          = PrecacheAsset("models/marine/rifle/rifle_grenade.model")
Grenade.kExplosionSound     = PrecacheAsset("sound/ns2.fev/marine/common/explode")
Grenade.kGrenadeBounceSound = PrecacheAsset("sound/ns2.fev/marine/rifle/grenade_bounce")
Grenade.kExplosionEffect    = "cinematics/materials/%s/grenade_explosion.cinematic"
PrecacheMultipleAssets(Grenade.kExplosionEffect, kSurfaceList)

Grenade.kDamageRadius       = kGrenadeLauncherDamageRadius
Grenade.kMaxDamage          = kGrenadeLauncherDamage
Grenade.kLifetime           = kGrenadeLifetime

function Grenade:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( Grenade.kModelName )
    
    // Explode after a bit
    self:SetNextThink(Grenade.kLifetime)
    
end

function Grenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function Grenade:GetDamageType()
    return kGrenadeLauncherDamageType
end

if (Server) then

    function Grenade:OnCollision(targetHit)
    
        if targetHit and (targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit then
            self:Detonate(targetHit)            
        else
            if self:GetVelocity():GetLength() > 2 then
                self:PlaySound(Grenade.kGrenadeBounceSound)
            end
        end
        
    end    
    
    // Blow up after a time
    function Grenade:OnThink()
        self:Detonate(nil)
    end
    
    function Grenade:Detonate(targetHit)
    
        // Play sound and particle effect
        Shared.PlayWorldSound(nil, Grenade.kExplosionSound, nil, self:GetOrigin())
        
        // Do damage to targets
        local hitEntities = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Grenade.kDamageRadius)
        
        // Remove grenade and add firing player
        table.removevalue(hitEntities, self)
        table.insertunique(hitEntities, self:GetOwner())
        
        RadiusDamage(hitEntities, self:GetOrigin(), Grenade.kDamageRadius, Grenade.kMaxDamage, self)

        if self.physicsBody then

            local surface = GetSurfaceFromEntity(targetHit)
            
            if(surface ~= "" and surface ~= nil and surface ~= "unknown") then
                Shared.CreateEffect(nil, string.format(Grenade.kExplosionEffect, surface), nil, BuildCoords(Vector(0, 1, 0), Vector(0, 0, 1), self.physicsBody:GetCoords().origin, 1))    
            end
            
        end

        // Destroy first, just in case there are script errors below somehow
        DestroyEntity(self)
        
    end

end

Shared.LinkClassToMap("Grenade", Grenade.kMapName)