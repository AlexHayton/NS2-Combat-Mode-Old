// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Commander_Alerts.lua")
Script.Load("lua/Commander_Buttons.lua")
Script.Load("lua/Commander_FocusPanel.lua")
Script.Load("lua/Commander_HotkeyPanel.lua")
Script.Load("lua/Commander_IdleWorkerPanel.lua")
Script.Load("lua/Commander_ResourcePanel.lua")
Script.Load("lua/Commander_SelectionPanel.lua")
Script.Load("lua/Commander_SquadsPanel.lua")

// Keeping this in for a while as I expect some further work may be required
// on mouse over UI detection soon
function CommanderUI_UpdateMouseOverUIStateDI(name, X, Y, width, height, alpha)

    Shared.Message("name: " .. name .. " X: " .. X .. " Y: " .. Y .. " width: " .. width .. " height: " .. height .. " alpha: " .. alpha)

end

function CommanderUI_UpdateMouseOverUIState(overUI)

    local player = Client.GetLocalPlayer()
    player.cursorOverUI = overUI

end

// These are the icons that appear next to alerts or as hotkey icons.
// Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImage()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return "alien_buildmenu"
    end
    
    return "marine_buildmenu"
    
end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1024
    end
    
    return 960, 960
    
end

function CommanderUI_IsAlienCommander()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return true
    end
    
    return false
    
end

function CommanderUI_MapImage()
    return "map"
end

/**
 * Return width of view in geometry space.
 */
function CommanderUI_MapViewWidth()
    return 1
end

/**
 * Return height of view in geometry space.
 */
function CommanderUI_MapViewHeight()
    return 1
end

/**
 * Return x center of view in geometry coordinate space.
 */
function CommanderUI_MapViewCenterX()
    local player = Client.GetLocalPlayer()        
    return player:GetScrollPositionX()
end

/**
 * Return y center of view in geometry coordinate space
 */
function CommanderUI_MapViewCenterY()
    local player = Client.GetLocalPlayer()        
    return player:GetScrollPositionY()
end

/**
 * Return horizontal scale (geometry/pixel)       
 */
function CommanderUI_MapLayoutHorizontalScale()
    return GetMinimapHorizontalScale(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Return vertical scale (geometry/pixel).
 */
function CommanderUI_MapLayoutVerticalScale()
    return GetMinimapVerticalScale(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function CommanderUI_MapLayoutPlayableWidth()
    return GetMinimapPlayableWidth(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function CommanderUI_MapLayoutPlayableHeight()
    return GetMinimapPlayableHeight(Client.GetLocalPlayer():GetHeightmap())
end

// Coords coming in are in terms of playable width and height
// Ie, not 0,0 to 1,1 most of the time, but for a vertical map, perhaps 0 to .4 for xc
// and 0 to 1 for yc.
function CommanderUI_MapMoveView(xc, yc)

    // Scroll map with left-click
    local player = Client.GetLocalPlayer()        
    local normX, normY = GetMinimapNormCoordsFromPlayable(player:GetHeightmap(), xc, yc)
    
    player:SetScrollPosition(normX, normY)

end

// x and y are the normalized map coords just like CommanderUI_MapMoveView(xc, yc).
// button is 0 for LMB, 1 for RMB
// Index is the button index whose targeting mode we're in (only if button == 0, nil otherwise)
function CommanderUI_MapClicked(x, y, button, index)

    // Translate minimap coords to world position
    local player = Client.GetLocalPlayer()
    local worldCoords = MinimapToWorld(player, x, y)
    
    if button == 0 then
    
        if index ~= nil then

            player:SendTargetedActionWorld(GetTechIdFromButtonIndex(index), worldCoords)
            
        else
            Print("CommanderUI_MapClicked(x, y, button, index) called with button 0 and no button index.")
        end        
        
    // Give default order with right-click
    elseif button == 1 then
    
        player:SendTargetedActionWorld(kTechId.Default, worldCoords)
        player.timeMinimapRightClicked = Shared.GetTime()
            
    end
    
end

function CommanderUI_OnMousePressGOBRIAN(mouseButton, x, y)

    local player = Client.GetLocalPlayer()
    player:ClientOnMousePress(mouseButton, x, y)
    
end

function CommanderUI_OnMouseReleaseGOBRIAN(mouseButton, x, y)

    local player = Client.GetLocalPlayer()
    
    // The .swf gives us both minimap and mouse release events, so don't process this one again
    if mouseButton ~= 1 or (player.timeMinimapRightClicked == nil or (Shared.GetTime() > (player.timeMinimapRightClicked + .2))) then
        player:ClientOnMouseRelease(mouseButton, x, y)
    end
    
end

/** 
 * Called from flash to determine if a tech on the button triggers instantly
 * or if it will look for a second mouse click afterwards.
 */
function CommanderUI_MenuButtonRequiresTarget(index)

    local techId = GetTechIdFromButtonIndex(index)
    local techTree = GetTechTree()
    local requiresTarget = false
    
    if(tech ~= 0 and techTree) then
    
        local techNode = techTree:GetTechNode(techId)
        
        if(techNode ~= nil) then
        
            // Buy nodes require a target for the commander
            requiresTarget = techNode:GetRequiresTarget() or techNode:GetIsBuy()
            
        end
        
    end
        
    return requiresTarget
    
end

// Returns nil or the index into the menu button array if the player
// just pressed a hotkey. The hotkey hit will always be set to nil after
// this function is called to make sure it's only triggered once.
function CommanderUI_HotkeyTriggeredButton()

    local hotkeyHit = nil
    local player = Client.GetLocalPlayer()
    
    if player.hotkeyIndexHit ~= nil then
    
        hotkeyHit = player.hotkeyIndexHit
        player.hotkeyIndexHit = nil
        
    end
    
    return hotkeyHit
    
end

function Commander:SetHotkeyHit(index)
    self.hotkeyIndexHit = index
end

function Commander:OnDestroy()

    Player.OnDestroy(self)

    local player = Client.GetLocalPlayer()
    
    if self == player or player == nil then
    
        RemoveFlashPlayer(kClassFlashIndex)
        
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderAlerts")
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderManager")
        
        self:DestroyGhostStructure()
        self:DestroySelectionCircles()
        self:DestroyGhostGuides()
        
        Client.DestroyRenderModel(self.unitUnderCursorRenderModel)
        
    end
    
end

function Commander:DestroySelectionCircles()
    
    // Delete old circles, if any
    if self.selectionCircles ~= nil then
    
        for index, circlePair in ipairs(self.selectionCircles) do
            Client.DestroyRenderModel(circlePair[2])
        end
        
    end
    
    self.selectionCircles = {}

end

// Creates ghost structure that is positioned where building would go
function Commander:CreateGhostStructureIfNeeded(techId)

    local techNode = GetTechNode(techId)
    
    if(techNode ~= nil and (techNode:GetIsBuild() or techNode:GetIsBuy())) then
    
        if(techId ~= self.ghostStructureId) then
        
            self:DestroyGhostStructure()
            
            local modelName = LookupTechData(techId, kTechDataModel)
            
            if(modelName ~= nil and self.ghostStructure == nil) then
            
                local modelIndex = Shared.GetModelIndex(modelName)
                self.ghostStructure = Client.CreateRenderModel(RenderScene.Zone_Default)
                
                self.ghostStructure:SetModel(modelIndex)
                self.ghostStructureId = techId
                self.ghostStructureValid = false
                                
            end
            
        end
    
    else
        self:DestroyGhostStructure()
    end
    
end

function Commander:AddGhostGuide(origin, radius)

    // Insert point, circle
    local guide = Client.CreateRenderModel(RenderScene.Zone_Default)
    local modelName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleModelName, Commander.kMarineCircleModelName)
    guide:SetModel(modelName)
    guide:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), origin + Vector(0, kZFightingConstant, 0), radius * 2))
    guide:SetIsVisible(true)
    
    table.insert(self.ghostGuides, {origin, guide})

