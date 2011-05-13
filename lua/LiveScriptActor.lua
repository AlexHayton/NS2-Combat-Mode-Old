// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Base class for all "live" entities. They have health and/or armor, can take damage, be killed 
// and can be given orders. Players, Drifters, MACs, ARCs, etc. Only objects of this type 
// are used for selection by the Commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/OrdersMixin.lua")

class 'LiveScriptActor' (ScriptActor)

LiveScriptActor.kMapName = "livescriptactor"

LiveScriptActor.kHealth = 100
LiveScriptActor.kArmor = 0

LiveScriptActor.kAnimFlinch = "flinch"
LiveScriptActor.kAnimFlinchFlames = "flinch_flames"

// Big flinch played when damage taken >= kStructureAnimFlinchHealth
LiveScriptActor.kAnimFlinchHealth = 50
LiveScriptActor.kAnimFlinchBig = "flinch_big"

// Takes this much time to reduce flinch completely
LiveScriptActor.kFlinchIntensityReduceRate = .4

LiveScriptActor.kDefaultPointValue = 10
LiveScriptActor.kMaxEnergy = 300

LiveScriptActor.kMoveToDistance = 1

if (Server) then
    Script.Load("lua/LiveScriptActor_Server.lua")
else
    Script.Load("lua/LiveScriptActor_Client.lua")
end

LiveScriptActor.networkVars = 
{
    // Used for limiting frequency of abilities
    energy                  = "float",
    maxEnergy               = string.format("integer (0 to %s)", LiveScriptActor.kMaxEnergy),

    // 0 to 1 value indicating how much pain we're in
    flinchIntensity         = "float",
    
    // Purchased tech (carapace, piercing, etc.). Also includes
    // global and class upgrades we didn't explicitly buy (armor1).
    upgrade1                = "enum kTechId",
    upgrade2                = "enum kTechId",
    upgrade3                = "enum kTechId",
    upgrade4                = "enum kTechId",
    
    // Bit mask for sending notice of gameplay effects to client.
    // Effects can stack but that's not tracked here.
    gameEffectsFlags        = "integer (0 to " .. kGameEffectMax .. ")",

    // Number of furys that are affecting this entity
    furyLevel               = string.format("integer (0 to %d)", kMaxStackLevel),
    
    activityEnd             = "float",  
    pathingEnabled          = "boolean"
    
}

// This should be moved out to classes that derive from LiveScriptActor soon.
PrepareClassForMixin(LiveScriptActor, LiveMixin)
PrepareClassForMixin(LiveScriptActor, OrdersMixin)

function LiveScriptActor:DestroyPhysicsController()

    if self.controller ~= nil then
        Shared.DestroyCollisionObject(self.controller)
        self.controller = nil
    end

end

function LiveScriptActor:OnCreate()

    ScriptActor.OnCreate(self)
	
	// List of people who have damaged me.
	self.damageList = {}
	self.totalDamage = 0
    
end

function LiveScriptActor:OnDestroy()

    self:DestroyPhysicsController()
    
    ScriptActor.OnDestroy(self)
    
end

// Depends on tech id being set before calling
function LiveScriptActor:OnInit()

    InitMixin(self, LiveMixin, { kHealth = LiveScriptActor.kHealth, kArmor = LiveScriptActor.kArmor })
    InitMixin(self, OrdersMixin, { kMoveToDistance = LiveScriptActor.kMoveToDistance })
    
    ScriptActor.OnInit(self)
    
    // Initialize energy
    self.energy = LookupTechData(self:GetTechId(), kTechDataInitialEnergy, 0)
    self.maxEnergy = LookupTechData(self:GetTechId(), kTechDataMaxEnergy, 0)
    
    self.timeLastUpdate = nil
    self.flinchIntensity = 0
    
    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
    
    // Flags to propagate to client indicating if we're under effect of anything (but doesn't include count)
    self.gameEffectsFlags = 0
    
    // List of strings indicating stackable game effects (Server only)
    self.gameEffects = {}
    
    self.furyLevel = 0
    
    self.activityEnd = 0
    
    self.timeOfLastAttack = 0
    
    self.fireAttackerId = Entity.invalidId
    self.fireDoerId = Entity.invalidId
    
    // Ability to turn off pathing for testing
    self.pathingEnabled = true
    
    self:SetPathingFlag(kPathingFlags.UnBuildable)   
    
