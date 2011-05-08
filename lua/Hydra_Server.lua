// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hydra_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Creepy plant turret the Gorge can create.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/InfestationMixin.lua")

Hydra.kThinkInterval = .5

PrepareClassForMixin(Hydra, InfestationMixin)
    
function Hydra:GetSortedTargetList()

    PROFILE("Hydra:GetSortedTargetList")

    local hydraAttackOrigin = self:GetModelOrigin()
    local targets = GetEntitiesForTeamWithinRange("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), hydraAttackOrigin, Hydra.kRange)

    function sortSentryTargets(ent1, ent2)
    
        // Prioritize damage-dealing targets
        if ent1:GetCanDoDamage() ~= ent2:GetCanDoDamage() then
        
            // But don't pick out players over structures unless closer
            if ent1:isa("Player") == ent2:isa("Player") then
                return ent1:GetCanDoDamage()
            end
            
        end

        // Shoot closer targets
        local dist1 = (hydraAttackOrigin - ent1:GetEngagementPoint()):GetLengthSquared()
        local dist2 = (hydraAttackOrigin - ent2:GetEngagementPoint()):GetLengthSquared()        
        if dist1 ~= dist2 then
            return dist1 < dist2
        end
        
        // Make deterministic in case that distances are equal
        return ent1:GetId() < ent2:GetId()

    end
    
    table.sort(targets, sortSentryTargets)
    
    return targets
    
end

function Hydra:AcquireTarget()

    PROFILE("Hydra:AcquireTarget")

    self.target = nil
    
    // Get list of potential targets - these will be of the proper team but may be blocked by something else
    local potentialTargets = self:GetSortedTargetList()
    
    // Now pick the first valid one
    for index, target in ipairs(potentialTargets) do
    
        if self:GetTargetValid(target) then
        
            self.target = target
            break
            
        end
        
    end
        
end
function Hydra:AcquireTargetUsingTargetCache()

    self.target, self.staticTargets, self.staticTargetsVersion = GetGamerules():GetTargetCache():AcquirePlayerPreferenceTarget(
            self,
            Hydra.kRange, 
            TargetCache.kAmtl, 
            TargetCache.kAstl, 
            self.staticTargets, 
            self.staticTargetsVersion)
end

function Hydra:GetDistanceToTarget(target)
    return (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()           
end

function Hydra:GetTargetValid(target, logError)

    if(target ~= nil and (target:isa("Player") or target:isa("Structure")) and HasMixin(target, "Live") and target:GetIsAlive() and target ~= self and target:GetCanTakeDamage()) then
    
        // Perform trace to make sure nothing is blocking our target. Trace from enemy to us
        local trace = Shared.TraceRay(target:GetModelOrigin(), self:GetModelOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(target, self))               
        local validTarget = (trace.fraction == 1)

        if not validTarget and logError then
            Print("Hydra:GetTargetValid(): Target %s not valid, blocked by %s", SafeClassName(target), SafeClassName(trace.entity))
        end
        
        return validTarget
            
    end
    
    return false

end

function Hydra:AttackTarget()

    self:CreateSpikeProjectile()
    
    self:TriggerEffects("hydra_attack")
    
    // Random rate of fire to prevent players from popping out of cover and shooting regularly
    self.timeOfNextFire = Shared.GetTime() + self:AdjustFuryFireDelay(.5 + NetworkRandom() * 1)
    
end

function Hydra:CreateSpikeProjectile()

    local directionToTarget = self.target:GetEngagementPoint() - self:GetEyePos()
    local targetDistanceSquared = directionToTarget:GetLengthSquared()
    local theTimeToReachEnemy = targetDistanceSquared / (Hydra.kSpikeSpeed * Hydra.kSpikeSpeed)

    local predictedEngagementPoint = self.target:GetEngagementPoint()
    if self.target.GetVelocity then
        local targetVelocity = self.target:GetVelocity()
        predictedEngagementPoint = self.target:GetEngagementPoint() + ((targetVelocity:GetLength() * Hydra.kTargetVelocityFactor * theTimeToReachEnemy) * GetNormalizedVector(targetVelocity))
    end
    
    local direction = GetNormalizedVector(predictedEngagementPoint - self:GetEyePos())
    local startPos = self:GetEyePos() + direction
    
    // Create it outside of the hydra a bit
    local spike = CreateEntity(HydraSpike.kMapName, startPos, self:GetTeamNumber())
    SetAnglesFromVector(spike, direction)
    
    local startVelocity = direction * Hydra.kSpikeSpeed
    spike:SetVelocity(startVelocity)
    
    spike:SetGravityEnabled(false)
    
    // Set spike owner so we don't collide with ourselves and so we
    // can attribute a kill to us
    spike:SetOwner(self:GetOwner())
    
    spike:SetIsVisible(true)
                
end

function Hydra:GetIsEnemyNearby()

    local enemyPlayers = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for index, player in ipairs(enemyPlayers) do                
    
        if player:GetIsVisible() and not player:isa("Commander") then
        
            local dist = self:GetDistanceToTarget(player)
            if dist < Hydra.kRange then
        
                return true
                
            end
            
        end
        
    end

    return false
    
end

function Hydra:OnThink()

    Structure.OnThink(self)
    
    if self:GetIsBuilt() and self:GetIsAlive() then    
    
        if GetGamerules():GetTargetCache():IsEnabled() then
            self:AcquireTargetUsingTargetCache()
        else
            self:AcquireTarget()
        end

        if self.target then
        
            if(self.timeOfNextFire == nil or (Shared.GetTime() > self.timeOfNextFire)) then
           
                self:AttackTarget()
                
            end

        else
        
            // Play alert animation if marines nearby and we're not targeting (ARCs?)
            if self.timeLastAlertCheck == nil or Shared.GetTime() > self.timeLastAlertCheck + Hydra.kAlertCheckInterval then
            
                if self:GetIsEnemyNearby() then
                
                    self:TriggerEffects("hydra_alert")
                    
                    self.timeLastAlertCheck = Shared.GetTime()
                
                end
                                                            
            end
            
        end
        
    end
    
    self:SetNextThink(Hydra.kThinkInterval)
    
end

function Hydra:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SpawnInfestation()
    
    // Start scanning for targets once built
    self:SetNextThink(Hydra.kThinkInterval)
        
end

function Hydra:OnInit()
    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
   
    self:SetNextThink(Hydra.kThinkInterval)
           
end



