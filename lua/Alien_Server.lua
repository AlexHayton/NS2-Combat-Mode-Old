// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * Morph into new class or buy upgrade.
 */
function Alien:Evolve(techIds)

    local success = false

    // Check for room
    local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
    local newAlienExtents = nil
    // Aliens will have a kTechDataMaxExtents defined, find it.
    for i, techId in ipairs(techIds) do
        newAlienExtents = LookupTechData(techId, kTechDataMaxExtents)
        if newAlienExtents then break end
    end
    // In case we aren't evolving to a new alien, using the current's extents.
    if not newAlienExtents then
        newAlienExtents = LookupTechData(self:GetTechId(), kTechDataMaxExtents)
    end
    
    local physicsMask = PhysicsMask.AllButPCsAndRagdolls
    local position = Vector(self:GetGroundAt(self:GetOrigin(), physicsMask))                        
    
    if not self:GetIsOnGround() then
    
        Print("You must be on the ground to evolve.")
        // Pop up tooltip
        self:AddTooltipOncePer("You must be on the ground to evolve.", 3)

    //elseif not self:GetGameEffectMask(kGameEffect.OnInfestation) then
    //    self:AddTooltipOncePer("You must be on infestation to evolve.", 3)
        
    elseif GetHasRoomForCapsule(eggExtents, position + Vector(0, eggExtents.y + Embryo.kEvolveSpawnOffset, 0), physicsMask, self)and
           GetHasRoomForCapsule(newAlienExtents, position + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), physicsMask, self)  then
    
        self:RemoveChildren()
        
        // Deduct cost here as player is immediately replaced and copied.
        for i, techId in ipairs(techIds) do
        
            local bought = true
            
            // Try to buy upgrades (upgrades don't have a gestate name, only aliens do).
            if not LookupTechData(techId, kTechDataGestateName) then
                // If we don't already have this upgrade, buy it.
                if not self:GetHasUpgrade(techId) then
                    bought = self:GiveUpgrade(techId)
                else
                    bought = false
                    Print("%s:AttemptToBuy(%s) - Player already has tech.", self:GetClassName(), EnumToString(kTechId, techId))
                end
            end
            
            if bought then
                self:AddResources(-LookupTechData(techId, kTechDataCostKey))
            end

        end
        
        local newPlayer = self:Replace(Embryo.kMapName)
        position.y = position.y + Embryo.kEvolveSpawnOffset
        newPlayer:SetOrigin(position)
        
        // Clear angles, in case we were wall-walking or doing some crazy alien thing
        local angles = Angles(self:GetViewAngles())
        angles.roll = 0.0
        angles.pitch = 0.0
        newPlayer:SetAngles(angles)
        
        // Eliminate velocity so that we don't slide or jump as an egg
        newPlayer.velocity.x = 0
        newPlayer.velocity.y = 0
        newPlayer.velocity.z = 0
        
        newPlayer:DropToFloor()
        
        newPlayer:SetGestationTechIds(techIds, self:GetTechId())
        
        success = true

    else
    
        // Pop up tooltip
        Print("You need more room to evolve.")
        self:AddTooltipOncePer("You need more room to evolve.", 3)
        
    end

    return success
    
end

// Availability and cost already checked
function Alien:AttemptToBuy(techIds)

    return self:Evolve(techIds)
    
end

function Alien:OnInit()

    Player.OnInit(self)
    
    self.abilityEnergy = Ability.kMaxEnergy
    
    self.armor = self:GetArmorAmount()
    self.maxArmor = self.armor

end

// Increase armor absorption the depending on our defensive upgrade level
function Alien:GetArmorAbsorbPercentageOverride(damageType, baseArmorAbsorption)
    
    local bonusArmorAbsorption = 1    
    if(GetTechSupported(self, kTechId.AlienArmor3Tech, true)) then
        bonusArmorAbsorption = kAlienArmorAbsorption3
    elseif(GetTechSupported(self, kTechId.AlienArmor2Tech, true)) then
        bonusArmorAbsorption = kAlienArmorAbsorption2
    elseif(GetTechSupported(self, kTechId.AlienArmor1Tech, true)) then
        bonusArmorAbsorption = kAlienArmorAbsorption1
    end

    return baseArmorAbsorption * bonusArmorAbsorption
    
end

function Alien:OnResearchComplete(structure, researchId)
    local success = Player.OnResearchComplete(self, structure, researchId)
    
    // For armor upgrades, give us more armor immediately (preserving percentage)
    if success then
    
        if researchId == kTechId.AlienArmor1Tech or researchId == kTechId.AlienArmor2Tech or researchId == kTechId.AlienArmor3Tech then
        
            local armorPercent = self.armor/self.maxArmor
            self.maxArmor = self:GetArmorAmount()
            self.armor = self.maxArmor * armorPercent
            
        end    
        
    end
    
    return success  
end

function Alien:MakeSpecialEdition()
    // Currently there's no alient special edition visual difference
end