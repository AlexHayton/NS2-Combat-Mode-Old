//=============================================================================
//
// lua\Bot_Player.lua
//
// AI "bot" functions for goal setting and moving (used by Bot.lua).
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

// State machines
//  Go to nearest unbuilt nozzle or tech point, poke around a bit, ask for order, poke around a bit, build it if dropped
//  Choose a friendly player in sight, pick a point near them that they can see, move to it, wait a bit, repeat. Attack any enemies. Choose again if certain time has elapsed.
//  Go to alien hive room and pick off eggs and shoot the hive
local kBotNames = {
    "Flayra (bot)", "m4x0r (bot)", "Ooghi (bot)", "Breadman (bot)", "Squeal Like a Pig (bot)", "Chops (bot)", "Numerik (bot)",
    "Comprox (bot)", "MonsieurEvil (bot)", "Joev (bot)", "puzl (bot)", "Crispix (bot)", "Kouji_San (bot)", "TychoCelchuuu (bot)",
    "Insane (bot)", "CoolCookieCooks (bot)", "devildog (bot)", "tommyd (bot)", "Relic25 (bot)"
}

function Player:ChooseOrder()

    local order = self:GetCurrentOrder()
    
    // If we have no order or are attacking, acquire possible new target
    if GetGamerules():GetGameStarted() then
    
        if order == nil or (order:GetType() == kTechId.Attack) then
        
            // Get nearby visible target
            self:AttackVisibleTarget()
            
            order = self:GetCurrentOrder()
            
        end
        
    end

    // If we aren't attacking, try something else    
    if order == nil then
    
        // Get healed at armory, pickup health/ammo on ground, move towards other player    
        if not self:GoToNearbyEntity() then
    
            // Move to random tech point or nozzle on map
            self:ChooseRandomDestination()

        end
            
    end

    // Update order values for client
    self:UpdateOrderVariables()
    
end

function Player:UpdateOrderVariables()

    local order = self:GetCurrentOrder()
    self.hasOrder = (order ~= nil)
    
    self.orderType = kTechId.None
    
    if self.hasOrder then
    
        self.orderPosition = Vector(order:GetLocation())
        self.orderType = order:GetType()

    end
    
end

