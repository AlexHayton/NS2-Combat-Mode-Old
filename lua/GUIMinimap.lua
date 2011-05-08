// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimap.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the minimap and icons on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScanlines.lua")

class 'GUIMinimap' (GUIScript)

GUIMinimap.kModeMini = 0
GUIMinimap.kModeBig = 1

GUIMinimap.kMapBackgroundXOffset = 10
GUIMinimap.kMapBackgroundYOffset = 10

GUIMinimap.kBackgroundTextureAlien = "ui/alien_commander_background.dds"
GUIMinimap.kBackgroundTextureMarine = "ui/marine_commander_background.dds"
GUIMinimap.kBackgroundTextureCoords = { X1 = 473, Y1 = 0, X2 = 793, Y2 = 333 }

GUIMinimap.kBackgroundWidth = 320 * kCommanderGUIsGlobalScale
GUIMinimap.kBackgroundHeight = 333 * kCommanderGUIsGlobalScale
GUIMinimap.kBackgroundMinimapOffset = 20 * kCommanderGUIsGlobalScale

GUIMinimap.kMinimapSize = Vector(GUIMinimap.kBackgroundWidth - GUIMinimap.kBackgroundMinimapOffset,
                                 GUIMinimap.kBackgroundHeight - GUIMinimap.kBackgroundMinimapOffset, 0)
GUIMinimap.kBigSizeScale = 2
GUIMinimap.kMinimapBigSize = GUIMinimap.kMinimapSize * GUIMinimap.kBigSizeScale

GUIMinimap.kBlipSize = 16
GUIMinimap.kUnpoweredNodeBlipSize = 32
GUIMinimap.kCameraIconLineSize = 4

GUIMinimap.kTeamColors = { }
GUIMinimap.kTeamColors[kMinimapBlipTeam.Friendly] = Color(0, 1, 0, 1)
GUIMinimap.kTeamColors[kMinimapBlipTeam.Enemy] = Color(1, 0, 0, 1)
GUIMinimap.kTeamColors[kMinimapBlipTeam.Neutral] = Color(0.5, 0.5, 0.5, 1)

GUIMinimap.kUnpoweredNodeColor = Color(1, 0, 0)

GUIMinimap.kIconFileName = "ui/minimap_blip.dds"
GUIMinimap.kNumberIcons = 4
GUIMinimap.kIconWidth = 16
GUIMinimap.kIconHeight = 64 / GUIMinimap.kNumberIcons

GUIMinimap.kUnpoweredNodeFileName = "ui/power_node_off.dds"
GUIMinimap.kUnpoweredNodeIconWidth = 32
GUIMinimap.kUnpoweredNodeIconHeight = 32

GUIMinimap.kStaticBlipsLayer = 0
GUIMinimap.kCameraIconLayer = 1
GUIMinimap.kDynamicBlipsLayer = 2

GUIMinimap.kBlipTexture = "ui/blip.dds"

GUIMinimap.kBlipTextureCoordinates = { }
GUIMinimap.kBlipTextureCoordinates[kAlertType.Attack] = { X1 = 0, Y1 = 0, X2 = 64, Y2 = 64 }

GUIMinimap.kAttackBlipMinSize = Vector(25, 25, 0)
GUIMinimap.kAttackBlipMaxSize = Vector(100, 100, 0)
GUIMinimap.kAttackBlipPulseSpeed = 6
GUIMinimap.kAttackBlipTime = 5
GUIMinimap.kAttackBlipFadeInTime = 4.5
GUIMinimap.kAttackBlipFadeOutTime = 1

GUIMinimap.kLocationFontSize = 12

function GUIMinimap:Initialize()

    self:InitializeBackground()
    self:InitializeScanlines()
    
    self.minimap = GUIManager:CreateGraphicItem()
    
    self:InitializeLocationNames()
    
    self.mode = nil
    self:SetBackgroundMode(GUIMinimap.kModeMini)
    self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
    self.minimap:SetColor(PlayerUI_GetTeamColor())
    
    self.background:AddChild(self.minimap)
    
    // Used for commander.
    self:InitializeCameraIcon()
    // Used for normal players.
    self:InitializePlayerIcon()
    
    self.staticBlips = { }
    
    self.reuseDynamicBlips = { }
    self.inuseDynamicBlips = { }
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
end

