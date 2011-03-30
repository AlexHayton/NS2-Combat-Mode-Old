// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Update radius of infestation according to if they are connected or not! If not connected to hive, we shrink.
// If connected to hive, we grow to our max radius. The rate at which it does either is dependent on the number 
// of connections.
function Infestation:UpdateInfestation(deltaTime)

    // Update lifetime if set
    if self.lifetime then
        self.lifetime = self.lifetime - deltaTime
    end

    // More connections count for faster growth, but only up to three and not explosive growth
    local growthRate = math.cos(.4 + math.min(table.count(self.connections), 3) / 3 * .6 * math.pi/2) * .45
    
    // Shrink down when lifetime runs low
    if self.lifetime then
    
        if self.lifetime < 2 then
            growthRate = -self.radius / self.lifetime
        end
        
    // Shrink when not connected, but only if we've fully grown first
    elseif not self.connectedToHive and self.fullyGrown then
        growthRate = -growthRate * .333
    end

    // Update radius based on lifetime
    self.radius = Clamp(self.radius + deltaTime * growthRate, 0, self:GetMaxRadius())
    
    // Mark as fully grown
    if self.radius == self:GetMaxRadius() and not self.fullyGrown then
        self:TriggerEffects("infestation_grown")
        self.fullyGrown = true
    end
    
    // Always regenerating
    self.health = Clamp(self.health + deltaTime * 5, 0, self.maxHealth)
    
    // Kill us off when we get too small!    
    if (growthRate < 0 and (self.radius <= 0)) or (self.lifetime and self.lifetime < 0) then
        self:TriggerEffects("death")
        Server.DestroyEntity(self)
    end
    
end

// Infestation can only take damage from flames.
function Infestation:ComputeDamageOverride(damage, damageType) 

    if damageType == kDamageType.Flame then
        return damage, damageType
    end
    
    // Returning nil for the damage type will cause no damage.
    return 0, nil

end

// Set to have infestation be temporary (for Gorge infestation).
// Lasts forever unless set. Infestation with a lifetime doesn't shrink
// when not connected to a hive.
function Infestation:SetLifetime(lifetime)
    self.lifetime = lifetime
end

// This is generator infestation - it sustains other growth
function Infestation:SetGeneratorState(state)
    self.generatorState = state
    self.connectedToHive = state
end

// Connected to generator infestation
function Infestation:SetConnectedToHive(state)
    self.connectedToHive = state
end

