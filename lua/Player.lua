// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Player coordinates - z is forward, x is to the left, y is up.
// The origin of the player is at their feet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/LiveScriptActor.lua")
Script.Load("lua/PhysicsGroups.lua")

class 'Player' (LiveScriptActor)

if (Server) then
    Script.Load("lua/Player_Server.lua")
    Script.Load("lua/Bot_Player.lua")
else
    Script.Load("lua/Player_Client.lua")
    Script.Load("lua/Chat.lua")
end

Player.kMapName = "player"

Player.kModelName                   = PrecacheAsset("models/marine/male/male.model")
Player.kSpecialModelName            = PrecacheAsset("models/marine/male/male_special.model")
Player.kClientConnectSoundName      = PrecacheAsset("sound/ns2.fev/common/connect")
Player.kNotEnoughResourcesSound     = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/more")
Player.kInvalidSound                = PrecacheAsset("sound/ns2.fev/common/invalid")
Player.kTooltipSound                = PrecacheAsset("sound/ns2.fev/common/tooltip")
Player.kChatSound                   = PrecacheAsset("sound/ns2.fev/common/chat")

// Animations
Player.kAnimRun = "run"
Player.kAnimTaunt = "taunt"
Player.kAnimStartJump = "jumpin"
Player.kAnimEndJump = "jumpout"
Player.kAnimJump = "jump"
Player.kAnimReload = "reload"
Player.kRunIdleSpeed = 1

Player.kLoginBreakingDistance = 150
Player.kUseRange  = 1.6
Player.kUseHolsterTime = .5
Player.kDefaultBuildTime = .2
    
Player.kGravity = -24
Player.kMass = 90.7 // ~200 pounds (incl. armor, weapons)
Player.kWalkBackwardSpeedScalar = 0.4
Player.kJumpHeight =  1   

// The physics shapes used for player collision have a "skin" that makes them appear to float, this makes the shape
// smaller so they don't appear to float anymore
Player.kSkinCompensation = 0.9
Player.kXZExtents = 0.35
Player.kYExtents = .95
Player.kViewOffsetHeight = Player.kYExtents * 2 - .28 // Eyes a bit below the top of the head. NS1 marine was 64" tall.
Player.kFov = 90
Player.kToolTipInterval = 18

// Percentage change in height when full crouched
Player.kCrouchShrinkAmount = .5
// Slow down players when crouching
Player.kCrouchSpeedScalar = .5
// How long does it take to crouch or uncrouch
Player.kCrouchAnimationTime = .25

Player.kMinVelocityForGravity = .5
Player.kThinkInterval = .2
Player.kMinimumPlayerVelocity = .05    // Minimum player velocity for network performance and ease of debugging

// Player speeds
Player.kWalkMaxSpeed = 5                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
Player.kStartRunMaxSpeed = Player.kWalkMaxSpeed
Player.kRunMaxSpeed = 6.25              // 10 miles an hour = 16,093 meters/hour = 4.4 meters/second (increase for FPS tastes)
Player.kMaxWalkableNormal =  math.cos( math.rad(45) )

Player.kAcceleration = 50
Player.kRunAcceleration = 300
Player.kLadderAcceleration = 50

// Out of breath
Player.kTimeToLoseBreath = 10
Player.kTimeToGainBreath = 20

Player.kTauntMovementScalar = .05           // Players can only move a little while taunting

Player.kDamageIndicatorDrawTime = 1

Player.kMaxHotkeyGroups = 5

Player.kUnstickDistance = .1
Player.kUnstickOffsets = { 
    Vector(0, Player.kUnstickDistance, 0), 
    Vector(Player.kUnstickDistance, 0, 0), 
    Vector(-Player.kUnstickDistance, 0, 0), 
    Vector(0, 0, Player.kUnstickDistance), 
    Vector(0, 0, -Player.kUnstickDistance)
}

// When changing these, make sure to update Player:CopyPlayerDataFrom. Any data which 
// needs to survive between player class changes needs to go in here.
// Compensated variables are things that you want reverted when processing commands
// so basically things that are important for defining whether or not something can be shot
// for the player this is anything that can affect the hit boxes, like the animation that's playing,
// the current animation time, pose parameters, etc (not for the player firing but for the
// player being shot). 
local networkVars =
{
    // Compensated means backed up and restored between calls to OnProcessMove, but only for other players, not yourself. 
    viewYaw                 = "compensated interpolated angle",
    viewPitch               = "compensated interpolated angle",
    viewRoll                = "compensated interpolated angle",

    cameraDistance          = "float",
    desiredCameraDistance   = "float",
    thirdPerson             = "boolean",
    smoothCamera            = "boolean", 
    
    // Controlling client index. -1 for not being controlled by a live player (ragdoll, fake player)
    clientIndex             = "integer",
    
    // In degrees
    fov                     = "integer (0 to 255)",
    
    velocity                = "compensated interpolated vector",
    gravityEnabled          = "boolean",
    
    // 0 means no active weapon, 1 means first child weapon, etc.
    activeWeaponIndex       = "integer (0 to 10)",
    activeWeaponHolstered   = "boolean",

    viewModelId             = "entityid",

    plasma                  = string.format("integer (0 to %d)", kMaxResources),
    teamCarbon              = string.format("integer (0 to %d)", kMaxResources),
    gameStarted             = "boolean",
    countingDown            = "boolean",
    frozen                  = "boolean",       
    
    timeOfDeath             = "float",
    timeOfLastUse           = "float",
   
    timeOfLastWeaponSwitch  = "float",
    crouching               = "compensated boolean",
    timeOfCrouchChange      = "compensated interpolated float",
    timeLegalCrouchTime     = "compensated interpolated float",
    
    flareStartTime          = "float",
    flareStopTime           = "float",
    flareScalar             = "float",
    
    desiredPitch            = "float",
    desiredRoll             = "float",

    showScoreboard          = "boolean",
    sayingsMenu             = "integer (0 to 6)",
    timeLastMenu            = "float",
    
    // True if target under reticle can be damaged
    reticleTarget           = "boolean",
    
    // Time we last did damage to a target
    timeTargetHit           = "float",
       
    // Set to true when jump key has been released after jump processed
    // Used to require the key to pressed multiple times
    jumpHandled             = "boolean",
    timeOfLastJump          = "float",
    onGround                = "boolean",
    onGroundNeedsUpdate     = "boolean",
    
    onLadder                = "boolean",
    
    // Player-specific mode. When set to kPlayerMode.Default, player moves and acts normally, otherwise
    // he doesn't take player input. Change mode and set modeTime to the game time that the mode
    // ends. ProcessEndMode() will be called when the mode ends. Return true from that to process
    // that mode change, otherwise it will go back to kPlayerMode.Default. Used for things like taunting,
    // building structures and other player actions that take time while the player is stationary.
    mode                    = "enum kPlayerMode",
    
    // Time when mode will end. Set to -1 to have it never end.
    modeTime                = "float",
    
    primaryAttackLastFrame      = "boolean",
    secondaryAttackLastFrame    = "boolean",
    // Indicates how active the player has been
    outOfBreath             = "integer (0 to 255)",
    
    baseYaw                 = "float",
    basePitch               = "float",
    baseRoll                = "float",
    
    // The next point in the world to go to in order to reach an order target location
    nextOrderWaypoint       = "vector",
    
    // The final point in the world to go to in order to reach an order target location
    finalWaypoint           = "vector",
    
    // Whether this entity has a next order waypoint
    nextOrderWaypointActive = "boolean",
    
    // Move, Build, etc.
    waypointType            = "enum kTechId",
    
    fallReadyForPlay        = "integer (0 to 3)",

}

function Player:OnCreate()
    
    LiveScriptActor.OnCreate(self)
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    // Create the controller for doing collision detection.
    // Just use default values for the capsule size for now. Player will update to correct
    // values when they are known.
    self:CreateController(PhysicsGroup.PlayerControllersGroup, 1, 0.5)
        
    self.viewYaw        = 0
    self.viewPitch      = 0
    self.viewRoll       = 0
    self.maxExtents     = Vector( LookupTechData(self:GetTechId(), kTechDataMaxExtents, Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents)) )
    self.viewOffset     = Vector()

    self.desiredCameraDistance = 0
    self.thirdPerson = false
    self.smoothCamera = false
    self.clientIndex = -1
    self.client = nil

    self.cameraDistance = 0
    
    self.velocity = Vector(0, 0, 0)
    self.gravityEnabled = true
    self.activeWeaponIndex = 0
    self.activeWeaponHolstered = false
   
    self.overlayAnimationName = ""
   
    self.showScoreboard = false
    
    if Server then
        self.sendTechTreeBase = false
    end
    
    if Client then
        self.showSayings = false
    end
    
    self.sayingsMenu = 0
    self.timeLastMenu = 0    
    self.timeLastSayingsAction = 0
    self.reticleTarget = false
    self.timeTargetHit = 0
    self.score = 0
    self.kills = 0
    self.deaths = 0
    self.displayedTooltips = {}
    
    self.sighted = false
    self.jumpHandled = false
    self.leftFoot = true
    self.mode = kPlayerMode.Default
    self.modeTime = -1
    self.primaryAttackLastFrame = false
    self.secondaryAttackLastFrame = false
    self.outOfBreath = 0
    
    self.baseYaw = 0
    self.basePitch = 0
    self.baseRoll = 0
    
    self.requestsScores = false   
    self.viewModelId = Entity.invalidId
    
    self.usingStructure = nil
    self.timeOfLastUse  = 0
    self.timeOfLastWeaponSwitch = nil
    self.respawnQueueEntryTime = nil

    self.timeOfDeath = nil
    self.crouching = false
    self.timeOfCrouchChange = 0
    self.timeLegalCrouchTime = 0
    self.onGroundNeedsUpdate = true
    self.onGround = false
    
    self.onLadder = false
    
    self.timeLastOnGround = 0
    
    self.fallReadyForPlay = 0

    self.flareStartTime = 0
    self.flareStopTime = 0
    self.flareScalar = 1
    self.plasma = 0
        
    // Make the player kinematic so that bullets and other things collide with it.
    self:SetPhysicsGroup(PhysicsGroup.PlayerGroup)
    
    self.nextOrderWaypoint = nil
    self.finalWaypoint = nil
    self.nextOrderWaypointActive = false
    self.waypointType = kTechId.None
    
end

function Player:OnInit()
    
    LiveScriptActor.OnInit(self)
    
    if Server then
           
        self:InitWeapons()
        
    end

    // Set true on creation 
    if Server then
        self:SetName(kDefaultPlayerName)
    end
    self:SetScoreboardChanged(true)
    
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight())
    self:SetFov(self:GetStartFov())
    
    self:SetFov(self:GetStartFov())
    
    self:UpdateControllerFromEntity()
        
    self:TriggerEffects("idle")
        
    if Server then
        self:SetNextThink(Player.kThinkInterval)
    end
    
    // Initialize hotkey groups. This is in player because
    // it needs to be preserved across player replacements.
    
    // Table of table of ids, in order of hotkey groups
    self:InitializeHotkeyGroups()
    
    self:LoadHeightmap()
    
end

function Player:InitializeHotkeyGroups()

    self.hotkeyGroups = {}
    
    for i = 1, Player.kMaxHotkeyGroups do
        table.insert(self.hotkeyGroups, {})
    end

end

function Player:OnEntityChange(oldEntityId, newEntityId)

    if Server then
    
        // Loop through hotgroups and update accordingly
        for i = 1, Player.kMaxHotkeyGroups do
        
            for index, entityId in ipairs(self.hotkeyGroups[i]) do
            
                if(entityId == oldEntityId) then
                
                    if(newEntityId ~= nil) then
                    
                        self.hotkeyGroups[i][index] = newEntityId
                        
                    else
                    
                        table.remove(self.hotkeyGroups[i], index)
                        
                    end
                    
                    if self.SendHotkeyGroup ~= nil then
                        self:SendHotkeyGroup(i)
                    end
                    
                end
                
            end
            
       end
   
   end
   
end

function Player:GetStatusDescription()
    return string.format("%s - %s", self:GetName(), self:GetClassName()), nil
end

function Player:GetHealthDescription()
    return "Health", self:GetHealth() / self:GetMaxHealth()
end

// Special unique client-identifier 
function Player:GetClientIndex()
    return self.clientIndex
end

/**
 * Sets the view angles for the player. Note that setting the yaw of the
 * view will also adjust the player's yaw. Pass true for second parameter
 * to indicate that this is from player input.
 */
function Player:SetViewAngles(viewAngles, playerInput)

    self.viewYaw = viewAngles.yaw + self.baseYaw
    self.viewPitch = viewAngles.pitch + self.basePitch
    self.viewRoll  = viewAngles.roll + self.baseRoll

    local angles = Angles(self:GetAngles())
    angles.yaw  = self.viewYaw

    self:SetAngles(angles)

end

function Player:SetOffsetAngles(offsetAngles)

    self:SetBaseViewAngles(offsetAngles)       
    self:SetViewAngles(Angles(0, 0, 0))
    self:SetAngles(offsetAngles)

    if Server then        
        Server.SendNetworkMessage(self, "ResetMouse", {}, true)
    else
        Client.SetPitch(0)
        Client.SetYaw(0)
    end

end

/**
 * Gets the view angles for the player.
 */
function Player:GetViewAngles()
    return Angles(self.viewPitch, self.viewYaw, self.viewRoll)
end

function Player:GetViewAnglesCoords()

    local currentCoords = self:GetViewAngles():GetCoords()
    VectorCopy(self:GetOrigin(), currentCoords.origin)
    currentCoords.origin = currentCoords.origin + self:GetViewOffset()
    
    return currentCoords

end

function Player:SetBaseViewAngles(viewAngles)

    self.baseYaw = viewAngles.yaw
    self.basePitch = viewAngles.pitch
    self.baseRoll = viewAngles.roll

end

/**
 * Whenever view angles are needed this function must be called
 * to compute them.
 */
function Player:ConvertToViewAngles(forPitch, forYaw, forRoll)

    return Angles(forPitch + self.basePitch, forYaw + self.baseYaw, forRoll + self.baseRoll)

end

function Player:OverrideInput(input)

    // Invert mouse if specified in options
    local invertMouse = Client.GetOptionBoolean ( kInvertedMouseOptionsKey, false )
    if invertMouse then
        input.pitch = -input.pitch
    end
    
    local maxPitch = Math.Radians(89.9)
    input.pitch = Math.Clamp(input.pitch, -maxPitch, maxPitch)
    
    if self.timeClosedMenu and (Shared.GetTime() < self.timeClosedMenu + .25) then
    
        // Don't allow weapon firing
        local removePrimaryAttackMask = bit.bxor(0xFFFFFFFF, Move.PrimaryAttack)
        input.commands = bit.band(input.commands, removePrimaryAttackMask)
        
    end
    
    self:OverrideSayingsMenu(input)
    
end

function Player:OverrideSayingsMenu(input)

    if(self:GetHasSayings() and (bit.band(input.commands, Move.ToggleSayings1) ~= 0 or bit.band(input.commands, Move.ToggleSayings2) ~= 0)) then
    
        // If enough time has passed
        if(self.timeLastSayingsAction == nil or (Shared.GetTime() > self.timeLastSayingsAction + .2)) then

            local newMenu = ConditionalValue(bit.band(input.commands, Move.ToggleSayings1) ~= 0, 1, 2)

            // If not visible, bring up menu
            if(not self.showSayings) then
            
                self.showSayings = true
                self.showSayingsMenu = newMenu
                
            // else if same menu and visible, hide it
            elseif(newMenu == self.showSayingsMenu) then
            
                self.showSayings = false
                self.showSayingsMenu = nil                
            
            // If different, change menu without showing or hiding
            elseif(newMenu ~= self.showSayingsMenu) then
            
                self.showSayingsMenu = newMenu
                
            end
            
        end
        
        // Sayings toggles are handled client side.
        local removeToggleSayingsMask = bit.bxor(0xFFFFFFFF, Move.ToggleSayings1)
        input.commands = bit.band(input.commands, removeToggleSayingsMask)
        removeToggleSayingsMask = bit.bxor(0xFFFFFFFF, Move.ToggleSayings2)
        input.commands = bit.band(input.commands, removeToggleSayingsMask)

        // Record time
        self.timeLastSayingsAction = Shared.GetTime()
        
    end
    
    // Intercept any execute sayings commands.
    if self.showSayings then
        local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }
        for i, weaponSwitchCommand in ipairs(weaponSwitchCommands) do
            if bit.band(input.commands, weaponSwitchCommand) ~= 0 then
                // Tell the server to execute this saying.
                local message = BuildExecuteSayingMessage(i, self.showSayingsMenu)
                Client.SendNetworkMessage("ExecuteSaying", message, true)
                local removeWeaponMask = bit.bxor(0xFFFFFFFF, weaponSwitchCommand)
                input.commands = bit.band(input.commands, removeWeaponMask)
                self.showSayings = false
            end
        end
    end

end

// Returns current FOV
function Player:GetFov()
    return self.fov
end

function Player:SetFov(fov)
    self.fov = fov
end

function Player:SetGravityEnabled(state)
    self.gravityEnabled = state
end

// Initial FOV when spawning as class. Can change through console
// commands, weapons, etc. but this is the base.
function Player:GetStartFov()
    return Player.kFov
end

function Player:SetDesiredCameraDistance(distance)
    self.desiredCameraDistance = math.max(distance, 0)
    self.thirdPerson = ((self.desiredCameraDistance > 0) or (self.cameraDistance > 0))
end

function Player:UpdateCamera(timePassed)
    
    if(self.cameraDistance ~= self.desiredCameraDistance) then
    
        local diff = (self.desiredCameraDistance - self.cameraDistance)
        local change = ConditionalValue(GetSign(diff) > 0, 10 * timePassed, -16 * timePassed)
        
        local newCameraDistance = self.cameraDistance + change
        
        if(math.abs(diff) < math.abs(change)) then
            newCameraDistance = self.desiredCameraDistance
        end

        self:SetCameraDistance(newCameraDistance)
        
    end
    
end

function Player:SetCameraDistance(distance)
    self.cameraDistance = math.max(distance, 0)
    self.thirdPerson = ((self.desiredCameraDistance > 0) or (self.cameraDistance > 0))
end

function Player:GetIsThirdPerson()
    return self.thirdPerson
end

// Set to 0 to get out of third person
function Player:SetIsThirdPerson(distance)
    self:SetDesiredCameraDistance(distance)
end

function Player:GetIsFirstPerson()
    return (Client and (Client.GetLocalPlayer() == self) and not self:GetIsThirdPerson())
end

function Player:GetCameraDistance()
    return self.cameraDistance
end

// Also specifies listener position
function Player:GetViewOffset()
    return self.viewOffset
end

// Stores the player's current view offset. Calculated from GetMaxViewOffset() and crouch state.
function Player:SetViewOffsetHeight(newViewOffsetHeight)

    VectorCopy(Vector(0, newViewOffsetHeight, 0), self.viewOffset)
    
end

function Player:GetEyePos()
    return self:GetOrigin() + self.viewOffset    
end

function Player:GetMaxViewOffsetHeight()
    return Player.kViewOffsetHeight
end

function Player:GetCanViewModelIdle()
    return self:GetIsAlive() and self:GetCanNewActivityStart() and (self.mode == kPlayerMode.Default)
end

function Player:LoadHeightmap()

    // Load height map
    self.heightmap = HeightMap()   
    local heightmapFilename = string.format("maps/overviews/%s.hmp", Shared.GetMapName())
    
    if(not self.heightmap:Load(heightmapFilename)) then
        Shared.Message("Couldn't load height map " .. heightmapFilename)
        self.heightmap = nil
    end

end

function Player:GetHeightmap()
    return self.heightmap
end

// worldX => -map y
// worldZ => +map x
function Player:GetMapXY(worldX, worldZ)

    local success = false
    local mapX = 0
    local mapY = 0

    if self.heightmap then
        mapX = self.heightmap:GetMapX(worldZ)
        mapY = self.heightmap:GetMapY(worldX)
    else
        Print("Player:GetMapXY(): heightmap is nil")
        return false, 0, 0
    end

    if mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
        success = true
    end

    return success, mapX, mapY

end

// Plays view model animation, given a string or a table of weighted entries.
// Returns length of animation or 0 if animation wasn't found. 
function Player:SetViewAnimation(animName, noForce, blend, speed)

    local length = 0.0
    
    if not speed then
        speed = 1
    end
    
    if (animName ~= nil and animName ~= "") then
    
        local viewModel = self:GetViewModelEntity()
        if (viewModel ~= nil) then

            local force = ConditionalValue(noForce, false, true)
            local success = false
            
            if blend then
                success = viewModel:SetAnimationWithBlending(animName, self:GetBlendTime(), force, speed)
                length = viewModel:GetAnimationLength(animName) / speed                
            else
                success = viewModel:SetAnimation(animName, force, speed)
                length = viewModel:GetAnimationLength(animName) / speed
            end
            
            if success then
            
                if Client then
                    self:UpdateRenderModel()
                end
                
                viewModel:UpdateBoneCoords()
            end
            
            if not success and force then
                Print("%s:SetViewAnimation(%s) failed.", self:GetClassName(), tostring(animSpecifier))
            end
            
        else
            Print("Player:SetViewAnimation(%s) - couldn't find view model", animName)
        end
        
    end
    
    return length
    
end

function Player:GetViewAnimationLength(animName)

    local length = 0
    
    local viewModel = self:GetViewModelEntity()
    if (viewModel ~= nil) then
        if animName and animName ~= "" then
            length = viewModel:GetAnimationLength(animName)
        else 
            length = viewModel:GetAnimationLength(nil)
        end
    end
    
    return length
    
end

function Player:SetViewOverlayAnimation(overlayAnim)

    local viewModel = self:GetViewModelEntity()
    if (viewModel ~= nil) then
        viewModel:SetOverlayAnimation(overlayAnim)
    end
    
end

function Player:GetVelocity()
    return self.velocity
end

function Player:SetVelocity(velocity)

    VectorCopy(velocity, self.velocity)

    // Snap to 0 when close to zero for network performance and our own sanity
    if (math.abs(self.velocity:GetLength()) < Player.kMinimumPlayerVelocity) then
    
        self.velocity:Scale(0)
        
    end
    
end

function Player:GetController()

    return self.controller
    
end

function Player:PrimaryAttack()

    local weapon = self:GetActiveWeapon()    
    if weapon and self:GetCanNewActivityStart() then
        weapon:OnPrimaryAttack(self)
    end
    
end

function Player:SecondaryAttack()

    local weapon = self:GetActiveWeapon()        
    if weapon and self:GetCanNewActivityStart() then
        weapon:OnSecondaryAttack(self)
    end

end

function Player:PrimaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnPrimaryAttackEnd(self)
    end

end

function Player:SecondaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnSecondaryAttackEnd(self)
    end
    
end

function Player:SelectNextWeapon()

    self:SelectWeaponWithFinder(self.FindChildEntity)
    
end

function Player:SelectPrevWeapon()

    self:SelectWeaponWithFinder(self.FindChildEntityReverse)
    
end

function Player:SelectWeaponWithFinder(finderFunction)
    
    local entity = finderFunction(self, self:GetActiveWeapon())
    
    if(entity == nil) then
        entity = finderFunction(self, nil)
    end
    
    while(entity ~= nil and not entity:isa("Weapon")) do
        entity = finderFunction(self, entity)
    end

    if(entity ~= nil and self:GetCanNewActivityStart()) then
        self:SetActiveWeapon(entity:GetMapName())
    end
    
end

function Player:GetActiveWeapon()

    local activeWeapon = nil
    
    if(self.activeWeaponIndex ~= 0) then
    
        local weapons = self:GetHUDOrderedWeaponList()
        
        if self.activeWeaponIndex <= table.count(weapons) then
            activeWeapon = weapons[self.activeWeaponIndex]
        end
        
    end
    
    return activeWeapon
    
end

function Player:GetActiveWeaponName()

    local activeWeaponName = ""
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponName = activeWeapon:GetClassName()
    end
    
    return activeWeaponName
    
end

function Player:Reload()
    local weapon = self:GetActiveWeapon()
    if(weapon ~= nil and self:GetCanNewActivityStart()) then
        weapon:OnReload(self)
    end
end

/**
 * Check to see if there's a LiveScriptActor we can use. Checks any attachpoints returned from  
 * GetAttachPointOrigin() and if that fails, does a regular traceray. Returns true if we processed the action.
 */
function Player:Use()

    local success = false
    
    local startPoint = self:GetViewOffset() + self:GetOrigin()
    local viewCoords = self:GetViewAngles():GetCoords()
    
    local elapsedTime = 0
    if self.timeOfLastUse ~= 0 then
        elapsedTime = math.min(Shared.GetTime() - self.timeOfLastUse, Player.kDefaultBuildTime)
    end
    
    // Get entities in radius
    
    local ents = GetEntitiesIsaInRadius("LiveScriptActor", self:GetTeamNumber(), self:GetOrigin(), Player.kUseRange)
    for index, entity in ipairs(ents) do
    
        // Look for attach point
        local attachPointName = entity:GetUseAttachPoint()
        
        if attachPointName ~= "" and entity:GetCanBeUsed(self) then

            local attachPoint = entity:GetAttachPointOrigin(attachPointName)
            local toAttachPoint = attachPoint - startPoint
            local legalUse = toAttachPoint:GetLength() < Player.kUseRange and viewCoords.zAxis:DotProduct(GetNormalizedVector(toAttachPoint)) > .8
            
            if(legalUse and entity:OnUse(self, elapsedTime, true, attachPoint)) then
            
                success = true
                
                break
                
            end
            
        end 
        
    end
    
    // If failed, do a regular trace with entities that don't have use attach points
    if not success then

        local endPoint = startPoint + viewCoords.zAxis * Player.kUseRange
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        
        if(trace.fraction < 1 and trace.entity ~= nil) then
        
            local entityName = trace.entity:GetMapName()
            
            if trace.entity:GetCanBeUsed(self) then

                success = trace.entity:OnUse(self, elapsedTime, false, trace.endPoint)
                
            end

        end
        
    end
    
    // Put away weapon when we +use
    if success then
    
    
        if self:isa("Marine") and not self:GetWeaponHolstered() then
            self:Holster(true)
        end
        
        self:SetActivityEnd(Structure.kUseInterval)
        
        self.timeOfLastUse = Shared.GetTime()
        
    end
    
    return success
    
end

// Play different animations depending on current weapon
function Player:GetCustomAnimationName(animName)
    local activeWeapon = self:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        return string.format("%s_%s", activeWeapon:GetMapName(), animName)
    else
        return animName
    end
end

function Player:Buy()
end

function Player:Holster(force)

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if weapon and (force or self:GetCanNewActivityStart()) then
    
        weapon:OnHolster(self)
        
        self.activeWeaponHolstered = true
        
        success = true
        
    end
    
    return success

end

function Player:Draw(previousWeaponName)

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and self:GetCanNewActivityStart()) then
    
        weapon:OnDraw(self, previousWeaponName)
        
        self.activeWeaponHolstered = false
        
        success = true
    end
        
    return success
    
