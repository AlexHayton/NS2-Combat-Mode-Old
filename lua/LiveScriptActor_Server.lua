// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
function LiveScriptActor:CopyDataFrom(player)

    self.gameEffectsFlags = player.gameEffectsFlags
    
    table.copy(player.gameEffects, self.gameEffects)
    
    self.timeOfLastDamage = player.timeOfLastDamage
    
    self.furyLevel = player.furyLevel
    
    self.activityEnd = player.activityEnd
    
    self.pathingEnabled = player.pathingEnabled
    
end

function LiveScriptActor:SetPathingEnabled(state)
    self.pathingEnabled = state
end

function LiveScriptActor:GetHasOrder()
    return self.hasOrder
end

function LiveScriptActor:Upgrade(newTechId)

    if self:GetTechId() ~= newTechId then

        // Preserve health and armor scalars but potentially change maxHealth and maxArmor
        local healthScalar = self:GetHealthScalar()
        local armorScalar = self:GetArmorScalar()
        local energyScalar = self.energy / self.maxEnergy
        
        self:SetTechId(newTechId)
        
        self.maxHealth = LookupTechData(newTechId, kTechDataMaxHealth, self.maxHealth)
        self.maxArmor = LookupTechData(newTechId, kTechDataMaxArmor, self.maxArmor)
        self.maxEnergy = LookupTechData(newTechId, kTechDataMaxEnergy, self.maxEnergy)
        
        self.health = healthScalar * self.maxHealth
        self.armor = armorScalar * self.maxArmor
        self.energy = energyScalar * self.maxEnergy
        
        return true
        
    end
    
    return false
    
end

// Server version of TakeDamage()
function LiveScriptActor:TakeDamage(damage, attacker, doer, point, direction)

    local killed = false
    
    if (self:GetIsAlive() and GetGamerules():CanEntityDoDamageTo(attacker, self)) then

        // Get damage type from source    
        local damageType = kDamageType.Normal
        if doer ~= nil then 
            damageType = doer:GetDamageType()
        end

        // Take into account upgrades on attacker (armor1, weapons1, etc.)        
        damage = GetGamerules():GetUpgradedDamage(attacker, damage, damageType)

        // highdamage cheat speeds things up for testing
        damage = damage * GetGamerules():GetDamageMultiplier()
        
        // Children can override to change damage according to player mode, damage type, etc.
        local armorUsed, healthUsed
        damage, armorUsed, healthUsed = self:ComputeDamage(damage, damageType)
        
        self.armor = self.armor - armorUsed
        self.health = math.max(self.health - healthUsed, 0)
        
        if damage > 0 then
        
            self:OnTakeDamage(damage, doer, point)
            
            local pointOwner = attacker
            // If the pointOwner is not a player, award it's points to it's owner.
            if pointOwner ~= nil and not pointOwner:isa("Player") then
                pointOwner = pointOwner:GetOwner()
            end
            
            // Award Experience
            if(pointOwner ~= nil and pointOwner:isa("Player") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber()) then
                local damagetaken = armorUsed + healthUsed
                local experience = Experience_ComputeExperience(self, damagetaken)
                
                pointOwner:AddExperience(experience)
                Experience_GrantNearbyExperience(pointOwner, experience)
            end
                
            if (self.health == 0) then
                
                GetGamerules():OnKill(self, damage, attacker, doer, point, direction)
                
                self:OnKill(damage, attacker, doer, point, direction)
                
                self:TriggerEffects("death")
                
                killed = true
                
            end
            
        end
        
    end
    
    return killed
    
end

// Return the amount of health we added 
function LiveScriptActor:AddHealth(health, playSound)

    local total = 0
    
    if self:GetIsAlive() and ((self.health < self:GetMaxHealth()) or (self.armor < self:GetMaxArmor())) then
    
        // Add health first, then armor if we're full
        local healthAdded = math.min(health, self:GetMaxHealth() - self.health)
        self.health = math.min(math.max(0, self.health + healthAdded), self:GetMaxHealth())
        
        local healthToAddToArmor = health - healthAdded
        if(healthToAddToArmor > 0) then        
            self.armor = math.min(math.max(0, self.armor + healthToAddToArmor), self:GetMaxArmor())   
        end
        
        total = healthAdded + healthToAddToArmor
        
        if total > 0 and playSound and (self:GetTeamType() == kAlienTeamType) then
            self:PlaySound(LiveScriptActor.kAlienRegenerationSound)
        end
        
    end
    
    return total    
    
end

function LiveScriptActor:GetFlinchOverlay(animName)
    return true
end

function LiveScriptActor:GetDamageImpulse(damage, doer, point)
    if damage and doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * (damage / 40) * .01
    end
    return nil
end

function LiveScriptActor:OnTakeDamage(damage, doer, point)

    // Play audio/visual effects when taking damage   
    local damageType = nil
    if doer then
        damageType = doer:GetDamageType()
    end
    self:TriggerEffects("flinch", {damagetype = damageType, flinch_severe = ConditionalValue(damage > 20, true, false)})
    
    // Apply directed impulse to physically simulated objects, according to amount of damage
    if (self.physicsModel ~= nil and self.physicsType == Actor.PhysicsType.Dynamic) then    
        local damageImpulse = self:GetDamageImpulse(damage, doer, point)
        if damageImpulse then
            self.physicsModel:AddImpulse(point, damageImpulse)
        end
    end
    
    // Once entity has taken this much damage in a second, it is flinching at it's maximum amount
    local maxFlinchDamage = self:GetMaxHealth() * .20
    
    local flinchAmount = (damage/maxFlinchDamage) 
    self.flinchIntensity = Clamp(self.flinchIntensity + flinchAmount, .25, 1)

    // Make sure new flinch intensity is big enough to be visible, but don't add too much from a bunch of small hits
    // Flamethrower make Harvester go wild   
    if doer and (doer:GetDamageType() == kDamageType.Flame) then
        self.flinchIntensity = self.flinchIntensity + .1
    end
    
    // Remember time we were last hurt so we can trigger alert
    self.timeOfLastDamage = Shared.GetTime()
    
end

function LiveScriptActor:GetTimeOfLastDamage()
    return self.timeOfLastDamage
end

function LiveScriptActor:SetFuryLevel(level)
    self.furyLevel = level
end

function LiveScriptActor:GetKilledSound(doer)
    return nil
end

function LiveScriptActor:OnKill(damage, attacker, doer, point, direction)

    // Give points to killer
    local pointOwner = attacker
    // If the pointOwner is not a player, award it's points to it's owner.
    if pointOwner ~= nil and not pointOwner:isa("Player") then
        pointOwner = pointOwner:GetOwner()
    end
    if(pointOwner ~= nil and pointOwner:isa("Player") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber()) then
        pointOwner:AddScore(self:GetPointValue())
    end

    local killedSound = self:GetKilledSound(doer)
    if killedSound ~= nil then
    
        // Play world sound instead of parented sound as entity is going away
        Shared.PlayWorldSound(nil, killedSound, nil, self:GetOrigin())
        
    end
    
    self.alive = false
    self.timeToRagdoll = Shared.GetTime()
            
    local deathAnim = self:GetDeathAnimation()
    if deathAnim ~= nil then
    
        self:SetAnimationWithBlending(deathAnim, self:GetBlendTime(), true)
        
        local ragdollDelay = self:GetAnimationLength(deathAnim)
        if ragdollDelay > 0 then
            self.timeToRagdoll = self.timeToRagdoll + ragdollDelay
        end

    else
        self.deathImpulse = self:GetDamageImpulse(damage, doer, point)
        self.deathPoint = Vector(point)
    end

    ScriptActor.OnKill(self, damage, attacker, doer, point, direction)
    
    self:SetNextThink(.01)
    
end

function LiveScriptActor:GetShouldRagdoll()
    return true
