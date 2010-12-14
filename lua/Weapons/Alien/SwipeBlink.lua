// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SwipeBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Swipe/blink - Left-click to attack, right click to show ghost. When ghost is showing,
// right click again to go there. Left-click to cancel. Attacking many times in a row will create
// a cool visual "chain" of attacks, showing the more flavorful animations in sequence.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'SwipeBlink' (Blink)
SwipeBlink.kMapName = "swipe"

// TODO: Hold shift for "rebound" type ability. Shift while looking at enemy lets you blink above, behind or off of a wall.

SwipeBlink.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/fade/swipe")
SwipeBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/swipe_hit_marine")
SwipeBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
PrecacheMultipleAssets(SwipeBlink.kScrapeMaterialSound, kSurfaceList)

// View model animations (update Blink.lua as well)
SwipeBlink.kAnimAttackTable = {{1, "attack"}, {1, "attack2"}, {1, "attack3"}, {1, "attack4"}, {1, "attack5"}, {1, "attack6"}}
SwipeBlink.kAnimStabTable = {{1, "attack"}, {1, "attack2"}, {1, "attack3"}, {1, "attack4"}}
SwipeBlink.kAnimIdleTable = {{1, "swipe_idle"}, {.1, "swipe_idle2"}, {.5, "swipe_idle3"}}

// Swipe
SwipeBlink.kSwipeEnergyCost = kSwipeEnergyCost
SwipeBlink.kPrimaryAttackDelay = kSwipeFireDelay
SwipeBlink.kDamage = kSwipeDamage
SwipeBlink.kRange = 1.5

function SwipeBlink:GetEnergyCost(player)
    return SwipeBlink.kSwipeEnergyCost
end

function SwipeBlink:GetHasSecondary()
    return true
end

function SwipeBlink:GetPrimaryAttackDelay()
    return SwipeBlink.kPrimaryAttackDelay
end

function SwipeBlink:GetHUDSlot()
    return 1
end

function SwipeBlink:GetIdleAnimation()
    return chooseWeightedEntry( SwipeBlink.kAnimIdleTable )
end

function SwipeBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.SwipeBlink
end

function SwipeBlink:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeBlink:GetDrawAnimation(previousWeaponMapName)
    if previousWeaponMapName == StabBlink.kMapName then
        return "from_stab"
    end
    return "draw"
end

function SwipeBlink:GetDrawAnimationSpeed()
    return 1.6
end

function SwipeBlink:GetDeathIconIndex()
    return kDeathMessageIcon.SwipeBlink
end

// Claw attack, or blink if we're in that mode
function SwipeBlink:PerformPrimaryAttack(player)
    
    // Delete ghost
    Blink.PerformPrimaryAttack(self, player)

    // Play random animation
    player:SetViewAnimation( SwipeBlink.kAnimAttackTable, nil, nil, 1/player:AdjustFuryFireDelay(1) )
    player:SetActivityEnd( player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay() ))

    // Play the attack animation on the character.
    player:SetOverlayAnimation( chooseWeightedEntry(Fade.kAnimSwipeTable) )

    Shared.PlaySound(player, SwipeBlink.kAttackSound)
    
    // Attack a short time later to match with animation
    self:SetNextThink(.15) 
    
end

function SwipeBlink:OnThink()

    local player = self:GetParent()
    if player then
    
        // Trace melee attack
        local didHit, trace = self:AttackMeleeCapsule(player, SwipeBlink.kDamage, SwipeBlink.kRange)
        if didHit then

            local hitObject = trace.entity
            local materialName = trace.surface
            
            if hitObject ~= nil then
            
                if hitObject:isa("Marine") then
                    Shared.PlaySound(player, SwipeBlink.kHitMarineSound)
                else
                
                    // Play special bite hit sound depending on material
                    local surface = GetSurfaceFromTrace(trace)
                    if(surface ~= "") then
                        Shared.PlayWorldSound(nil, string.format(SwipeBlink.kScrapeMaterialSound, surface), nil, trace.endPoint)
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

Shared.LinkClassToMap("SwipeBlink", SwipeBlink.kMapName, {} )