end

function Player:GetWeaponHolstered()
    return self.activeWeaponHolstered
end

function Player:GetExtents()
    return self:GetExtentsFromCrouch(self:GetCrouchAmount())
end

function Player:GetMaxExtents()
    return Vector(self.maxExtents)    
end

/**
 * Returns true if the player is currently on a team and the game has started.
 */
function Player:GetIsPlaying()
    return self.gameStarted and (self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index)
end

function Player:GetCanTakeDamage()
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index)
end

function Player:GetCanSeeEntity(targetEntity)
    return GetCanSeeEntity(self, targetEntity)
end

// Individual resources
function Player:GetPlasma()
    return self.plasma
end

// Returns player mass in kg
function Player:GetMass()
    return Player.kMass
end

function Player:AddPlasma(amount)
    local newPlasma = math.max(math.min(self.plasma + amount, kMaxResources), 0)
    if newPlasma ~= self.plasma then
        self.plasma = newPlasma
        self:SetScoreboardChanged(true)
    end
    
end

function Player:AddCarbon(amount)
    self.teamCarbon = math.max(math.min(self.teamCarbon + amount, kMaxResources), 0)
end

function Player:GetDisplayPlasma()

    local displayPlasma = self.plasma
    if(Client and self.resourceDisplay) then
        displayPlasma = self.animatedPlasmaDisplay:GetDisplayValue()
    end
    return displayPlasma
    
end

function Player:GetDisplayTeamCarbon()

    local displayTeamCarbon = self.teamCarbon
    if(Client and self.resourceDisplay) then
        displayTeamCarbon = self.animatedCarbonDisplay:GetDisplayValue()
    end
    return displayTeamCarbon
    
end

// Team resources
function Player:GetTeamCarbon()
    return self.teamCarbon
end

function Player:GetMoveDirection(moveVelocity)

    if(self:GetIsOnLadder()) then
    
        return GetNormalizedVector(moveVelocity)

    end
    
    local up = Vector(0, 1, 0)
    local right = GetNormalizedVector(moveVelocity):CrossProduct(up)
    local moveDirection = up:CrossProduct(right)
    moveDirection:Normalize()
    
    return moveDirection
    
end

// Compute the desired velocity based on the input. Make sure that going off at 45 degree 
// angles doesn't make us faster. Also make sure that moving forward while looking down
// doesn't slow us down.
function Player:ComputeForwardVelocity(input)

    PROFILE("Player:ComputeForwardVelocity")

    local forwardVelocity = Vector(0, 0, 0)

    local move          = GetNormalizedVector(input.move)
    local angles        = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    local viewCoords    = angles:GetCoords()
    
    local accel = ConditionalValue(self:GetIsOnLadder(), Player.kLadderAcceleration, self:GetAcceleration())
    local moveVelocity = viewCoords:TransformVector( move ) * accel
    self:ConstrainMoveVelocity(moveVelocity)
    
    // Make sure that moving forward while looking down doesn't slow 
    // us down (get forward velocity, not view velocity)
    local moveVelocityLength = moveVelocity:GetLength()
    
    if(moveVelocityLength > 0) then

        local moveDirection = self:GetMoveDirection(moveVelocity)
        
        // Trying to move straight down
        if(not ValidateValue(moveDirection)) then
            moveDirection = Vector(0, -1, 0)
        end
            
        forwardVelocity = moveDirection * moveVelocityLength
        
    end
    
    return forwardVelocity

end

function Player:UpdateEnergy(input)
end

function Player:UpdateUse(deltaTime)

    // Pull out weapon again if we haven't built for a bit
    if self:GetWeaponHolstered() and self:isa("Marine") and ((Shared.GetTime() - self.timeOfLastUse) > (Structure.kUseInterval + .2)) then    
        self:Draw()        
    end 

    local viewModel = self:GetViewModelEntity()
    if viewModel then
        
        local newVisState = not self:GetWeaponHolstered()
        if newVisState ~= viewModel:GetIsVisible() then
        
            viewModel:SetIsVisible(newVisState)        
            
        end
        
    end
    
    self.updatedSinceUse = true
        
end

// Make sure we can't move faster than our max speed (esp. when holding
// down multiple keys, going down ramps, etc.)
function Player:ClampSpeed(input, velocity)

    PROFILE("Player:ClampSpeed")

    // Only clamp XZ speed so it feels better
    local moveSpeedXZ = velocity:GetLengthXZ()        
    local maxSpeed = self:GetMaxSpeed()
    
    // Players moving backwards can't go full speed    
    if input.move.z < 0 then
    
        maxSpeed = maxSpeed * self:GetMaxBackwardSpeedScalar()
        
    end
    
    if (moveSpeedXZ > maxSpeed) then
    
        local velocityY = velocity.y
        velocity:Scale( maxSpeed / moveSpeedXZ )
        velocity.y = velocityY
        
    end 
    
end

// Allow child classes to alter player's move at beginning of frame. Alter amount they
// can move by scaling input.move, remove key presses, etc.
function Player:UpdateMove(input)

    PROFILE("Player:UpdateMove")
    
    // Don't allow movement when frozen in place
    if(self.frozen) then
    
        input.move:Scale(0)
        
    else        
    
        // Allow child classes to affect how much input is allowed at any time
        if (self.mode == kPlayerMode.Taunt) then
    
            input.move:Scale(Player.kTauntMovementScalar)
            
        end
        
    end
    
end

function Player:UpdateViewAngles(input)

    PROFILE("Player:UpdateViewAngles")
    
    if(self.desiredPitch ~= nil or self.desiredRoll ~= nil) then
    
        local kRate = input.time * 10
    
        local angles = Angles(self:GetAngles())
        
        if(self.desiredRoll ~= nil) then
            angles.roll = SlerpRadians(angles.roll, self.desiredRoll, kRate)
            self:SetAngles(angles)
        end
        
        local viewAngles = Angles(input.pitch, input.yaw, 0)
        
        /*
        if(self.desiredRoll ~= nil) then
            viewAngles.roll = SlerpRadians(viewAngles.roll, 0 + self.desiredRoll, kRate)
        end
        
        if(self.desiredPitch ~= nil) then
            viewAngles.pitch = SlerpRadians(viewAngles.pitch, input.pitch + self.desiredPitch, kRate)
        end
        */
                
        self:SetViewAngles(viewAngles, true)

    else
    
        // Update to the current view angles.    
        local viewAngles = Angles(input.pitch, input.yaw, 0)
        self:SetViewAngles(viewAngles, true)
        
    end    
    
    // Update view offset from crouching
    local viewY = self:GetMaxViewOffsetHeight()
    viewY = viewY - viewY * self:GetCrouchShrinkAmount() * self:GetCrouchAmount()

    // Don't set new view offset height unless needed (avoids Vector churn)        
    local lastViewOffsetHeight = self:GetViewOffset().y
    if math.abs(viewY - lastViewOffsetHeight) > kEpsilon then
        self:SetViewOffsetHeight(viewY)
    end
    
end

function Player:PreUpdateMovePhysics(input, runningPrediction)
end

function Player:DrawDevLine(p0, p1, r, g, b, a)

    /*if Shared.GetDevMode() then
        DebugLine(p0, p1, .1, r, g, b, a)
    end*/
    
end

// Update origin and velocity from move
function Player:UpdateMovePhysics(input)

    PROFILE("Player:UpdateMovePhysics")
    
    // Accelerate the movement by the velocity.
    local forwardVelocity = self:ComputeForwardVelocity(input)
    local velocity = self:GetVelocity() + forwardVelocity * input.time
    
    // Add in the friction force.
    local frictionForce = self:GetFrictionForce(input, velocity)

    velocity = velocity + frictionForce * input.time
    
    // Don't apply gravity if we're on a ladder or standing still on the ground so we're not sliding down ramps
    if ((not self:GetIsOnLadder()) and (not (self:GetIsOnGround() and self:GetVelocity():GetLengthXZ() < Player.kMinVelocityForGravity) and self.gravityEnabled)) then
    
        // Update velocity with gravity after we update our position (it accounts for gravity and varying frame rates)
        velocity.y = velocity.y + self:GetGravityForce(input) * input.time
        
    end
    
    // Add additional velocity according to specials
    self:ModifyVelocity(input, velocity)
    
    // Clamp speed to max speed
    self:ClampSpeed(input, velocity)
    
    self:UpdatePosition(velocity, input.time)
    
    self:SetVelocity(velocity)
                
end

// Allow children to update state after setting origin/velocity
function Player:PostUpdateMovePhysics(input, runningPrediction)
end

function Player:SetDesiredRoll(roll)
    self.desiredRoll = roll
end

function Player:SetDesiredPitch(pitch)
    self.desiredPitch = pitch
end

