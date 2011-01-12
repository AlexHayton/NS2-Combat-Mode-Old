// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

function Whip:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == self.attackAnimation then
    
        local target = self:GetTarget()
        
        if not target or not self:GetIsTargetValid(target) then
        
            self:CompletedCurrentOrder()
            
            self:OnIdle()

        end
        
    end
    
end

function Whip:OnThink()

    Structure.OnThink(self)
    
    // Check if alive because map-placed structures don't die when killed
    if self:GetIsBuilt() and self:GetIsAlive() then
        
        local target = self:GetTarget()
        
        if self:GetIsTargetValid(target) then
                    
            // Check to see if it's time to fire again
            local time = Shared.GetTime()
            
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
            
        end
        
        if self.timeOfNextStrikeHit ~= nil then
        
            if Shared.GetTime() > self.timeOfNextStrikeHit then
                self:StrikeTarget()
            end
            
        elseif target == nil or not self:GetIsTargetValid(target) then
        
            self:AcquireTarget()
            
        end
        
    end
    
    self:SetNextThink(Whip.kScanThinkInterval)
    
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

function Whip:PerformActivation(techId, position, commander)

    local success = false
    
    if techId == kTechId.WhipFury then
        success = self:TriggerFury()
    elseif techId == kTechId.WhipBombard then
        success = self:TargetBombard(position)
    end
    
    return success
    
end