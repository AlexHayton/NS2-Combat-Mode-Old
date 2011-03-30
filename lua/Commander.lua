// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Player.lua")
Script.Load("lua/Globals.lua")

class 'Commander' (Player)
Commander.kMapName = "commander"

Script.Load("lua/Commander_Hotkeys.lua")

Commander.kSpendCarbonSoundName = PrecacheAsset("sound/ns2.fev/marine/common/comm_spend_metal")
Commander.kSpendPlasmaSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")

Commander.kSelectionCircleModelName = PrecacheAsset("models/misc/marine-build/marine-build.model")
Commander.kSentryOrientationModelName = PrecacheAsset("models/misc/sentry_arc/sentry_arc.model")
Commander.kSentryRangeModelName = PrecacheAsset("models/misc/sentry_arc/sentry_line.model")
Commander.kMarineCircleModelName = PrecacheAsset("models/misc/circle/circle.model")
Commander.kAlienCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

Commander.kSentryArcScale = 8

// Extra hard-coded vertical distance that makes it so we set our scroll position,
// we are looking at that point, instead of setting our position to that point)
Commander.kViewOffsetXHeight = 5
// Default height above the ground when there's no height map
Commander.kDefaultCommanderHeight = 11
Commander.kFov = 90
Commander.kScoreBoardDisplayDelay = .12

// Snap structures to attach points within this range
Commander.kAttachStructuresRadius = 5

Commander.kScrollVelocity = 40

// Snap structures within this range to attach points.
Commander.kStructureSnapRadius = 4

Script.Load("lua/Commander_Selection.lua")

if (Server) then
    Script.Load("lua/Commander_Server.lua")
else
    Script.Load("lua/Commander_Client.lua")
end

Commander.kMaxSubGroupIndex = 32

Commander.kSelectMode = enum( {'None', 'SelectedGroup', 'JumpedToGroup'} )

local networkVars = 
{
    timeScoreboardPressed   = "float",
    focusGroupIndex         = string.format("integer (0 to %d)", Commander.kMaxSubGroupIndex - 1),
    numIdleWorkers          = string.format("integer (0 to %d)", kMaxIdleWorkers),
    numPlayerAlerts         = string.format("integer (0 to %d)", kMaxPlayerAlerts),
    commanderCancel         = "boolean",
    commandStationId        = "entityid",
    // Set to a number after a hotgroup is selected, so we know to jump to it next time we try to select it
    positionBeforeJump      = "vector",
    selectMode              = "enum Commander.kSelectMode"
}

function Commander:OnInit()

    Player.OnInit(self)

    self.selectedEntities = {}
    
    self.selectedSubGroupEntities = {}

    self:SetIsVisible(false)
    
    self:SetDefaultSelection()
    
    if(Client) then

        self.drawResearch = false
        
        // Remember which buttons are down.
        self.mouseButtonDown = {false, false, false}
        // Start off assuming all buttons are up.
        self.mouseButtonUpSinceAction = {true, true, true}
        
        self.specifyingOrientation = false
        self.orientationAngle = 0
        self.specifyingOrientationPosition = Vector(0, 0, 0)
        
        self.scrollX = 0
        self.scrollY = 0
       
        self.timeSinceUpdateMenu = 0
                
    end
    
    if(Server) then
    
        self.smoothCamera = false
        
        self:SetFov(Commander.kFov)

        // Wait a short time before sending hotkey groups to make sure
        // client has been replaced by commander
        self.timeToSendHotkeyGroups = Shared.GetTime() + .5
        
        self.alerts = {}
        
    end

    self.timeScoreboardPressed = 0
    self.focusGroupIndex = 0
    self.numIdleWorkers = 0
    self.numPlayerAlerts = 0
    self.positionBeforeJump = Vector(0, 0, 0)
    self:SetSelectMode(Commander.kSelectMode.None)
    self.commandStationId = Entity.invalidId
    
end

function Commander:SetSelectMode(mode)
    if mode ~= self.selectMode then
        self.selectMode = mode
    end
end

// Needed so player origin is same as camera for selection
function Commander:GetViewOffset()
    return Vector(0, 0, 0)
end

function Commander:GetMaxViewOffsetHeight()
    return 0
end

function Commander:GetTeamType()
    return kNeutralTeamType
end

function Commander:HandleButtons(input)
  
    PROFILE("Commander:HandleButtons")
    
    // Set Commander orientation to looking down but not straight down for visual interest
    local yawDegrees    = 90
    local pitchDegrees  = 70
    local angles        = Angles((pitchDegrees/90)*math.pi/2, (yawDegrees/90)*math.pi/2, 0)   
    
    // Update to the current view angles.
    self:SetViewAngles(angles)
    
    // Update shift order drawing/queueing
    self.queuingOrders = (bit.band(input.commands, Move.MovementModifier) ~= 0)
    self.controlClick = (bit.band(input.commands, Move.Crouch) ~= 0)
    
    // Check for commander cancel action. It is reset in the flash hook to make 
    // sure it's recognized.
    if(bit.band(input.commands, Move.Exit) ~= 0) then
        // TODO: If we have nothing to cancel, bring up menu
        //ShowInGameMenu()
        self.commanderCancel = true
    end
    
    self:HandleCommanderHotkeys(input)
    
    self:HandleScoreboardSubgroups(input)
    
    if Client then
        self:ShowMap(bit.band(input.commands, Move.ShowMap) ~= 0)
    end
    