end

// All children should override this
function LiveScriptActor:GetExtents()
    return Vector(1, 1, 1)
end

function LiveScriptActor:CreateController(physicsGroup, capsuleHeight, capsuleRadius)

    if self.controller == nil then
    
        self.controller = Shared.CreateCollisionObject(self)
        self.controller:SetGroup( physicsGroup )
        self.controller:SetTriggeringEnabled( true )
        
        local success = self.controller:SetupCapsule( capsuleRadius, capsuleHeight, self.controller:GetCoords() )
        ASSERT(success)
        
        // Make the controller kinematic so physically simulated objects will
        // interact/collide with it.
        self.controller:SetPhysicsType( CollisionObject.Kinematic )
        
    else
        Print("%s:CreateController(): Already has a controller.", self:GetClassName())
    end
    
end

/**
 * Synchronizes the origin and shape of the physics controller with the current
 * state of the entity.
 */
function LiveScriptActor:UpdateControllerFromEntity()
        
    // Update the physics controller to reflect the current state.
    if (self.controller ~= nil) then
        
        // The origin of the controller is at its center and the origin of the
        // player is at their feet, so offset it.
        self.controller:SetPosition( self:GetOrigin() + Vector(0, self:GetExtents().y, 0) )

    end
    
end

function LiveScriptActor:UpdateOriginFromController()
        
    // Update the physics controller to reflect the current state.
    if (self.controller ~= nil) then

        // Update origin of entity to new controller position
        local origin = Vector(self.controller:GetPosition()) - Vector(0, self:GetExtents().y, 0)                
        ScriptActor.SetOrigin(self, origin)

    end
    
end

function LiveScriptActor:ClearActivity()
    self.activityEnd = 0
end

function LiveScriptActor:SetActivityEnd(deltaTime)
    self.activityEnd = Shared.GetTime() + deltaTime
end

function LiveScriptActor:GetCanNewActivityStart()
    if(self.activityEnd == 0 or (Shared.GetTime() > self.activityEnd)) then
        return true
    end
    return false
end

// Used for sentries/hydras to figure out what to attack first
function LiveScriptActor:GetCanDoDamage()
    return false
end

function LiveScriptActor:GetCanIdle()
    return self:GetIsAlive()
end

function LiveScriptActor:GetHasUpgrade(techId) 
    return techId ~= kTechId.None and (techId == self.upgrade1 or techId == self.upgrade2 or techId == self.upgrade3 or techId == self.upgrade4)
end

function LiveScriptActor:GiveUpgrade(techId) 

    if not self:GetHasUpgrade(techId) then

        if self.upgrade1 == kTechId.None then
        
            self.upgrade1 = techId
            return true
            
        elseif self.upgrade2 == kTechId.None then
        
            self.upgrade2 = techId
            return true

        elseif self.upgrade3 == kTechId.None then
        
            self.upgrade3 = techId
            return true
            
        elseif self.upgrade4 == kTechId.None then
        
            self.upgrade4 = techId
            return true
            
        end
        
        Print("%s:GiveUpgrade(%d): Player already has the max of four upgrades.", self:GetClassName())
        
    else
        Print("%s:GiveUpgrade(%d): Player already has tech %s.", self:GetClassName(), techId, LookupTechData(techId, kTechDataDisplayName))
    end
    
    return false
    
end

function LiveScriptActor:GetUpgrades()
    local upgrades = {}
    
    if self.upgrade1 ~= kTechId.None then
        table.insert(upgrades, self.upgrade1)
    end
    if self.upgrade2 ~= kTechId.None then
        table.insert(upgrades, self.upgrade2)
    end
    if self.upgrade3 ~= kTechId.None then
        table.insert(upgrades, self.upgrade3)
    end
    if self.upgrade4 ~= kTechId.None then
        table.insert(upgrades, self.upgrade4)
    end
    
    return upgrades
