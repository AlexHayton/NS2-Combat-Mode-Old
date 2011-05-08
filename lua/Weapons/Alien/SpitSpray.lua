// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SpitSpray.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Spit attack on primary, healing spray on secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

SpitSpray.kSpitDelay = kSpitFireDelay
SpitSpray.kSpitSpeed = 40

SpitSpray.kHealthSprayEnergyCost = kHealsprayEnergyCost
SpitSpray.kMinHeal = 5
SpitSpray.kHealRadius = 3.5
SpitSpray.kBaseHealAmount = 13      // Heal by base amount + percentage of max health
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

function SpitSpray:CreateSpitProjectile(player)   

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetViewOffset() + player:GetOrigin() + viewCoords.zAxis * 1
        
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
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    self:CreateSpitProjectile(player)               
    
end

// Find friendly players and structures in front of us, in cone and heal them by a 
// a percentage of their health
function SpitSpray:HealEntities(player)
    
    local success = false
    
    local ents = GetEntitiesWithinRangeAreVisible("LiveScriptActor", self:GetHealOrigin(player), SpitSpray.kHealRadius, true)
    
    for index, targetEntity in ipairs(ents) do

        if( targetEntity ~= player ) then
            
            local isHurtPlayer = (GetEnemyTeamNumber(player:GetTeamNumber()) == targetEntity:GetTeamNumber()) and targetEntity:isa("Player")
            local isHealTarget = (player:GetTeamNumber() == targetEntity:GetTeamNumber())
            
            // TODO: Traceline to target to make sure we don't go through objects (or check line of sight because of area effect?)
            // GetHealthScalar() factors in health and armor.
            if isHealTarget and targetEntity:GetHealthScalar() < 1 then

                // Heal entities by base amount plus a scaleable amount so it is helpful vs. weak targets yet doesn't take forever to heal hives (NS1)
                local health = SpitSpray.kBaseHealAmount + math.max(SpitSpray.kMinHeal, targetEntity:GetMaxHealth() * SpitSpray.kHealthPercent)
                targetEntity:AddHealth( health )
				
				// Grant experience too
				local experience = Experience_ComputeExperience(targetEntity, health)
				player:AddExperience(experience)
				Experience_GrantNearbyExperience(player, experience)
                
                // Put out entities on fire sometimes
                if math.random() < kSprayDouseOnFireChance then
                    targetEntity:SetGameEffectMask(kGameEffect.OnFire, false)
                end
                
                targetEntity:TriggerEffects("sprayed")
                
                success = true
                
            elseif isHurtPlayer then
            
                targetEntity:TakeDamage( SpitSpray.kHealingSprayDamage, player, self, self:GetOrigin(), nil)
                targetEntity:TriggerEffects("sprayed")
                success = true
                
            end 
       
        end
        
    end
    
    return success
        
end

function SpitSpray:GetSecondaryAttackDelay()
    return SpitSpray.kHealthSprayDelay 
end

function SpitSpray:GetSecondaryEnergyCost()
    return SpitSpray.kHealthSprayEnergyCost
end

function SpitSpray:GetHealOrigin(player)

    local startPos = player:GetEyePos()
    local trace = Shared.TraceRay(startPos, startPos + (player:GetViewAngles():GetCoords().zAxis * SpitSpray.kHealRadius), PhysicsMask.Bullets, EntityFilterOne(player))
    return trace.endPoint
    
end

function SpitSpray:PerformSecondaryAttack(player)

    self.spitMode = false
    
    player:SetActivityEnd( player:AdjustFuryFireDelay(self:GetSecondaryAttackDelay() ))
    
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

function SpitSpray:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    // Override host coords for spray to be where heal origin is
    local player = self:GetParent()
    if player then
        tableParams[kEffectHostCoords] = BuildCoordsFromDirection(player:GetViewCoords().zAxis, self:GetHealOrigin(player))
    end
    
end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars )
