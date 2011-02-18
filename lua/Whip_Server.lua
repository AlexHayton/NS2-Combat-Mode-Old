// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Whip_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Whip:OnConstructionComplete()

    Structure.OnConstructionComplete(self)

    self:SetNextThink(1.0)
        
end

function Whip:AcquireTarget()

    local finalTarget = nil
    
    if(self.timeOfLastTargetAcquisition == nil or (Shared.GetTime() > self.timeOfLastTargetAcquisition + Whip.kTargetCheckTime)) then
    
        self.shortestDistanceToTarget = nil
        self.targetIsaPlayer = false
        
        local targets = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Whip.kRange, true)
        
        for index, target in pairs(targets) do
        
            local validTarget, distanceToTarget = self:GetIsTargetValid(target)
            
            if validTarget then
            
                local newTargetCloser = (self.shortestDistanceToTarget == nil or (distanceToTarget < self.shortestDistanceToTarget))
                local newTargetIsaPlayer = target:isa("Player")
        
                // Give players priority over regular entities, but still pick closer players
                if( (not self.targetIsaPlayer and newTargetIsaPlayer) or
                    (newTargetCloser and not (self.targetIsaPlayer and not newTargetIsaPlayer)) ) then
            
                    // Set new target
                    finalTarget = target
                    self.shortestDistanceToTarget = distanceToTarget
                    self.targetIsaPlayer = newTargetIsaPlayer
                    
                end           
                
            end
                
        end
        
        if finalTarget ~= nil then
    
            self:GiveOrder(kTechId.Attack, finalTarget:GetId(), nil)
        
        else
        
            self:ClearOrders()
            
        end
        
        self.timeOfLastTargetAcquisition = Shared.GetTime()

    end
    
end

function Whip:GetIsTargetValid(target)

    if(target ~= nil and target:GetIsAlive() and target ~= self and target:GetCanTakeDamage() and target:GetIsVisible()) then
    
        local distance = (target:GetOrigin() - self:GetOrigin()):GetLength()
        
        if(self:GetCanSeeEntity(target) and (distance < Whip.kRange)) then
        
            return true, distance
            
        end
    
    end

    return false, -1

end

function Whip:AttackTarget()

    local target = self:GetTarget()
    
    if(target ~= nil) then
    
        self:TriggerEffects("whip_attack")
   
        // When attack animation finishes, attack again
        self.attackAnimation = self:GetAnimation()
    
        self.timeOfLastStrikeStart = Shared.GetTime()
        
        self.timeOfNextStrikeHit = Shared.GetTime() + self:AdjustFuryFireDelay(.5)
        
    end

end

function Whip:StrikeTarget()

    local target = self:GetTarget()
    if(target ~= nil) then

        // Hit main target
        self:DamageTarget(target)
        
        // Try to hit other targets close by
        local nearbyEnts = GetGamerules():GetEntities("LiveScriptActor", target:GetTeamNumber(), target:GetModelOrigin(), Whip.kAreaEffectRadius, false, true)
        for index, ent in ipairs(nearbyEnts) do
        
            if ent ~= target then
                ent:TakeDamage(Whip.kDamage, self, self, target:GetOrigin(), direction)
            end
            
        end
        
    end
    
    self.timeOfNextStrikeHit = nil
    
end

function Whip:DamageTarget(target)

    local direction = target:GetModelOrigin() - self:GetOrigin()
    
    direction:Normalize()

    target:TakeDamage(Whip.kDamage, self, self, target:GetOrigin(), direction)

end

function Whip:SetDesiredMode(mode)
    if self.desiredMode ~= mode then
        self.desiredMode = mode
    end
end

function Whip:UpdateMode(deltaTime)

    if self.desiredMode ~= self.mode then
    
        if (self.desiredMode == Whip.kMode.UnrootedStationary) and (self.mode == Whip.kMode.Rooted) then
        
            self:SetMode(Whip.kMode.Unrooting)
            
        elseif self.desiredMode == Whip.kMode.Moving and (self.mode == Whip.kMode.UnrootedStationary) then
        
            self:SetMode(Whip.kMode.StartMoving)
            
        elseif (self.desiredMode == Whip.kMode.Rooted) and (self.mode == Whip.kMode.UnrootedStationary or self.mode == Whip.kMode.StartMoving or self.mode == Whip.kMode.Moving or self.mode == Whip.kMode.EndMoving) then
        
            self:SetMode(Whip.kMode.Rooting)
           
        end
        
    end
    
end

function Whip:OnDestroyCurrentOrder(currentOrder)

    Structure.OnDestroyCurrentOrder(self, currentOrder)
    
    // Order was stopped or canceled
    if(currentOrder:GetType() == kTechId.Move and self.mode == Whip.kMode.UnrootedStationary) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)        
    end
    
end

function Whip:OnOrderComplete(currentOrder)

    Structure.OnOrderComplete(self, currentOrder)

    if(currentOrder:GetType() == kTechId.Move) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)        
    end

end

