// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OrdersMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

OrdersMixin = { }
OrdersMixin.type = "Orders"

function OrdersMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "OrdersMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        ignoreOrders    = "boolean",
        orderPosition   = "vector",
        orderType       = "enum kTechId"
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function OrdersMixin:__initmixin()

    self.ignoreOrders = false
        
    self.orderPosition = Vector(0, 0, 0)
    
    self.orderType = kTechId.None
    
    // Current orders. List of order entity ids.
    self.orders = { }
    
end

function OrdersMixin:TransferOrders(dest)
    
    table.copy(self.orders, dest.orders)
    dest:_OrderChanged()
    
    table.clear(self.orders)
    self:_OrderChanged()
    
end

function OrdersMixin:GetHasOrder()
    return self:GetCurrentOrder() ~= nil
end

function OrdersMixin:GetNumOrders()
    return table.count(self.orders)
end

function OrdersMixin:SetIgnoreOrders(setIgnoreOrders)
    self.ignoreOrders = setIgnoreOrders
end

/**
 * Children can provide a OnOverrideOrder function to issue build, construct, etc. orders on right-click.
 */
function OrdersMixin:_OverrideOrder(order)

    if self.OnOverrideOrder then
        self:OnOverrideOrder(order)
    elseif order:GetType() == kTechId.Default then
        order:SetType(kTechId.Move)
    end
    
end

// Create order, set it, override it
function OrdersMixin:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst)

    ASSERT(type(orderType) == "number")
    ASSERT(type(targetId) == "number")
    
    if self.ignoreOrders then
        return kTechId.None
    end
    
    local order = CreateOrder(orderType, targetId, targetOrigin, orientation)
    
    self:_OverrideOrder(order)
    
    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end
    
    self:_SetOrder(order, clearExisting, insertFirst)
    
    return order:GetType()

end

function OrdersMixin:ClearOrders()

    if table.count(self.orders) > 0 then
    
        self:_DestroyOrders()
        self:_OrderChanged()
        
    end
    
end

function OrdersMixin:_DestroyOrders()
    
    // Allow ents to hook destruction of current order.
    local first = true
    
    // Delete all order entities.
    for index, orderEntId in ipairs(self.orders) do
    
        local orderEnt = Shared.GetEntity(orderEntId)
        ASSERT(orderEnt ~= nil)
        
        if first then
        
            if self.OnDestroyCurrentOrder and orderEnt ~= nil then
                self:OnDestroyCurrentOrder(orderEnt)
            end
            first = false
            
        end
        
        DestroyEntity(orderEnt)            
        
    end
    
    table.clear(self.orders)

end

function OrdersMixin:GetHasSpecifiedOrder(orderEnt)

    ASSERT(orderEnt ~= nil and orderEnt.GetId ~= nil)
    
    for index, orderEntId in ipairs(self.orders) do
        if orderEntId == orderEnt:GetId() then
            return true
        end
    end
    
    return false

end

function OrdersMixin:_SetOrder(order, clearExisting, insertFirst)

    if self.ignoreOrders then
        return
    end
    
    if clearExisting then
        self:ClearOrders()
    end

    // Always snap the location of the order to the ground.
    local location = order:GetLocation()
    if self.GetGroundAt then
        location = self:GetGroundAt(location, PhysicsMask.AIMovement)
    end
    order:SetLocation(location)
    
    if(insertFirst) then
        table.insert(self.orders, 1, order:GetId())
    else    
        table.insert(self.orders, order:GetId())
    end
    
    self:_OrderChanged()

end

function OrdersMixin:GetCurrentOrder()

    local currentOrder = nil
    
    if(self.orders and table.maxn(self.orders) > 0) then
        local orderId = self.orders[1] 
        currentOrder = Shared.GetEntity(orderId)
        ASSERT(currentOrder ~= nil)
    end

    return currentOrder
    
end

function OrdersMixin:ClearCurrentOrder()

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        DestroyEntity(currentOrder)
        
        table.remove(self.orders, 1)
        
    end
    
    self:_OrderChanged()
    
end

function OrdersMixin:CompletedCurrentOrder()

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if self.OnOrderComplete then
            self:OnOrderComplete(currentOrder)
        end
    
        DestroyEntity(currentOrder)
        
        table.remove(self.orders, 1)
        
    end
    
    self:_OrderChanged()
    
end

function OrdersMixin:_OrderChanged()
    
    if self:GetHasOrder() then
    
        local order = self:GetCurrentOrder()
        local orderLocation = order:GetLocation()
        self.orderPosition = Vector(orderLocation)
        self.orderType = order:GetType()
        
    end
    
    if self.OnOrderChanged then
        self:OnOrderChanged()
    end
    
end

// Convert rally orders to move and we're done
function OrdersMixin:ProcessRallyOrder(originatingEntity)

    if self.ignoreOrders then
        return
    end
    
    originatingEntity:TransferOrders(self)
    
    // Convert rally orders to move and we're done
    for index, orderId in ipairs(self.orders) do
    
        local order = Shared.GetEntity(orderId)
        ASSERT(order ~= nil)
        
        if order:GetType() == kTechId.SetRally then
            order:SetType(kTechId.Move)
        end
        
    end
    
end

// This is an "attack-move" from RTS. Attack the entity specified in our current attack order, if any. 
//  Otherwise, move to the location specified in the attack order and attack anything along the way.
function OrdersMixin:ProcessAttackOrder(targetSearchDistance, moveSpeed, time)

    // If we have a target, attack it
    local currentOrder = self:GetCurrentOrder()
    if(currentOrder ~= nil) then
    
        local target = Shared.GetEntity(currentOrder:GetParam())
        
        if target then
        
            if not target:GetIsAlive() then
            
                self:CompletedCurrentOrder()
                
            else
            
                local targetLocation = target:GetEngagementPoint()
                if self:GetIsFlying() then
                    targetLocation = self:GetHoverAt(targetLocation)
                end
                local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time)
                if(distToTarget < self.__mixindata.kMoveToDistance) then
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
            local targetLocation = currentOrder:GetLocation()
            if self:GetIsFlying() then
                targetLocation = self:GetHoverAt(targetLocation)
            end
            self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time)
            
            local distanceToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLength()
            if(distanceToTarget < self.__mixindata.kMoveToDistance) then
                self:CompletedCurrentOrder()
            end
 
        end
        
    end
    
end