end

function LiveScriptActor:OnThink()

    ScriptActor.OnThink(self)
    
    if self.timeToRagdoll ~= nil and (Shared.GetTime() > self.timeToRagdoll) and not self.alive and (self.timeToDestroy == nil) then
    
        if self:GetShouldRagdoll() then
        
            self:SetPhysicsType(Actor.PhysicsType.Dynamic)
            
            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
            
            // Apply landing blow death impulse to ragdoll (but only if we didn't play death animation)
            if self.deathImpulse and self.deathPoint and self.physicsModel and self.physicsType == Actor.PhysicsType.Dynamic then
            
                self.physicsModel:AddImpulse(self.deathPoint, self.deathImpulse)
                self.deathImpulse = nil
                
            end
        
            self.timeToRagdoll = nil
            
            self.timeToDestroy = Shared.GetTime() + LiveScriptActor.kRagdollTime
            
            self:SetNextThink(.1)    
            
        else
        
            self:SafeDestroy()
            
        end
        
    elseif self.timeToDestroy ~= nil and Shared.GetTime() > self.timeToDestroy and not self:GetPersistentRagdoll() then
    
        // Don't destroy pre-placed map entities - we activate them again on round reset
        self:SafeDestroy()

    else
        self:SetNextThink(.2)
    end
    
end

function LiveScriptActor:GetPersistentRagdoll()
    return false
end

function LiveScriptActor:SafeDestroy()

    if bit.bor(self.gameEffectsFlags, kGameEffect.OnFire) then
        self:StopSound(self:GetOnFireSound())
    end

    if(self:GetIsMapEntity()) then
    
        self:SetIsAlive(false)
        self:SetIsVisible(false)
        self:SetNextThink(-1)
        self:SetPhysicsType(Actor.PhysicsType.None)
        
    else
    
        DestroyEntity(self)
        
    end

end

function LiveScriptActor:Kill(attacker, doer, point, direction)
    self:TakeDamage(1000, attacker, doer, nil, nil)
end

// Calculate damage from damage types 
function LiveScriptActor:ComputeDamage(damage, damageType)

    local armorPointsUsed = 0
    local healthPointsUsed = 0    

    damage = GetGamerules():ComputeDamageFromType(damage, damageType, self)

    if damage > 0 then
    
        // Calculate damage absorbed by armor according to damage type
        local absorbPercentage = self:GetArmorAbsorbPercentage(damageType)
        
        // Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        healthPointsBlocked = math.min(self.armor, absorbPercentage * damage )
        armorPointsUsed = healthPointsBlocked / self:GetHealthPerArmor(damageType)
        
        // Anything left over comes off of health
        healthPointsUsed = damage - healthPointsBlocked   
     
    end
    
    return damage, armorPointsUsed, healthPointsUsed

end

// Children can override this to issue build, construct, etc. orders on right-click
function LiveScriptActor:OverrideOrder(order)

    if(order:GetType() == kTechId.Default) then
    
        order:SetType(kTechId.Move)
        
    end
    
end

// Create order, set it, override it
function LiveScriptActor:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst)

    local order = CreateOrder(orderType, targetId, targetOrigin, orientation)
    
    self:OverrideOrder(order)
    
    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end
    
    self:SetOrder(order, clearExisting, insertFirst)
    
    return order:GetType()

end

function LiveScriptActor:SetOrder(order, clearExisting, insertFirst)

    if(clearExisting) then
        table.clear(self.orders)
    end

    // Override location of order so floating units stay off the ground
    if order:GetType() == kTechId.Move then
    
        local location = Vector(order:GetLocation())
        location.y = location.y + self:GetHoverHeight()
        order:SetLocation(location)
        
    end
    
    if(insertFirst) then
        table.insert(self.orders, 1, order)
    else    
        table.insert(self.orders, order)
    end
    
    self:OrderChanged()

end