end

// Check tech id and create guides showing where extractors, harvesters, infantry portals, etc. go. Also draw
// visual range for selected units if they are specified.
function Commander:UpdateGhostGuides()

    local kGhostGuideUpdateTime = .3

    // Only update every so often (update immediately after minimap click?)
    if self.timeOfLastGhostGuideUpdate == nil or Shared.GetTime() > self.timeOfLastGhostGuideUpdate + kGhostGuideUpdateTime then

        self:DestroyGhostGuides()
    
        local techId = self.ghostStructureId
        if techId ~= nil and techId ~= kTechId.None then
            
            // If entity can only be placed within range of attach structures, get all the ents that
            // count for this and draw circles around them
            local ghostRadius = LookupTechData(techId, kStructureAttachRange, 0)
            
            if ghostRadius ~= 0 then
            
                // Lookup attach entity 
                local attachId = LookupTechData(techId, kStructureAttachId)
                
                local supportingTechIds = GetTechTree():ComputeUpgradedTechIdsSupportingId(attachId)
                table.insert(supportingTechIds, attachId)
                
                for index, ent in ipairs(GetEntsWithTechId(supportingTechIds)) do
                
                    self:AddGhostGuide(Vector(ent:GetOrigin()), ghostRadius)
                
                end
                    
            else

                // Otherwise, draw only the free attach entities for this build tech (this is the common case)
                for index, ent in ipairs(GetFreeAttachEntsForTechId(techId)) do
                
                    self:AddGhostGuide(Vector(ent:GetOrigin()), Commander.kStructureSnapRadius)
                    
                end

            end
            
            // If attach range specified, then structures don't go on this attach point, but within this range of it            
            self.attachRange = LookupTechData(techId, kStructureAttachRange, nil)
            
        end
        
        // Now draw visual ranges for selected units
        for index, entityEntry in pairs(self.selectedEntities) do    
        
            // Draw visual range on structures that specify it (no building effects)
            local entity = Shared.GetEntity(entityEntry[1])
            if entity ~= nil then
            
                local visualRadius = LookupTechData(entity:GetTechId(), kStructureVisualRange, nil)
                
                if visualRadius ~= nil then
                    self:AddGhostGuide(Vector(entity:GetOrigin()), visualRadius)
                end
                
            end
            
        end
       
        self.timeOfLastGhostGuideUpdate = Shared.GetTime()
 
    end
    
end

