// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'Weapon' (ScriptActor)

Weapon.kMapName = "weapon"

// Attach point for marine weapons
Weapon.kHumanAttachPoint = "RHand_Weapon"

Weapon.kSprintStart = "sprint_start"
Weapon.kAnimSprint = "sprint"
Weapon.kSprintEnd = "sprint_end"

Weapon.kAnimPrimaryAttack = "shoot"
Weapon.kAnimSecondaryAttack = "shoot"
Weapon.kAnimDraw = "draw"
Weapon.kAnimRunIdle = "run"

Weapon.kSwingYaw = "swing_yaw"
Weapon.kSwingPitch = "swing_pitch"

// Move hit effect slightly off surface we hit so particles don't penetrate. In meters.
Weapon.kHitEffectOffset = .15

if (Server) then
    Script.Load("lua/Weapons/Weapon_Server.lua")
else
    Script.Load("lua/Weapons/Weapon_Client.lua")
end

local networkVars = 
{
    primaryAttackLastFrame      = "boolean",
    secondaryAttackLastFrame    = "boolean",
}

function Weapon:OnCreate()

    ScriptActor.OnCreate(self)
    
    self:SetUpdates(true)
    
    self.reverseX = false
    self.moveWithView = false
    
    self:SetIsVisible(false)
    
    // So we don't attack more than once if GetPrimaryAttackRequiresPress()/GetSecondaryAttackRequiresPress()
    self.primaryAttackLastFrame = false
    self.secondaryAttackLastFrame = false
    
end

function Weapon:GetViewModelName()
    return ""
end

function Weapon:SetMoveWithView(moveWithView)
    self.moveWithView = moveWithView
end

function Weapon:GetRange()
    return 8012
end

function Weapon:SetCameraShake(amount, speed, time)
    local parent = self:GetParent()
    if(parent ~= nil and Client) then
        parent:SetCameraShake(amount, speed, time)
    end
end

function Weapon:Dropped()
    self.dropTime = Shared.GetTime()
end

function Weapon:GetPrimaryAttackAnimation()
    return Weapon.kAnimPrimaryAttack
end

function Weapon:GetSecondaryAttackAnimation()
    return Weapon.kAnimSecondaryAttack
end

function Weapon:GetRunIdleAnimation()
    return self:GetBaseIdleAnimation()
    //return Weapon.kAnimRunIdle
end

function Weapon:GetPrimaryAttackDelay()
    return .5
end

function Weapon:GetSecondaryAttackDelay()
    return .5
end

function Weapon:GetPrimaryAttackRequiresPress()
    return false
end

function Weapon:GetSecondaryAttackRequiresPress()
    return false
end

function Weapon:OnPrimaryAttack(player)
    self.primaryAttackLastFrame = true
end

function Weapon:OnPrimaryAttackEnd(player)
    self.primaryAttackLastFrame = false
end

function Weapon:OnSecondaryAttack(player)
    self.secondaryAttackLastFrame = true   
end

function Weapon:OnSecondaryAttackEnd(player)
    self.secondaryAttackLastFrame = false
end

function Weapon:OnReload(player)
end

function Weapon:OnHolster(player)
    self:SetIsVisible(false)
end

function Weapon:OnDraw(player, previousWeaponMapName)

    self:SetIsVisible(true)
    
    player:SetViewModel(self:GetViewModelName(), self)
    
end

/**
 * Called when the view animation is finished playing.
 */
function Weapon:OnAnimationComplete(animName)
end

function Weapon:AttackMeleeCapsule(player, damage, range)

    local viewOffset = player:GetViewOffset()
    local startPoint = viewOffset + player:GetOrigin()
    local endPoint = startPoint + player:GetViewAngles():GetCoords().zAxis * range
    
    local hitSomething = false
    local entityHit = nil
    local materialHit = ""
    
    while true do
    
        // const Vec3& sweepStart, const Vec3& sweepEnd, Real capsuleRadius, Real capsuleHeight, unsigned int groupsMask, EntityFilter* filter
        local capsuleHeight, capsuleRadius = player:GetTraceCapsule()
        local filter = EntityFilterOne(player)
        local trace = Shared.TraceCapsule(startPoint, endPoint, capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs, filter)
            
        if (trace.fraction < 1) then
        
            if(trace.entity ~= player) then
        
                self:CreateHitEffect(player, trace.endPoint - GetNormalizedVector(endPoint - startPoint) * Weapon.kHitEffectOffset, trace.surface)
                
                if Server then
                
                    local direction = (trace.endPoint - startPoint):GetUnit()
                    self:ApplyMeleeHitEffects(player, damage, trace.entity, trace.endPoint, direction)
                    
                end
                
                return true, trace
                
            else
            
                // Trace again so we don't hit ourselves
                startPoint = trace.endPoint
                
            end 
       
        else
        
            return false, trace
            
        end
        
    end
    
end

function Weapon:ConstrainMoveVelocity(moveVelocity)
end

// If we hit something, create an effect (in the future will be some sort of sparks or blood or whatever).        
function Weapon:CreateHitEffect(player, origin, surface)
    Shared.CreateEffect(player, ScriptActor.kSparksEffect, nil, Coords.GetTranslation(origin))
end

// Weapons can override
function Weapon:OnTargetKilled(entity)
end

function Weapon:ApplyMeleeHitEffects(player, damage, target, endPoint, direction)

    if(target ~= nil and Server and target:isa("LiveScriptActor")) then
    
        if(target:TakeDamage(damage, player, self, endPoint, direction)) then
            self:OnTargetKilled(player)        
        end
            
        self:GetParent():SetTimeTargetHit()
        
    end
    
end

function Weapon:UpdateViewModelPoseParameters(viewModel, input)
end

// TODO: Move into UpdateAnimation?
function Weapon:OnProcessMove(player, input)

    // Only update if deployed as current weapon
    if(self:GetIsActive()) then
    
        if not Shared.GetIsRunningPrediction() then
        
            local viewModel = player:GetViewModelEntity()
            if viewModel ~= nil and viewModel.modelIndex ~= 0 then
                self:UpdateViewModelPoseParameters(player:GetViewModelEntity(), input)
            end

            self:UpdateAnimation( input.time )
            
        end
        
    end
end

function Weapon:GetIsActive()
    local parent = self:GetParent()
    return (parent ~= nil and (parent:GetActiveWeapon() == self))
end

/**
 * Don't idle (we don't have a model by default).
 */
function Weapon:GetCanIdle()
    return false
end

/**
 * Don't play animations on weapons.
 */
function Weapon:SetAnimation(sequenceName, force)
end

function Weapon:GetDrawAnimation(previousWeaponMapName)
    return Weapon.kAnimDraw
end

function Weapon:GetDrawAnimationSpeed()
    return 1
end

function Weapon:GetSprintStartAnimation()
    return Weapon.kSprintStart
end

function Weapon:GetSprintAnimation()
    return Weapon.kAnimSprint
end

function Weapon:GetSprintEndAnimation()
    return Weapon.kSprintEnd
end

// Max degrees that weapon can swing left or right
function Weapon:GetSwingAmount()
    return 40
end

function Weapon:GetSwingSensitivity()
    return .5
end

Shared.LinkClassToMap("Weapon", Weapon.kMapName, networkVars)