function Player:AttackVisibleTarget()

    // Are there any visible enemy players or structures nearby?
    local success = false
    
    if not self.timeLastTargetCheck or (Shared.GetTime() - self.timeLastTargetCheck > 2) then
    
        local nearestTarget = nil
        local nearestTargetDistance = nil
        
        local targets = GetEntitiesForTeamWithinRange("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), 20)
        for index, target in pairs(targets) do
        
            if target:GetIsAlive() and target:GetIsVisible() and target:GetCanTakeDamage() and target ~= self then
            
                // Prioritize players over non-players
                local dist = (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()
                
                local newTarget = (not nearestTarget) or (target:isa("Player") and not nearestTarget:isa("Player"))
                if not newTarget then
                
                    if dist < nearestTargetDistance then
                        newTarget = not nearestTarget:isa("Player") or target:isa("Player")
                    end
                    
                end
                
                if newTarget then
                
                    nearestTarget = target
                    nearestTargetDistance = dist
                    
                end
                
            end
            
        end
        
        if nearestTarget then
        
            local name = SafeClassName(nearestTarget)
            if nearestTarget:isa("Player") then
                name = nearestTarget:GetName()
            end
            
            //Print("%s now attacking %s", self:GetName(), name)
            local order = CreateOrder(kTechId.Attack, nearestTarget:GetId(), nearestTarget:GetEngagementPoint())
                
            // Converts default orders into something more appropriate for unit
            self:OverrideOrder(order)
                    
            self:SetOrder(order, true, true)
            
            success = true
        end
        
        self.timeLastTargetCheck = Shared.GetTime()
        
    end
    
    return success
    
end

function Player:GoToNearbyEntity(move)
    return false    
end

function Player:MoveRandomly(move)

    // Jump up and down crazily!
    if (Shared.GetRandomInt(0, 100) <= 5) then
        move.commands = bit.bor(move.commands, Move.Jump)
    end
    
    return true
    
end

function Player:ChooseRandomDestination(move)

    // Go to nearest unbuilt tech point or nozzle
    local className = ConditionalValue(math.random() < .5, "TechPoint", "ResourcePoint")

    local ents = Shared.GetEntitiesWithClassname(className)
    
    if ents:GetSize() > 0 then 
    
        local index = math.floor(math.random() * ents:GetSize())
        
        local destination = ents:GetEntityAtIndex(index)
        
        local order = CreateOrder(kTechId.Move, 0, destination:GetEngagementPoint())
                
        // Converts default orders into something more appropriate for unit
        self:OverrideOrder(order)
                
        self:SetOrder(order, true, true)
        
        return true
        
    end
    
    return false
    
end

function Player:GetAttackDistance()

    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon then
        return math.min(activeWeapon:GetRange(), 15)
    end
    
    return nil
    
end

function Player:UpdateWeaponMove(move)

    // Switch to proper weapon for target
    local order = self:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack) then
    
        local target = Shared.GetEntity(order:GetParam())
        if target then
        
            local activeWeapon = self:GetActiveWeapon()
        
            if self:isa("Marine") and activeWeapon then
                local outOfAmmo = (activeWeapon:isa("ClipWeapon") and (activeWeapon:GetAmmo() == 0))
            
                // Some bots switch to axe to take down structures
                if (target:isa("Structure") and self.prefersAxe and not activeWeapon:isa("Axe")) or outOfAmmo then
                    //Print("%s switching to axe to attack structure", self:GetName())
                    move.commands = bit.bor(move.commands, Move.Weapon3)
                elseif target:isa("Player") and not activeWeapon:isa("Rifle") then
                    //Print("%s switching to weapon #1", self:GetName())
                    move.commands = bit.bor(move.commands, Move.Weapon1)
                // If we're out of ammo in our primary weapon, switch to next weapon (pistol or axe)
                elseif outOfAmmo then
                    //Print("%s switching to next weapon", self:GetName())
                    move.commands = bit.bor(move.commands, Move.NextWeapon)
                end
                
            end
            
            // Attack target! TODO: We should have formal point where attack emanates from.
            local distToTarget = (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()
            local attackDist = self:GetAttackDistance()
            
            self.inAttackRange = false
            
            if activeWeapon and attackDist and (distToTarget < attackDist) then
            
                // Make sure we can see target
                local filter = EntityFilterTwo(self, activeWeapon)
                local trace = Shared.TraceRay(self:GetEyePos(), target:GetModelOrigin(), PhysicsMask.AllButPCs, filter)
                if trace.entity == target then
                
                    move.commands = bit.bor(move.commands, Move.PrimaryAttack)
                    self.inAttackRange = true
                    
                end
                
            end
        
        end        
        
    end
    
end

function Player:MoveToPoint(toPoint, move)
    
    // Fill in move to get to specified point
    local diff = (toPoint - self:GetEyePos())
    local direction = GetNormalizedVector(diff)
    
    // Look at target (needed for moving and attacking)
    move.yaw   = GetYawFromVector(direction) - self.baseYaw
    move.pitch = GetPitchFromVector(direction) - self.basePitch
    
    //self:SetViewAngles(Angles())
    
    if not self.inAttackRange then
        move.move.z = 1        
    end
    
end

/**
 * Responsible for generating the "input" for the bot. This is equivalent to
 * what a client sends across the network.
 */
function Player:GenerateMove()

    local move = Move()
    
    move:Clear()
    self.inAttackRange = false
    
    // If we're inside an egg, hatch
    if self:isa("AlienSpectator") then
        move.commands = Move.PrimaryAttack
    else
    
        local order = self:GetCurrentOrder()

        // Look at order and generate move for it
        if order then
        
            self:UpdateWeaponMove(move)
        
            local orderLocation = order:GetLocation()
            
            // Check for moving targets. This isn't done inside Order:GetLocation
            // so that human players don't have special information about invisible
            // targets just because they have an order to them.
            if (order:GetType() == kTechId.Attack) then
                local target = Shared.GetEntity(order:GetParam())
                if (target ~= nil) then
                    orderLocation = target:GetEngagementPoint()
                end
            end
            
            local moved = false            
            
            if self.pathingEnabled then
            
                local movement = Server.MoveToTarget(PhysicsMask.AIMovement, self, self:GetWaypointGroupName(), orderLocation, 1.5)
                
                if movement.valid then
                    self:MoveToPoint(movement.position, move)
                    moved = true
                end
                
            end
            
            if not moved then
                // Generate naive move towards point
                self:MoveToPoint(orderLocation, move)
            end
            
        else
        
            // If no goal, hop around randomly
            self:MoveRandomly(move) 
            
        end
        
        // Trigger request when marine need them (health, ammo, orders)
        self:TriggerAlerts()
        
    end
    
    return move

end

function Player:TriggerAlerts()

    local team = self:GetTeam()
    if self:isa("Marine") and team and team.TriggerAlert then
    
        local primaryWeapon = nil
        local weapons = self:GetHUDOrderedWeaponList()        
        if table.count(weapons) > 0 then
            primaryWeapon = weapons[1]
        end
        
        // Don't ask for stuff too often
        if not self.timeOfLastRequest or (Shared.GetTime() > self.timeOfLastRequest + 9) then
        
            // Ask for health if we need it
            if self:GetHealthScalar() < .4 and (math.random() < .3) then
            
                self:PlaySound(marineRequestSayingsSounds[2])
                team:TriggerAlert(kTechId.MarineAlertNeedMedpack, self)
                self.timeOfLastRequest = Shared.GetTime()
                
            // Ask for ammo if we need it            
            elseif primaryWeapon and primaryWeapon:isa("ClipWeapon") and (primaryWeapon:GetAmmo() < primaryWeapon:GetMaxAmmo()*.4) and (math.random() < .25) then
            
                self:PlaySound(marineRequestSayingsSounds[3])
                team:TriggerAlert(kTechId.MarineAlertNeedAmmo, self)
                self.timeOfLastRequest = Shared.GetTime()
                
            elseif (not self:GetHasOrder()) and (math.random() < .2) then
            
                self:PlaySound(marineRequestSayingsSounds[4])
                team:TriggerAlert(kTechId.MarineAlertNeedOrder, self)
                self.timeOfLastRequest = Shared.GetTime()
                
            end
            
        end
        
    end
    
end

function Player:InitializeBot()

    if not self.initializedBot then
    
        self.prefersAxe = (math.random() < .5)
        
        self.inAttackRange = false
        
        self.initializedBot = true
        
    end
    
end

function Player:UpdateName()

    // Set name after a bit of time to simulate real players
    if math.random() < .01 then

        local name = self:GetName()
        if name and string.find(string.lower(name), string.lower(kDefaultPlayerName)) ~= nil then
    
            local numNames = table.maxn(kBotNames)
            local index = Clamp(math.ceil(math.random() * numNames), 1, numNames)
            OnCommandSetName(self.client, kBotNames[index])
            
        end
        
    end
    
end

function Player:UpdateTeam(joinTeam)

    // Join random team (could force join if needed but will enter respawn queue if game already started)
    if self:GetTeamNumber() == 0 and (math.random() < .03) then
    
        if joinTeam == nil then
            joinTeam = ConditionalValue(math.random() < .5, 1, 2)
        end
        
        if GetGamerules():GetCanJoinTeamNumber(joinTeam) or Shared.GetCheatsEnabled() then
        
            GetGamerules():JoinTeam(self, joinTeam)
            
        end
        
    end
    
end

function Player:UpdateOrder()

    // Complete order if we're close to it, no need to be exact
    local order = self:GetCurrentOrder()
    if order then
    
        local orderType = order:GetType()
        
        if (orderType == kTechId.Move) or (orderType == kTechId.SquadMove) then

            local orderLocation = order:GetLocation()
            local orderDist = (self:GetOrigin() - orderLocation):GetLength()
            
            if orderDist < .75 then
                self:CompletedCurrentOrder()
            end
            
        end
        
    end

end