end

// Handle sub-group selection
function Commander:HandleScoreboardSubgroups(input)

    // If player holds scoreboard key (tab), show scores. If they tap it, switch
    // focus to next sub-group within selection
    if (bit.band(input.commands, Move.Scoreboard) ~= 0) then
    
        if self.timeScoreboardPressed == 0 then
            self.timeScoreboardPressed = Shared.GetTime()
        end
        
        if Shared.GetTime() > (self.timeScoreboardPressed + Commander.kScoreBoardDisplayDelay) then
            self.showScoreboard = true
        end
    
    else
    
        // If we're showing scoreboard, hide it
        if self.showScoreboard then
        
            self.showScoreboard = false

        elseif self.timeScoreboardPressed ~= 0 then
        
            // else switch to next sub group
            self.focusGroupIndex = ( self.focusGroupIndex + 1 ) % Commander.kMaxSubGroupIndex
            
        end
        
        self.timeScoreboardPressed = 0
        
    end

end

function Commander:UpdateCrouch()
end

function Commander:UpdateViewAngles()
end

// Move commander without any collision detection
function Commander:UpdatePosition(velocity, time)

    PROFILE("Commander:UpdatePosition")

    local offset = velocity * time
    
    if self.controller then
    
        self:UpdateControllerFromEntity()
        
        self.controller:SetPosition(self:GetOrigin() + offset)

        self:UpdateOriginFromController()

    end    

end

function Commander:UpdateMovePhysics(input)

    PROFILE("Commander:UpdateMovePhysics")
    
    local finalPos = Vector()
    
    local heightmap = self:GetHeightmap()
    // If minimap clicked, go right to that position
    if (bit.band(input.commands, Move.Minimap) ~= 0) then

        // Translate from panel coords to world coordinates described by minimap
        if(heightmap ~= nil) then
            
            // Store normalized minimap coords in yaw and pitch
            finalPos = Vector(heightmap:GetWorldX(tonumber(input.pitch)), 0, heightmap:GetWorldZ(tonumber(input.yaw)))
            
            // Add in extra x offset to center view where we're told, not ourselves
            finalPos.x = finalPos.x - Commander.kViewOffsetXHeight
            
        end

        self:SetSelectMode(Commander.kSelectMode.None)
        
    // Returns true if player jumped to a hotkey group
    elseif not self:ProcessNumberKeysMove(input, finalPos) then
    
        local angles = self:GetViewAngles()
        local moveVelocity = angles:GetCoords():TransformVector( input.move ) * Commander.kScrollVelocity
        
        // Set final position (no collision)
        finalPos = self:GetOrigin() + moveVelocity * input.time

        self:SetSelectMode(Commander.kSelectMode.None)
        
    end
    
    // Set commander height according to height map (allows commander to move off height map, but uses clipped values to determine height)
    if(heightmap ~= nil) then
    
        finalPos.x = heightmap:ClampXToMapBounds(finalPos.x)
        finalPos.z = heightmap:ClampZToMapBounds(finalPos.z)
        finalPos.y = heightmap:GetElevation(finalPos.x, finalPos.z) + Commander.kDefaultCommanderHeight

    else
    
        // If there's no height map, trace to the ground and hover a set distance above it 
        // Doesn't update height if nothing was hit
        local belowComm = Vector(self:GetOrigin())
        belowComm.y = belowComm.y - 50
        
        local trace = Shared.TraceRay(self:GetOrigin(), belowComm, PhysicsMask.CommanderSelect, EntityFilterOne(self))
        
        if trace.fraction < 1 then
            finalPos.y = trace.endPoint.y + Commander.kDefaultCommanderHeight
        end
        
    end
        
    self:SetOrigin(finalPos)
    
    self:SetVelocity(Vector(0, 0, 0))
            
end

function Commander:UpdateAnimation(timePassed)
end

function Commander:GetNumIdleWorkers()
    return self.numIdleWorkers
end

function Commander:GetNumPlayerAlerts()
    return self.numPlayerAlerts
end

function Commander:UpdateMisc(input)

    PROFILE("Commander:UpdateMisc")

    if Server then
        self:UpdateNumIdleWorkers()
        self:UpdateAlerts()
    end
    
    if Client then
        self:UpdateChat(input)
    end
    
end

