// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LiveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

LiveMixin = { }
LiveMixin.type = "Live"
// Whatever uses the LiveMixin needs to implement the following callback functions.
LiveMixin.expectedCallbacks = { "GetCanTakeDamage", "OnTakeDamage", "OnKill" }

LiveMixin.kHealth = 100
LiveMixin.kArmor = 0

function LiveMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "LiveMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        alive       = "boolean",

        health      = "float",
        maxHealth   = "float",
        
        armor       = "float",
        maxArmor    = "float",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function LiveMixin:__initmixin()

    self.alive = true
    
    self.health = LookupTechData(self:GetTechId(), kTechDataMaxHealth, self.__mixindata.kHealth)
    self.maxHealth = self.health

    self.armor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, self.__mixindata.kArmor)
    self.maxArmor = self.armor
	
	// List of people who have damaged me.
	self.damageList = { }
	self.totalDamage = 0
    
end

// Returns text and 0-1 scalar for health bar on commander HUD when selected.
function LiveMixin:GetHealthDescription()

    local armorString = ""
    
    local armor = self:GetArmor()
    local maxArmor = self:GetMaxArmor()
    
    if armor and maxArmor and armor > 0 and maxArmor > 0 then
        armorString = string.format("  Armor %s/%s", ToString(math.ceil(armor)), ToString(maxArmor))
    end
    
    return string.format("Health  %s/%s%s", ToString(math.ceil(self:GetHealth())), ToString(math.ceil(self:GetMaxHealth())), armorString), self:GetHealthScalar()
    
end

function LiveMixin:GetHealthScalar()

    local max = self:GetMaxHealth() + self:GetMaxArmor() * kHealthPointsPerArmor
    local current = self:GetHealth() + self:GetArmor() * kHealthPointsPerArmor
    
    if max == 0 then
        return 0
    end

    return current / max
    
end

function LiveMixin:GetHealth()
    return self.health
end

function LiveMixin:SetHealth(health)
    self.health = math.min(self:GetMaxHealth(), health)
end

function LiveMixin:GetMaxHealth()
    return self.maxHealth
end

function LiveMixin:SetMaxHealth(setMax)
    self.maxHealth = setMax
end

function LiveMixin:GetArmorScalar()
    if self:GetMaxArmor() == 0 then
        return 0
    end
    return self:GetArmor() / self:GetMaxArmor()
end

function LiveMixin:GetArmor()
    return self.armor
end

function LiveMixin:SetArmor(armor)
    self.armor = math.min(self:GetMaxArmor(), armor)
end

function LiveMixin:GetMaxArmor()
    return self.maxArmor
end

function LiveMixin:SetMaxArmor(setMax)
    self.maxArmor = setMax
end

function LiveMixin:Heal(amount)

    local healed = false
    
    local newHealth = math.min( math.max(0, self.health + amount), self:GetMaxHealth() )
    if(self.alive and self.health ~= newHealth) then
    
        self.health = newHealth
        healed = true
        
    end    
    
    return healed
    
end

function LiveMixin:GetIsAlive()

    if (self.GetIsAliveOverride) then
        return self:GetIsAliveOverride()
    end
    return self.alive
    
end

function LiveMixin:SetIsAlive(state)

    ASSERT(type(state) == "boolean")
    self.alive = state
    
end

function LiveMixin:GetHealthPerArmor(damageType)

    local healthPerArmor = kHealthPointsPerArmor
    
    if damageType == kDamageType.Light then
        healthPerArmor = kHealthPointsPerArmorLight
    elseif damageType == kDamageType.Heavy then
        healthPerArmor = kHealthPointsPerArmorHeavy
    end
    
    if self.GetHealthPerArmorOverride then
        return self:GetHealthPerArmorOverride(damageType, healthPerArmor)
    end
    
    return healthPerArmor
    
end

/**
 * Damage to marine armor could show sparks and debris and castings for aliens
 * Damage to health shows blood and the player makes grunting/squealing/pain noises
 * Armor is best at absorbing melee damage, less against projectiles and not effective for gas/breathing damage
 * (the TSA designed their armor to deal best against skulks!)
 */
