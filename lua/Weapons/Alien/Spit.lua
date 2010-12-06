//=============================================================================
//
// lua\Weapons\Alien\Spit.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2010, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Spit' (Projectile)

Spit.kMapName            = "spit"
Spit.kModelName          = PrecacheAsset("models/alien/gorge/spit_proj.model")
Spit.kSpitHitSound       = PrecacheAsset("sound/ns2.fev/alien/gorge/spit_hit")
Spit.kSpitEffect         = PrecacheAsset("cinematics/alien/gorge/spit.cinematic")
Spit.kSpitHitEffect      = PrecacheAsset("cinematics/alien/gorge/spit_impact.cinematic")
Spit.kDamage             = kSpitDamage

function Spit:OnInit()

    Projectile.OnInit(self)
    
    self:SetModel( Spit.kModelName )
    
    if Client then
    
        self:SetUpdates(true)
        
        // Create trailing spit that is attached to projectile
        self.spitEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.spitEffect:SetCinematic(Spit.kSpitEffect)
        
        self.spitEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        
    end
    
end

function Spit:OnDestroy()

    if Server then
        self:SetOwner(nil)
    end
    
    if Client and self.spitEffect then
        Client.DestroyCinematic(self.spitEffect)
        self.spitEffect = nil
    end
    
    Projectile.OnDestroy(self)

end

function Spit:GetDeathIconIndex()
    return kDeathMessageIcon.Spit
end

if (Server) then

    function Spit:OnCollision(targetHit)

        // Don't hit owner - shooter
        if targetHit == nil or self:GetOwner() ~= targetHit then
            // Play sound and particle effect
            Shared.PlayWorldSound(nil, Spit.kSpitHitSound, nil, self:GetOrigin())
            
            if self.physicsBody then
                Shared.CreateEffect(nil, Spit.kSpitHitEffect, nil, self.physicsBody:GetCoords())
            end

            if targetHit == nil or (targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) then

                if targetHit ~= nil then
                
                    targetHit:TakeDamage(Spit.kDamage, self:GetOwner(), self, self:GetOrigin(), nil)
                    
                end

            end            
            
            // Destroy first, just in case there are script errors below
            DestroyEntity(self)
                
        end    
        
    end
    
end

if Client then

    function Spit:OnUpdate(deltaTime)
    
        //Print("Spit:OnUpdate(): %.2f fps", 1/deltaTime)
        if self.spitEffect ~= nil and self:GetId() ~= Entity.invalidId then
        
            Projectile.OnUpdate(self)
            
            local coords = Coords.GetIdentity()
            VectorCopy(self:GetOrigin(), coords.origin)
            self.spitEffect:SetCoords(coords)
            
            //Print("Setting cinematic coords: %s", CoordsToString(coords))
            
        end 
       
    end
    
end

Shared.LinkClassToMap("Spit", Spit.kMapName)