function GUIMinimap:InitializeBackground()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
    self.background:SetPosition(Vector(0, -GUIMinimap.kBackgroundHeight, 0))
    GUISetTextureCoordinatesTable(self.background, GUIMinimap.kBackgroundTextureCoords)

    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetLayer(kGUILayerMinimap)
    
    // Non-commander players assume the map isn't visible by default.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(false)
    end

end

function GUIMinimap:InitializeScanlines()

    local settingsTable = { }
    settingsTable.Width = GUIMinimap.kBackgroundWidth
    settingsTable.Height = GUIMinimap.kBackgroundHeight
    // The amount of extra scanline space that should be above the minimap.
    settingsTable.ExtraHeight = 0
    self.scanlines = GUIScanlines()
    self.scanlines:Initialize(settingsTable)
    self.scanlines:GetBackground():SetInheritsParentAlpha(true)
    self.background:AddChild(self.scanlines:GetBackground())
    
end

function GUIMinimap:InitializeCameraIcon()

    self.cameraIcon = GUIManager:CreateGraphicItem()
    self.cameraIcon:SetUseStencil(true)
    self.cameraIcon:SetAnchor(GUIItem.Center, GUIItem.Middle)

    self.cameraIconMask = GUIManager:CreateGraphicItem()
    self.cameraIconMask:SetIsStencil(true)
    self.cameraIconMask:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.cameraIconMask:SetLayer(GUIMinimap.kCameraIconLayer)
    
    self.cameraIconMask:AddChild(self.cameraIcon)
    self.minimap:AddChild(self.cameraIconMask)
    
end

function GUIMinimap:InitializePlayerIcon()

    self.playerIcon = GUIManager:CreateGraphicItem()
    self.playerIcon:SetSize(Vector(GUIMinimap.kIconWidth, GUIMinimap.kIconHeight, 0))
    self.playerIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerIcon:SetTexture(GUIMinimap.kIconFileName)
    self.playerIcon:SetTexturePixelCoordinates(0, 0, GUIMinimap.kIconWidth, GUIMinimap.kIconHeight)
    self.playerIcon:SetIsVisible(false)
    self.playerIcon:SetLayer(GUIMinimap.kCameraIconLayer)
    self.minimap:AddChild(self.playerIcon)

end

function GUIMinimap:InitializeLocationNames()

    self.locationItems = { }
    local locationData = PlayerUI_GetLocationData()
    
    // Average the position of same named locations so they don't display
    // multiple times.
    local multipleLocationsData = { }
    for i, location in ipairs(locationData) do
        // Filter out the ready room.
        if location.Name ~= "Ready Room" then
            local locationTable = multipleLocationsData[location.Name]
            if locationTable == nil then
                locationTable = { }
                multipleLocationsData[location.Name] = locationTable
            end
            table.insert(locationTable, location.Origin)
        end
    end
    local uniqueLocationsData = { }
    for name, origins in pairs(multipleLocationsData) do
        local averageOrigin = Vector(0, 0, 0)
        table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
        table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / table.count(origins) })
    end
    
    for i, location in ipairs(uniqueLocationsData) do
        local locationItem = GUIManager:CreateTextItem()
        locationItem:SetFontSize(GUIMinimap.kLocationFontSize)
        locationItem:SetFontIsBold(true)
        locationItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        locationItem:SetTextAlignmentX(GUIItem.Align_Center)
        locationItem:SetTextAlignmentY(GUIItem.Align_Center)
        local posX, posY = PlayerUI_GetMapXY(location.Origin.x, location.Origin.z)
        // Locations only supported on the big mode.
        posX = posX * GUIMinimap.kMinimapBigSize.x
        posY = posY * GUIMinimap.kMinimapBigSize.y
        locationItem:SetPosition(Vector(posX, posY, 0))
        locationItem:SetColor(Color(1, 1, 1, 1))
        locationItem:SetText(location.Name)
        self.minimap:AddChild(locationItem)
        table.insert(self.locationItems, locationItem)
    end

end