function Commander:DestroyGhostGuides()

    if self.ghostGuides then
    
        for index, guide in ipairs(self.ghostGuides) do
        
            Client.DestroyRenderModel(guide[2])
            
        end
        
    end
        
    self.ghostGuides = {}
    
end

function Commander:DestroyGhostStructure()

    if(self.ghostStructure ~= nil) then
    
        Client.DestroyRenderModel(self.ghostStructure)
        self.ghostStructure = nil
        self.ghostStructureId = kTechId.None
        self.ghostStructureValid = nil
        
    end
    
end

// Update ghost structure position to show where building would go
function Commander:UpdateGhostStructure(x, y)

    if(self.ghostStructure ~= nil) then
           
        local valid, position, attachEntity = GetIsBuildPickVecLegal(self.ghostStructureId, self, CreatePickRay(self, x, y), Commander.kStructureSnapRadius)
        
        local coords = Coords.GetIdentity()
        
        if attachEntity then
            coords = attachEntity:GetAngles():GetCoords()
        end
        
        VectorCopy(position, coords.origin)        
        self.ghostStructure:SetCoords(coords)

        // TODO: Update color of ghost structure depending on valid
        self.ghostStructureValid = valid
        self.ghostStructure:SetIsVisible(valid)
        
    end

end

/** 
 * Flash should call this whenever we're in a mode like waiting for a target. If this returns true,
 * the action should be cancelled and the mode should be exited. For instance, if selecting a target
 * for an ability and CommanderUI_ActionCancelled() returns true, the menu should no longer highlight
 * that ability's button and mouse input should return to normal. This returns true when a player
 * triggers the CommCancel command.
 */
function CommanderUI_ActionCancelled()

    local player = Client.GetLocalPlayer()
    local cancelled = (player.commanderCancel ~= nil) and (player.commanderCancel == true)
    
    // Clear cancel after we trigger it
    player.commanderCancel = false
    
    player:DestroyGhostStructure()
    
    return cancelled
    
end

/**
 * Called when the user drags out a selection box. The coordinates are in
 * pixel space.
 */
function CommanderUI_SelectMarqueeGOBRIAN(selectStartX, selectStartY, selectEndX, selectEndY)
   
    local player = Client.GetLocalPlayer()        
    player:SelectMarquee(selectStartX, selectStartY, selectEndX, selectEndY)

end

/**
 * Called by Flash when the mouse is at the edge of the screen.
 */
function CommanderUI_ScrollViewGOBRIAN(deltaX, deltaY) 
   
    local player = Client.GetLocalPlayer()        
    player.scrollX = deltaX
    player.scrollY = deltaY

end

function GetTechIdFromButtonIndex(index)

    local techId = kTechId.None
    local player = Client.GetLocalPlayer()
    
    if(index <= table.count(player.menuTechButtons)) then
        techId = player.menuTechButtons[index]
    end
       
    return techId
    
end

function Commander:CloseMenu()

    if self.ghostStructureValid ~= nil then
        return self:DestroyGhostStructure()
    end
    
    return Player.CloseMenu(self)
    
end

// var mouseButton:Number = (_lbutton?1:0) + (_mbutton?4:0) + (_rbutton?2:0);
function CommanderUI_TargetedAction(index, x, y, button)

    local techId = GetTechIdFromButtonIndex(index)   
    local player = Client.GetLocalPlayer()
    local normalizedPickRay = CreatePickRay(player, x, y)
    
    if (player.ghostStructureValid == nil or player.ghostStructureValid == true) and button == 1 then
    
        // Send order target to where ghost structure is, in case it was snapped to an attach point
        if player.ghostStructureValid then

            local ghostOrigin = player.ghostStructure:GetCoords().origin
            local ghostScreenPos = Client.WorldToScreen(ghostOrigin)
            
            local pickRay = CreatePickRay(player, ghostScreenPos.x, ghostScreenPos.y)
            VectorCopy(pickRay, normalizedPickRay)
            
        end
        
        player:SendTargetedAction(techId, normalizedPickRay)
        player:DestroyGhostStructure()
        
    end
    
end

function CommanderUI_MousingAction(index, x, y)

    local player = Client.GetLocalPlayer()
    
    if(CommanderUI_MenuButtonRequiresTarget(index)) then
    
        local techId = GetTechIdFromButtonIndex(index)
        player:CreateGhostStructureIfNeeded(techId)
        player:UpdateGhostStructure(x, y)
        
    else
        player:DestroyGhostStructure()
    end

end

/**
 * Called to determine if target is valid for a targeted tech id. For example, this function
 * could return false when trying to place a medpack on an alien. 
 */
function CommanderUI_IsValid(button, x, y)

    // Check for valid structure placement
    local valid = false
    
    local player = Client.GetLocalPlayer()
    if player.ghostStructureId ~= nil and player.ghostStructureId ~= kTechId.None then

        // To allow canceling structures, esp. ones with attach points (this button index seems off by 1)
        if button == 2 then
            valid = true
        else
        
            local techNode = GetTechNode(player.ghostStructureId)
            if techNode ~= nil and (techNode:GetIsBuild() or techNode:GetIsBuy()) then
                valid = GetIsBuildPickVecLegal(player.ghostStructureId, player, CreatePickRay(player, x, y), Commander.kStructureSnapRadius)
            else
                valid = true
            end
            
        end
        
    else
        // Needed to make sure we can leave targeting mode
        valid = true        
    end
    
    return valid
    
