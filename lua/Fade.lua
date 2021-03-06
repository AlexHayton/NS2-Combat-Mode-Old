// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")
Script.Load("lua/Weapons/Alien/StabBlink.lua")
Script.Load("lua/Alien.lua")

class 'Fade' (Alien)
Fade.kMapName = "fade"
Fade.kModelName = PrecacheAsset("models/alien/fade/fade.model")
Fade.kViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")

Fade.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/fade/spawn") 
Fade.kTauntSound = PrecacheAsset("sound/ns2.fev/alien/fade/taunt")
Fade.kJumpSound = PrecacheAsset("sound/ns2.fev/alien/fade/jump")

Fade.kAnimSwipeTable = { {1, "swipe"}, {1, "swipe2"}, {1, "swipe3"}, {1, "swipe4"}, {1, "swipe5"}, {1, "swipe6"} }
Fade.kAnimBlinkTable = { {1, "blink"} }
Fade.kAnimStabTable = { {1, "stab"}, {1, "stab2"} }
Fade.kBlinkInAnim = "blinkin"
Fade.kBlinkOutAnim = "blinkout"

Fade.kViewOffsetHeight = 1.2
Fade.XZExtents = .4
Fade.YExtents = .8
Fade.kHealth = kFadeHealth
Fade.kArmor = kFadeArmor
Fade.kFov = 90
Fade.kMass = 158 // ~350 pounds
Fade.kJumpHeight = 1
Fade.kMaxSpeed = 6.5
Fade.kStabSpeed = .5
Fade.kEtherealSpeed = 20
Fade.kEtherealAcceleration = 10
Fade.kBlinkEnergyCost = 30

// Energy per second
Fade.kBlinkContinuousEnergyCost = 50

if(Server) then
    Script.Load("lua/Fade_Server.lua")
end

Fade.kBlinkState = enum( {'Normal', 'BlinkOut', 'BlinkIn'} )

Fade.networkVars =
{
    blinkModifier    = "boolean",
}

function Fade:GetTauntSound()
    return Fade.kTauntSound
end

function Fade:OnInit()
    
    Alien.OnInit(self)
    
    self.blinkState = Fade.kBlinkState.Normal
    self.blinkModifier = false
    
end

function Fade:PreCopyPlayerDataFrom()

    // Reset visibility and gravity in case we were in ether mode.
    self:SetIsVisible(true)
    self:SetGravityEnabled(true)

end

function Fade:GetBaseArmor()
    return Fade.kArmor
end

function Fade:GetArmorFullyUpgradedAmount()
    return kFadeArmorFullyUpgradedAmount
end

function Fade:GetMaxViewOffsetHeight()
    return Fade.kViewOffsetHeight
end

function Fade:GetStartFov()
    return Fade.kFov
end

function Fade:GetViewModelName()
    return Fade.kViewModelName
end

function Fade:SetCrouchState(newCrouchState)
    self.crouching = newCrouchState
end

// Disable crouch until working properly
function Fade:GetCrouchAmount()
    return 0
end

function Fade:UpdateButtons(input)

    Alien.HandleButtons(self, input)
    
    self.blinkModifier = (bit.band(input.commands, Move.MovementModifier) ~= 0)
    
end

function Fade:GetFrictionForce(input, velocity)
    if self:GetIsEthereal() then
        return Vector(0, 0, 0)
    end
    return Alien.GetFrictionForce(self, input, velocity)
end

function Fade:GetBlinkModifier()
    return self.blinkModifier
end

function Fade:ConstrainMoveVelocity(moveVelocity)
    
    if not self:GetIsEthereal() then
        Alien.ConstrainMoveVelocity(self, moveVelocity)
    end
    
end

function Fade:ModifyVelocity(input, velocity)   

    if not self:GetIsEthereal() then
        Alien.ModifyVelocity(self, input, velocity)
    end
    
end

function Fade:GetIsOnGround()
    if self:GetIsEthereal() then
        return false
    end
    return Alien.GetIsOnGround(self)
end

function Fade:GetAcceleration()
    if self:GetIsEthereal() then
        return Fade.kEtherealAcceleration
    end
    return Alien.GetAcceleration(self)
end


function Fade:GetIsEthereal()

    local weapon = self:GetActiveWeapon()
    return (weapon ~= nil and weapon:isa("Blink") and weapon:GetEthereal())
    
end

// When in ethereal mode, move forward at full speed if no movement given (so you
// can't speed up by pressing keys)
function Fade:OverrideInput(input)

    if self:GetIsEthereal() and input.move:GetLength() == 0 then
        input.move.z = 1
    end
    
    return Alien.OverrideInput(self, input)
    
end

function Fade:GetMaxSpeed()

    // Ethereal Fades move very quickly
    if self:GetIsEthereal() then
        return Fade.kEtherealSpeed
    end

    local baseSpeed = Fade.kMaxSpeed    
    if self.mode == kPlayerMode.FadeStab then
        baseSpeed = Fade.kStabSpeed        
    end

    // Take into account crouching
    return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * baseSpeed

end

function Fade:GetMass()
    return Fade.kMass 
end

function Fade:GetJumpHeight()
    return Fade.kJumpHeight
end

function Fade:GetHasSpecialAbility()
    return false
end

// For special ability, return an array of energy, energy cost, tex x offset, tex y offset, 
// visibility (boolean), command name
function Fade:GetSpecialAbilityInterfaceData()

    local vis = self:GetInactiveVisible() or (self:GetEnergy() ~= Ability.kMaxEnergy)

    return { self:GetEnergy()/Ability.kMaxEnergy, Fade.kBlinkEnergyCost/Ability.kMaxEnergy, 0, kAbilityOffset.SwipeBlink, vis, GetDescForMove(Move.MovementModifier) }
    
end

function Fade:GetIsBlinking()

    local isBlinking = false
    
    local weapon = self:GetActiveWeapon()
    
    if weapon ~= nil and weapon:isa("Blink") then
        isBlinking = weapon:GetIsBlinking()
    end
    
    return isBlinking
    
end

function Fade:SetAnimAndMode(animName, mode)

    Alien.SetAnimAndMode(self, animName, mode)
    
    if mode == kPlayerMode.FadeStab then
    
        local velocity = self:GetVelocity()
        velocity:Scale(.1)
        self:SetVelocity(velocity)

        self.modeTime = Shared.GetTime() + StabBlink.kStabDuration 
        
    end
    
end

function Fade:UpdateMove(input)

    PROFILE("Fade:UpdateMove")

    Alien.UpdateMove(self, input)

    if self.mode == kPlayerMode.FadeStab then
    
        // Don't move much
        input.move:Scale(0.00001)
        
    end
    
    return input

end

function Fade:UpdateHelp()

    if self:AddTooltipOnce("You are now a Fade! Left-click to swipe and right-click to blink.") then
        return true
    elseif self:AddTooltipOnce("Use stab (weapon #2) to inflict mega damage.") then
        return true
    end
    
    return false
    
end

function Fade:GetBlinkTime()
    return math.max(self:GetAnimationLength(Fade.kBlinkInAnim), self:GetAnimationLength(Fade.kBlinkOutAnim))
end

// Double-tap in a direction to blink that way quickly
function Fade:OnDoubleTap(tapDirection)

    // Move Fade in direction as far as we can go
    local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
    local trace = Shared.TraceCapsule(self:GetOrigin(), self:GetOrigin() + tapDirection * 6, capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs, EntityFilterOne(self))
    self:SetOrigin(trace.endPoint)
    
    self:SetActivityEnd(.1)
    
end

Shared.LinkClassToMap( "Fade", Fade.kMapName, Fade.networkVars )