// Returns true if it set our position
function Commander:ProcessNumberKeysMove(input, newPosition)

    local setPosition = false
    local number = 0
    
    if (bit.band(input.commands, Move.Weapon1) ~= 0) then
        number = 1
    elseif (bit.band(input.commands, Move.Weapon2) ~= 0) then
        number = 2
    elseif (bit.band(input.commands, Move.Weapon3) ~= 0) then
        number = 3
    elseif (bit.band(input.commands, Move.Weapon4) ~= 0) then
        number = 4
    elseif (bit.band(input.commands, Move.Weapon5) ~= 0) then
        number = 5
    end
    
    if (number ~= 0) then
    
        if (bit.band(input.commands, Move.Crouch) ~= 0) then
        
            if Server then
                self:CreateHotkeyGroup(number)
            end
            
        // Make sure we're not selection a squad
        elseif (bit.band(input.commands, Move.MovementModifier) == 0) then
        
            // Temporarily removed jumping to a hotkey group because it doesn't work well
            if self.selectMode == Commander.kSelectMode.None then
            
                self:SelectHotkeyGroup(number)
                
                self.positionBeforeJump = Vector(self:GetOrigin())
                self:SetSelectMode(Commander.kSelectMode.SelectedGroup)
                self.gotoHotKeyGroup = number
                setPosition = true
                
            // Jump to position of hotkey group
            elseif self.selectMode == Commander.kSelectMode.SelectedGroup then
            
                self:GotoHotkeyGroup(number, newPosition)
                self:SetSelectMode(Commander.kSelectMode.JumpedToGroup)
                setPosition = true

            // Jump back to our last position if hit again
            else
            
                self:SetOrigin(self.positionBeforeJump)
                self:SetSelectMode(Commander.kSelectMode.SelectedGroup)
                setPosition = true
                
            end
                
        end
        
    end
    
    return setPosition
    
end

function Commander:GetIsCommander()
    return true
end

function Commander:GetOrderConfirmedEffect()
    return ""
end

/**
 * Returns the x-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionX()
    local scrollPositionX = 1
    local heightmap = self:GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionX = heightmap:GetMapX( self:GetOrigin().z )
    end
    return scrollPositionX
end

/**
 * Returns the y-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionY()
    local scrollPositionY = 1
    local heightmap = self:GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionY = heightmap:GetMapY( self:GetOrigin().x + Commander.kViewOffsetXHeight )
    end
    return scrollPositionY
end

// For making top row the same. Marine commander overrides to set top four icons to always be identical.
function Commander:GetTopRowTechButtons()
    return {}
end

function Commander:GetSelectionRowsTechButtons(menuTechId)
    return {}
end

function Commander:GetCurrentTechButtons(techId, entity)

    local techButtons = {}

    local topRowTechButtons = self:GetTopRowTechButtons()
    if topRowTechButtons then
        table.copy(topRowTechButtons, techButtons, true)
    end
    
    local selectedTechButtons = entity:GetTechButtons(techId)
    if not selectedTechButtons then
        selectedTechButtons = self:GetSelectionRowsTechButtons(techId)
    end
    if selectedTechButtons then
        table.copy(selectedTechButtons, techButtons, true)
    end
    
    return techButtons

end

// Updates hotkeys to account for entity changes. Pass both parameters to indicate
// that an entity has changed (ie, a player has changed class), or pass nil
// for newEntityId to indicate an entity has been destroyed.
function Commander:OnEntityChange(oldEntityId, newEntityId)
    
    // Replace old object with new one if selected
    local newSelection = {}
    table.copy(self.selectedEntities, newSelection)
    
    local selectionChanged = false
    for index, pair in ipairs(newSelection) do

        if pair[1] == oldEntityId then
        
            if newEntityId then
                pair[1] = newEntityId
            else
                table.remove(newSelection, index)                
            end  
            
            selectionChanged = true
            
        end
        
    end
    
    if selectionChanged then
        self:InternalSetSelection(newSelection)
    end
    
    // Hotkey groups are handled in player.
    Player.OnEntityChange(self, oldEntityId, newEntityId)
   
end

function Commander:GetIsEntityNameSelected(className)

    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        // Don't allow it to be researched while researching
        if( entity ~= nil and entity:isa(className) ) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Commander:OnUpdate(deltaTime)

    Player.OnUpdate(self, deltaTime)

    // Remove selected units that are no longer valid for selection
    self:UpdateSelection(deltaTime)
    
    if Server then
    
        self:UpdateHotkeyGroups()
        self:UpdateTeamHarvesterCount()
      
    end
        
end

// Draw waypoint of selected unit as our own as quick ability for commander to see results of orders
function Commander:GetVisibleWaypoint()

    if self.selectedEntities and table.count(self.selectedEntities) > 0 then
    
        local ent = Shared.GetEntity(self.selectedEntities[1][1])
        
        if ent and ent:isa("Player") then
        
            return ent:GetVisibleWaypoint()
            
        end
        
    end
    
    return Player.GetVisibleWaypoint(self)
    
end

function Commander:GetHostCommandStructure()
    return Shared.GetEntity(self.commandStationId)
end

function Commander:GetCanDoDamage()
    return false
end

Shared.LinkClassToMap( "Commander", Commander.kMapName, networkVars )