end

/**
 * Returns a linear array of static blip data
 * X position, Y position, X texture offset, Y texture offset, kMinimapBlipType, kMinimapBlipTeam
 *
 * Eg {0.5, 0.5, 0, 0, 3, 1}
 */
function CommanderUI_GetStaticMapBlips()

    local blips = {}
    
    local commander = Client.GetLocalPlayer()
    local time = Shared.GetTime()
    
    for index, blipPair in ipairs(commander.minimapBlips) do
    
        local blip = blipPair[2]
        
        table.insert(blips, blip[2])
        table.insert(blips, blip[3])
        table.insert(blips, 0)
        table.insert(blips, 0)
        table.insert(blips, blip[4])
        table.insert(blips, blip[5])
        
    end    
    
    return blips
    
end

/**
 * Returns a linear array of dynamic blip data
 * These are ONE-SHOT, i.e. once a blip is requested 
 * from this function, it should be removed from the 
 * list of blips returned
 * from this function
 *
 * Data is formatted as:
 * X position, Y position, blip type
 *
 * Blip types - kAlertType
 * 
 * 0 - Attack
 * Attention-getting spinning squares that start outside the minimap and spin down to converge to point 
 * on map, continuing to draw at point for a few seconds).
 * 
 * 1 - Info
 * Research complete, area blocked, structure couldn't be built, etc. White effect, not as important to
 * grab your attention right away).
 * 
 * 2 - Request
 * Soldier needs ammo, asking for order, etc. Should be yellow or green effect that isn't as 
 * attention-getting as the under attack. Should draw for a couple seconds.)
 *
 * Eg {0.5, 0.5, 2} generates a request in the middle of the map
 */
function CommanderUI_GetDynamicMapBlips()

    return Client.GetLocalPlayer():GetAndClearAlertBlips()

end

function Commander:AddAlert(techId, worldX, worldZ, entityId, entityTechId)
    
    // Create alert blip
    local alertType = LookupTechData(techId, kTechDataAlertType, kAlertType.Info)
    local success, mapX, mapY = self:GetMapXY(worldX, worldZ)
    local xOffset, yOffset = self:GetMaterialXYOffset(entityTechId, self:isa("MarineCommander"))
    if success then
    
        table.insert(self.alertBlips, mapX)
        table.insert(self.alertBlips, mapY)
        table.insert(self.alertBlips, alertType - 1)
        
        // Create alert message => {text, icon x offset, icon y offset, -1, entity id}
        local alertText = LookupTechData(techId, kTechDataAlertText, "")
        table.insert(self.alertMessages, alertText)
        table.insert(self.alertMessages, xOffset)
        table.insert(self.alertMessages, yOffset)
        table.insert(self.alertMessages, entityId)
        table.insert(self.alertMessages, worldX)
        table.insert(self.alertMessages, worldZ)
        
    end
    
end

function Commander:GetAndClearAlertBlips()

    local alertBlips = {}
    table.copy(self.alertBlips, alertBlips)
    table.clear(self.alertBlips)
    return alertBlips
    
end

function Commander:GetAndClearAlertMessages()

    local alertMessages = {}
    table.copy(self.alertMessages, alertMessages)
    table.clear(self.alertMessages)
    return alertMessages

end

function Commander:OnBlipMessage(entityId, minimapNormX, minimapNormY, blipType, blipTeam)

    // Update blip if already have one with this id
    local existingBlipIndex = nil
    for index, blipPair in ipairs(self.minimapBlips) do
    
        if blipPair[2][1] == entityId then
        
            existingBlipIndex = index
            
            break
            
        end
        
    end

    // Update blip     
    if existingBlipIndex then
    
        local existingBlip = self.minimapBlips[existingBlipIndex]
        
        existingBlip[1] = Shared.GetTime()
        
        existingBlip[2][2] = minimapNormX
        existingBlip[2][3] = minimapNormY
        existingBlip[2][4] = blipType
        existingBlip[2][5] = blipTeam
    
    else
    
        // Insert as new blip pair: {time, {entityId, minimapNormX, minimapNormY, blipType, blipTeam}}
        table.insert(self.minimapBlips, {Shared.GetTime(), {entityId, minimapNormX, minimapNormY, blipType, blipTeam}})
    
    end
    
end

// Get rid of any old blips. Create new table because you can't delete entries out of old table easily!
function Commander:ExpireMinimapBlips()

    local newBlips = {}
    
    local time = Shared.GetTime()
    
    for index, blip in ipairs(self.minimapBlips) do

        // Don't expire blips immediately to account for networking delay    
        if time < (blip[1] + kMinimapBlipLifetime + .5) then
            table.insert(newBlips, blip)
        end
        
    end
    
    self.minimapBlips = newBlips
    
end