function LiveMixin:GetArmorAbsorbPercentage(damageType)

    local armorAbsorbPercentage = kBaseArmorAbsorption
    
    if(damageType == kDamageType.Falling) then
    
        armorAbsorbPercentage = 0
        
    end
    
    if self.GetArmorAbsorbPercentageOverride then
        armorAbsorbPercentage = self:GetArmorAbsorbPercentageOverride(damageType, armorAbsorbPercentage)
    end
    
    return armorAbsorbPercentage
    
end

function LiveMixin:ComputeDamage(damage, damageType)

    // The host can provide an override for this function.
    if self.ComputeDamageOverride then
        damage, damageType = self:ComputeDamageOverride(damage, damageType)
    end
    
    local armorPointsUsed = 0
    local healthPointsUsed = 0    

    if damageType then
        damage = GetGamerules():ComputeDamageFromType(damage, damageType, self)
    end

    if damage > 0 then
    
        // Calculate damage absorbed by armor according to damage type
        local absorbPercentage = self:GetArmorAbsorbPercentage(damageType)
        
        // Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        // Thanks Harimau!
        healthPointsBlocked = math.min(self:GetHealthPerArmor(damageType) * self.armor, absorbPercentage * damage)
        armorPointsUsed = healthPointsBlocked / self:GetHealthPerArmor(damageType)
        
        // Anything left over comes off of health
        healthPointsUsed = damage - healthPointsBlocked
    
    end
    
    return damage, armorPointsUsed, healthPointsUsed

end

/**
 * Returns true if the damage has killed the entity.
 */
function LiveMixin:TakeDamage(damage, attacker, doer, point, direction)

    // Use AddHealth to give health.
    ASSERT(damage >= 0)
    
    local killed = false
    
    if self:GetCanTakeDamage() then
        if Client then
            killed = self:TakeDamageClient(damage, attacker, doer, point, direction)
        else
            killed = self:TakeDamageServer(damage, attacker, doer, point, direction)
        end
    end
    
    return killed
    
end

/**
 * Client version just calls OnTakeDamage() for pushing around ragdolls and such.
 */
function LiveMixin:TakeDamageClient(damage, attacker, doer, point, direction)
    
    if self:GetIsAlive() then
    
        self:OnTakeDamage(damage, doer, point)
        
    end
    
    // Client is not authoritative over death.
    return false
    
end