function LiveScriptActor:CopyOrdersFrom(source)
    if source.orders and self.orders then
        table.copy(source.orders, self.orders)
        self:OrderChanged()
    end
end

function LiveScriptActor:GetCurrentOrder()

    local currentOrder = nil
    
    if(table.maxn(self.orders) > 0) then
        currentOrder = self.orders[1]    
    end

    return currentOrder
    
end

function LiveScriptActor:CompletedCurrentOrder()

    self:OnOrderComplete(self.orders[1])
    
    table.remove(self.orders, 1)
    
    self:OrderChanged()
    
end

function LiveScriptActor:ClearOrders()

    table.clear(self.orders)
    self:OrderChanged()
    
end

function LiveScriptActor:OnOrderComplete(order)
end

function LiveScriptActor:OrderChanged()

    local order = self:GetCurrentOrder()
    
    self.hasOrder = (order ~= nil)
    
    if self.hasOrder then
    
        local orderLocation = order:GetLocation()
        self.orderX = orderLocation.x
        self.orderY = orderLocation.y
        self.orderZ = orderLocation.z
        self.orderType = order:GetType()
        
    end
    
end

// This is an "attack-move" from RTS. Attack the entity specified in our current attack order, if any. 
//  Otherwise, move to the location specified in the attack order and attack anything along the way.
function LiveScriptActor:ProcessAttackOrder(targetSearchDistance, moveSpeed, time)

    // If we have a target, attack it
    local currentOrder = self:GetCurrentOrder()
    if(currentOrder ~= nil) then
    
        local target = Shared.GetEntity(currentOrder:GetParam())
        
        if target then
        
            if not target:GetIsAlive() then
            
                self:CompletedCurrentOrder()
                
            else
            
                local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, target:GetEngagementPoint(), moveSpeed, time)
                if(distToTarget < LiveScriptActor.kMoveToDistance) then
                    self:CompletedCurrentOrder()
                end
                
            end
                
            return

        end
        
        if not target then
        
            // Check for a nearby target. If not found, move towards destination.
            target = self:FindTarget(targetSearchDistance)
 
        end
        
        if target then
        
            // If we are close enough to target, attack it    
            local targetPosition = Vector(target:GetOrigin())
            targetPosition.y = targetPosition.y + self:GetHoverHeight()
            
            // Different targets can be attacked from different ranges, depending on size
            local attackDistance = GetEngagementDistance(currentOrder:GetParam())
            
            local distanceToTarget = (targetPosition - self:GetOrigin()):GetLength()
            if (distanceToTarget <= attackDistance) and target:GetIsAlive() then
            
                self:MeleeAttack(target, time)
                
                
            end
           
        else
        
            // otherwise move towards attack location and end order when we get there
            self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), moveSpeed, time)
            
            local distanceToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLength()
            if(distanceToTarget < LiveScriptActor.kMoveToDistance) then
                self:CompletedCurrentOrder()
            end
 
        end
        
    end
    
end

// If false, then MoveToTarget() projects entity down to floor
function LiveScriptActor:GetIsFlying()
    return false
end

// For non-flying units, snap new movement position to ground. Assumes actor
// origin at feet of unit.
function LiveScriptActor:SnapToGround(origin, physicsGroupMask)

    if not self:GetIsFlying() then
    
        // Avoid boundary case where model goes through floor
        local startOrigin = origin + Vector(0, .2, 0)
        local endOrigin = origin - Vector(0, 100, 0)
        local trace = Shared.TraceRay(startOrigin, endOrigin, physicsGroupMask, EntityFilterOne(self))
        VectorCopy(trace.endPoint, origin)
        
    end
    
end

function LiveScriptActor:GetWaypointGroupName()
    return ConditionalValue(self:GetIsFlying(), kAirWaypointsGroup, kDefaultWaypointGroup)
end

