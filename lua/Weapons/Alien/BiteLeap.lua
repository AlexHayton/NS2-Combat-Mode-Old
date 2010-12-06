// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

BiteLeap.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite")
BiteLeap.kLeapSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_alt")
BiteLeap.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_hit_marine")
BiteLeap.kKillSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_kill")

BiteLeap.kHitMaterialSoundSpec = "sound/ns2.fev/alien/skulk/bite_hit_%s"
PrecacheMultipleAssets(BiteLeap.kHitMaterialSoundSpec, kSurfaceList)

// Currently unused
BiteLeap.kSalivaNode = "fxnode_bitesaliva"

BiteLeap.kDamage = kBiteDamage
BiteLeap.kBiteDelay = kBiteFireDelay
BiteLeap.kRange = 1.5       // From NS1

BiteLeap.kAnimPlayerBite = "bite"
BiteLeap.kAnimAttackTable = {{.03, "attack1slow"}, {.03, "attack2slow"}, {1, "attack3slow"}, {1, "attack4slow"}}
BiteLeap.kAnimIdleTable = {{1, "bite_idle"}, {.1, "bite_idle2"}, {.5, "bite_idle3"}, {.4, "bite_idle4"}}
BiteLeap.kLeapAnim = "leap"

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

function BiteLeap:GetTechId()
    return kTechId.Bite
end

function BiteLeap:GetRange()
    return BiteLeap.kRange
end

function BiteLeap:GetDeathIconIndex()
    return kDeathMessageIcon.Bite
end

function BiteLeap:GetIdleAnimation()
    return chooseWeightedEntry( BiteLeap.kAnimIdleTable )
end

function BiteLeap:GetCanIdle()
    return false
end

function BiteLeap:OnTargetKilled(entity)
    Shared.PlaySound(player, BiteLeap.kKillSound)
end

function BiteLeap:PerformPrimaryAttack(player)
    
    // Play random animation, speeding it up if we're under effects of fury
    player:SetViewAnimation( BiteLeap.kAnimAttackTable, nil, nil, kSkulkBiteSpeedScalar * 1/player:AdjustFuryFireDelay(1) )
    player:SetActivityEnd( player:AdjustFuryFireDelay(BiteLeap.kBiteDelay) )

    // Play the attack animation on the character.
    player:SetOverlayAnimation(BiteLeap.kAnimPlayerBite)

    Shared.PlaySound(player, BiteLeap.kAttackSound)
    
    // Trace melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, BiteLeap.kDamage, BiteLeap.kRange)
    if(didHit) then

        local hitObject = trace.entity
        local materialName = trace.surface
        
        if(hitObject ~= nil and hitObject:isa("Marine")) then
            Shared.PlaySound(player, BiteLeap.kHitMarineSound)
        else
            // Play special bite hit sound depending on material
            local surface = GetSurfaceFromTrace(trace)
            if(surface ~= "") then
                Shared.PlayWorldSound(nil, string.format(BiteLeap.kHitMaterialSoundSpec, surface), nil, trace.endPoint)
            end
        end
        
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
        
                local volume = ConditionalValue(player:GetHasUpgrade(kTechId.Leap), 1, .6)
                Shared.PlaySound(player, BiteLeap.kLeapSound, volume)
                
                player:SetViewAnimation( BiteLeap.kLeapAnim, nil, nil, 1/player:AdjustFuryFireDelay(1) )
                
                player:OnLeap()
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

Shared.LinkClassToMap("BiteLeap", BiteLeap.kMapName, {} )