function Commander:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    self:SetupHud()
    
    // Turn off skybox rendering when commanding
    SetSkyboxDrawState(false)
    
    // Initialize offsets used for drawing tech ids as buttons
    self:InitTechTreeMaterialOffsets()
    
    // Set props invisible for Comm      
    SetCommanderPropState(true)
    
    // Turn off sound occlusion for Comm
    Client.SetSoundGeometryEnabled(false)
    
    // Set commander geometry invisible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, false)
    
    // Turn off fog to improve look
    Client.SetEnableFog(false)
    
    // Set our location so we are viewing the command structure we're in
    self:SetStartPosition() 

    self.selectionCircles = {}
    
    self.ghostGuides = {}
    
    self.alertBlips = {}
    
    self.alertMessages = {}
    
    self.cursorOverUI = false
    
    self.hotkeyAllowed = true

end

function Commander:SetStartPosition()

    local entId = FindNearestEntityId("CommandStructure", self:GetOrigin())
    local commandStructure = Shared.GetEntity(entId)
    if commandStructure ~= nil then
    
        local origin = commandStructure:GetOrigin()
        self:SetWorldScrollPosition(origin.x, origin.z)
        
    else
        Print("%s:SetStartPosition(): Couldn't find command structure to center view upon.", self:GetClassName())
    end
    
end

/**
 * Allow player to create a different move if desired (Client only).
 */
function Commander:OverrideInput(input)

    // Look for scroll commands and move position
    if (bit.band(input.commands, Move.ScrollForward) ~= 0) then self.scrollY = -1 end
    if (bit.band(input.commands, Move.ScrollBackward) ~= 0) then self.scrollY = 1 end
    if (bit.band(input.commands, Move.ScrollLeft) ~= 0) then self.scrollX = -1 end
    if (bit.band(input.commands, Move.ScrollRight) ~= 0) then self.scrollX = 1 end
    
    // Completely override movement and impulses
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0
    
    // Move to position if minimap clicked or idle work clicked
    if self.setScrollPosition then
    
        input.commands = Move.Minimap
        
        // Put in yaw and pitch because they are 16 bits
        // each. Without them we get a "settling" after
        // clicking the minimap due to differences after
        // sending to the server
        input.yaw = self.minimapNormX
        input.pitch = self.minimapNormY
        
        self.setScrollPosition = false

    else    
    
        input.move.x = -self.scrollX
        input.move.y = -self.scrollY

    end
    
    if (self.hotkeyGroupButtonPressed) then
    
        if (self.hotkeyGroupButtonPressed == 1) then
            input.commands = bit.bor(input.commands, Move.Weapon1)
        end            
            
        self.hotkeyGroupButtonPressed = nil
    end
    
    if (self.selectHotkeyGroup ~= 0) then
    
        // Process hotkey select and send up to server
        if self.selectHotkeyGroup == 1 then
            input.commands = bit.bor(input.commands, Move.Weapon1)
        elseif self.selectHotkeyGroup == 2 then
            input.commands = bit.bor(input.commands, Move.Weapon2)
        elseif self.selectHotkeyGroup == 3 then
            input.commands = bit.bor(input.commands, Move.Weapon3)
        elseif self.selectHotkeyGroup == 4 then
            input.commands = bit.bor(input.commands, Move.Weapon4)
        elseif self.selectHotkeyGroup == 5 then
            input.commands = bit.bor(input.commands, Move.Weapon5)
        end
    
        self.selectHotkeyGroup = 0
        
    end

end

// Called when commander is jumping to a world position (jumping to an alert, etc.)
function Commander:SetWorldScrollPosition(x, z)

    if self.heightmap then
   
        self.minimapNormX = self.heightmap:GetMapX( z )
        self.minimapNormY = self.heightmap:GetMapY( x )
        self.setScrollPosition = true
        
    end
    
end

// Called when minimap is clicked or scrolled. 0,0 is upper left, 1,1 is lower right
function Commander:SetScrollPosition(x, y)
    
    if self.heightmap then
    
        self.minimapNormX = x
        self.minimapNormY = y

        self.setScrollPosition = true
        
    end
    
end

function Commander:HotkeyGroupButtonPressed(index)
    self.hotkeyGroupButtonPressed = index
end

function Commander:SetupHud()

    Client.SetMouseVisible(true)
    Client.SetMouseCaptured(false)
    Client.SetMouseClipped(true)
    
    Client.UnbindFlashTexture("map")
    Client.BindFlashTexture("map", "maps/overviews/" .. Shared.GetMapName() .. ".tga")
    
    self.menuTechButtons = {}
    
    // Create circle for display under cursor
    self.unitUnderCursorRenderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    local modelName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleModelName, Commander.kMarineCircleModelName)
    self.unitUnderCursorRenderModel:SetModel(modelName)
    self.unitUnderCursorRenderModel:SetIsVisible(false)
    
    self.entityIdUnderCursor = Entity.invalidId
    
    GetGUIManager():CreateGUIScriptSingle("GUICommanderAlerts")
    GetGUIManager():CreateGUIScriptSingle("GUICommanderManager")
    
end

function Commander:Logout()

    Client.ConsoleCommand("logout")      
        
end