// You can't modify a compensated field for another (relevant) entity during OnProcessMove(). The
// "local" player doesn't undergo lag compensation it's only all of the other players and entities.
// For example, if health was compensated, you can't modify it when a player was shot -
// it will just overwrite it with the old value after OnProcessMove() is done. This is because
// compensated fields are rolled back in time, so it needs to restore them once the processing
// is done. So it backs up, synchs to the old state, runs the OnProcessMove(), then restores them. 
function Player:OnProcessMove(input)

    PROFILE("Player:OnProcessMove")
    
    SetRunningProcessMove(self)
  
    // Only update player movement on server or for local player
    if (self:GetIsAlive() and (Server or (Client.GetLocalPlayer() == self))) then
    
        local runningPrediction = Shared.GetIsRunningPrediction()
      
        // Allow children to alter player's move before processing. To alter the move
        // before it's sent to the server, use OverrideInput
        self:UpdateMove(input)

        // Before UpdateViewAngles and UpdateMovePhysics
        self:UpdateCrouch()

        // Update player angles and view angles smoothly from desired angles if set. 
        // But visual effects should only be calculated when not predicting.
        self:UpdateViewAngles(input)    
        
        // Check for jumping, attacking, etc.
        self:HandleButtons(input)
       
        // Allow child to update its own internal state before changing position
        self:PreUpdateMovePhysics(input, runningPrediction)
        
        // Update origin and velocity from move (main physics behavior)
        self:UpdateMovePhysics(input)
        
        // Allow children to update state after setting origin/velocity
        self:PostUpdateMovePhysics(input, runningPrediction)
        
        // Animation transitions (walking, jumping, etc.)
        self:UpdateAnimationTransitions(input.time)
        
        // Everything else
        self:UpdateMisc(input)
        
        // Debug if desired
        //self:OutputDebug()
        
    elseif not self:GetIsAlive() and Client and (Client.GetLocalPlayer() == self) then
    
        // Allow the use of scoreboard even when not alive
        self:UpdateScoreboard(input) 
        
    end
    
    if (not Shared.GetIsRunningPrediction()) then
    
        self:UpdatePoseParameters(input.time)
        
        // Since we changed the coords for the player, update the physics model.
        self:SetPhysicsDirty()
        
        // Force the view model to be dirty so the animation properly predicts.
        local viewModel = self:GetViewModelEntity()
        if (viewModel ~= nil) then
            viewModel:SetPhysicsDirty()
        end

    end
    
    if Server then
        // Because we aren't predicting the use operation, we shouldn't predict
        // the end of the use operation (or else with lag we can get rogue weapon
        // drawing while holding down use)
        self:UpdateUse(input.time)
    end
    
    SetRunningProcessMove(nil)
    
end

function Player:OutputDebug()

    local startPoint = Vector(self:GetOrigin())
    startPoint.y = startPoint.y + self:GetExtents().y
    DebugBox(startPoint, startPoint, self:GetExtents(), .05, 1, 1, 0, 1)
    
end

function Player:GetItem(mapName)
    
    local startEntity = nil
    
    while true do
   
        local currentEntity = self:FindChildEntity(startEntity)
        
        if(currentEntity == nil) then 
            break
        end

        if(currentEntity:GetMapName() == mapName) then
        
            return currentEntity
            
        end        
        
        startEntity = currentEntity
        
    end
    
    return nil
    
end

function Player:GetTraceCapsule()
    return GetTraceCapsuleFromExtents(self:GetExtents())    
end

function Player:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

/**
 * Moves by the player by the specified offset, colliding and sliding with the world.
 */
function Player:PerformMovement(offset, maxTraces, velocity)

    PROFILE("Player:PerformMovement")

    local hitEntities = nil
    
    if self.controller then
    
        self:UpdateControllerFromEntity()

        local tracesPerformed = 0
        
        while (offset:GetLengthSquared() > 0.0 and tracesPerformed < maxTraces) do

            local trace = self.controller:Move(offset, self:GetMovePhysicsMask())

            if (trace.fraction < 1) then
        
                // Remove the amount of the offset we've already moved.
                offset = offset * (1 - trace.fraction)

                // Make the motion perpendicular to the surface we collided with so we slide.
                offset = offset - offset:GetProjection(trace.normal)
                
                // Redirect velocity if specified
                if velocity ~= nil then
                
                    // Scale it according to how much velocity we lost
                    local newVelocity = velocity - velocity:GetProjection(trace.normal)
                    
                    // Copy it so it's changed for caller
                    VectorCopy(newVelocity, velocity)
    
                end
                
                // Defer the processing of the callbacks until after we've finished moving,
                // since the callbacks may modify our self an interfere with our loop
                if trace.entity ~= nil and trace.entity:isa("ScriptActor") then
                    if (hitEntities == nil) then
                        hitEntities = { trace.entity }
                    else
                        table.insert(hitEntities, trace.entity)
                    end    
                end
                
                completedSweep = false
                capsuleSweepHit = true
        
            else
                offset = Vector(0, 0, 0)
            end

            self.controller:SetPosition(trace.endPoint)
            
            tracesPerformed = tracesPerformed + 1

        end
        
        self:UpdateOriginFromController()
        
    end
    
    // Do the hit callbacks.
    if hitEntities then
        for index, entity in ipairs(hitEntities) do
            entity:OnCapsuleTraceHit(self)
            self:OnCapsuleTraceHit(entity)
        end
    end
    
    return self:GetOrigin()
    
end

function Player:Unstick()

    // Try moving player in a couple different directions until we're unstuck
    for index, direction in ipairs(Player.kUnstickOffsets) do
    
        local trace = self.controller:Trace(direction, self:GetMovePhysicsMask())
        if trace.fraction == 1 then
        
            self:SetOrigin(self:GetOrigin() + direction)
            self:UpdateControllerFromEntity()
            return true
            
        end

    end
    
    return false
    
end

function Player:UpdatePosition(velocity, time)

    PROFILE("Player:UpdatePosition")

    // First move the character upwards to allow them to go up stairs and over small obstacles. 
    local offset = nil
    local stepHeight = self:GetStepHeight()
    local onGround = self:GetIsOnGround()    

    // Handle when we're interpenetrating an object usually due to animation. Ie we're under a hive that's breathing into us
    // or when we're standing on top of animated structures like Hives, Extractors, etc.
    local stuck = self:GetIsStuck()
    if stuck then    
        self:Unstick()
    end
    
    if onGround then
        offset = self:PerformMovement(Vector(0, stepHeight, 0), 1) - self:GetOrigin()
    end
    
    // First try moving capsule desired distance. We're done if we moved all the way without hitting anything.
    self:PerformMovement(velocity * time, 10, ConditionalValue(onGround, nil, velocity))
    
    // Finally, move the player back down to compensate for moving them up. We add in an additional step 
    // height for moving down steps/ramps.
    if onGround then
        offset.y = offset.y + stepHeight
        self:PerformMovement( -offset, 1, nil, true )
    end

end

// Return the height that this player can step over automatically
function Player:GetStepHeight()
    return .5
end

function Player:GetBreathingHeight()
    return 0
end

function Player:UpdateBreathing(timePassed)

    // Add in breathing according to how fast we're moving
    local movementSpeedScalar = 1.5//math.max(1, self:GetVelocity():GetLength())
    local currentBreathingHeight = self:GetBreathingHeight() * math.cos( Shared.GetTime() * movementSpeedScalar )
    
    local viewOffset = self:GetViewOffset()
    viewOffset.y = viewOffset.y + currentBreathingHeight
    self:SetViewOffsetHeight(viewOffset.y) 
    
    // Update out of breath scalar if we've been running
    local moveScalar = self:GetVelocity():GetLength()/self:GetMaxSpeed()
    self.outOfBreath = self.outOfBreath + (moveScalar*timePassed/Player.kTimeToLoseBreath)*255
    
    // Catch breath
    self.outOfBreath = self.outOfBreath - (1*timePassed/Player.kTimeToGainBreath)*255
    self.outOfBreath = math.max(math.min(self.outOfBreath, 255), 0)

end

/**
 * Returns a value between 0 and 1 indicating how much the player has crouched
 * visually (actual crouching is binary).
 */
function Player:GetCrouchAmount()
     
    // Get 0-1 scalar of time since crouch changed        
    local crouchScalar = 0
    if(self.timeOfCrouchChange > 0 and self.timeLegalCrouchTime > 0) then
    
        crouchScalar = math.min(self.timeLegalCrouchTime - self.timeOfCrouchChange, Player.kCrouchAnimationTime)/Player.kCrouchAnimationTime
        
        if(self.crouching) then
            crouchScalar = math.sin(crouchScalar * math.pi/2)
        else
            crouchScalar = math.cos(crouchScalar * math.pi/2)
        end
        
    end
    
    //Print("%s:GetCrouchAmount(): timeCrouchChange: %s timeLegalCrouchTime: %s => scalar: %.2f (crouching: %s)", self:GetClassName(), tostring(self.timeOfCrouchChange), tostring(self.timeLegalCrouchTime), crouchScalar, tostring(self.crouching))
    
    return crouchScalar

end

function Player:GetCrouching()
    return self.crouching
end

function Player:GetCrouchShrinkAmount()
    return Player.kCrouchShrinkAmount
end

function Player:GetExtentsFromCrouch(crouchScalar)

    local extents = self:GetMaxExtents()
    extents.y = extents.y - (extents.y * self:GetCrouchShrinkAmount() * crouchScalar) / 2
    return extents

end

