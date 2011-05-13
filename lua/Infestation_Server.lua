// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


// a 2m radius patch will go away in 5 seconds
Infestation.kShrinkRate = 0.4


// Update radius of infestation according to if they are connected or not! If not connected to hive, we shrink.
// If connected to hive, we grow to our max radius. The rate at which it does either is dependent on the number 
// of connections.
function Infestation:UpdateInfestation(deltaTime)

    PROFILE("Infestation:UpdateInfestation")

    local now = Shared.GetTime()
    
    if not self.growthRate or now >= self.lastUpdateThinkTime + self.thinkTime then
        if not self.addedToMap then
            self.addedToMap = true
            // must do a late add, as an infestation max range are modified after OnInit
            Server.infestationMap:AddInfestation(self) 
        end
        local deltaUpdateThinkTime = now - self.lastUpdateThinkTime
        self.lastUpdateThinkTime = self.lastUpdateThinkTime + self.thinkTime
        
        //Log("%s: UI-think %s/%s ", self, deltaTime, deltaUpdateThinkTime)

        self.growthRate = 0
        
        if not self.fullyGrown then
            // More connections count for faster growth, but only up to three and not explosive growth
            self.growthRate = math.cos(.4 + math.min(table.count(self.connections), 3) / 3 * .6 * math.pi/2) * .45
        end
    
        // when lifetime runs low or when we are not connected, we shrink with a fixed speed
        if self.dying then
            // do nothing
        elseif self.deathTime then
            if now > self.deathTime then 
                Log("%s: dying", self)
                self.dying = true
                // switch to per-tick updates by making sure radius differs from max radius
                self.radius = self.radius - 0.001 
            end
       elseif not self.connectedToHive and self.fullyGrown then
            // Shrink if not connected, but only if we've fully grown first
            self.growthRate = -Infestation.kShrinkRate
        end

        // Always regenerating (5 health/sec)
        self.health = Clamp(self.health + deltaUpdateThinkTime * 5, 0, self.maxHealth)
    else
        //Log("%s: UI-no think %s ", self, deltaTime)
    end

    if self.growthRate ~= 0 then    
        // Update radius based on lifetime
        self.radius = Clamp(self.radius + deltaTime * self.growthRate, 0, self:GetMaxRadius())
    
        // Mark as fully grown
        if self.radius == self:GetMaxRadius() and not self.fullyGrown then
            self:TriggerEffects("infestation_grown")
            self.fullyGrown = true
        end
      
        // Kill us off when we get too small!    
        if (self.growthRate < 0 and self.radius <= 0) then
            self:TriggerEffects("death")
            Server.DestroyEntity(self)
        end
        
    end
    
    if self.dying then
        self.growthRate = -Infestation.kShrinkRate
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
    self.deathTime = Shared.GetTime() + lifetime
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

