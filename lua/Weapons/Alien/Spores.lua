// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spores.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SporeCloud.lua")

class 'Spores' (Ability)

Spores.kMapName = "spores"

Spores.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spores_shoot")
Spores.kHitSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spores_hit")

// Particle effects
Spores.kEffect = PrecacheAsset("cinematics/alien/lerk/spores.cinematic")
Spores.kImpactEffect = PrecacheAsset("cinematics/alien/lerk/spore_impact.cinematic")
Spores.kViewIdleEffect = PrecacheAsset("cinematics/alien/lerk/spore_view_idle.cinematic")
Spores.kViewFireEffect = PrecacheAsset("cinematics/alien/lerk/spore_view_fire.cinematic")

Spores.kAnimIdleTable = {{1, "idle"}/*, {.1, "idle2"}, {.5, "idle3"}*/ }
Spores.kAnimAttack = "attack"
Spores.kPlayerAnimAttack = "spores"
Spores.kDelay = kSporesFireDelay
Spores.kSwitchTime = .5

// Points per second
Spores.kDamage = kSporesDamagePerSecond

local networkVars = {
    sporePoseParam     = "compensated float"
}

function Spores:OnCreate()
    Ability.OnCreate(self)
    self.sporePoseParam = 0
end

function Spores:GetEnergyCost(player)
    return kSporesEnergyCost
end

function Spores:GetIdleAnimation()
    return chooseWeightedEntry( Spores.kAnimIdleTable )
end

function Spores:GetPrimaryAttackDelay()
    return Spores.kDelay
end

function Spores:GetIconOffsetY(secondary)
    return kAbilityOffset.Spores
end

function Spores:OnViewModelIdle()
    self:CreateViewModelEffect(Spores.kViewIdleEffect)
end

function Spores:PerformPrimaryAttack(player)
    
    player:SetViewAnimation(Spores.kAnimAttack, nil, nil, 1/player:AdjustFuryFireDelay(1))
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    // Play the attack animation on the character.
    player:SetOverlayAnimation(Spores.kPlayerAnimAttack)      

    Shared.PlaySound(player, Spores.kAttackSound)
    
    // TODO: Create projectile and update Spores.kEffect so it follows it to it
    
    // Trace instant line to where it should hit
    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()    
    local startPoint = player:GetOrigin() + player:GetViewOffset() + viewCoords.zAxis

    local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * 1000, PhysicsMask.AllButPCs, EntityFilterOne(self))
    if trace.fraction < 1 then
    
        Shared.CreateEffect(player, Spores.kImpactEffect, nil, Coords.GetTranslation(trace.endPoint))
        
        // Create spore cloud that will damage players
        if Server then
       
            local spores = CreateEntity(SporeCloud.kMapName, trace.endPoint, player:GetTeamNumber())
            spores:SetOwner(player)

            Shared.PlayWorldSound(nil, Spores.kHitSound, nil, trace.endPoint)

        end
        
    end
    
end

function Spores:GetHUDSlot()
    return 2
end

function Spores:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)
    
    self.sporePoseParam = Clamp(Slerp(self.sporePoseParam, 1, (1 / kLerkWeaponSwitchTime) * input.time), 0, 1)
    
    viewModel:SetPoseParam("spore", self.sporePoseParam)
    
end


Shared.LinkClassToMap("Spores", Spores.kMapName, networkVars )
