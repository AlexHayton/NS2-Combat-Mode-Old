// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Finite state machine for moving ARC towards desired mode. The last entry in each
// table is the desired mode and the previous entries represent the path to get there.
local desiredModeTransitions =
{
    {ARC.kMode.Firing, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.FireCooldown, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.Deployed, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.UndeployedStationary, ARC.kMode.Deploying, ARC.kMode.Deployed},
    {ARC.kMode.Moving, ARC.kMode.Deploying, ARC.kMode.Deployed},
    {ARC.kMode.UndeployedStationary, ARC.kMode.Moving},
    {ARC.kMode.Moving, ARC.kMode.UndeployedStationary},
    {ARC.kMode.Deployed, ARC.kMode.Targeting, ARC.kMode.Firing},
    {ARC.kMode.FireCooldown, ARC.kMode.Targeting, ARC.kMode.Firing},
}

function ARC:UpdateMoveOrder(deltaTime)

    local currentOrder = self:GetCurrentOrder()
    ASSERT(currentOrder)
    
    self:SetDesiredMode(ARC.kMode.Moving)
    
    local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), ARC.kMoveSpeed, deltaTime)
    if distToTarget < kEpsilon then
    
        self:CompletedCurrentOrder()
        self:SetPoseParam(ARC.kMoveParam, 0)
        
        // If no more orders, we're done
        if self:GetCurrentOrder() == nil then
            self:SetDesiredMode(ARC.kMode.UndeployedStationary)
        end
        
    else    
        // Repeatedly trigger movement effect 
        self:TriggerEffects("arc_moving")
        
        self:SetPoseParam(ARC.kMoveParam, .5)
    end
    
end

function ARC:UpdateOrders(deltaTime)

    // If deployed, check for targets
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        // Move ARC if it has an order and it can be moved
        if currentOrder:GetType() == kTechId.Move and (self.mode == ARC.kMode.Moving or self.mode == ARC.kMode.UndeployedStationary) then
        
            self:UpdateMoveOrder(deltaTime)

        elseif currentOrder:GetType() == kTechId.Attack and (self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.FireCooldown) then
            
            local target = self:GetTarget()
            if self:GetIsTargetValid(target) then
            
                // Try to attack it
                self:SetDesiredMode(ARC.kMode.Firing)
                
            else
            
                self:ClearCurrentOrder()
                
            end
            
        end

    elseif self:GetInAttackMode() then
    
        // Check for new target every so often, but not every frame
        local time = Shared.GetTime()
        if self.timeOfLastAcquire == nil or (time > self.timeOfLastAcquire + 1.5) then
        
            self:AcquireTarget()
            
            self.timeOfLastAcquire = time
            
        end

    end

end

function ARC:AcquireTarget()

    local newTarget = nil
    
    // Find the nearest enemy structure in range
    local shortestDistanceToTarget = nil
    
    local targets = GetGamerules():GetEntities("Structure" , GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), ARC.kFireRange, true)

    for index, structure in pairs(targets) do

        if self:GetIsTargetValid(structure) then

            // Is it closest?
            local distanceToTarget = (structure:GetOrigin() - self:GetOrigin()):GetLengthXZ()
            if(newTarget == nil or distanceToTarget < shortestDistanceToTarget) then

                // New closest target
                newTarget = structure
                shortestDistanceToTarget = distanceToTarget

            end

        end

    end
    
    if newTarget ~= nil then
    
        if not self.desiredMode == ARC.kMode.UndeployedStationary then
        
            //Print("ARC:Acquired new target: %s, firing", SafeClassName(newTarget))
            self:GiveOrder(kTechId.Attack, newTarget:GetId(), nil)
            self:SetDesiredMode(ARC.kMode.Firing)
            
        end
        
    end
    
    return newTarget

end

function ARC:GetIsTargetValid(target) 
    return target ~= nil and target:isa("Structure") and (GetEnemyTeamNumber(self:GetTeamNumber()) == target:GetTeamNumber()) and target:GetIsAlive() and ((target:GetOrigin() - self:GetOrigin()):GetLengthXZ() < ARC.kFireRange) and self:GetCanSeeEntity(target)
