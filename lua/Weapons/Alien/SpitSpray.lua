// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SpitSpray.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Spit attack on primary, health spray on secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

SpitSpray.kAttackSoundName = PrecacheAsset("sound/ns2.fev/alien/gorge/spit")
SpitSpray.kAnimSpitAttack = "spit_attack"
SpitSpray.kAnimSprayAttack = "spray_attack"
SpitSpray.kSpitDelay = kSpitFireDelay
SpitSpray.kSpitSpeed = 40
SpitSpray.kAnimPlayerSpit = "spit"
SpitSpray.kAnimPlayerSpray = "healthspray"

// Gorge spit
SpitSpray.kPlayerAnimAttack = "spit"

// Health spray
SpitSpray.kHealthSpraySound = PrecacheAsset("sound/ns2.fev/alien/gorge/heal_spray")
SpitSpray.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")
SpitSpray.kSprayAttachPoint = "Head"

// Effects
SpitSpray.kSpitEffect = PrecacheAsset("cinematics/alien/gorge/spit.cinematic")
SpitSpray.kSpitImpactEffect = PrecacheAsset("cinematics/alien/gorge/spit_impact.cinematic")
SpitSpray.kSpitFireEffect = PrecacheAsset("cinematics/alien/gorge/spit_fire.cinematic")
SpitSpray.kHealthSprayEffect = PrecacheAsset("cinematics/alien/gorge/healthspray.cinematic")
SpitSpray.kHealthSprayViewEffect = PrecacheAsset("cinematics/alien/gorge/healthspray_view.cinematic")
SpitSpray.kHealthSprayViewIdleEffect = PrecacheAsset("cinematics/alien/gorge/healthspray_view_idle.cinematic")

// Gorge health spray
SpitSpray.kAnimSprayTable = { {.5, "health_spray_attack"} }

SpitSpray.kAnimIdleTable = { {1, "idle"}, {.3, "idle2"}, {.05, "idle3"} }

SpitSpray.kHealthSprayEnergyCost = kHealsprayEnergyCost
SpitSpray.kMinHeal = 5
SpitSpray.kHealRadius = 1.5
SpitSpray.kHealthPercent = 0.05
SpitSpray.kHealingSprayDamage = kHealsprayDamage
SpitSpray.kHealthSprayDelay = kHealsprayFireDelay

local networkVars = {
    chamberPoseParam        = "compensated float",
    // Remember if we most recently spit or sprayed for damage types
    spitMode                = "boolean"
}

function SpitSpray:OnCreate()
    Ability.OnCreate(self)
    self.chamberPoseParam = 0
    self.spitMode = true
end

function SpitSpray:GetEnergyCost(player)
    return kSpitEnergyCost
end

function SpitSpray:GetHasSecondary()
    return true
end

function SpitSpray:GetHUDSlot()
    return 1
end

function SpitSpray:GetTechId()
    if self.spitMode then
        return kTechId.Spit
    else
        return kTechId.Spray
    end
end

function SpitSpray:GetDeathIconIndex()
    if self.spitMode then
        return kDeathMessageIcon.Spit
    else
        return kDeathMessageIcon.Spray
    end
end

function SpitSpray:GetIconOffsetY(secondary)
    return kAbilityOffset.Spit
end

function SpitSpray:GetIdleAnimation()
    return chooseWeightedEntry(SpitSpray.kAnimIdleTable)
end

function SpitSpray:CreateSpitProjectile(player)   

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetViewOffset() + player:GetOrigin()
        
        local spit = CreateEntity(Spit.kMapName, startPoint, player:GetTeamNumber())
        SetAnglesFromVector(spit, viewCoords.zAxis)
        
        spit:SetPhysicsType(Actor.PhysicsType.Kinematic)
        
        local startVelocity = viewCoords.zAxis * SpitSpray.kSpitSpeed
        spit:SetVelocity(startVelocity)
        
        spit:SetGravityEnabled(false)
        
        // Set spit owner to player so we don't collide with ourselves and so we
        // can attribute a kill to us
        spit:SetOwner(player)
        
    end

end

function SpitSpray:GetPrimaryAttackDelay()
    return SpitSpray.kSpitDelay
end

function SpitSpray:GetPrimaryEnergyCost()
    return kSpitEnergyCost
end

function SpitSpray:PerformPrimaryAttack(player)
    
    self.spitMode = true
    
    player:SetViewAnimation(SpitSpray.kAnimSpitAttack, nil, nil, 1/player:AdjustFuryFireDelay(1))
    
    player:SetOverlayAnimation(SpitSpray.kAnimPlayerSpit)
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    Shared.PlaySound(player, SpitSpray.kAttackSoundName)

    self:CreateSpitProjectile(player)               
    
end

// Find friendly players and structures in front of us, in cone and heal them by a 
// a percentage of their health
function SpitSpray:HealEntities(player)

    local ents = GetEntitiesIsaInRadius("LiveScriptActor", -1, self:GetHealOrigin(player), SpitSpray.kHealRadius, false, true)
    
    for index, targetEntity in ipairs(ents) do
    
        if( targetEntity ~= player ) then
        
            local hurtPlayer = (GetEnemyTeamNumber(player:GetTeamNumber()) == targetEntity:GetTeamNumber())
            local healPlayer = (player:GetTeamNumber() == targetEntity:GetTeamNumber())
            if targetEntity:GetHealth() < targetEntity:GetMaxHealth() then
                
                // TODO: Traceline to target to make sure we don't go through objects (or check line of sight because of area effect?)
                if healPlayer then
                    
                    local health = math.max(SpitSpray.kMinHeal, targetEntity:GetMaxHealth() * SpitSpray.kHealthPercent)
                    targetEntity:AddHealth( health )
                    
                    // Put out entities on fire 
                    targetEntity:SetGameEffectMask(kGameEffect.OnFire, false)
                    
                elseif hurtPlayer then
                
                    targetEntity:AddHealth( -SpitSpray.kHealingSprayDamage )
                    
                end 
               
                Shared.PlayWorldSound(nil, SpitSpray.kRegenerationSound, nil, targetEntity:GetOrigin())
            
            end
       
        end
        
    end
        
end

function SpitSpray:GetSecondaryAttackDelay()
    return SpitSpray.kHealthSprayDelay 
end

function SpitSpray:GetSecondaryEnergyCost()
    return SpitSpray.kHealthSprayEnergyCost
end

function SpitSpray:GetHealOrigin(player)
    return player:GetEyePos() + (player:GetViewAngles():GetCoords().zAxis * SpitSpray.kHealRadius)
end

function SpitSpray:PerformSecondaryAttack(player)

    self.spitMode = false
    
    player:SetViewAnimation(SpitSpray.kAnimSprayAttack, nil, nil, 1/player:AdjustFuryFireDelay(1))
    
    player:SetOverlayAnimation(SpitSpray.kAnimPlayerSpray)
    
    player:SetActivityEnd( player:AdjustFuryFireDelay(self:GetSecondaryAttackDelay() ))

    Shared.PlaySound(player, SpitSpray.kHealthSpraySound)
    
    // Put slightly in front of us
    local coords = Coords(self:GetViewCoords())
    coords.origin = self:GetHealOrigin(player)
    Shared.CreateEffect(player, SpitSpray.kHealthSprayEffect, nil, coords)

    if Server then           
        self:HealEntities( player )
    end        
    
    return true

end

function SpitSpray:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)

    // Move away from chamber 
    self.chamberPoseParam = Clamp(Slerp(self.chamberPoseParam, 0, input.time), 0, 1)
    viewModel:SetPoseParam("chamber", self.chamberPoseParam)
    
end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars )
