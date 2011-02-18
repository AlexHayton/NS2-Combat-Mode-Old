//=============================================================================
//
// lua\Weapons\Marine\Grenade.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Grenade' (Projectile)

Grenade.kMapName            = "grenade"
Grenade.kModelName          = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

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
                self:TriggerEffects("grenade_bounce")
            end
        end
        
    end    
    
    // Blow up after a time
    function Grenade:OnThink()
        self:Detonate(nil)
    end
    
    // Kill all infestation entities in half of range
    function Grenade:DetonateInfestation()
        
        local centerOrigin = self:GetOrigin()
        
        local infestations = GetGamerules():GetEntities("Infestation", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Grenade.kDamageRadius/2)
        
        for index, target in ipairs(infestations) do
        
            // Trace line to each target to make sure it's not blocked by a wall 
            local targetOrigin = target:GetModelOrigin()
            if target.GetEngagementPoint then
                targetOrigin = target:GetEngagementPoint()
            end
            
            // Trace to make sure we have LOS
            if not GetWallBetween(centerOrigin, targetOrigin, self) and target.Kill then

                target:Kill(nil, self, centerOrigin, GetNormalizedVector(targetOrigin - centerOrigin))
                
            end
            
        end

    end
    
    function Grenade:Detonate(targetHit)
    
        // Do damage to targets
        local hitEntities = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Grenade.kDamageRadius)
        
        // Remove grenade and add firing player
        table.removevalue(hitEntities, self)
        table.insertunique(hitEntities, self:GetOwner())
        
        RadiusDamage(hitEntities, self:GetOrigin(), Grenade.kDamageRadius, Grenade.kMaxDamage, self)
        
        self:DetonateInfestation()
        
        local surface = GetSurfaceFromEntity(targetHit)        
        local params = {surface = surface}
        if not targetHit then
            params[kEffectHostCoords] = BuildCoords(Vector(0, 1, 0), self:GetCoords().zAxis, self:GetOrigin(), 1)
        end
        
        self:TriggerEffects("grenade_explode", params)

        // Destroy first, just in case there are script errors below somehow
        DestroyEntity(self)
        
    end

end

Shared.LinkClassToMap("Grenade", Grenade.kMapName)