// Returns distance from location after move. 
function LiveScriptActor:MoveToTarget(physicsGroupMask, location, movespeed, time)

    // Any time waypoints are added to a group without naming it in the editor it will be named "GroundWaypoints" (kDefaultWaypointGroup)
    local movement = nil
    
    if self.pathingEnabled then
        movement = Server.MoveToTarget(physicsGroupMask, self, self:GetWaypointGroupName(), location, movespeed * time)
    end

    // if the newer navigation fails, default to the old version;
    if self.pathingEnabled and movement and movement.valid then
    
        local newOrigin = Vector()
        VectorCopy(movement.position, newOrigin)
        self:SnapToGround(newOrigin, physicsGroupMask)
        self:SetOrigin(newOrigin)
        SetAnglesFromVector(self, movement.direction)
        return movement.distance
        
    else
    
        // No pathing - move straight towards target 
        local distToTarget = (location - self:GetOrigin()):GetLength()
        if distToTarget < movespeed * time then
        
            self:SnapToGround(location, physicsGroupMask)
            self:SetOrigin(location)
            return 0

        else
        
            local newOrigin = self:GetOrigin() + GetNormalizedVector(location - self:GetOrigin()) * movespeed * time
            self:SnapToGround(newOrigin, physicsGroupMask)
            self:SetOrigin(newOrigin)
            distToTarget = (location - self:GetOrigin()):GetLength()
            return distToTarget
            
        end            

    end
    
end

function LiveScriptActor:PerformAction(techNode, position)

    if(techNode:GetTechId() == kTechId.Stop) then
        self:ClearOrders()
        return true
    end
    
    return ScriptActor.PerformAction(self, techNode, position)
    
end

function LiveScriptActor:OnWeld(entity, elapsedTime)
end

// Damage to marine armor could show sparks and debris and debris and castings for aliens
// Damage to health shows blood and the player makes grunting/squealing/pain noises
// Armor is best at absorbing melee damage, less against projectiles and not effective for gas/breathing damage
// (the TSA designed their armor to deal best against skulks!)
function LiveScriptActor:GetArmorAbsorbPercentage(damageType)

    local armorAbsorbPercentage = kBaseArmorAbsorption
    
    if(damageType == kDamageType.Falling) then
    
        armorAbsorbPercentage = 0
        
    end
    
    return armorAbsorbPercentage
    
end

function LiveScriptActor:GetHealthPerArmor(damageType)

    local healthPerArmor = kHealthPointsPerArmor
    
    if damageType == kDamageType.Light then
        healthPerArmor = kHealthPointsPerArmorLight
    elseif damageType == kDamageType.Heavy then
        healthPerArmor = kHealthPointsPerArmorHeavy
    end
    
    return healthPerArmor
    
end

// Sets or clears a game effect flag
function LiveScriptActor:SetGameEffectMask(effect, state)

    local startGameEffectsFlags = self.gameEffectsFlags
    
    if state then
    
        // Set game effect bit
        if not self:GetGameEffectMask(effect) then
            self:OnGameEffectMaskChanged(effect, true)
        end
        
        self.gameEffectsFlags = bit.bor(self.gameEffectsFlags, effect)
        
    else
    
        // Clear game effect bit
        if self:GetGameEffectMask(effect) then
            self:OnGameEffectMaskChanged(effect, false)
        end

        local notEffect = bit.bnot(effect)
        self.gameEffectsFlags = bit.band(self.gameEffectsFlags, notEffect)
        
    end
    
    // Return if state changed
    return startGameEffectsFlags ~= self.gameEffectsFlags
    
end

function LiveScriptActor:ClearGameEffects()

    if self.gameEffectsFlags then
    
        for index = 1, kGameEffect.Max do 
        
            local effect = bit.lshift(1, index)

            if bit.bor(self.gameEffectsFlags, effect) then
                self:OnGameEffectMaskChanged(effect, false)
            end
            
        end
        
    end
    
    self.gameEffectsFlags = 0
    
end

