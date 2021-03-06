// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CombatBalance.lua")

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

function LiveScriptActor:Upgrade(newTechId)

    if self:GetTechId() ~= newTechId then

        // Preserve health and armor scalars but potentially change maxHealth and maxArmor
        local healthScalar = self:GetHealthScalar()
        local armorScalar = self:GetArmorScalar()
        
        self:SetTechId(newTechId)
        
        self:SetMaxHealth(LookupTechData(newTechId, kTechDataMaxHealth, self:GetMaxHealth()))
        self:SetMaxArmor(LookupTechData(newTechId, kTechDataMaxArmor, self:GetMaxArmor()))
        
        self:SetHealth(healthScalar * self:GetMaxHealth())
        self:SetArmor(armorScalar * self:GetMaxArmor())
        
        return true
        
    end
    
    return false
    
end

function LiveScriptActor:UpdateJustKilled()

    if self.justKilled then
    
        // Clear current animation so we know if it was set in TriggerEffects
        self:SetAnimation("", true)
        
        self:TriggerEffects("death")
        
        // Destroy immediately if death animation or ragdoll wasn't triggered (used queued because we're in OnProcessMove)
        local anim = self:GetAnimation()
        if (self:GetPhysicsGroup() == PhysicsGroup.RagdollGroup) or (anim ~= nil and anim ~= "") then
        
            // Set default time to destroy so it's impossible to have things lying around 
            self.timeToDestroy = Shared.GetTime() + 4
            self:SetNextThink(.1)
            
        else
            self:SafeDestroy()                    
        end
        
        self.justKilled = nil

    end
    
end

function LiveScriptActor:GetDamageImpulse(damage, doer, point)
    if damage and doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * (damage / 40) * .01
    end
    return nil
end

function LiveScriptActor:OnTakeDamage(damage, doer, point)

    // Play audio/visual effects when taking damage    
    local damageType = kDamageType.Normal
    if doer then
        damageType = doer:GetDamageType()
    end
    
    local flinchParams = {damagetype = damageType, flinch_severe = ConditionalValue(damage > 20, true, false)}
    if point then
        flinchParams[kEffectHostCoords] = Coords.GetTranslation(point)
    end
    
    if doer then
        flinchParams[kEffectFilterDoerName] = doer:GetClassName()
    end
    
    self:TriggerEffects("flinch", flinchParams)
    
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
    
end

function LiveScriptActor:GetTimeOfLastDamage()
    return self.timeOfLastDamage
end

function LiveScriptActor:SetFuryLevel(level)
    self.furyLevel = level
end

function LiveScriptActor:Reset()

    ScriptActor.Reset(self)
    self:ResetUpgrades()
    self:ClearOrders()
    
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
	
	if(pointOwner ~= nil and pointOwner:isa("Player") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber()) then
		// Give experience for the kill
		local experience = Experience_ComputeExperience(self, self:GetPointValue()*100)
		local assistExperience = Experience_ComputeExperience(self, self:GetPointValue()*10)
		
		pointOwner:AddExperience(experience)
		Experience_GrantNearbyExperience(pointOwner, experience)
		
		// Give experience for any assists.
		// At the moment the record persists after you die. Not sure whether to keep this.
		for damager, damageInflicted in ipairs(self.damageList) do
			damager:AddExperience(assistExperience * damageInflicted / self.totalDamage)
		end
	end

    self:SetIsAlive(false)
    
    if point then
        self.deathImpulse = self:GetDamageImpulse(damage, doer, point)
        self.deathPoint = Vector(point)
    end

    self:ResetUpgrades()
    self:ClearOrders()

    ScriptActor.OnKill(self, damage, attacker, doer, point, direction)

end

function LiveScriptActor:ResetUpgrades()
    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
end

function LiveScriptActor:SetRagdoll(deathTime)

    if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

        self:SetPhysicsType(Actor.PhysicsType.Dynamic)
        
        self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        
        // Apply landing blow death impulse to ragdoll (but only if we didn't play death animation)
        if self.deathImpulse and self.deathPoint and self.physicsModel and self.physicsType == Actor.PhysicsType.Dynamic then
        
            self.physicsModel:AddImpulse(self.deathPoint, self.deathImpulse)
            self.deathImpulse = nil
            
        end
        
        if deathTime then

            self.timeToDestroy = Shared.GetTime() + deathTime
            
            self:SetNextThink(.1)    
            
        end
        
    end
    