function Commander:ClickSelect(x, y)
   
    local pickVec = CreatePickRay( self, x, y)
    
    if(self.controlClick) then
    
        local screenStartVec = CreatePickRay( self, 0, 0)
        local screenEndVec = CreatePickRay(self, Client.GetScreenWidth(), Client.GetScreenHeight())
        
        self:ControlClickSelectEntities(pickVec, screenStartVec, screenEndVec)
        
        self:SendControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)
        
    else
    
        // Try selecting a unit
        if self:ClickSelectEntities(pickVec) then
    
            self:SendClickSelectCommand(pickVec, 1)
            
        // If nothing, try to select a squad
        elseif self:isa("MarineCommander") then    
            
            local xScalar, yScalar = Client.GetCursorPos()
            local clickedSquadNumber = self:GetSquadBlob(Vector(xScalar, yScalar, 0))
            
            if clickedSquadNumber ~= nil then
            
                self:ClientSelectSquad(clickedSquadNumber)
                
            end
        
        end
        
    end

    self.clickStartX = x
    self.clickStartY = y
    self.clickEndX = x
    self.clickEndY = y
            
end

function Commander:SendMarqueeSelectCommand(pickStartVec, pickEndVec)

    local message = BuildMarqueeSelectCommand(pickStartVec, pickEndVec)
    Client.SendNetworkMessage("MarqueeSelect", message, true)

end

function Commander:SendClickSelectCommand(pickVec)

    local message = BuildClickSelectCommand(pickVec)
    Client.SendNetworkMessage("ClickSelect", message, true)

end

function Commander:SendControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)

    local message = BuildControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)
    Client.SendNetworkMessage("ControlClickSelect", message, true)

end

function Commander:SendAction(techId)

    local message = BuildCommActionMessage(techId)
    Client.SendNetworkMessage("CommAction", message, true)
    
end

function Commander:SendTargetedAction(techId, normalizedPickRay)

    local message = BuildCommTargetedActionMessage(techId, normalizedPickRay.x, normalizedPickRay.y, normalizedPickRay.z, 0)
    Client.SendNetworkMessage("CommTargetedAction", message, true)    
    
end

function Commander:SendTargetedOrientedAction(techId, normalizedPickRay, orientation)

    local message = BuildCommTargetedActionMessage(techId, normalizedPickRay.x, normalizedPickRay.y, normalizedPickRay.z, orientation)
    Client.SendNetworkMessage("CommTargetedAction", message, true)    
    
end

function Commander:SendTargetedActionWorld(techId, worldCoords)

    local message = BuildCommTargetedActionMessage(techId, worldCoords.x, worldCoords.y, worldCoords.z, 0)
    Client.SendNetworkMessage("CommTargetedActionWorld", message, true)
    
end

function Commander:UpdateOrientationAngle(x, y)

    if(self.specifyingOrientation) then
    
        // Get screen coords from world position       
        local normalizedPickRay = CreatePickRay (self, x, y)
        local trace = GetCommanderPickTarget(self, normalizedPickRay, false, true)
        
        local normToMouse = GetNormalizedVector(trace.endPoint - self.specifyingOrientationPosition)

        self.orientationAngle = GetYawFromVector(normToMouse)
        
    else
        self.orientationAngle = 0
    end
    
end

// Only called when not running prediction
function Commander:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    if isLocal then
        
        self:UpdateMenu(deltaTime)
        
        // Update highlighted unit under cursor
        local xScalar, yScalar = Client.GetCursorPos()
        local x = xScalar * Client.GetScreenWidth()
        local y = yScalar * Client.GetScreenHeight()
        
        if self.ghostStructure == nil then
            self.entityIdUnderCursor = self:GetUnitIdUnderCursor(  CreatePickRay( self, x, y) )
        else
            self.entityIdUnderCursor = Entity.invalidId
        end
        
        self:UpdateOrientationAngle(x, y)
        
        self:UpdateSelectionCircles()
        
        self:UpdateGhostGuides()
        
        self:UpdateCircleUnderCursor()
        
        self:UpdateCursor()

        self.lastMouseX = x
        self.lastMouseY = y
        
    end
    
end

// For debugging order-giving, selection, etc.
function Commander:DrawDebugTrace()

    if(self.lastMouseX ~= nil and self.lastMouseY ~= nil) then
    
        local trace = GetCommanderPickTarget(self, Client.CreatePickingRayXY(self.lastMouseX, self.lastMouseY))
        
        if(trace ~= nil and trace.endPoint ~= nil) then
        
            Shared.CreateEffect(self, "cinematics/debug.cinematic", nil, Coords.GetTranslation(trace.endPoint))
            
        end
        
    end
    
end

function Commander:GetCircleSizeForEntity(entity)

    local size = ConditionalValue(entity:isa("Player"),2.0, 2)
    size = ConditionalValue(entity:isa("Drifter"), 2.5, size)
    size = ConditionalValue(entity:isa("Hive"), 6.5, size)
    size = ConditionalValue(entity:isa("MAC"), 2.0, size)
    size = ConditionalValue(entity:isa("Door"), 4.0, size)
    size = ConditionalValue(entity:isa("InfantryPortal"), 3.5, size)
    size = ConditionalValue(entity:isa("Extractor"), 3.0, size)
    size = ConditionalValue(entity:isa("CommandStation"), 5.5, size)
    size = ConditionalValue(entity:isa("Egg"), 2.5, size)
    size = ConditionalValue(entity:isa("Cocoon"), 3.0, size)
    size = ConditionalValue(entity:isa("Armory"), 4.0, size)
    size = ConditionalValue(entity:isa("Harvester"), 3.7, size)
    size = ConditionalValue(entity:isa("RoboticsFactory"), 4.3, size)
    size = ConditionalValue(entity:isa("ARC"), 3.5, size)
    return size
    