function Player:UpdateCrouch()

    PROFILE("Player:UpdateCrouch")
    
    local lastExtents = self:GetExtents()

    // Increment crouch scalar if it doesn't get us stuck
    local lastLegalCrouchTime = self.timeLegalCrouchTime
    self.timeLegalCrouchTime = Shared.GetTime()
    
    self:UpdateControllerFromEntity()
    
    if(self:GetIsStuck()) then
    
        // Standing up in a vent, for instance
        
        self.timeLegalCrouchTime = lastLegalCrouchTime
        
        self:UpdateControllerFromEntity()
        
    end
    
    // Update extents and possibly origin to make sure we're not stuck in the world
    local crouchScalar = self:GetCrouchAmount()
    
    local newExtents = self:GetExtentsFromCrouch(crouchScalar)
    
    // Update y position in case we're in something (move you up as you stand up)
    local yExtentsDiff = newExtents.y - lastExtents.y

    if yExtentsDiff > 0 then
    
        self:SetOrigin(self:GetOrigin() + Vector(0, yExtentsDiff, 0))
        
    end

end

// Returns true if the player is currently standing on top of something solid. Recalculates
// onGround if we've updated our position since we've last called this.
function Player:GetIsOnGround()
    
    // Re-calculate every time SetOrigin is called
    if(self.onGroundNeedsUpdate) then
    
        self.onGround = false

        // We're not on ground for a short time after we jump
        if (self:GetOverlayAnimation() ~= self:GetCustomAnimationName(Player.kAnimStartJump) or self:GetOverlayAnimationFinished()) then

            self.onGround = self:GetGroundPosition()
            
            if self.onGround then
                self.timeLastOnGround = Shared.GetTime()
            end
            
        end
        
        self.onGroundNeedsUpdate = false        
        
    end
    
    if(self:GetIsOnLadder()) then
    
        return false
        
    end
    
    return self.onGround
    
end

function Player:SetIsOnLadder(onLadder, ladderEntity)

    self.onLadder = onLadder
    
end

// Override this for Player types that shouldn't be on Ladders
function Player:GetIsOnLadder()

    return self.onLadder
    
end

// Recalculate self.onGround next time
function Player:SetOrigin(origin)

    Entity.SetOrigin(self, origin)
    
    self:UpdateControllerFromEntity()
    
    self.onGroundNeedsUpdate = true
    
end

// Returns boolean indicating if we're on the ground now or not (but always false with +y velocity).
// If position parameter passed, set it to ground if right below us to avoid unnecessary falling.
// If no position passed, use current origin.
function Player:GetGroundPosition(position)

    if self.controller == nil then
        return false
    end

    // Try to move the controller downward a small amount to determine if
    // we're on the ground.
    local offset = Vector(0, -0.05, 0)
    local trace = self.controller:Trace(offset, self:GetMovePhysicsMask())

    if (self.velocity.y > 0 and self.timeOfLastJump ~= nil and (Shared.GetTime() - self.timeOfLastJump < .2)) then
    
        // If we are moving away from the ground, don't treat
        // us as standing on it.
        return false
        
    end
    
    if (trace.fraction < 1 and trace.normal.y < Player.kMaxWalkableNormal) then
        return false
    end

    if trace.fraction < 1 then
    
        // If position parameter passed in, set it to point on ground
        if position ~= nil then
            VectorCopy(trace.endPoint, position)
        end
        
        return true
        
    end
    
    return false
    
end

// Look current player position and size and determine if we're stuck
function Player:GetIsStuck()

    PROFILE("Player:GetIsStuck")

    // If we don't limit this to the ground then the player can get "stuck"
    // on the ceiling as a skulk or on top of a ladder touching the ceiling
    // for example.
    if self:GetIsOnGround() then
    
        local offset = Vector(0, 0.05, 0)
        
        local trace = self.controller:Trace(offset, self:GetMovePhysicsMask())
        
        return trace.fraction ~= 1
        
    end
    
    return false
    
end

/**
 * Synchronizes the origin and shape of the physics controller with the current
 * state of the entity.
 */
function Player:UpdateControllerFromEntity()
        
    PROFILE("Player:UpdateControllerFromEntity")
    
    // Update the physics controller to reflect the current state.
    
    if (self.controller ~= nil) then
        
        local extents = self:GetExtentsFromCrouch(self:GetCrouchAmount())
        
        local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
        
        if capsuleHeight ~= 0 or capsuleRadius ~= 0 then

            self.controller:SetupCapsule( capsuleRadius * Player.kSkinCompensation,
                capsuleHeight * Player.kSkinCompensation, self.controller:GetCoords() )
            
        end
        
        // The origin of the controller is at its center and the origin of the
        // player is at their feet, so offset it.
        local offsetOrigin = self:GetOrigin()
        local newControllerOriginY = offsetOrigin.y + extents.y

        self.controller:SetPosition(Vector(offsetOrigin.x, newControllerOriginY, offsetOrigin.z))
        
    end
    
end

/**
 * Synchronizes the origin of the entity with the current state of the physics
 * controller.
 */
function Player:UpdateOriginFromController()
        
    // The origin of the controller is at its center and the origin of the
    // player is at their feet, so offset it.
    local origin = Vector(self.controller:GetPosition())
    origin.y = origin.y - self:GetExtents().y
    
    Entity.SetOrigin(self, origin)
    
    self.onGroundNeedsUpdate = true

end

function Player:GetPlayFootsteps()

    local velocity = self:GetVelocity()
    local velocityLength = velocity:GetLength() 
    return not self.crouching and self:GetIsOnGround() and velocityLength > .75
    
end

function Player:GetIsJumping()

    local overlayAnim = self:GetOverlayAnimation()
    
    return  overlayAnim == self:GetCustomAnimationName(Player.kAnimStartJump) or 
            overlayAnim == self:GetCustomAnimationName(Player.kAnimJump) or 
            overlayAnim == self:GetCustomAnimationName(Player.kAnimEndJump)

end

function Player:GetCanIdle()
    local groundSpeed = self:GetVelocity():GetLengthXZ()
    return groundSpeed < .5 and self:GetIsOnGround()
end

/**
 * Called to update the animation playing on the player based on the current
 * state (not moving, jumping, etc.)
 */
function Player:UpdateAnimationTransitions(timePassed)

    PROFILE("Player:UpdateAnimationTransitions")
    
    if (self.mode == kPlayerMode.Default and self:GetIsAlive()) then
    
        // If we've been in the air long enough to finish jump animation, transition to jump animation
        // Also play jump animation when falling. 
        local overlayAnim = self:GetOverlayAnimation()
        local velocity    = self:GetVelocity()

        // If we started jumping and finished animation, or if we've stepped off something, play falling animation, 
        if ( overlayAnim == self:GetCustomAnimationName(Player.kAnimStartJump) and (self.fallReadyForPlay == 0) and self:GetOverlayAnimationFinished() ) then
            
            // fallReadyForPlay prevents the fall sound from being played multiple times
            self.fallReadyForPlay = 1
            self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimJump))
            
        // If we're about to land, play land animation
        elseif (overlayAnim == self:GetCustomAnimationName(Player.kAnimJump) and (self.fallReadyForPlay == 1) and (((velocity.y < 0) and self:GetGroundPosition()) or self:GetIsOnGround())) then

            // Play special fall sounds depending on material
            self:TriggerEffects("fall", {surface = self:GetMaterialBelowPlayer()})
            
            self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimEndJump))
            
            self.fallReadyForPlay = 2
            
        elseif (overlayAnim == self:GetCustomAnimationName(Player.kAnimEndJump) and self:GetOverlayAnimationFinished()) then
        
            self:SetOverlayAnimation("")
            
            self.fallReadyForPlay = 0
            
        end
  
        self:UpdateMoveAnimation()
        
    end
    
    LiveScriptActor.UpdateAnimation(self, timePassed)
        
end

function Player:UpdateAnimation()
    // Override the LiveScriptActor version since we explicitly call this during OnProcessMove
    // for players (so we have consistent results on the client and server).
end

// Called by client/server UpdateMisc()
function Player:UpdateSharedMisc(input)

    self:UpdateCamera(input.time)
    self:UpdateBreathing(input.time)
    self:UpdateMode()
    self:UpdateWeapons(input)
    
    if Client then
        self:UpdateChat(input)
    end

    self:UpdateScoreboard(input) 
    
end

function Player:UpdateScoreboard(input)
    self.showScoreboard = (bit.band(input.commands, Move.Scoreboard) ~= 0)
end

function Player:UpdateMoveAnimation()

    local groundSpeed = self:GetVelocity():GetLengthXZ()
    if (groundSpeed > .1) then

        self:SetAnimationWithBlending(Player.kAnimRun)
        
    end
    
end

function Player:UpdatePoseParameters(deltaTime)

    PROFILE("Player:UpdatePoseParameters")
    
    SetPlayerPoseParameters(self, self:GetViewAngles(), self.velocity, self:GetMaxSpeed(), self:GetMaxBackwardSpeedScalar(), self:GetCrouchAmount())    

end

// By default the movement speed will not factor in the vertical velocity.
function Player:GetMoveSpeedIs2D()
    return true
end