function LiveMixin:TakeDamageServer(damage, attacker, doer, point, direction)
    if (self:GetIsAlive() and GetGamerules():CanEntityDoDamageTo(attacker, self)) then

        // Get damage type from source    
        local damageType = kDamageType.Normal
        if doer ~= nil then 
            damageType = doer:GetDamageType()
        end
	
	local pointOwner = attacker
        // If the pointOwner is not a player, award it's points to it's owner.
        if pointOwner ~= nil and not pointOwner:isa("Player") then
            pointOwner = pointOwner:GetOwner()
        end

        // Take into account upgrades on attacker (armor1, weapons1, etc.)        
        damage = GetGamerules():GetUpgradedDamage(pointOwner, damage, damageType)

        // highdamage cheat speeds things up for testing
        damage = damage * GetGamerules():GetDamageMultiplier()
		
		// Moved the friendly fire check to here.
		local isHealing = false
		if (attacker ~= nil) then
			local isAxeHit = false
			// Check if this is an axe/welder hit
			if (attacker:isa("Marine") and attacker:GetActiveWeapon():isa("Axe") and attacker:GetTeamNumber() == self:GetTeamNumber()) then
				isAxeHit = true
			end
			
			// Deal with axe/welder healing
			if (isAxeHit) then
				if (self:isa("Structure")) then
					local damageHealed = self:AddHealth(damage*kHealingScalar)
					if (pointOwner ~= nil and pointOwner:isa("Player")) then
						local experience = Experience_ComputeExperience(self, damageHealed)
						pointOwner:AddExperience(experience)
						Experience_GrantNearbyExperience(pointOwner, experience)
					end
				end
				isHealing = true
			end
		end
        
        // Children can override to change damage according to player mode, damage type, etc.
        local armorUsed, healthUsed
        damage, armorUsed, healthUsed = self:ComputeDamage(damage, damageType)
        
        local oldHealth = self:GetHealth()
        
        if (damage > 0 and not isHealing) then
        	self:SetArmor(self:GetArmor() - armorUsed)
        	self:SetHealth(math.max(self:GetHealth() - healthUsed, 0))
        
            self:OnTakeDamage(damage, doer, point)
            
            // Notify the doer they are giving out damage.
            local doerPlayer = doer
            if doer and doer:GetParent() and doer:GetParent():isa("Player") then
                doerPlayer = doer:GetParent()
            end
            if doerPlayer and doerPlayer:isa("Player") then
                // Not sent reliably as this notification is just an added bonus.
                Server.SendNetworkMessage(doerPlayer, "GiveDamageIndicator", BuildGiveDamageIndicatorMessage(damage), false)
            end
            
            local pointOwner = attacker
            // If the pointOwner is not a player, award it's points to it's owner.
            if pointOwner ~= nil and not pointOwner:isa("Player") then
                pointOwner = pointOwner:GetOwner()
            end
			
			// Experience Calculations:
			// Grant experience for damaging structures and also make a note of the total damage done 
			// by each player for when we die
			if (pointOwner ~= nil and pointOwner:isa("Player") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber()) then
			
				local damageTaken = armorUsed + healthUsed
		
				// Award Experience for damaging structures
				if (self:isa("Structure")) then
					if (not self:isa("PowerPoint") or (self:isa("PowerPoint") and self:GetIsPowered())) then
						local experience = Experience_ComputeExperience(self, damageTaken)
						
						pointOwner:AddExperience(experience)
						Experience_GrantNearbyExperience(pointOwner, experience)
					end
				end
				
				// Record the player in the assists table
				if (not self.damageList[pointOwner]) then 
					self.damageList[pointOwner] = 0
				end
                self.damageList[pointOwner] = self.damageList[pointOwner] + damageTaken
				self.totalDamage = self.totalDamage + damageTaken
            end
                
            if (oldHealth > 0 and self.health == 0) then
            
                // Do this first to make sure death message is sent
                GetGamerules():OnKill(self, damage, attacker, doer, point, direction)
        
                self:OnKill(damage, attacker, doer, point, direction)

                self.justKilled = true
                               
            end
            
        end
        
    end
    
    return (self.justKilled == true)
    
end

//
// How damaged this entity is, ie how much healing it can receive.
//
function LiveMixin:AmountDamaged() 
    return (self:GetMaxHealth() - self:GetHealth()) + (self:GetMaxArmor() - self:GetArmor())
end

// Return the amount of health we added 
function LiveMixin:AddHealth(health, playSound)

    // TakeDamage should be used for negative values.
    ASSERT( health >= 0 )

    local total = 0
    
    if self:GetIsAlive() and self:AmountDamaged() > 0 then
    
        // Add health first, then armor if we're full
        local healthAdded = math.min(health, self:GetMaxHealth() - self:GetHealth())
        self:SetHealth(math.min(math.max(0, self:GetHealth() + healthAdded), self:GetMaxHealth()))

        local healthToAddToArmor = health - healthAdded
        if(healthToAddToArmor > 0) then
            local armorMultiplier = self:GetHealthPerArmor(kDamageType.Normal)
            local armorPoints = healthToAddToArmor / armorMultiplier            
            self:SetArmor(math.min(math.max(0, self:GetArmor() + armorPoints), self:GetMaxArmor()))
        end
        
        total = healthAdded + healthToAddToArmor
        
        if total > 0 and playSound and (self:GetTeamType() == kAlienTeamType) then
            self:TriggerEffects("regenerate")
        end
        
    end
    
    return total
    
end