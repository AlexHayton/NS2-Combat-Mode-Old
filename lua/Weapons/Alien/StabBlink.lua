// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StabBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Left-click to stab (with both claws), right-click to do the massive rising up and 
// downward attack, with both claws. Insta-kill.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'StabBlink' (Blink)

StabBlink.kMapName = "stab"

StabBlink.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/fade/stab")
StabBlink.kStabSound = PrecacheAsset("sound/ns2.fev/alien/fade/impale")
StabBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/stab_marine")
StabBlink.kImpaleSound = PrecacheAsset("sound/ns2.fev/alien/fade/impale")
StabBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
PrecacheMultipleAssets(StabBlink.kScrapeMaterialSound, kSurfaceList)

// View model animations
StabBlink.kAnimAttackTable = {{1, "attack1"}}
StabBlink.kAnimIdleTable = {{1, "stab_idle"}, {.1, "stab_idle2"}}

// Balance
StabBlink.kDamage = kStabDamage
StabBlink.kPrimaryAttackDelay = kStabFireDelay
StabBlink.kPrimaryEnergyCost = kStabEnergyCost
StabBlink.kDamageType = kStabDamageType
StabBlink.kRange = 3
StabBlink.kStabDuration = 1

function StabBlink:GetPrimaryEnergyCost(player)
    return StabBlink.kPrimaryEnergyCost
end

function StabBlink:GetHUDSlot()
    return 2
end

function StabBlink:GetDeathIconIndex()
    return kDeathMessageIcon.SwipeBlink
end

function StabBlink:GetIdleAnimation()
    return chooseWeightedEntry( StabBlink.kAnimIdleTable ) 
end

function StabBlink:GetDrawAnimation(previousWeaponMapName)
    if previousWeaponMapName == SwipeBlink.kMapName then
        return "from_swipe"
    end
    return ""
end

function StabBlink:GetDrawAnimationSpeed()
    return 1.5
end

function StabBlink:GetPrimaryAttackDelay()
    return StabBlink.kPrimaryAttackDelay
end

function StabBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.StabBlink
end

function StabBlink:GetPrimaryAttackRequiresPress()
    return true
end

function StabBlink:OnThink()

    local player = self:GetParent()
    if player then
    
        // Trace melee attack
        local didHit, trace = self:AttackMeleeCapsule(player, StabBlink.kDamage, StabBlink.kRange)
        if didHit then

            local hitObject = trace.entity
            
            if hitObject ~= nil then
            
                if hitObject:isa("Marine") then
                
                    if hitObject:GetIsAlive() then
                        Shared.PlaySound(player, StabBlink.kHitMarineSound)
                    else
                        Shared.PlaySound(player, StabBlink.kImpaleSound)
                    end
                    
                else
                
                    // Play special stab hit sound depending on material
                    local surface = GetSurfaceFromTrace(trace)
                    if(surface ~= "") then
                        Shared.PlayWorldSound(nil, string.format(StabBlink.kScrapeMaterialSound, surface), nil, trace.endPoint)
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

function StabBlink:PerformPrimaryAttack(player)
    
    Blink.PerformPrimaryAttack(self, player)
    
    // Play random animation
    player:SetViewAnimation( StabBlink.kAnimAttackTable )
    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    player:SetAnimAndMode(chooseWeightedEntry(Fade.kAnimStabTable), kPlayerMode.FadeStab)

    Shared.PlaySound(player, StabBlink.kAttackSound)

    // Attack doesn't hit until later    
    self:SetNextThink(.85) 
    
end

Shared.LinkClassToMap("StabBlink", StabBlink.kMapName, {} )