function Player:UpdateMode()

    if(self.mode ~= kPlayerMode.Default and self.modeTime ~= -1 and Shared.GetTime() > self.modeTime) then
    
        if(not self:ProcessEndMode()) then
        
            self.mode = kPlayerMode.Default
            self.modeTime = -1
            
        end

    end
    
end

function Player:UpdateWeapons(input)

    // Get list once a frame
    if not Shared.GetIsRunningPrediction() then
    
        self:ComputeHUDOrderedWeaponList()

        // Call ProcessMove on all our weapons so they can update properly
        for index, weapon in ipairs(self.hudOrderedWeaponList) do
            weapon:OnProcessMove(self, input)
        end
        
    end
        
end

function Player:ProcessEndMode()

    if(self.mode == kPlayerMode.Knockback) then
    
        self:SetAnimAndMode("standup", kPlayerMode.StandUp)
        
        // No anim yet, set modetime manually
        self.modeTime = 1.25
        return true
        
    end
    
    return false
end

function Player:GetMaxSpeed()

    // Take into account crouching
    return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * Player.kWalkMaxSpeed
        
end

function Player:GetAcceleration()
    return Player.kAcceleration
end

// Maximum speed a player can move backwards
function Player:GetMaxBackwardSpeedScalar()
    return Player.kWalkBackwardSpeedScalar
end

/**
 * Don't allow full air control but allow players to especially their movement in the opposite way they are moving (airmove).
 */
function Player:ConstrainMoveVelocity(wishVelocity)
    
    if not self:GetIsOnLadder() and not self:GetIsOnGround() and wishVelocity:GetLengthXZ() > 0 and self:GetVelocity():GetLengthXZ() > 0 then
    
        local normWishVelocity = GetNormalizedVectorXZ(wishVelocity)
        local normVelocity = GetNormalizedVectorXZ(self:GetVelocity())
        local scalar = Clamp((1 - normWishVelocity:DotProduct(normVelocity)) * .4, 0, 1)
        
        wishVelocity:Scale(scalar)

    end
    
end

function Player:GetCanJump()
    return self:GetIsOnGround()
end

function Player:GetJumpHeight()
    return Player.kJumpHeight
end

// If we jump, make sure to set self.timeOfLastJump to the current time
function Player:HandleJump(input, velocity)

    if self:GetCanJump() then
    
        // Compute the initial velocity to give us the desired jump
        // height under the force of gravity.
        velocity.y = math.sqrt(-2 * self:GetJumpHeight() * self:GetGravityForce(input))         

        if not Shared.GetIsRunningPrediction() then
            self:TriggerEffects("jump", {surface = self:GetMaterialBelowPlayer()})
        end
        
        // TODO: Set this somehow (set on sounds for entity, not by sound name?)
        //self:SetSoundParameter(soundName, "speed", self:GetFootstepSpeedScalar(), 1)
        
        self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimStartJump))
        
        self.timeOfLastJump = Shared.GetTime()
        
        self.onGroundNeedsUpdate = true
               
    end
    
    // Jumping while on a ladder cancels being on the ladder
    if self:GetIsOnLadder() then
    
        self:SetIsOnLadder(false)
        
    end

end

function Player:OnTag(tagName)

    //Print("%s:OnTag(%s)(play footsteps: %s)", self:GetClassName(), tagName, ToString(self:GetPlayFootsteps()))

    LiveScriptActor.OnTag(self, tagName)

    // Play footstep when foot hits the ground
    if(string.lower(tagName) == "step" and self:GetPlayFootsteps()) then
    
        self.leftFoot = not self.leftFoot
        self:TriggerEffects("footstep", {surface = self:GetMaterialBelowPlayer(), left = self.leftFoot})
        
    end
    
end

function Player:GetMaterialBelowPlayer()
    local fixedOrigin = Vector(self:GetOrigin())
    // Start the trace a bit above the very bottom of the origin because
    // of cases where a large velocity has pushed the origin below the
    // surface the player is on
    fixedOrigin.y = fixedOrigin.y + self:GetExtents().y / 2
    local trace = Shared.TraceRay(fixedOrigin, fixedOrigin + Vector(0, -(2.5*self:GetExtents().y + .1), 0), PhysicsMask.AllButPCs, EntityFilterOne(self))
    return trace.surface
end

function Player:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / self:GetMaxSpeed(), 0, 1)
end

function Player:CanDrawWeapon()
    return true
end

function Player:HandleAttacks(input)

    if (bit.band(input.commands, Move.PrimaryAttack) ~= 0) then
    
        self:PrimaryAttack()
        
    else
    
        if self.primaryAttackLastFrame then
        
            self:PrimaryAttackEnd()
            
        end
        
    end

    if (bit.band(input.commands, Move.SecondaryAttack) ~= 0) then
    
        self:SecondaryAttack()
        
    else
    
        if(self.secondaryAttackLastFrame ~= nil and self.secondaryAttackLastFrame) then
        
            self:SecondaryAttackEnd()
            
        end
        
    end

    // Remember if we attacked so we don't call AttackEnd() until mouse button is released
    self.primaryAttackLastFrame = (bit.band(input.commands, Move.PrimaryAttack) ~= 0)
    self.secondaryAttackLastFrame = (bit.band(input.commands, Move.SecondaryAttack) ~= 0)
    
end

function Player:GetPrimaryAttackLastFrame()
    return self.primaryAttackLastFrame
end

function Player:GetSecondaryAttackLastFrame()
    return self.secondaryAttackLastFrame
end

// Children can add or remove velocity according to special abilities, modes, etc.
function Player:ModifyVelocity(input, velocity)   

    PROFILE("Player:ModifyVelocity")
    
    // Must press jump multiple times to get multiple jumps 
    if (bit.band(input.commands, Move.Jump) ~= 0) and not self.jumpHandled then
    
        self:HandleJump(input, velocity)
        self.jumpHandled = true
    
    elseif self:GetIsOnLadder() then
    
        // No other velocity when on a ladder
        velocity.x = 0
        velocity.z = 0
    
    elseif self:GetIsOnGround() then
    
        //Print("Setting velocity y to 0 (was %.2f)", velocity.y)

        velocity.y = 0
    
    end
    
end

function Player:HandleButtons(input)

    PROFILE("Player:HandleButtons")
    
    if not Shared.GetIsRunningPrediction() then
    
        if (bit.band(input.commands, Move.Use) ~= 0) then
            self:Use()
        end
           
        // Player is bringing up the buy menu (don't toggle it too quickly)
        if (bit.band(input.commands, Move.Buy) ~= 0 and Shared.GetTime() > (self.timeLastMenu + .3)) then
        
            self:Buy()
            self.timeLastMenu = Shared.GetTime()
            
        end
        
        // When exit hit, bring up menu
        if (bit.band(input.commands, Move.Exit) ~= 0 and (Shared.GetTime() > (self.timeLastMenu + .3)) and (Client ~= nil)) then
            ExitPressed()
            self.timeLastMenu = Shared.GetTime()
        end
        
    end
        
    // Remember when jump released
    if (bit.band(input.commands, Move.Jump) == 0) then
        self.jumpHandled = false
    end
    
    self:HandleAttacks(input)
        
    if (bit.band(input.commands, Move.NextWeapon) ~= 0) then
        self:SelectNextWeapon()
    end
    
    if (bit.band(input.commands, Move.PrevWeapon) ~= 0) then
        self:SelectPrevWeapon()
    end
    
    if (bit.band(input.commands, Move.Reload) ~= 0) then
        self:Reload()
    end

    if ( bit.band(input.commands, Move.Drop) ~= 0 and self.Drop ) then
        self:Drop()
    end
    
    if ( bit.band(input.commands, Move.Taunt) ~= 0 ) then
        self:Taunt()
    end

    // Weapon switch
    if (bit.band(input.commands, Move.Weapon1) ~= 0) then
        self:SwitchWeapon(1)
    end
    
    if (bit.band(input.commands, Move.Weapon2) ~= 0) then
        self:SwitchWeapon(2)
    end
    
    if (bit.band(input.commands, Move.Weapon3) ~= 0) then
        self:SwitchWeapon(3)
    end
    
    if (bit.band(input.commands, Move.Weapon4) ~= 0) then
        self:SwitchWeapon(4)
    end
    
    if (bit.band(input.commands, Move.Weapon5) ~= 0) then
        self:SwitchWeapon(5)
    end

    local newCrouchState = (bit.band(input.commands, Move.Crouch) ~= 0)
    if(self.crouching ~= newCrouchState) then
        self:SetCrouchState(newCrouchState)
    end
    
    if Client then
        self:ShowMap(bit.band(input.commands, Move.ShowMap) ~= 0)
    end
        
end

function Player:SetCrouchState(newCrouchState)
   
    self.crouching = newCrouchState
    self.timeOfCrouchChange = Shared.GetTime()
    self.timeLegalCrouchTime = Shared.GetTime()

end

function Player:GetFrictionForce(input, velocity)
    
    local frictionScalar = 0

    // Don't apply friction when we're moving on the ground,
    // it affects our max speed too much. Just bring us to a stop
    // when we stop trying to move.
    if(self:GetIsOnGround() and input.move:GetLength() == 0) then
        frictionScalar = 8
    end
    
    local scaleVelY = 0
    if(self:GetIsOnLadder()) then
        frictionScalar = 8
        scaleVelY = -velocity.y
    end
    
    //if(self.mode ~= kPlayerMode.Default) then
    //    frictionScalar = 10
    //end
    
    return Vector(-velocity.x, scaleVelY, -velocity.z) * frictionScalar
    
