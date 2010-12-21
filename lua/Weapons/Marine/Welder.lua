//
// lua\Weapons\Welder.lua
//
//    Created by:   Alex Hayton (alex.hayton@gmail.com)
//
Script.Load("lua/Weapons/Weapon.lua")

class 'Welder' (Weapon)

Welder.kMapName = "welder"

Welder.kModelName = PrecacheAsset("models/marine/flamethrower/flamethrower.model")
Welder.kViewModelName = PrecacheAsset("models/marine/axe/flamethrower_view.model")

Welder.kAttackStartSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_start")
Welder.kAttackLoopSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_loop")
Welder.kAttackEndSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_end")
Welder.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/draw")
Welder.kHitEffect = "cinematics/materials/%s/axe.cinematic"
PrecacheMultipleAssets(Welder.kHitEffect, kSurfaceList)

PrecacheMultipleAssets(Welder.kScrapeMaterialSound, kSurfaceList)
PrecacheMultipleAssets(Welder.kMetalScrapeMaterialSound, kSurfaceList)

// Use only single attack until we have shared random numbers
Welder.kAnimAttackTable = {{.5, "attack4"}}
Welder.kAnimIdleTable = {{.5, "idle"}, {.5, "idle2"}, {.5, "idle3"}, {.03, "idle4"}, {.15, "idle5"}}

Welder.kDamage = kAxeDamage
Welder.kFireDelay = kAxeFireDelay
Welder.kRange = 1.0

local networkVars = { }

function Welder:GetViewModelName()
    return Welder.kViewModelName
end

function Welder:GetFireSoundName()
    return Welder.kFireSoundName
end

function Welder:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function Welder:GetRange()
    return Welder.kRange
end

function Welder:GetPrimaryAttackDelay()
    return Welder.kFireDelay
end

function Welder:OnReload(player)
end

function Welder:GetDeathIconIndex()
    return kDeathMessageIcon.Axe
end

function Welder:GetIdleAnimation()
    return chooseWeightedEntry(Welder.kAnimIdleTable)
end

function Welder:OnInit()
    
    // Set model to be rendered in 3rd-person
    self:SetModel(Welder.kModelName)

    self:SetMoveWithView(true)
    
    // Set invisible so view model doesn't draw in world. We draw view model manually for local player
    self:SetIsVisible(false)

    Weapon.OnInit(self)

end

function Welder:GetDrawSound()
    return Welder.kDrawSoundName
end

function Welder:GetDrawAnimationSpeed()
    return kMarineDrawSpeedScalar
end

function Welder:OnDraw(player, previousWeaponMapName)

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

function Welder:OnPrimaryAttack(player)

    Shared.PlaySound(player, self:GetFireSoundName())
   
    // Allow the weapon to be fired again before the activity animation ends.
    // This allows us to have a fast rate of fire and still have a nice animation
    // when not interrupted
    player:SetViewAnimation( Welder.kAnimAttackTable )
    player:SetActivityEnd(self:GetPrimaryAttackDelay() * player:GetCatalystFireModifier())
    
    // Play the attack animation on the character.
    player:SetOverlayAnimation(Marine.kAnimOverlayFire)
    
    self:DoMelee()
    
end

function Welder:DoMelee()

    local player = self:GetParent()
    local hit, trace = self:AttackMeleeCapsule(player, Welder.kDamage, self:GetRange())
    
    // Play scraping sound depending on material
    local surface = GetSurfaceFromTrace(trace)
    if(surface ~= "") then
        Shared.PlayWorldSound(nil, string.format(Welder.kMetalScrapeMaterialSound, surface), nil, trace.endPoint)
    end

end

function Welder:OnTag(tagName)

    Weapon.OnTag(self, tagName)

    if(tagName == "hit") then
    
        // TODO: Trigger melee
        
    end
    
end

function Welder:CreateHitEffect(player, origin, surface)
    if surface ~= "" and surface ~= nil and surface ~= "unknown" then
        Shared.CreateEffect(player, string.format(Welder.kHitEffect, surface), nil, Coords.GetTranslation(origin))
    end        
end

// Max degrees that weapon can swing left or right
function Welder:GetSwingAmount()
    return 10
end

Shared.LinkClassToMap("Axe", Welder.kMapName, networkVars)