end

function LiveScriptActor:OnThink()

    ScriptActor.OnThink(self)
    
    if self.timeToDestroy and (Shared.GetTime() > self.timeToDestroy) then
    
        self:SafeDestroy()

    else
        self:SetNextThink(.1)
    end
    
end

function LiveScriptActor:SafeDestroy()

    if bit.bor(self.gameEffectsFlags, kGameEffect.OnFire) then
        self:TriggerEffects("fire_stop")
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

// If false, then MoveToTarget() projects entity down to floor
function LiveScriptActor:GetIsFlying()
    return false
end

/**
 * Return the passed in position casted down to the ground.
 */
function LiveScriptActor:GetGroundAt(position, physicsGroupMask)

    local topOffset = self:GetExtents().y
    local startPosition = position + Vector(0, topOffset, 0)
    local endPosition = position - Vector(0, 100, 0)
    local trace = Shared.TraceRay(startPosition, endPosition, physicsGroupMask, EntityFilterOne(self))
    return trace.endPoint

end

function LiveScriptActor:GetHoverAt(position)

    local ground = self:GetGroundAt(position, PhysicsMask.AIMovement)
    local resultY = position.y
    // if we have a hover height, use it to find our minimum height above ground, otherwise use zero
    local minHeightAboveGround = self.GetHoverHeight and self:GetHoverHeight() or 0

    local heightAboveGround = position.y - resultY

    // always snap "up", snap "down" only if not flying
    if heightAboveGround < minHeightAboveGround or not self:GetIsFlying() then
        resultY = resultY + minHeightAboveGround - heightAboveGround
    end

    if resultY ~= position.y then
        return Vector(position.x, resultY, position.z)
    end

    return position

end

function LiveScriptActor:GetWaypointGroupName()
    return ConditionalValue(self:GetIsFlying(), kAirWaypointsGroup, kDefaultWaypointGroup)
end

function LiveScriptActor:MoveToTarget(physicsGroupMask, location, movespeed, time)
    
    // Any time waypoints are added to a group without naming it in the editor it will be named "GroundWaypoints" (kDefaultWaypointGroup).
    local movement = nil
    
    if self.pathingEnabled then
        movement = Server.MoveToTarget(physicsGroupMask, self, self:GetWaypointGroupName(), location, movespeed * time)
    end

    local newOrigin = Vector()
    local distance = 0
    
    // If the newer navigation fails, default to the old version.
    if self.pathingEnabled and movement and movement.valid then
    
        newOrigin = movement.position
        SetAnglesFromVector(self, movement.direction)
        distance = movement.distance
        
    else
    
        // No pathing, move straight towards target.
        local distToTarget = (location - self:GetOrigin()):GetLength()
        if distToTarget < movespeed * time then        
            VectorCopy(location, newOrigin)
            distance = 0
        else
        
            newOrigin = self:GetOrigin() + GetNormalizedVector(location - self:GetOrigin()) * movespeed * time
            distance = (location - self:GetOrigin()):GetLength()        
        end
        
        // $AS - FIXME: This is to prevent you from going through the level and such if navigation fails
        // it will just stop and you will not move anywhere better than nothing really. 
        local trace = Shared.TraceRay(location, newOrigin, PhysicsMask.AIMovement, EntityFilterOne(self))
        if trace.fraction ~= 1 or trace.entity then
            VectorCopy(self:GetOrigin(), newOrigin)
            distance = 0
            Print("Invalid move location")
        end
    end

    if not self:GetIsFlying() then
        newOrigin = self:GetGroundAt(newOrigin, physicsGroupMask)
    end
    self:SetOrigin(newOrigin)
    
    return distance
    
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
        self:TriggerEffects("fire_start")
    elseif effect == kGameEffect.OnFire and not state then
        self:TriggerEffects("fire_stop")
    end
    
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

function LiveScriptActor:GetMeleeAttackOrigin()
    return self:GetOrigin()
end

function LiveScriptActor:MeleeAttack(target, time)

    local meleeAttackInterval = self:AdjustFuryFireDelay(self:GetMeleeAttackInterval())
   
    if(Shared.GetTime() > (self.timeOfLastAttack + meleeAttackInterval)) then
    
        self:TriggerEffects(string.format("%s_melee_attack", string.lower(self:GetClassName())))

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

        // Play hit effects - doer, target, origin, surface
        TriggerHitEffects(self, target, trace.endPoint, trace.surface)
            
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

