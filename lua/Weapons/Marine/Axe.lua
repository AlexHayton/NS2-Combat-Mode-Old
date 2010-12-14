// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Axe.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Axe' (Weapon)

Axe.kMapName = "axe"

Axe.kModelName = PrecacheAsset("models/marine/axe/axe.model")
Axe.kViewModelName = PrecacheAsset("models/marine/axe/axe_view.model")

Axe.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/axe/attack")
Axe.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/axe/draw")
Axe.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
Axe.kMetalScrapeMaterialSound = "sound/ns2.fev/materials/%s/metal_scrape"
Axe.kHitEffect = "cinematics/materials/%s/axe.cinematic"
PrecacheMultipleAssets(Axe.kHitEffect, kSurfaceList)

PrecacheMultipleAssets(Axe.kScrapeMaterialSound, kSurfaceList)
PrecacheMultipleAssets(Axe.kMetalScrapeMaterialSound, kSurfaceList)

// Use only single attack until we have shared random numbers
Axe.kAnimAttackTable = {{.5, "attack4"}}
Axe.kAnimIdleTable = {{.5, "idle"}, {.5, "idle2"}, {.5, "idle3"}, {.03, "idle4"}, {.15, "idle5"}}

Axe.kDamage = kAxeDamage
Axe.kFireDelay = kAxeFireDelay
Axe.kRange = 1.0

local networkVars = { }

function Axe:GetViewModelName()
    return Axe.kViewModelName
end

function Axe:GetFireSoundName()
    return Axe.kFireSoundName
end

function Axe:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function Axe:GetRange()
    return Axe.kRange
end

function Axe:GetPrimaryAttackDelay()
    return Axe.kFireDelay
end

function Axe:OnReload(player)
end

function Axe:GetDeathIconIndex()
    return kDeathMessageIcon.Axe
end

function Axe:GetIdleAnimation()
    return chooseWeightedEntry(Axe.kAnimIdleTable)
end

function Axe:OnInit()
    
    // Set model to be rendered in 3rd-person
    self:SetModel(Axe.kModelName)

    self:SetMoveWithView(true)
    
    // Set invisible so view model doesn't draw in world. We draw view model manually for local player
    self:SetIsVisible(false)

    Weapon.OnInit(self)

end

function Axe:GetDrawSound()
    return Axe.kDrawSoundName
end

function Axe:GetDrawAnimationSpeed()
    return kMarineDrawSpeedScalar
end

function Axe:OnDraw(player, previousWeaponMapName)

    if (player:GetCanNewActivityStart() and player:CanDrawWeapon()) then
    
        Weapon.OnDraw(self, player, previousWeaponMapName)
        
        // Attach weapon to parent's hand
        self:SetAttachPoint(Weapon.kHumanAttachPoint)
        
        self:SetIsVisible(true)
    
        local length = player:SetViewAnimation(self:GetDrawAnimation(previousWeaponMapName), nil, nil, self:GetDrawAnimationSpeed())
        
        player:SetActivityEnd(length)
        
        local drawSound = self:GetDrawSound()
        if(drawSound ~= nil) then
            Shared.PlaySound(player, drawSound)
        end
        
    end
    
end

function Axe:OnPrimaryAttack(player)

    Shared.PlaySound(player, self:GetFireSoundName())
   
    // Allow the weapon to be fired again before the activity animation ends.
    // This allows us to have a fast rate of fire and still have a nice animation
    // when not interrupted
    player:SetViewAnimation( Axe.kAnimAttackTable )
    player:SetActivityEnd(self:GetPrimaryAttackDelay() * player:GetCatalystFireModifier())
    
    // Play the attack animation on the character.
    player:SetOverlayAnimation(Marine.kAnimOverlayFire)
    
    self:DoMelee()
    
end

function Axe:DoMelee()

    local player = self:GetParent()
    local hit, trace = self:AttackMeleeCapsule(player, Axe.kDamage, self:GetRange())
    
    // Play scraping sound depending on material
    local surface = GetSurfaceFromTrace(trace)
    if(surface ~= "") then
        Shared.PlayWorldSound(nil, string.format(Axe.kMetalScrapeMaterialSound, surface), nil, trace.endPoint)
    end

end

function Axe:OnTag(tagName)

    Weapon.OnTag(self, tagName)

    if(tagName == "hit") then
    
        // TODO: Trigger melee
        
    end
    
end

function Axe:CreateHitEffect(player, origin, surface)
    if surface ~= "" and surface ~= nil and surface ~= "unknown" then
        Shared.CreateEffect(player, string.format(Axe.kHitEffect, surface), nil, Coords.GetTranslation(origin))
    end        
end

// Max degrees that weapon can swing left or right
function Axe:GetSwingAmount()
    return 10
end

Shared.LinkClassToMap("Axe", Axe.kMapName, networkVars)