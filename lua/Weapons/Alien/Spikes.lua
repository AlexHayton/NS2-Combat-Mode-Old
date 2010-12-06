// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spikes.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spike.lua")

class 'Spikes' (Ability)

Spikes.kMapName = "spikes"

Spikes.kModelName = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")

Spikes.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes")
Spikes.kAttackPierceSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_pierce")
Spikes.kAttackZoomedSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoomed")
Spikes.kAttackZoomedPierceSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoomed_pierce")
Spikes.kZoomToggleSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoom")

Spikes.kFireEffect = PrecacheAsset("cinematics/alien/lerk/spike_fire.cinematic")
Spikes.kEffect = PrecacheAsset("cinematics/alien/lerk/spike.cinematic")
Spikes.kImpactEffect = PrecacheAsset("cinematics/alien/lerk/spike_impact.cinematic")
Spikes.kFireViewEffect = PrecacheAsset("cinematics/alien/lerk/spike_view_fire.cinematic")

// Lerk spikes (view model)
Spikes.kAnimLeftAttack = "attack_l"
Spikes.kAnimRightAttack = "attack_r"
Spikes.kPlayerAnimAttack = "spikes"
Spikes.kAnimSnipe = "snipe"
Spikes.kAnimIdleTable = {{1, "idle"}/*, {.1, "idle2"}, {.5, "idle3"}*/ }

Spikes.kDelay = kSpikeFireDelay
Spikes.kSnipeDelay = kSpikesAltFireDelay
Spikes.kZoomDelay = .3
Spikes.kZoomedFov = 45
Spikes.kZoomedSensScalar = 0.25
Spikes.kSpikeEnergy = kSpikeEnergyCost
Spikes.kSnipeEnergy = kSpikesAltEnergyCost
Spikes.kSnipeDamage = kSpikesAltDamage
Spikes.kSpread2Degrees = Vector( 0.01745, 0.01745, 0.01745 )

local networkVars =
{
    zoomedIn            = "boolean",
    fireLeftNext        = "boolean",
    timeZoomedIn        = "float",
    sporePoseParam      = "float"
}

function Spikes:OnCreate()

    Ability.OnCreate(self)

    self.zoomedIn = false
    self.fireLeftNext = true
    self.timeZoomedIn = 0
    self.sporePoseParam = 0
    
end

function Spikes:OnDestroy()

    // Make sure the player doesn't get stuck with scaled sensitivity
    if Client then
        Client.SetMouseSensitivityScalar(1)
    end
    
    Ability.OnDestroy(self)
    
end

function Spikes:GetEnergyCost(player)
    return ConditionalValue(self.zoomedIn, Spikes.kSnipeEnergy, Spikes.kSpikeEnergy)
end

function Spikes:GetHasSecondary()
    return true
end

function Spikes:GetIconOffsetY(secondary)
    return ConditionalValue(not self.zoomedIn, kAbilityOffset.Spikes, kAbilityOffset.Sniper)
end

function Spikes:OnHolster(player)
    self:SetZoomState(player, false)
    Ability.OnHolster(self, player)
end

function Spikes:GetPrimaryAttackDelay()
    return ConditionalValue(self.zoomedIn, Spikes.kSnipeDelay, Spikes.kDelay)
end

function Spikes:GetIdleAnimation()
    return chooseWeightedEntry( Spikes.kAnimIdleTable )
end

function Spikes:GetTechId()
    return ConditionalValue(self.zoomedIn, kTechId.SpikesAlt, kTechId.Spikes)
end

function Spikes:GetDeathIconIndex()
    return ConditionalValue(self.zoomedIn, kDeathMessageIcon.SpikesAlt, kDeathMessageIcon.Spikes)
end

function Spikes:GetHUDSlot()
    return 1
end

function Spikes:PerformPrimaryAttack(player)

    if not self.zoomedIn then
    
        player:SetViewAnimation(ConditionalValue(self.fireLeftNext, Spikes.kAnimLeftAttack, Spikes.kAnimRightAttack), nil, nil, 1/player:AdjustFuryFireDelay(1))
        
        // Alternate view model animation to fire left then right
        self.fireLeftNext = not self.fireLeftNext
    
        Shared.PlaySound(player, ConditionalValue(player:GetHasUpgrade(kTechId.Piercing), Spikes.kAttackPierceSound, Spikes.kAttackSound))
        
        self:FireSpikeProjectile(player)        
        
    else
    
        player:SetViewAnimation(Spikes.kAnimSnipe, nil, nil, 1/player:AdjustFuryFireDelay(1))
    
        // Snipe them!
        self:PerformZoomedAttack(player)
        
    end

    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    // Play the attack animation on the character.
    player:SetOverlayAnimation(Spikes.kPlayerAnimAttack)
    
end

function Spikes:FireSpikeProjectile(player)

    // On server, create projectile
    if(Server) then

        local viewCoords = player:GetViewAngles():GetCoords()
        local startPoint = player:GetViewOffset() + player:GetOrigin() + viewCoords.zAxis * 2
        
        local spike = CreateEntity(Spike.kMapName, startPoint, player:GetTeamNumber())
        
        // Add slight randomness to start direction. Gaussian distribution.
        local x = (NetworkRandom() - .5) + (NetworkRandom() - .5)
        local y = (NetworkRandom() - .5) + (NetworkRandom() - .5)
        
        local spread = Spikes.kSpread2Degrees 
        local direction = viewCoords.zAxis + x * spread.x * viewCoords.xAxis + y * spread.y * viewCoords.yAxis

        spike:SetVelocity(direction * 40)
        
        spike:SetOrientationFromVelocity()
        
        spike:SetGravityEnabled(true)
        
        // Set spike parent to player so we don't collide with ourselves and so we
        // can attribute a kill to us
        spike:SetOwner(player)
        
        spike:SetIsVisible(true)
        
        spike:SetUpdates(true)
        
        spike:SetDeathIconIndex(self:GetDeathIconIndex())
                
    end

end

function Spikes:PerformZoomedAttack(player)

    // Trace line to attack
    local viewCoords = player:GetViewAngles():GetCoords()    
    local startPoint = Vector(player:GetViewOffset() + Vector(player:GetOrigin()))
    local endPoint = startPoint + viewCoords.zAxis * 1000

    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
        
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, filter)
    
    local hasPiercing = player:GetHasUpgrade(kTechId.Piercing)
    
    if Server and trace.fraction < 1 and trace.entity ~= nil and trace.entity:isa("LiveScriptActor")then
    
        local direction = GetNormalizedVector(endPoint - startPoint)
        
        local damageScalar = ConditionalValue(hasPiercing, kPiercingDamageScalar, 1)
        trace.entity:TakeDamage(Spikes.kSnipeDamage * damageScalar, player, self, endPoint, direction)
        
    end
    
    local soundName = ConditionalValue(hasPiercing, Spikes.kAttackZoomedPierceSound, Spikes.kAttackZoomedSound)
    
    // Play attack sound
    Shared.PlaySound(player, soundName)

    // Play snipe sound where it hits so players know what's going on
    Shared.PlayWorldSound(nil, soundName, nil, trace.endPoint)
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(Spikes.kSnipeDelay))
    
end

function Spikes:SetZoomState(player, zoomedIn)

    if(zoomedIn ~= self.zoomedIn) then
    
        self.zoomedIn = zoomedIn
        self.timeZoomedIn = Shared.GetTime()
            
        Shared.PlaySound(player, Spikes.kZoomToggleSound)
        
        if(Client) then
        
            // Lower mouse sensitivity when zoomed in
            Client.SetMouseSensitivityScalar(ConditionalValue(self.zoomedIn, Spikes.kZoomedSensScalar, 1))
            
        end
    end
    
end

// Toggle zoom
function Spikes:PerformSecondaryAttack(player)

    if(player:GetCanNewActivityStart()) then
    
        self:SetZoomState(player, not self.zoomedIn)
                
        player:SetActivityEnd(player:AdjustFuryFireDelay(Spikes.kZoomDelay))
        
        return true
        
    end
    
    return false
    
end

function Spikes:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)
    
    self.sporePoseParam = Clamp(Slerp(self.sporePoseParam, 0, (1 / kLerkWeaponSwitchTime) * input.time), 0, 1)
    
    viewModel:SetPoseParam("spore", self.sporePoseParam)
    
end

function Spikes:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    // Update fov smoothly but quickly
    local timePassed = Shared.GetTime() - self.timeZoomedIn
    local timeScalar = Clamp(timePassed/.12, 0, 1)
    local transitionScalar = Clamp(math.sin( timeScalar * math.pi / 2 ), 0, 1)
    local player = self:GetParent()

    if player then
    
        if self.zoomedIn then
            player:SetFov( Lerk.kFov + transitionScalar * (Spikes.kZoomedFov - Lerk.kFov))
        else
            player:SetFov( Spikes.kZoomedFov + transitionScalar * (Lerk.kFov - Spikes.kZoomedFov))
        end
        
    end
    
end

function Spikes:GetSecondaryAttackRequiresPress()
    return true
end

function Spikes:GetSecondaryEnergyCost(player)
    return 0
end

Shared.LinkClassToMap("Spikes", Spikes.kMapName, networkVars )