end

function ARC:PerformAttack()

    local target = self:GetTarget()
    if target then
    
        // Play big hit sound at origin
        target:TriggerEffects("arc_hit_primary")

        // Do damage to everything in radius. Use upgraded splash radius if researched.
        local damageRadius = ConditionalValue(GetTechSupported(self, kTechId.ARCSplashTech), ARC.kUpgradedSplashRadius, ARC.kSplashRadius)
        local hitEntities = GetEntitiesIsaInRadius("Structure", GetEnemyTeamNumber(self:GetTeamNumber()), target:GetOrigin(), damageRadius, false)

        // Do damage to every target in range
        RadiusDamage(hitEntities, target:GetOrigin(), damageRadius, ARC.kAttackDamage, self)

        // Play hit effect on each
        for index, target in ipairs(hitEntities) do
        
            target:TriggerEffects("arc_hit_secondary")
            
        end
        
    else
        Print("ARC:PerformAttack(): No target.")
    end
    
end

function ARC:SetMode(mode)

    if self.mode ~= mode then
    
        local currentAnimation = self:GetAnimation()
        local currentAnimationLength = self:GetAnimationLength()
        local prevAnimationComplete = self.animationComplete

        local triggerEffectName = "arc_" .. string.lower(EnumToString(ARC.kMode, mode))        
        //Print("SetMode(%s) - Triggering %s", EnumToString(ARC.kMode, mode), triggerEffectName)
        self:TriggerEffects(triggerEffectName)
        
        self.mode = mode
        
        // If animation was triggered, store it so we don't transition until it's complete
        if self:GetAnimation() ~= currentAnimation or self.animationComplete ~= prevAnimationComplete then
            self.modeBlockTime = Shared.GetTime() + self:GetAnimationLength()
        else
            self.modeBlockTime = nil    
        end
        
        // Now process actions per mode
        if self.mode == ARC.kMode.Deployed then
        
            self:AcquireTarget()

        elseif self.mode == ARC.kMode.Firing then
        
            self:PerformAttack()
            
            self:SetMode(ARC.kMode.FireCooldown)            
                        
        elseif self.mode == ARC.kMode.FireCooldown then  
        
            // Cooldown time is length attack rate minus fire animation length
            self.modeBlockTime = Shared.GetTime() + ARC.kAttackInterval/*(ARC.kAttackInterval - currentAnimationLength)*/
                        
        elseif self.mode == ARC.kMode.Targeting then
        
            // Hit a short time after firing
            self.modeBlockTime = Shared.GetTime() + ARC.kFireToHitInterval 

        end
        
        if self.modeBlockTime then
            Print("Set mode block time delay %.2f (currentTime is %.2f)", self.modeBlockTime - Shared.GetTime(), Shared.GetTime())
        end
        
    end
    
end

function ARC:SetDesiredMode(mode)
    if self.desiredMode ~= mode then
        //Print("Setting desired mode to %s", EnumToString(ARC.kMode, mode))
        self.desiredMode = mode
    end
end

function ARC:UpdateMode()

    if self.desiredMode ~= self.mode then
    
        // Look at desired state transitions with a target of this desired mode and move us toward it
        if not self.modeBlockTime or Shared.GetTime() >= self.modeBlockTime then
                    
            for index, path in ipairs(desiredModeTransitions) do
            
                local numPathEntries = table.count(path)
                local target = path[numPathEntries]
                
                if target == self.desiredMode then
                
                    for pathIndex = 1, numPathEntries - 1 do
                    
                        if path[pathIndex] == self.mode then
                        
                            local newMode = path[pathIndex + 1]
                            
                            //Print("Found path transition (%s) => %s", ToString(path), EnumToString(ARC.kMode, newMode))
                            
                            self:SetMode(newMode)
                            
                            return
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

function ARC:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)
    
    self:UpdateMode()
    
    self:UpdateOrders(deltaTime)
    
end

