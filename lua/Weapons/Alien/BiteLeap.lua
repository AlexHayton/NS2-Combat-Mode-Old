// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\BiteLeap.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Bite is main attack, leap is secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'BiteLeap' (Ability)

BiteLeap.kMapName = "bite"

BiteLeap.kRange = 1.0    // 60" inches in NS1

local networkVars =
{
    lastBittenEntityId = "entityid"
}

function BiteLeap:OnInit()

    Ability.OnInit(self)
    
    self.lastBittenEntityId = Entity.invalidId

end

function BiteLeap:GetEnergyCost(player)
    return kBiteEnergyCost
end

function BiteLeap:GetHasSecondary()
    return true
end

function BiteLeap:GetHUDSlot()
    return 1
end

function BiteLeap:GetSecondaryEnergyCost(player)
    return 40
end

function BiteLeap:GetIconOffsetY(secondary)
    return kAbilityOffset.Bite
end

function BiteLeap:GetRange()
    return BiteLeap.kRange
end

function BiteLeap:GetDeathIconIndex()
    return kDeathMessageIcon.Bite
end

function BiteLeap:PerformPrimaryAttack(player)
    
    // Play random animation, speeding it up if we're under effects of fury
    player:SetActivityEnd( player:AdjustFuryFireDelay(kBiteFireDelay) )

    // Trace melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, kBiteDamage, BiteLeap.kRange)
    
    self.lastBittenEntityId = Entity.invalidId
    if didHit and trace and trace.entity then
        self.lastBittenEntityId = trace.entity:GetId()
    end

end

// Leap if it makes sense (not if looking down).
function BiteLeap:PerformSecondaryAttack(player)

    local parent = self:GetParent()
    if parent then
    
        // Check to make sure there's nothing right in front of us
        local startPoint = player:GetViewOffset() + player:GetOrigin()       
        local viewCoords = player:GetViewAngles():GetCoords()
        local kLeapCheckRange = 2
        
        local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * kLeapCheckRange, PhysicsMask.AllButPCs, EntityFilterOne(player))
        if(trace.fraction == 1) then
        
            // Make sure we're on the ground or something else
            trace = Shared.TraceRay(startPoint, Vector(startPoint.x, startPoint.y - .5, startPoint.z), PhysicsMask.AllButPCs, EntityFilterOne(player))
            if(trace.fraction ~= 1 or player:GetCanJump()) then
        
                // TODO: Pass this into effects system
                local volume = ConditionalValue(player:GetHasUpgrade(kTechId.Leap), 1, .6)
                
                player:OnLeap()
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function BiteLeap:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    // There is a special case for biting structures.
    if self.lastBittenEntityId ~= Entity.invalidId then
        local lastBittenEntity = Shared.GetEntity(self.lastBittenEntityId)
        if lastBittenEntity and lastBittenEntity:isa("Structure") then
            tableParams[kEffectFilterHitSurface] = "structure"
        end
    end
    
end

/**
 * Allow weapons to have different capsules
 * Skulks are so low to the groun, they need a slimmer box in the vertical range
 * to avoid biting into the ground so easily.
 */
function BiteLeap:GetMeleeCapsule()
    return Vector(0.4, 0.1, 0.01)
end

/**
 * Offset the start of the melee capsule with this much from the viewpoint.
 * Skulk needs a bit more than others, as they are four-legged critters, with more
 * of their body between their midpoint and their head.
 */
function BiteLeap:GetMeleeOffset()
    return 0.4
end

Shared.LinkClassToMap("BiteLeap", BiteLeap.kMapName, networkVars )