end

// Used for flying creatures so they stay at this height off the ground whenever possible
function LiveScriptActor:GetHoverHeight()
    return 0
end

// Returns text and 0-1 scalar for status bar on commander HUD when selected. Return nil to display nothing.
function LiveScriptActor:GetStatusDescription()
    return nil, nil
end

function LiveScriptActor:GetEnergy()
    return self.energy
end

function LiveScriptActor:SetEnergy(newEnergy)
    self.energy = math.max(math.min(newEnergy, self:GetMaxEnergy()), 0)
end

function LiveScriptActor:AddEnergy(amount)
    self.energy = self.energy + amount
    self.energy = math.max(math.min(self.energy, self.maxEnergy), 0)
end

function LiveScriptActor:GetMaxEnergy()
    return self.maxEnergy
end

function LiveScriptActor:OnUpdate(deltaTime)

    PROFILE("LiveScriptActor:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    // Process outside of OnProcessMove() because animations can't be set there
    if Server then
        self:UpdateJustKilled()
    end
    
    if (self.controller ~= nil and not self:GetIsAlive()) then
        self:DestroyPhysicsController()
    end        
    
    if self.timeLastUpdate ~= nil then

        // Update flinch intensity
        if self.flinchIntensity == nil then
            Shared.Message("self.flinchIntensity is nil! class name: " .. self:GetClassName())
        end
        self.flinchIntensity = Clamp(self.flinchIntensity - deltaTime*LiveScriptActor.kFlinchIntensityReduceRate, 0, 1)
        
        // Stop overlaying basic looping flinch animation when not needed
        if self.flinchIntensity == 0 then
            self:StopOverlayAnimation(LiveScriptActor.kAnimFlinch)
        end
        
        self:SetPoseParameters()
        
    end
    
    // Update expiring stackable game effects
    if Server then
    
        self:ExpireStackableGameEffects(deltaTime)
        
        // Set fury level to be propagated to client so gameplay effects are predicted properly
        self:SetFuryLevel( self:GetStackableGameEffectCount(kFuryGameEffect) )

    end
    
    self.timeLastUpdate = Shared.GetTime()
    
end

function LiveScriptActor:SetPoseParameters()
    //Print("%s:SetPoseParam(intensity, %s)", self:GetClassName(), tostring(self.flinchIntensity))
    self:SetPoseParam("intensity", self.flinchIntensity)
end

function LiveScriptActor:GetIsSelectable()
    return self:GetIsAlive()
end

function LiveScriptActor:GetPointValue()
    return LookupTechData(self:GetTechId(), kTechDataPointValue, LiveScriptActor.kDefaultPointValue)
end

// If the gamerules indicate it's OK an entity to take damage, it calls this. World objects or those without
// health can return false. 
function LiveScriptActor:GetCanTakeDamage()
    return true
end

function LiveScriptActor:GetGameEffectMask(effect)
    return bit.band(self.gameEffectsFlags, effect) ~= 0
end

function LiveScriptActor:OnEntityChange(entityId, newEntityId)

    ScriptActor.OnEntityChange(self, entityId, newEntityId)
    
    if entityId == self.fireAttackerId then
        self.fireAttackerId = newEntityId
    end
    
end

function LiveScriptActor:GetFuryLevel()
    return self.furyLevel
end

function LiveScriptActor:AdjustFuryFireDelay(inDelay)

    // Reduce delay between attacks by number of fury effects, but 
    // decreasing in effect
    local delay = inDelay
    
    for i = 1, self.furyLevel do
        delay = delay * (1 - kFuryROFIncrease)
    end
    
    return delay
    
end

function LiveScriptActor:GetSendDeathMessage()
    return self:GetIsAlive()
end

Shared.LinkClassToMap("LiveScriptActor", LiveScriptActor.kMapName, LiveScriptActor.networkVars )