function Whip:UpdateOrders(deltaTime)

    // If we're moving
    local currentOrder = self:GetCurrentOrder()
    if currentOrder and currentOrder:GetType() == kTechId.Move then
    
        self:SetDesiredMode(Whip.kMode.Moving)
        
        if self.mode == Whip.kMode.Moving then

            // Repeatedly trigger movement effect 
            self:TriggerEffects("whip_moving")
    
            local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), Whip.kMoveSpeed, deltaTime)
            if(distToTarget < kEpsilon) then
                self:CompletedCurrentOrder()
            end
            
        end
        
    end

    // Attack on our own
    if self.mode == Whip.kMode.Rooted then
            
        self:UpdateAttack(deltaTime)
            
    end
    
end

function Whip:UpdateAttack(deltaTime)

    // Check if alive because map-placed structures don't die when killed
    if self:GetIsBuilt() and self:GetIsAlive() then
        
        local target = self:GetTarget()
        
        if self:GetIsTargetValid(target) then

            // Check to see if it's time to fire again
            local time = Shared.GetTime()
                    
            if not self.timeOfLastAttack or (time > (self.timeOfLastAttack + Whip.kScanThinkInterval)) then
            
                local delay = self:AdjustFuryFireDelay(Whip.kROF)
                if(self.timeOfLastStrikeStart == nil or (time > self.timeOfLastStrikeStart + delay)) then
                
                    self:AttackTarget()
                    
                end
                
                // Update our attackYaw to aim at our current target
                local attackDir = GetNormalizedVector(target:GetEngagementPoint() - self:GetModelOrigin())
                
                // This is negative because of how model is set up (spins clockwise)
                local attackYawRadians = -math.atan2(attackDir.x, attackDir.z)
                self.attackYaw = DegreesTo360(math.deg(attackYawRadians))
                
                if self.attackYaw < 0 then
                    self.attackYaw = self.attackYaw + 360
                end
                
                self.timeOfLastAttack = time
                
            end
            
        end
        
        if self.timeOfNextStrikeHit ~= nil then
        
            if Shared.GetTime() > self.timeOfNextStrikeHit then
                self:StrikeTarget()
            end
            
        elseif target == nil or not self:GetIsTargetValid(target) then
        
            self:AcquireTarget()
            
        end
        
    end
    
end

function Whip:SetMode(mode)

    if self.mode ~= mode then

        self.modeAnimation = ""
        
        local triggerEffectName = "whip_" .. string.lower(EnumToString(Whip.kMode, mode))
        self:TriggerEffects(triggerEffectName)

        self.mode = mode
        self.modeAnimation = self:GetAnimation()
        
    end
    
end

function Whip:UpdateRootState()

    // Unroot whips if infestation recedes
    if (self.mode == Whip.kMode.Rooted) and not self:GetGameEffectMask(kGameEffect.OnInfestation) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)
    end
    
end

function Whip:OnUpdate(deltaTime)

    PROFILE("Whip:OnUpdate")

    Structure.OnUpdate(self, deltaTime)
    
    self:UpdateRootState()
    
    // Handle sentry state changes
    self:UpdateMode(deltaTime)
    
    self:UpdateOrders(deltaTime)

end

function Whip:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == self.attackAnimation then
    
        local target = self:GetTarget()
        
        if not target or not self:GetIsTargetValid(target) then
        
            self:CompletedCurrentOrder()
            
            self:OnIdle()

        end
        
    end

    // Handle whip movement transitions        
    if self.modeAnimation == animName then
        
        if self.mode == Whip.kMode.Unrooting then
        
            self:SetMode(Whip.kMode.UnrootedStationary)        
    
        elseif self.mode == Whip.kMode.Rooting then
        
            self:SetMode(Whip.kMode.Rooted)

        elseif self.mode == Whip.kMode.StartMoving then
        
            self:SetMode(Whip.kMode.Moving)

        elseif self.mode == Whip.kMode.EndMoving then
        
            self:SetMode(Whip.kMode.UnrootedStationary)
            
        end
        
    end
    
end

function Whip:GetCanIdle()
    local target = self:GetTarget()
    return not target and (self.mode == Whip.kMode.Rooted or (self.mode == Whip.kMode.UnrootedStationary and not self:GetCurrentOrder()))
end

function Whip:GetIsFuryActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastFury ~= nil) and (Shared.GetTime() < (self.timeOfLastFury + Whip.kFuryDuration))
end

function Whip:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)

    if success then
    
        // Transform into mature whip
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeWhip) then
        
            success = self:Upgrade(kTechId.MatureWhip)
            
        end
        
    end
    
    return success    
    
end

function Whip:TriggerFury()

    self:TriggerEffects("whip_trigger_fury")
    
    // Increase damage for players, whips (including self!), etc. in range
    self.timeOfLastFury = Shared.GetTime()
    
    return true
    
end

function Whip:TargetBombard(position)
    return true
end

function Whip:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.WhipFury then
        success = self:TriggerFury()
    elseif techId == kTechId.WhipBombard then
        success = self:TargetBombard(position)
    elseif techId == kTechId.WhipUnroot then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)
    elseif techId == kTechId.WhipRoot then
        self:SetDesiredMode(Whip.kMode.Rooted)
    end
    
    return success
    
end