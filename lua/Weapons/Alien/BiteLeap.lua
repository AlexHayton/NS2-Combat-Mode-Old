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
    self:AttackMeleeCapsule(player, kBiteDamage, BiteLeap.kRange)   

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

Shared.LinkClassToMap("BiteLeap", BiteLeap.kMapName, {} )