end

function Commander:UpdateSelectionCircles()

    // Check self.selectionCircles because this function may be called before it is valid.
    if not Client.GetIsRunningPrediction() and self.selectionCircles ~= nil then
        
        // Selection changed, so deleted old circles and create new ones
        if self.createSelectionCircles then
            
            self:DestroySelectionCircles()
        
            // Create new ones
            for index, entityEntry in pairs(self.selectedEntities) do
                
                local renderModelCircle = Client.CreateRenderModel(RenderScene.Zone_Default)
                renderModelCircle:SetModel(Commander.kSelectionCircleModelName)
                
                local model = Shared.GetModel(Shared.GetModelIndex(Commander.kSelectionCircleModelName))
                
                // Insert pair into selectionCircles: {entityId, render model}
                table.insert(self.selectionCircles, {entityEntry[1], renderModelCircle})
                
            end
            
            self.createSelectionCircles = nil
            
        end
        
        // Update positions and scale for each
        local poseParams = PoseParams()
        
        for index, circlePair in ipairs(self.selectionCircles) do
        
            local entity = Shared.GetEntity(circlePair[1])
            if entity ~= nil then
            
                local scale = self:GetCircleSizeForEntity(entity)
                local renderModelCircle = circlePair[2]
                
                // Set position, orientation, scale (add in a littler vertical to avoid z-fighting)
                renderModelCircle:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), Vector(entity:GetOrigin() + Vector(0, kZFightingConstant, 0)), scale))
                renderModelCircle:SetMaterialParameter("healthPercentage", entity:GetHealthScalar() * 100)
                local buildPercentage = 1
                if entity:isa("Structure") then
                    buildPercentage = entity:GetBuiltFraction()
                end
                renderModelCircle:SetMaterialParameter("buildPercentage", buildPercentage * 100)
                
            end
            
        end
        
    end
    
end

function Commander:UpdateCircleUnderCursor()
    
    local visibility = false
    
    if self.entityIdUnderCursor ~= Entity.invalidId then
    
        local entity = Shared.GetEntity(self.entityIdUnderCursor)
        if entity ~= nil then
            
            local scale = self:GetCircleSizeForEntity(entity)
            
            // Set position, orientation, scale
            self.unitUnderCursorRenderModel:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), Vector(entity:GetOrigin()), scale))
            
            visibility = true
            
        end        
        
    end
    
    self.unitUnderCursorRenderModel:SetIsVisible( visibility )

end

