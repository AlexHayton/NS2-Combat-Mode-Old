// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Ability.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Ability' (Weapon)

Ability.kMapName = "alienability"

Ability.kAttackDelay = .5
Ability.kEnergyCost = 20
Ability.kMaxEnergy = 100

// Special note on alien view model animations:
// The current ability is prefixed to the animation played. So
// "idle" becomes "bite_idle". Missing animations will be displayed
// in the log.
Ability.kTransitionAnimPrefix = "draw_from_"

// The order of icons in kHUDAbilitiesTexture, used by GetIconOffsetY.
// These are just the rows, the colum is determined by primary or secondary
// The 0th row is the unknown (?) icon
kAbilityOffset = enum( {'Bite', 'Parasite', 'Spit', 'Hydra', 'Spikes', 'Sniper', 'Spores', 'SwipeBlink', 'StabBlink', 'Blink', 'Gore', 'BoneShield', 'Stomp', 'Charge'} )

// Override these
function Ability:GetPrimaryAttackDelay()
    return Ability.kAttackDelay
end

// Return 0-100 energy cost (where 100 is full energy bar)
function Ability:GetEnergyCost(player)
    return Ability.kEnergyCost
end

function Ability:GetHasSecondary()
    return false
end

function Ability:GetSecondaryEnergyCost(player)
    return self:GetEnergyCost(player)
end

function Ability:GetIconOffsetX(secondary)
    return ConditionalValue(secondary, 1, 0)
end

function Ability:GetIconOffsetY(secondary)
    return 0
end

// return array of player energy (0-1), ability energy cost (0-1), x offset, y offset, visibility and hud slot
function Ability:GetInterfaceData(secondary, inactive)

    local parent = self:GetParent()
    local vis = (inactive and parent:GetInactiveVisible()) or (not inactive) //(parent:GetEnergy() ~= Ability.kMaxEnergy)
    local hudSlot = 0
    if self.GetHUDSlot then
        hudSlot = self:GetHUDSlot()
    end
    
    // Inactive abilities return only xoff, yoff, hud slot
    if inactive then
        return {self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), hudSlot}
    else
    
        if secondary then
            return {parent:GetEnergy()/Ability.kMaxEnergy, self:GetSecondaryEnergyCost()/Ability.kMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
        else
            return {parent:GetEnergy()/Ability.kMaxEnergy, self:GetEnergyCost()/Ability.kMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
        end
        
    end
    
end

// Abilities don't have world models, they are part of the creature
function Ability:GetWorldModelName()
    return ""
end

// All alien abilities use the view model designated by the alien
function Ability:GetViewModelName()

    local viewModel = ""
    local parent = self:GetParent()
    
    if (parent ~= nil and parent:isa("Alien")) then
        viewModel = parent:GetViewModelName()        
    end
    
    return viewModel
    
end

function Ability:PerformPrimaryAttack(player)
end

function Ability:PerformSecondaryAttack(player)
    return false
end

function Ability:OnInit()
            
    self:SetMoveWithView(false)
    
    Weapon.OnInit(self)
    
end

// Child class can override
function Ability:OnPrimaryAttack(player)

    if(not self:GetPrimaryAttackRequiresPress() or not self.primaryAttackLastFrame) then
    
        // Check energy cost
        local energyCost = self:GetEnergyCost(player)
        
        // No energy cost in Darwin mode
        if(Server and GetGamerules():GetDarwinMode()) then
            energyCost = 0
        end
        
        if(player:GetEnergy() >= energyCost) then

            player:DeductAbilityEnergy(energyCost)
                
            self:PerformPrimaryAttack(player)

        end
        
    end

    Weapon.OnPrimaryAttack(self, player)
    
end

function Ability:OnSecondaryAttack(player)

    if(not self:GetSecondaryAttackRequiresPress() or not self.secondaryAttackLastFrame) then

        // Check energy cost
        local energyCost = self:GetSecondaryEnergyCost(player)
        
        if(player:GetEnergy() >= energyCost) then

            if self:PerformSecondaryAttack(player) then
            
                player:DeductAbilityEnergy(energyCost)
                
            end

        end

    end
    
    Weapon.OnSecondaryAttack(self, player)
    
end

// TODO: Do something for reloading? Give alien some quick energy for a long-term cost (a little health, or slower energy gaining for a while?)
function Ability:OnReload()
end
function Ability:Reload()
end

// Aliens have no draw animations any more. Will try to cover this with a "sploosh" from the egg.
function Ability:GetDrawAnimation(previousWeaponMapName)
    return ""
end

function Ability:OnDraw(player, previousWeaponMapName)

    if (player:GetCanNewActivityStart() and player:CanDrawWeapon()) then

        Weapon.OnDraw(self, player, previousWeaponMapName)
    
        if(previousWeaponMapName ~= self:GetMapName() and previousWeaponMapName ~= nil and previousWeaponMapName ~= "") then
        
            local animName = self:GetDrawAnimation(previousWeaponMapName)
            local length = player:SetViewAnimation(animName, nil, nil, self:GetDrawAnimationSpeed())
            player:SetActivityEnd(length)
            
        end
        
    end
    
end

Shared.LinkClassToMap("Ability", "alienability", {})
