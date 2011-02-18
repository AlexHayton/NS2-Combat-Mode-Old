// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
class 'Alien' (Player)
Alien.kMapName = "alien"

if (Server) then
    Script.Load("lua/Alien_Server.lua")
else
    Script.Load("lua/Alien_Client.lua")
end

Alien.kNotEnoughResourcesSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/more")
Alien.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")
Alien.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
Alien.kSpendPlasmaSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")

// Representative portrait of selected units in the middle of the build button cluster
Alien.kPortraitIconsTexture = "ui/alien_portraiticons.dds"

// Multiple selection icons at bottom middle of screen
Alien.kFocusIconsTexture = "ui/alien_focusicons.dds"

// Small mono-color icons representing 1-4 upgrades that the creature or structure has
Alien.kUpgradeIconsTexture = "ui/alien_upgradeicons.dds"

Alien.kAnimOverlayAttack = "attack"

// DI regen think time
Alien.kRegenThinkInterval = 1.0
Alien.kWalkBackwardSpeedScalar = 0.75

// Percentage per DI regen
Alien.kInnateRegenerationPercentage = 0.02
Alien.kEnergyRecuperationRate = 10.0
Alien.kEnergyBreathScalar = .5

local networkVars = 
{
    // Energy used for all alien weapons and abilities (instead of ammo).
    // Regenerates on its own over time. Not called energy because used in base class.
    abilityEnergy           = "float", // Range is (0 to Ability.kMaxEnergy)
    
    energizeLevel           = string.format("integer (0 to %d)", kMaxStackLevel),

    movementModiferState    = "boolean",
}

function Alien:OnCreate()
    
    Player.OnCreate(self)
    self.energizeLevel = 0
    
    // Only used on the local client.
    self.darkVisionOn   = false
    self.darkVisionTime = 0
    self.darkVisionEndTime = 0

end

// For special ability, return an array of totalPower, minimumPower, tex x offset, tex y offset, 
// visibility (boolean), command name
function Alien:GetAbilityInterfaceData()
    return {}
end

function Alien:GetEnergy()
    return self.abilityEnergy
end

function Alien:DeductAbilityEnergy(energyCost)

    // Reduce energy
    self.abilityEnergy = Clamp(self.abilityEnergy - energyCost, 0, Ability.kMaxEnergy)
    
    // Make us a bit more out of breath
    self.outOfBreath = self.outOfBreath + (energyCost/Ability.kMaxEnergy * Alien.kEnergyBreathScalar)*255
    self.outOfBreath = math.max(math.min(self.outOfBreath, 255), 0)
    
end

function Alien:UpdateAbilityEnergy(input)

    // Take into account any shifts giving us energy
    local energyRate = self:GetRecuperationRate() * (1 + self.energizeLevel * kEnergizeEnergyIncrease)

    // Add energy back over time, called from Player:OnProcessMove
    self.abilityEnergy = Clamp(self.abilityEnergy + energyRate * input.time, 0, Ability.kMaxEnergy)

end

function Alien:GetMaxBackwardSpeedScalar()
    return Alien.kWalkBackwardSpeedScalar
end

function Alien:UpdateSharedMisc(input)

    self:UpdateAbilityEnergy(input)    
    Player.UpdateSharedMisc(self, input)
    
end

function Alien:HandleButtons(input)

    PROFILE("Alien:HandleButtons")

    Player.HandleButtons(self, input)
    
    // Update alien movement ability
    local newMovementState = bit.band(input.commands, Move.MovementModifier) ~= 0
    if(newMovementState ~= self.movementModiferState and self.movementModiferState ~= nil) then
    
        self:MovementModifierChanged(newMovementState, input)
        
    end
    self.movementModiferState = newMovementState

    if Client and not Shared.GetIsRunningPrediction() then
        if bit.band(input.commands, Move.ToggleFlashlight) ~= 0 then
            self.darkVisionOn = not self.darkVisionOn
            if self.darkVisionOn then
                self.darkVisionTime = Client.GetTime()
                self:TriggerEffects("alien_vision_on")            
            else
                self.darkVisionEndTime = Client.GetTime()
                self:TriggerEffects("alien_vision_off")           
            end
        end
    end
    
end

function Alien:GetCustomAnimationName(animName)
    return animName
end

function Alien:PlayInvalidSound()
    Shared.PlaySound(self, Player.kInvalidSound)
end

function Alien:GetNotEnoughResourcesSound()
    return Alien.kNotEnoughResourcesSound
end

// Return true if creature has an energy powered special ability
// that shows up on the HUD (blink)
function Alien:GetHasSpecialAbility()
    return false
end

// Returns true when players are selecting new abilities. When true, draw small icons
// next to your current weapon and force all abilities to draw.
function Alien:GetInactiveVisible()
    return self.timeOfLastWeaponSwitch ~= nil and (Shared.GetTime() < self.timeOfLastWeaponSwitch + kDisplayWeaponTime)
end

function Alien:OnUpdate(deltaTime)
    
    Player.OnUpdate(self, deltaTime)
    
    if not self.timeSinceLastAbilityListUpdate then
        self.timeSinceLastAbilityListUpdate = 0
    end
    
    self.timeSinceLastAbilityListUpdate = self.timeSinceLastAbilityListUpdate + deltaTime
    
    if self.timeSinceLastAbilityListUpdate > 2 then
    
        self:ComputeAbilityList()
        self.timeSinceLastAbilityListUpdate = 0
        
    end
    
    // Propagate count to client so energy is predicted
    if Server then
        self.energizeLevel = self:GetStackableGameEffectCount(kEnergizeGameEffect)
    end
    
end

function Alien:GetRecuperationRate()
    local scalar = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnFire), kOnFireEnergyRecuperationScalar, 1)
    return scalar * Alien.kEnergyRecuperationRate
end

function Alien:MovementModifierChanged(newMovementModifierState, input)
end

function Alien:GetHasSayings()
    return true
end

function Alien:GetSayings()

    if(self.showSayings) then
        return alienGroupSayingsText    
    end
    
    return nil
    
end

function Alien:ExecuteSaying(index, menu)

    Player.ExecuteSaying(self, index, menu)

    if(Server) then

        self:PlaySound(alienGroupSayingsSounds[index])
        
        local techId = alienRequestActions[index]
        if techId ~= kTechId.None then
            self:GetTeam():TriggerAlert(techId, self)
        end
        
    end
    
end

function Alien:GetChatSound()
    return Alien.kChatSound
end

function Alien:GetDeathMapName()
    return AlienSpectator.kMapName
end

// This is slow enough we don't want to do it too often
function Alien:ComputeAbilityList()
    self.abilityList = GetChildEntities(self, "Ability")
end

function Alien:GetAbilityList()
    return self.abilityList
end

// Returns the name of the player's lifeform
function Alien:GetPlayerStatusDesc()

    local status = ""
    
    if (self:GetIsAlive() == false) then
        status = "Dead"
    else
        if (self:isa("Embryo")) then
            status = "Evolving"
        else
            status = self:GetClassName()
        end
    end
    
    return status

end

Shared.LinkClassToMap( "Alien", Alien.kMapName, networkVars )