function GUIMinimap:Uninitialize()

    // The ItemMask is the parent of the Item so this will destroy both.
    for i, blip in ipairs(self.reuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.reuseDynamicBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.inuseDynamicBlips = { }
    
    if self.scanlines then
        self.scanlines:Uninitialize()
        self.scanlines = nil
    end
    
    if self.minimap then
        GUI.DestroyItem(self.minimap)
    end
    self.minimap = nil
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    // The staticBlips are children of the background so will be cleaned up with it.
    self.staticBlips = { }
    
end

function GUIMinimap:SetButtonsScript(setButtonsScript)

    self.buttonsScript = setButtonsScript

end

function GUIMinimap:Update(deltaTime)
 
    // Commander always sees the minimap.
    if PlayerUI_IsACommander() then
        self.background:SetIsVisible(true)
        if CommanderUI_IsAlienCommander() then
            self.background:SetTexture(GUIMinimap.kBackgroundTextureAlien)
        else
            self.background:SetTexture(GUIMinimap.kBackgroundTextureMarine)
        end
    elseif self.mode == GUIMinimap.kModeMini then
        // No minimap for non-commaders
        self.background:SetIsVisible(false)
    end
    
    self:UpdateIcon()
    
    self:UpdateStaticBlips(deltaTime)
    
    self:UpdateDynamicBlips(deltaTime)
    
    self:UpdateInput()
    
    if self.minimap:GetIsVisible() then
        // The color cannot be attained right away in some cases so
        // we need to make sure it is the correct color.
        self.minimap:SetColor(PlayerUI_GetTeamColor())
    end
    
    if self.scanlines then
        self.scanlines:Update(deltaTime)
    end
    
end

function GUIMinimap:UpdateIcon()

    if PlayerUI_IsACommander() then
        self.playerIcon:SetIsVisible(false)
        self.cameraIconMask:SetIsVisible(true)
        local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = CommanderUI_ViewFarPlanePoints()
        local topLeftX, topLeftY = PlayerUI_GetMapXY(topLeftPoint.x, topLeftPoint.z)
        local bottomRightX, bottomRightY = PlayerUI_GetMapXY(bottomRightPoint.x, bottomRightPoint.z)
        
        local iconWidth = (bottomRightX - topLeftX) * self:GetMinimapSize().x
        local iconHeight = (bottomRightY - topLeftY) * self:GetMinimapSize().y
        self.cameraIconMask:SetSize(Vector(iconWidth, iconHeight, 0))
        // The icon is always slightly bigger than the mask to draw the outline.
        local sizeX = iconWidth + GUIMinimap.kCameraIconLineSize
        local sizeY = iconHeight + GUIMinimap.kCameraIconLineSize
        self.cameraIcon:SetSize(Vector(sizeX, sizeY, 0))
        self.cameraIcon:SetPosition(Vector(-sizeX / 2, -sizeY / 2, 0))
        local iconX = topLeftX * self:GetMinimapSize().x
        local iconY = topLeftY * self:GetMinimapSize().y
        self.cameraIconMask:SetPosition(Vector(iconX, iconY, 0))
    elseif PlayerUI_IsAReadyRoomPlayer() then
        // No icons for ready room players.
        self.cameraIconMask:SetIsVisible(false)
        self.playerIcon:SetIsVisible(false)
    else
        // Draw a player icon representing this player's position.
        self.cameraIconMask:SetIsVisible(false)
        self.playerIcon:SetIsVisible(true)
        local playerOrigin = PlayerUI_GetOrigin()
        local posX, posY = PlayerUI_GetMapXY(playerOrigin.x, playerOrigin.z)
        posX = (posX * self:GetMinimapSize().x) - (GUIMinimap.kIconWidth / 2)
        posY = (posY * self:GetMinimapSize().y) - (GUIMinimap.kIconHeight / 2)
        self.playerIcon:SetPosition(Vector(posX, posY, 0))
    end
    
end

function GUIMinimap:UpdateStaticBlips(deltaTime)

    // First hide all previous static blips.
    for index, oldBlip in ipairs(self.staticBlips) do
        oldBlip:SetIsVisible(false)
    end
    
    local staticBlips = PlayerUI_GetStaticMapBlips()
    local blipItemCount = 6
    local numBlips = table.count(staticBlips) / blipItemCount
    local currentIndex = 1
    while numBlips > 0 do
        xPos = staticBlips[currentIndex]
        yPos = staticBlips[currentIndex + 1]
        xTexture = staticBlips[currentIndex + 2]
        yTexture = staticBlips[currentIndex + 3]
        blipType = staticBlips[currentIndex + 4]
        blipTeam = staticBlips[currentIndex + 5]
        self:SetStaticBlip(xPos, yPos, xTexture, yTexture, blipType, blipTeam)
        currentIndex = currentIndex + blipItemCount
        numBlips = numBlips - 1
    end
    
end

function GUIMinimap:SetStaticBlip(xPos, yPos, xTexture, yTexture, blipType, blipTeam)
    
    // Find a free static blip to reuse or create a new one.
    local foundBlip = nil
    for index, oldBlip in ipairs(self.staticBlips) do
        if not oldBlip:GetIsVisible() then
            foundBlip = oldBlip
            break
        end
    end
    
    if not foundBlip then
        foundBlip = self:AddStaticBlip()
    end
    
    local yOffset = nil
    local textureName = GUIMinimap.kIconFileName
    local iconWidth = GUIMinimap.kIconWidth
    local iconHeight = GUIMinimap.kIconHeight
    local blipColor = GUIMinimap.kTeamColors[blipTeam]
    local blendTechnique = GUIItem.Default
    local blipSize = GUIMinimap.kBlipSize
    if blipType == kMinimapBlipType.TechPoint then
        yOffset = 0
    elseif blipType == kMinimapBlipType.ResourcePoint then
        yOffset = 1
    elseif blipType == kMinimapBlipType.Player then
        yOffset = 2
    elseif blipType == kMinimapBlipType.PowerPoint then
        // Only unpowered node blips are sent.
        yOffset = 0
        textureName = GUIMinimap.kUnpoweredNodeFileName
        iconWidth = GUIMinimap.kUnpoweredNodeIconWidth
        iconHeight = GUIMinimap.kUnpoweredNodeIconHeight
        blipColor = GUIMinimap.kUnpoweredNodeColor
        local pulseAmount = (math.sin(Shared.GetTime()) + 1) / 2
        blipColor.a = 0.5 + (pulseAmount * 0.5)
        blipSize = GUIMinimap.kUnpoweredNodeBlipSize
    end
    
    if yOffset then
        foundBlip:SetTexture(textureName)
        yOffset = yOffset * iconHeight
        foundBlip:SetTexturePixelCoordinates(0, yOffset, iconWidth, yOffset + iconHeight)
    else
        foundBlip:SetTexture("")
    end
    
    foundBlip:SetIsVisible(true)
    foundBlip:SetSize(Vector(blipSize, blipSize, 0))
    foundBlip:SetPosition(Vector(xPos * self:GetMinimapSize().x - blipSize / 2, yPos * self:GetMinimapSize().y - blipSize / 2, 0))
    foundBlip:SetColor(blipColor)
    foundBlip:SetBlendTechnique(blendTechnique)
    
end

function GUIMinimap:AddStaticBlip()

    addedBlip = GUIManager:CreateGraphicItem()
    addedBlip:SetAnchor(GUIItem.Left, GUIItem.Top)
    addedBlip:SetLayer(GUIMinimap.kStaticBlipsLayer)
    self.minimap:AddChild(addedBlip)
    table.insert(self.staticBlips, addedBlip)
    return addedBlip

end

function GUIMinimap:UpdateDynamicBlips(deltaTime)

    if PlayerUI_IsACommander() then
        local newDynamicBlips = CommanderUI_GetDynamicMapBlips()
        local blipItemCount = 3
        local numBlips = table.count(newDynamicBlips) / blipItemCount
        local currentIndex = 1
        while numBlips > 0 do
            xPos = newDynamicBlips[currentIndex]
            yPos = newDynamicBlips[currentIndex + 1]
            blipType = newDynamicBlips[currentIndex + 2]
            self:AddDynamicBlip(xPos, yPos, blipType)
            currentIndex = currentIndex + blipItemCount
            numBlips = numBlips - 1
        end
    end
    
    local removeBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        if blip["Type"] == kAlertType.Attack then
            if self:UpdateAttackBlip(blip, deltaTime) then
                table.insert(removeBlips, blip)
            end
        end
    end
    for i, blip in ipairs(removeBlips) do
        self:RemoveDynamicBlip(blip)
    end

end

function GUIMinimap:UpdateAttackBlip(blip, deltaTime)

    blip["Time"] = blip["Time"] - deltaTime
    
    // Fade in.
    if blip["Time"] >= GUIMinimap.kAttackBlipFadeInTime then
        local fadeInAmount = ((GUIMinimap.kAttackBlipTime - blip["Time"]) / (GUIMinimap.kAttackBlipTime - GUIMinimap.kAttackBlipFadeInTime))
        blip["Item"]:SetColor(Color(1, 1, 1, fadeInAmount))
    else
        blip["Item"]:SetColor(Color(1, 1, 1, 1))
    end
    
    // Fade out.
    if blip["Time"] <= GUIMinimap.kAttackBlipFadeOutTime then
        if blip["Time"] <= 0 then
            // Done animating.
            return true
        end
        blip["Item"]:SetColor(Color(1, 1, 1, blip["Time"] / GUIMinimap.kAttackBlipFadeOutTime))
    end
    
    local timeLeft = GUIMinimap.kAttackBlipTime - blip["Time"]
    local pulseAmount = (math.sin(timeLeft * GUIMinimap.kAttackBlipPulseSpeed) + 1) / 2
    local blipSize = LerpGeneric(GUIMinimap.kAttackBlipMinSize, GUIMinimap.kAttackBlipMaxSize / 2, pulseAmount)
    
    blip["Item"]:SetSize(blipSize)
    // Make sure it is always centered.
    local sizeDifference = GUIMinimap.kAttackBlipMaxSize - blipSize
    local minimapSize = self:GetMinimapSize()
    local xOffset = (sizeDifference.x / 2) - GUIMinimap.kAttackBlipMaxSize.x / 2
    local yOffset = (sizeDifference.y / 2) - GUIMinimap.kAttackBlipMaxSize.y / 2
    blip["Item"]:SetPosition(Vector((blip["X"] * minimapSize.x) + xOffset, (blip["Y"] * minimapSize.y) + yOffset, 0))
    
    // Not done yet.
    return false

end

function GUIMinimap:AddDynamicBlip(xPos, yPos, blipType)

    /**
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
     */
    if blipType == kAlertType.Attack then
        if self.scanlines then
            // Disrupt should probably be a global function that disrupts all scanlines at the same time.
            self.scanlines:Disrupt()
        end
        addedBlip = self:GetFreeDynamicBlip(xPos, yPos, blipType)
        addedBlip["Item"]:SetSize(Vector(0, 0, 0))
        addedBlip["Time"] = GUIMinimap.kAttackBlipTime
    end
    
end

function GUIMinimap:RemoveDynamicBlip(blip)

    blip["Item"]:SetIsVisible(false)
    table.removevalue(self.inuseDynamicBlips, blip)
    table.insert(self.reuseDynamicBlips, blip)
    
end

function GUIMinimap:GetFreeDynamicBlip(xPos, yPos, blipType)

    local returnBlip = nil
    if table.count(self.reuseDynamicBlips) > 0 then
    
        returnBlip = self.reuseDynamicBlips[1]
        table.removevalue(self.reuseDynamicBlips, returnBlip)
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    else
    
        returnBlip = { }
        returnBlip["Item"] = GUIManager:CreateGraphicItem()
        // Make sure these draw a layer above the minimap so they are on top.
        returnBlip["Item"]:SetLayer(GUIMinimap.kDynamicBlipsLayer)
        returnBlip["Item"]:SetTexture(GUIMinimap.kBlipTexture)
        returnBlip["Item"]:SetBlendTechnique(GUIItem.Add)
        returnBlip["Item"]:SetAnchor(GUIItem.Top, GUIItem.Left)
        self.minimap:AddChild(returnBlip["Item"])
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    end
    
    returnBlip["X"] = xPos
    returnBlip["Y"] = yPos
    
    returnBlip["Type"] = blipType
    returnBlip["Item"]:SetIsVisible(true)
    returnBlip["Item"]:SetColor(Color(1, 1, 1, 1))
    local minimapSize = self:GetMinimapSize()
    returnBlip["Item"]:SetPosition(Vector(xPos * minimapSize.x, yPos * minimapSize.y, 0))
    GUISetTextureCoordinatesTable(returnBlip["Item"], GUIMinimap.kBlipTextureCoordinates[blipType])
    return returnBlip
    
end

function GUIMinimap:UpdateInput()

    if PlayerUI_IsACommander() then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if self.mousePressed["LMB"]["Down"] then
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if containsPoint then
                local minimapSize = self:GetMinimapSize()
                local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                local cameraIconSize = self.cameraIcon:GetSize()
                
                local cameraPosition = Vector(mouseX, mouseY, 0)
                
                local playableX = (1 - CommanderUI_MapLayoutPlayableWidth()) / 2 * (minimapSize.x - cameraIconSize.x)
                local playableY = (1 - CommanderUI_MapLayoutPlayableHeight()) / 2 * (minimapSize.y - cameraIconSize.y)

                if cameraPosition.x < backgroundScreenPosition.x + playableX then
                    cameraPosition.x = backgroundScreenPosition.x + playableX
                elseif cameraPosition.x > (backgroundScreenPosition.x + minimapSize.x) - playableX then
                    cameraPosition.x = (backgroundScreenPosition.x + minimapSize.x) - playableX
                end

                if cameraPosition.y < backgroundScreenPosition.y + playableY then
                    cameraPosition.y = backgroundScreenPosition.y + playableY
                elseif cameraPosition.y > (backgroundScreenPosition.y + minimapSize.y) - playableY then
                    cameraPosition.y = (backgroundScreenPosition.y + minimapSize.y) - playableY
                end
                
                cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
                cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y

                local horizontalScale = CommanderUI_MapLayoutHorizontalScale()
                local verticalScale = CommanderUI_MapLayoutVerticalScale()

                local moveX = (cameraPosition.x / minimapSize.x) * horizontalScale
                local moveY = (cameraPosition.y / minimapSize.y) * verticalScale

                CommanderUI_MapMoveView(moveX, moveY)
            end
        end
    end

end

function GUIMinimap:SetBackgroundMode(setMode)

    if self.mode ~= setMode then
        self.mode = setMode
        local modeIsMini = self.mode == GUIMinimap.kModeMini
        
        // Locations only visible in the big mode
        table.foreachfunctor(self.locationItems, function (item) item:SetIsVisible(not modeIsMini) end)
        
        local modeSize = self:GetMinimapSize()
        
        if self.background then
            if modeIsMini then
                self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
                self.background:SetPosition(Vector(GUIMinimap.kMapBackgroundXOffset, -GUIMinimap.kBackgroundHeight - GUIMinimap.kMapBackgroundYOffset, 0))
                self.background:SetColor(Color(1, 1, 1, 1))
            else
                self.background:SetAnchor(GUIItem.Center, GUIItem.Middle)
                self.background:SetPosition(Vector(-modeSize.x / 2, -modeSize.y / 2, 0))
                self.background:SetColor(Color(1, 1, 1, 0))
            end
        end
        self.minimap:SetSize(modeSize)
        
        // We want the background to sit "inside" the border so move it up and to the right a bit.
        local borderExtraWidth = ConditionalValue(self.background, GUIMinimap.kBackgroundWidth - self:GetMinimapSize().x, 0)
        local borderExtraHeight = ConditionalValue(self.background, GUIMinimap.kBackgroundHeight - self:GetMinimapSize().y, 0)
        local defaultPosition = Vector(borderExtraWidth / 2, borderExtraHeight / 2, 0)
        local modePosition = ConditionalValue(modeIsMini, defaultPosition, Vector(0, 0, 0))
        self.minimap:SetPosition(modePosition)
    end
    
end

function GUIMinimap:GetMinimapSize()

    return ConditionalValue(self.mode == GUIMinimap.kModeMini, GUIMinimap.kMinimapSize, GUIMinimap.kMinimapBigSize)
    
end

function GUIMinimap:GetPositionOnBackground(xPos, yPos, currentSize)

    local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
    local inBackgroundPosition = Vector((xPos * self:GetMinimapSize().x) - (currentSize.x / 2), (yPos * self:GetMinimapSize().y) - (currentSize.y / 2), 0)
    return backgroundScreenPosition + inBackgroundPosition

end

// Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)
    
    // Non-commander players only see the map when the key is held down.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(showMap)
    end
    self:SetBackgroundMode(ConditionalValue(showMap, GUIMinimap.kModeBig, GUIMinimap.kModeMini))

end

function GUIMinimap:SendKeyEvent(key, down)
    
    if PlayerUI_IsACommander() then
        if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
            self.mousePressed["LMB"]["Down"] = down
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if down and containsPoint then
                local buttonIndex = nil
                if self.buttonsScript then
                    buttonIndex = self.buttonsScript:GetTargetedButton()
                end
                if buttonIndex then
                    CommanderUI_ActionCancelled()
                    self.buttonsScript:SetTargetedButton(nil)
                    CommanderUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 0, buttonIndex)
                    // The down event is considered "captured" at this point and shouldn't be processed in UpdateInput().
                    self.mousePressed["LMB"]["Down"] = false
                end
                return true
            end
        elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
            self.mousePressed["RMB"]["Down"] = down
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if down and containsPoint then
                if self.buttonsScript then
                    // Cancel just in case the user had a targeted action selected before this press.
                    CommanderUI_ActionCancelled()
                    self.buttonsScript:SetTargetedButton(nil)
                end
                CommanderUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 1, nil)
                return true
            end
        end
    end
    
    return false

end

function GUIMinimap:GetBackground()

    return self.background

end

function GUIMinimap:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self:GetBackground(), pointX, pointY) or
           GUIItemContainsPoint(self.minimap, pointX, pointY)

end