// Set the context-sensitive mouse cursor 
// Marine Commander default (like arrow from Starcraft 2, pointing to upper-left, MarineCommanderDefault.dds)
// Alien Commander default (like arrow from Starcraft 2, pointing to upper-left, AlienCommanderDefault.dds)
// Valid for friendly action (green "brackets" in Starcraft 2, FriendlyAction.dds)
// Valid for neutral action (yellow "brackets" in Starcraft 2, NeutralAction.dds)
// Valid for enemy action (red "brackets" in Starcraft 2, EnemyAction.dds)
// Build/target default (white crosshairs, BuildTargetDefault.dds)
// Build/target enemy (red crosshairs, BuildTargetEnemy.dds)
function Commander:UpdateCursor()

    // By default, use side-specific default cursor
    local baseCursor = ConditionalValue(self:GetTeamType() == kAlienTeamType, "AlienCommanderDefault", "MarineCommanderDefault")

    // Update highlighted unit under cursor
    local xScalar, yScalar = Client.GetCursorPos()
    local highlightSquad = -1
    
    if Client and self:isa("MarineCommander") then
    
        highlightSquad = self:GetSquadBlob(Vector(xScalar, yScalar, 0))
        
    end
    
    local entityUnderCursor = nil

    if(self.entityIdUnderCursor ~= Entity.invalidId) then
    
        entityUnderCursor = Shared.GetEntity(self.entityIdUnderCursor)
        
        if entityUnderCursor:GetTeamNumber() == self:GetTeamNumber() then
        
            baseCursor = "FriendlyAction"
            
        elseif entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber()) then
        
            baseCursor = "EnemyAction"
            
        else
        
            baseCursor = "NeutralAction"
            
        end
        
    elseif(highlightSquad >= 0) then

        baseCursor = "FriendlyAction"

    end
    
    // If we're building or in a targeted mode, use a special targeting cursor
    if self.ghostStructure ~= nil then
    
        baseCursor = "BuildTargetDefault"
    
    // Or if we're targeting an ability
    elseif self.targetedModeTechId ~= nil and self.targetedModeTechId ~= kTechId.None then
    
        local techNode = GetTechNode(self.targetedModeTechId)
        
        if((techNode ~= nil) and techNode:GetRequiresTarget()) then

            baseCursor = "BuildTargetDefault"

            if entityUnderCursor and (entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
            
                baseCursor = "BuildTargetEnemy"
                
            end
            
        end
        
    end
    
    // Set the cursor if it changed
    local cursorTexture = string.format("ui/Cursor_%s.dds", baseCursor)
    if(self.cursorOverUI) then

        cursorTexture = "ui/Cursor_MenuDefault.dds"
    
    end
    if cursorTexture ~= self.lastCursorTexture then
    
        Client.SetCursor(cursorTexture)
        self.lastCursorTexture = cursorTexture
        
    end
    
end

function Commander:ClientOnMousePress(mouseButton, x, y)

    self.mouseButtonDown[mouseButton + 1] = true
    
    if(mouseButton == 0) then

        // Only allowed when there is not a ghost structure or the structure is valid.
        if self.ghostStructure == nil or self.ghostStructureValid == true then
            local techNode = GetTechNode(self.targetedModeTechId)
            if((self.targetedModeTechId == nil) or (techNode == nil) or not techNode:GetRequiresTarget()) then
                // Select things near click.
                self:ClickSelect(x, y)
            end
        end
        
    end
    
end

function Commander:ClientOnMouseRelease(mouseButton, x, y)

    local displayConfirmationEffect = false
    
    local normalizedPickRay = CreatePickRay(self, x, y)

    if(mouseButton == 0) then

        // Don't do anything if we're ghost structure is at invalid place
        if self.ghostStructure == nil or self.ghostStructureValid == true then

            // If we're in a mode, clear it and handle it
            local techNode = GetTechNode(self.targetedModeTechId)
            if((self.targetedModeTechId ~= nil) and (techNode ~= nil) and techNode:GetRequiresTarget()) then
            
                // See if we have indicated an orientation for the structure yet (sentries only right now)
                if((self.targetedModeTechId == kTechId.Sentry) and not self.specifyingOrientation) then
                
                    // Compute world position where we will place this entity
                    local trace = GetCommanderPickTarget(self, normalizedPickRay, false, true)
                    VectorCopy(trace.endPoint, self.specifyingOrientationPosition)
                    
                    self.specifyingOrientationPickVec = Vector()
                    VectorCopy(normalizedPickRay, self.specifyingOrientationPickVec)
                    
                    self.specifyingOrientation = true
                    
                    self:UpdateOrientationAngle(x, y)
                    
                else
            
                    local techNode = GetTechNode(self.targetedModeTechId)
                    if(techNode ~= nil and techNode.available) then

                        local orientationAngle = ConditionalValue(self.specifyingOrientation, self.orientationAngle, NetworkRandom() * 2*math.pi)
                        if((self.targetedModeTechId == kTechId.CommandStation) or (self.targetedModeTechId == kTechId.Hive)) then
                            orientationAngle = 0
                        end
                        
                        local pickVec = ConditionalValue(self.specifyingOrientation, self.specifyingOrientationPickVec, normalizedPickRay)
                        self:SendTargetedOrientedAction(self.targetedModeTechId, pickVec, orientationAngle)
                        
                        displayConfirmationEffect = true

                    end
                    
                    self.specifyingOrientation = false
                    
                end
                
                // Clear mode after executed
                self.targetedModeTechId = kTechId.None
                
            end
            
        end
        
    // right-click order
    elseif(mouseButton == 1) then
       
        if self.ghostStructure ~= nil then
            self:DestroyGhostStructure()
        else
            self:SendTargetedAction(kTechId.Default, normalizedPickRay)
            displayConfirmationEffect = true
        end
       
    end
    
    if displayConfirmationEffect then
    
        local trace = GetCommanderPickTarget(self, normalizedPickRay)
        local effectName = self:GetOrderConfirmedEffect()
        if effectName ~= "" then
            Shared.CreateEffect(nil, effectName, nil, Coords.GetTranslation(trace.endPoint))
        end
        
    end
    
    self.mouseButtonDown[mouseButton + 1] = false
    
end

function Commander:GetMouseButtonDown(mouseButton)
    return self.mouseButtonDown[mouseButton + 1]
end

function Commander:SelectMarquee(selectStartX, selectStartY, selectEndX, selectEndY)
   
    // Create normalized coords which can be used on client and server
    local pickStartVec = CreatePickRay(self, selectStartX, selectStartY)
    local pickEndVec  = CreatePickRay(self, selectEndX, selectEndY)

    // Process selection locally
    self:MarqueeSelectEntities(pickStartVec, pickEndVec)
    
    // Send selection command to server
    self:SendMarqueeSelectCommand(pickStartVec, pickEndVec)
    
    self.clickStartX = selectStartX*Client.GetScreenWidth()
    self.clickStartY = selectStartY*Client.GetScreenHeight()
    self.clickEndX = selectEndX*Client.GetScreenWidth()
    self.clickEndY = selectEndY*Client.GetScreenHeight()

end

function Commander:SetCurrentTech(techId)

    // Change menu if it is a menu
    local techNode = GetTechNode(techId)
    if(techNode ~= nil and techNode:GetIsMenu()) then
    
        self.menuTechId = techId
        
    end

    // Send action up to server. Necessary for even menu changes as 
    // server validates all actions.
    self:SendAction(techId)
    
    // Remember this techId, which we need during ClientOnMouseRelease()
    self.targetedModeTechId = techId
    
end