// Overrideable by children. Called on server only.
function LiveScriptActor:OnGameEffectMaskChanged(effect, state)
    
    if effect == kGameEffect.OnFire and state then
        self:PlaySound(self:GetOnFireSound())
    elseif effect == kGameEffect.OnFire and not state then
        self:StopSound(self:GetOnFireSound())
    end
    
end

function LiveScriptActor:GetOnFireSound()
    return LiveScriptActor.kOnFireSmallSound
end

// Adds a stackable game effect (up to kMaxStackLevel max). Don't add one if we already have
// this effect from this source entity.
function LiveScriptActor:AddStackableGameEffect(gameEffectName, duration, sourceEntity)

    if type(gameEffectName) == "string" then
        
        if table.count(self.gameEffects) < kMaxStackLevel then
        
            local sourceEntityId = Entity.invalidId
            
            if sourceEntity then
            
                sourceEntityId = sourceEntity:GetId()
                
                // Insert stackable game effect if we don't already have one from this entity
                for index, elementTriple in ipairs(self.gameEffects) do
                
                    if elementTriple[3] == sourceEntityId then
                    
                        return
                        
                    end
                    
                end
                
            end
            
            // Otherwise insert new triple (game effect, duration, id)
            table.insert(self.gameEffects, {gameEffectName, duration, sourceEntityId})
            
        end
        
    else
        Print("%s:AddStackableGameEffect(): Can only add strings (got type %s)", self:GetClassName(), type(gameEffectName))
    end
    
end

function LiveScriptActor:ClearStackableGameEffects()
    table.clear(self.gameEffects)
end

function LiveScriptActor:GetStackableGameEffectCount(gameEffectName)

    local count = 0
    
    for index, elementTriple in ipairs(self.gameEffects) do
    
        local effectName = elementTriple[1]
        if effectName == gameEffectName then
        
            count = count + 1
            
        end
        
    end

    return count
    
end

function LiveScriptActor:ExpireStackableGameEffects(deltaTime)

    local time = Shared.GetTime()
    
    function effectExpired(elemTriple) 
    
        // nil expire times last forever
        local duration = elemTriple[2]
        if not duration then
            return false
        end
        
        duration = duration - deltaTime
        if duration <= 0 then
            return true
        end
        
        elemTriple[2] = duration
        return false
        
    end
    
    table.removeConditional(self.gameEffects, effectExpired)
    
end

function LiveScriptActor:GetMeleeAttackDamage()
    return 5
end

function LiveScriptActor:GetMeleeAttackInterval()
    return .6
end

function LiveScriptActor:PlayMeleeHitEffects(target, point, direction)
end

function LiveScriptActor:GetMeleeAttackOrigin()
    return self:GetOrigin()
end

function LiveScriptActor:MeleeAttack(target, time)

    local meleeAttackInterval = self:AdjustFuryFireDelay(self:GetMeleeAttackInterval())
   
    if(Shared.GetTime() > (self.timeOfLastAttack + meleeAttackInterval)) then

        // Traceline from us to them
        local trace = Shared.TraceRay(self:GetMeleeAttackOrigin(), target:GetOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(self, target))

        local direction = target:GetOrigin() - self:GetOrigin()
        direction:Normalize()
        
        // Use player or owner (in the case of MACs, Drifters, etc.)
        local attacker = self:GetOwner()
        if self:isa("Player") then
            attacker = self
        end
        
        target:TakeDamage(self:GetMeleeAttackDamage(), attacker, self, trace.endPoint, direction)
            
        self:PlayMeleeHitEffects(target, trace.endPoint, direction)
        
        self.timeOfLastAttack = Shared.GetTime()
        
    end
        
end

// Get target of attack order, if any
function LiveScriptActor:GetTarget()
    local target = nil

    local order = self:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) then
        target = Shared.GetEntity(order:GetParam())
    end    
    
    return target
end

function LiveScriptActor:SetOnFire(attacker, doer)

    self:SetGameEffectMask(kGameEffect.OnFire, true)
    
    self.fireAttackerId = attacker:GetId()
    self.fireDoerId = doer:GetId()
    
end