end

function Player:GetGravityForce(input)
    return Player.kGravity 
end

function Player:OnBuy()
end

function Player:GetNotEnoughResourcesSound()
    return Player.kNotEnoughResourcesSound    
end

// Get list of weapons in order displayed on HUD
function Player:ComputeHUDOrderedWeaponList()

    local childEntities = GetChildEntities(self, "Weapon")
        
    // Sort weapons
    function sort(weapon1, weapon2)
        return weapon2:GetHUDSlot() > weapon1:GetHUDSlot()
    end
    
    table.sort(childEntities, sort)
        
    self.hudOrderedWeaponList = childEntities
    
end   

function Player:GetHUDOrderedWeaponList()

    if self.hudOrderedWeaponList == nil then
        self:ComputeHUDOrderedWeaponList()
    end
    
    return self.hudOrderedWeaponList
    
end

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function Player:SetActiveWeapon(weaponMapName)

    local weaponList = self:GetHUDOrderedWeaponList()
    
    for index, weapon in ipairs(weaponList) do
    
        local mapName = weapon:GetMapName()

        if (mapName == weaponMapName) then
        
            local newWeapon = weapon
            local activeWeapon = self:GetActiveWeapon()
            
            if (activeWeapon == nil or activeWeapon:GetMapName() ~= weaponMapName) then
            
                local previousWeaponName = ""
                
                if activeWeapon then
                
                    activeWeapon:OnHolster(self)
                    activeWeapon:SetIsVisible(false)
                    previousWeaponName = activeWeapon:GetMapName()
                    
                end

                // Set active first so proper anim plays
                self.activeWeaponIndex = index
                
                newWeapon:SetIsVisible(true)
                
                // Always allow player to draw weapon
                self:ClearActivity()
                
                newWeapon:OnDraw(self, previousWeaponName)

                return true
                
            end
            
        end
        
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon ~= nil and activeWeapon:GetMapName() == weaponMapName then
        return true
    end
    
    Print("%s:SetActiveWeapon(%s) failed", self:GetClassName(), weaponMapName)
    
    return false

end

function Player:GetIsCommander()
    return false
end

// SwitchWeapon or choose option from sayings menu if open
// weaponindex starts at 1
function Player:SwitchWeapon(weaponIndex)

    local success = false
    
    if( not self:GetIsCommander()) then
        
        local weaponList = self:GetHUDOrderedWeaponList()
        
        if(weaponIndex >= 1 and weaponIndex <= table.maxn(weaponList)) then
        
            success = self:SetActiveWeapon(weaponList[weaponIndex]:GetMapName())
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()
            
        end
        
    end
    
    return success
    
end

// Children should override with specific menu actions
function Player:ExecuteSaying(index, menu)
    self.executeSaying = index
end

function Player:GetAndClearSaying()
    if(self.executeSaying ~= nil) then
        local saying = self.executeSaying
        self.executeSaying = nil
        return saying
    end
    return nil
end

/**
 * Returns the view model entity.
 */
function Player:GetViewModelEntity()    

    if Server then
    if self.viewModelId == Entity.invalidId then
        self:InitViewModel()    
    end
    end
    
    return Shared.GetEntity(self.viewModelId)
    
end

/**
 * Sets the model currently displayed on the view model.
 */
function Player:SetViewModel(viewModelName, weapon)
    local viewModel = self:GetViewModelEntity()
    if viewModel then
        viewModel:SetModel(viewModelName, weapon)
    else
        Print("%s:SetViewModel(%s): View model nil", self:GetClassName(), ToString(viewModelName))
    end
end

function Player:OnAnimationComplete(animName)

    LiveScriptActor.OnAnimationComplete(self, animName)

    if(animName == Player.kAnimTaunt and not self.thirdPerson) then
        self.desiredCameraDistance = 0 
    end
    
end

function Player:GetTauntSound()
    return Player.kInvalidSound
end

function Player:GetTauntAnimation()
    return Player.kAnimTaunt
end

function Player:Taunt()

    if (self:GetAnimation() ~= Player.kAnimTaunt and self:GetIsOnGround()) then
    
        // Play taunt animation and sound
        self:SetAnimAndMode(self:GetTauntAnimation(), kPlayerMode.Taunt)
        
        Shared.PlaySound(self, self:GetTauntSound())

        //self:SetDesiredCameraDistance( ConditionalValue(self.desiredCameraDistance > 0, 0, 5) )
        
    end
    
end

function Player:SetAnimAndMode(animName, mode)

    local force = (self.mode ~= mode)
    self:SetAnimationWithBlending(animName, self:GetBlendTime(), force)
    
    self.mode = mode
    
    self.modeTime = Shared.GetTime() + self:GetAnimationLength(animName)
       
end

function Player:GetCanBeUsed(player)
    return false
end

function Player:GetScore()
    return self.score
end

function Player:GetScoreboardChanged()
    return self.scoreboardChanged
end

// Set to true when score, name, kills, team, etc. changes so it's propagated to players
function Player:SetScoreboardChanged(state)
    self.scoreboardChanged = state
end

function Player:GetTimeTargetHit()
    return self.timeTargetHit
end

function Player:GetReticleTarget()
    return self.reticleTarget
end

function Player:GetHasSayings()
    return false
end

function Player:GetSayings()
    return {}
end

// Index starts with 1
function Player:ChooseSaying(sayingIndex)
end

function Player:GetShowSayings()
    return self.showSayings
end

// Tooltips

// Check if we've already displayed this tooltip. Returns false if we haven't, or if time
// has expired since we've displayed
function Player:GetCanDisplayTooltip(tooltipText, timeInterval)

    local currentTime = Shared.GetTime()
    
    // Return false if we've recently added any tooltip
    if self.timeOfLastTooltip ~= nil and currentTime < (self.timeOfLastTooltip + Player.kToolTipInterval) then
    
        return false
        
    end
    
    // Return false if we've too recently shown this particular tooltip
    for index, entity in ipairs(self.displayedTooltips) do
    
        if(tooltipText == entity[1]) then
        
            if(timeInterval == nil or (currentTime < entity[2] + timeInterval)) then
            
                return false
                
            end
            
        end
        
    end
    
    return true
    
end

function Player:AddTooltipOnce(tooltipText)

    if(self:GetCanDisplayTooltip(tooltipText, nil)) then
    
        self:AddTooltip(tooltipText)
        return true
        
    end

    return false
    
end

function Player:AddTooltipOncePer(tooltipText, timeInterval)

    if(timeInterval == nil) then
        timeInterval = 10
    end
    
    if(self:GetCanDisplayTooltip(tooltipText, timeInterval)) then
    
        self:AddTooltip(tooltipText)
        
        return true
        
    end

    return false

end

function Player:AddDisplayedTooltip(tooltipText)
    table.insertunique(self.displayedTooltips, {tooltipText, Shared.GetTime()})
end

function Player:ClearDisplayedTooltips()
    table.clear(self.displayedTooltips)
end

function Player:UpdateHelp()
    return false
end

function Player:SpaceClearForEntity(position, printResults)

    local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
    local center = Vector(0, capsuleHeight * 0.5 + capsuleRadius, 0)
    
    local traceStart = position + center
    local traceEnd = traceStart + Vector(0, .1, 0)

    if capsuleRadius == 0 and printResults then    
        Print("%s:SpaceClearForEntity(): capsule radius is 0, returning true.", self:GetClassName())
        return true
    elseif capsuleRadius < 0 and printResults then
        Print("%s:SpaceClearForEntity(): capsule radius is %.2f.", self:GetClassName(), capsuleRadius)
    end
    
    local trace = Shared.TraceCapsule(traceStart, traceEnd, capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    if trace.fraction ~= 1 and printCollision then
        Print("%s:SpaceClearForEntity: Hit %s", self:GetClassName(), SafeClassName(trace.entity))
    end
    
    return (trace.fraction == 1)
    
end

function Player:GetChatSound()
    return Player.kChatSound
end

function Player:GetNumHotkeyGroups()
    
    local numGroups = 0
    
    for i = 1, Player.kMaxHotkeyGroups do
    
        if (table.count(self.hotkeyGroups[i]) > 0) then
        
            numGroups = numGroups + 1
            
        end
        
    end
    
    return numGroups

end

function Player:GetHotkeyGroups()
    return self.hotkeyGroups
end

function Player:GetVisibleWaypoint()
    return self.finalWaypoint
end

// Player is incapacitated briefly
function Player:Knockback(velocity)

    // Apply force
    self:SetVelocity(self:GetVelocity() + velocity)
    
    // Play animation - can't do anything until we've gotten up
    self:SetAnimAndMode("knockback", kPlayerMode.Knockback)
    
    // No animation yet, so set mode time manually
    self.modeTime = 1.25
    
end

function Player:GetCanDoDamage()
    return true
end


Shared.LinkClassToMap("Player", Player.kMapName, networkVars )