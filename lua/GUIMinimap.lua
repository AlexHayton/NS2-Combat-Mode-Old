// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimap.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the minimap and icons on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMinimap' (GUIScript)

GUIMinimap.kModeMini = 0
GUIMinimap.kModeBig = 1

GUIMinimap.kMapBackgroundBorder = "ui/map_background.dds"

GUIMinimap.kMinimapSize = 200
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

GUIMinimap.kAttackBlipMinSize = 50
GUIMinimap.kAttackBlipShrinkRate = Vector(1000, 1000, 0)

// First the dynamic blip will do some attention grabbing animation.
GUIMinimap.kDynamicBlipAnimModeGrabAttention = 0
// Next the dynamic blip will pulse for a while on the minimap.
GUIMinimap.kDynamicBlipAnimModeMapPulse = 1

// This is how long the dynamic blip should pulse on the minimap.
GUIMinimap.kDynamicBlipAnimMapPulseTime = 4
GUIMinimap.kDynamicBlipAnimMapPulseRate = 5

// This is the size of the attack blip border.
GUIMinimap.kDynamicBlipAttackMaskScalar = 0.95
GUIMinimap.kDynamicBlipAttackRotationRate = 1
GUIMinimap.kDynamicBlipAttackColor = Color(0.8, 0, 0, 1)

function GUIMinimap:Initialize()

    //self.backgroundBorder = GUI.CreateGraphicsItem()
    //self.backgroundBorder:SetTexture(GUIMinimap.kMapBackgroundBorder)

    self.background = GUI.CreateGraphicsItem()
    self.mode = GUIMinimap.kModeMini
    self:SetBackgroundMode(self.mode)
    self.background:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
    self.background:SetColor(CommanderUI_GetTeamColor())
    
    self:InitializeCameraIcon()
    
    self.staticBlips = { }
    
    self.reuseDynamicBlips = { }
    self.inuseDynamicBlips = { }
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
end

function GUIMinimap:InitializeCameraIcon()

    self.cameraIcon = GUI.CreateGraphicsItem()
    self.cameraIcon:SetUseStencil(true)
    self.cameraIcon:SetAnchor(GUIItem.Center, GUIItem.Middle)

    self.cameraIconMask = GUI.CreateGraphicsItem()
    self.cameraIconMask:SetIsStencil(true)
    self.cameraIconMask:SetAnchor(GUIItem.Left, GUIItem.Top)
    
    self.cameraIconMask:AddChild(self.cameraIcon)
    self.background:AddChild(self.cameraIconMask)
    
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
    
    if self.backgroundBorder then
        GUI.DestroyItem(self.backgroundBorder)
    end
    GUI.DestroyItem(self.background)
    self.background = nil
    // The staticBlips are children of the background so will be cleaned up with it.
    self.staticBlips = { }
    
end

function GUIMinimap:Update(deltaTime)
 
    self:UpdateCameraIcon()
    
    self:UpdateStaticBlips(deltaTime)
    
    self:UpdateDynamicBlips(deltaTime)
    
    self:UpdateInput()
    
end

function GUIMinimap:UpdateCameraIcon()

    local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = CommanderUI_ViewFarPlanePoints()
    local topLeftX, topLeftY = CommanderUI_GetMapXY(topLeftPoint.x, topLeftPoint.z)
    local bottomRightX, bottomRightY = CommanderUI_GetMapXY(bottomRightPoint.x, bottomRightPoint.z)
    
    local iconWidth = (bottomRightX - topLeftX) * self:GetBackgroundSize()
    local iconHeight = (bottomRightY - topLeftY) * self:GetBackgroundSize()
    self.cameraIconMask:SetSize(Vector(iconWidth, iconHeight, 0))
    // The icon is always slightly bigger than the mask to draw the outline.
    local sizeX = iconWidth + GUIMinimap.kCameraIconLineSize
    local sizeY = iconHeight + GUIMinimap.kCameraIconLineSize
    self.cameraIcon:SetSize(Vector(sizeX, sizeY, 0))
    self.cameraIcon:SetPosition(Vector(-sizeX / 2, -sizeY / 2, 0))
    local iconX = topLeftX * self:GetBackgroundSize()
    local iconY = topLeftY * self:GetBackgroundSize()
    self.cameraIconMask:SetPosition(Vector(iconX, iconY, 0))
    
end

function GUIMinimap:UpdateStaticBlips(deltaTime)

    // First hide all previous static blips.
    for index, oldBlip in ipairs(self.staticBlips) do
        oldBlip:SetIsVisible(false)
    end
    
    local staticBlips = CommanderUI_GetStaticMapBlips()
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
    foundBlip:SetPosition(Vector(xPos * self:GetBackgroundSize() - blipSize / 2, yPos * self:GetBackgroundSize() - blipSize / 2, 0))
    foundBlip:SetColor(blipColor)
    foundBlip:SetBlendTechnique(blendTechnique)
    
end

function GUIMinimap:AddStaticBlip()

    addedBlip = GUI.CreateGraphicsItem()
    addedBlip:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:AddChild(addedBlip)
    table.insert(self.staticBlips, addedBlip)
    return addedBlip

end

function GUIMinimap:UpdateDynamicBlips(deltaTime)

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
    
    local removeBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        if blip["Type"] == kAlertType.Attack then
            if not self:UpdateAttackBlip(blip, deltaTime) then
                table.insert(removeBlips, blip)
            end
        end
    end
    for i, blip in ipairs(removeBlips) do
        self:RemoveDynamicBlip(blip)
    end

end

function GUIMinimap:UpdateAttackBlip(blip, deltaTime)

    local currentSize = blip["Item"]:GetSize()
    local currentPosition = blip["ItemMask"]:GetPosition()
    
    if blip["AnimMode"] == GUIMinimap.kDynamicBlipAnimModeGrabAttention then
    
        currentSize = currentSize - GUIMinimap.kAttackBlipShrinkRate * deltaTime
        
        if currentSize.x < GUIMinimap.kAttackBlipMinSize then
            currentSize.x = GUIMinimap.kAttackBlipMinSize
            currentSize.y = GUIMinimap.kAttackBlipMinSize
            blip["AnimMode"] = GUIMinimap.kDynamicBlipAnimModeMapPulse
            blip["AnimTime"] = Shared.GetTime()
        end
        
        local positionOnScreen = Vector((Client.GetScreenWidth() - currentSize.x) / 2, (Client.GetScreenHeight() - currentSize.y) / 2, 0)
        local positionOnBackground = self:GetPositionOnBackground(blip["XPos"], blip["YPos"], currentSize)
        local lerpAmount = 1 - ((currentSize.x - GUIMinimap.kAttackBlipMinSize) / (blip["StartSize"] - GUIMinimap.kAttackBlipMinSize))
        currentPosition = positionOnScreen + ((positionOnBackground - positionOnScreen) * lerpAmount)
        
    elseif blip["AnimMode"] == GUIMinimap.kDynamicBlipAnimModeMapPulse then
    
        local timePassed = Shared.GetTime() - blip["AnimTime"]
        local shrinkDownTime = GUIMinimap.kDynamicBlipAnimMapPulseTime - 0.2
        if timePassed >= GUIMinimap.kDynamicBlipAnimMapPulseTime then
            // Time to remove this blip.
            return false
        elseif timePassed >= shrinkDownTime then
            // Shrink down to nothing really fast before removing.
            local shrinkAmount = 1 - ((timePassed - shrinkDownTime) / (GUIMinimap.kDynamicBlipAnimMapPulseTime - shrinkDownTime))
            currentSize = Vector(GUIMinimap.kAttackBlipMinSize, GUIMinimap.kAttackBlipMinSize, 0) * shrinkAmount
        else
            // Pulse the blip in and out for a while.
            local pulseAmount = (0.5 + (((math.sin(Shared.GetTime() * GUIMinimap.kDynamicBlipAnimMapPulseRate) + 1) / 2) * 0.5))
            currentSize = Vector(GUIMinimap.kAttackBlipMinSize, GUIMinimap.kAttackBlipMinSize, 0) * pulseAmount
        end
        currentPosition = self:GetPositionOnBackground(blip["XPos"], blip["YPos"], currentSize)
    
    end
    
    blip["Item"]:SetSize(currentSize)
    blip["ItemMask"]:SetSize(currentSize * GUIMinimap.kDynamicBlipAttackMaskScalar)
    
    local positionAdjustment = currentSize - (currentSize * GUIMinimap.kDynamicBlipAttackMaskScalar)
    blip["Item"]:SetPosition(-positionAdjustment / 2)
    blip["ItemMask"]:SetPosition(currentPosition)
    
    blip["Item"]:SetRotation(Vector(0, 0, blip["Rotation"]))
    blip["ItemMask"]:SetRotation(Vector(0, 0, blip["Rotation"]))

    blip["Rotation"] = blip["Rotation"] + GUIMinimap.kDynamicBlipAttackRotationRate * deltaTime
    // Don't remove yet, it isn't done animating.
    return true

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
        addedBlip = self:GetFreeDynamicBlip(xPos, yPos, blipType)
        // Start a little bigger than the screen size.
        local attackBlipSize = math.max(Client.GetScreenWidth(), Client.GetScreenHeight())
        addedBlip["StartSize"] = attackBlipSize
        addedBlip["Item"]:SetSize(Vector(attackBlipSize, attackBlipSize, 0))
        addedBlip["Item"]:SetUseStencil(true)
        addedBlip["Item"]:SetAnchor(GUIItem.Top, GUIItem.Left)
        addedBlip["Item"]:SetColor(GUIMinimap.kDynamicBlipAttackColor)
        // Setup the stencil to mask out the center of the attack blip.
        local maskSize = attackBlipSize * GUIMinimap.kDynamicBlipAttackMaskScalar
        addedBlip["ItemMask"]:SetSize(Vector(maskSize, maskSize, 0))
        addedBlip["ItemMask"]:SetAnchor(GUIItem.Top, GUIItem.Left)
    end
    
end

function GUIMinimap:RemoveDynamicBlip(blip)

    blip["ItemMask"]:SetIsVisible(false)
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
        returnBlip["Item"] = GUI.CreateGraphicsItem()
        returnBlip["ItemMask"] = GUI.CreateGraphicsItem()
        returnBlip["ItemMask"]:SetIsStencil(true)
        returnBlip["ItemMask"]:AddChild(returnBlip["Item"])
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    end
    
    returnBlip["Type"] = blipType
    returnBlip["ItemMask"]:SetIsVisible(true)
    // Assume the mask isn't going to be used by default.
    returnBlip["Item"]:SetUseStencil(false)
    returnBlip["XPos"] = xPos
    returnBlip["YPos"] = yPos
    returnBlip["Rotation"] = 0
    returnBlip["AnimMode"] = GUIMinimap.kDynamicBlipAnimModeGrabAttention
    returnBlip["AnimTime"] = Shared.GetTime()
    returnBlip["StartSize"] = 0
    return returnBlip
    
end

function GUIMinimap:UpdateInput()

    local mouseX, mouseY = Client.GetCursorPosScreen()
    if self.mousePressed["LMB"]["Down"] then
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
        if containsPoint then
            local backgroundSize = self:GetBackgroundSize()
            local backgroundScreenPosition = self.background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
            local cameraIconSize = self.cameraIcon:GetSize()
            
            local cameraPosition = Vector(mouseX, mouseY, 0)
            
            local playableX = (1 - CommanderUI_MapLayoutPlayableWidth()) / 2 * (backgroundSize - cameraIconSize.x)
            local playableY = (1 - CommanderUI_MapLayoutPlayableHeight()) / 2 * (backgroundSize - cameraIconSize.y)

            if cameraPosition.x < backgroundScreenPosition.x + playableX then
                cameraPosition.x = backgroundScreenPosition.x + playableX
            elseif cameraPosition.x > (backgroundScreenPosition.x + backgroundSize) - playableX then
                cameraPosition.x = (backgroundScreenPosition.x + backgroundSize) - playableX
            end

            if cameraPosition.y < backgroundScreenPosition.y + playableY then
                cameraPosition.y = backgroundScreenPosition.y + playableY
            elseif cameraPosition.y > (backgroundScreenPosition.y + backgroundSize) - playableY then
                cameraPosition.y = (backgroundScreenPosition.y + backgroundSize) - playableY
            end
            
            cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
            cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y

            local horizontalScale = CommanderUI_MapLayoutHorizontalScale()
            local verticalScale = CommanderUI_MapLayoutVerticalScale()

            local moveX = (cameraPosition.x / backgroundSize) * horizontalScale
            local moveY = (cameraPosition.y / backgroundSize) * verticalScale

            CommanderUI_MapMoveView(moveX, moveY)
        end
    end

end

function GUIMinimap:SetBackgroundMode(setMode)

    self.mode = setMode
    local modeIsMini = self.mode == GUIMinimap.kModeMini
    
    // Needs to scale for now until the whole Commander UI is complete.
    local borderWidth = Client.GetScreenWidth() * 0.24
    local borderHeight = Client.GetScreenHeight() * 0.3
    if self.backgroundBorder then
        if modeIsMini then
            self.backgroundBorder:SetSize(Vector(borderWidth, borderHeight, 0))
            self.backgroundBorder:SetAnchor(GUIItem.Left, GUIItem.Bottom)
            self.backgroundBorder:SetPosition(Vector(0, -borderHeight, 0))
            self.backgroundBorder:SetIsVisible(true)
        else
            self.backgroundBorder:SetIsVisible(false)
        end
    end
    local borderExtraSize = ConditionalValue(self.backgroundBorder, borderWidth - self:GetBackgroundSize(), 0)
    
    local modeSize = self:GetBackgroundSize()
    self.background:SetSize(Vector(modeSize, modeSize, 0))
    self.background:SetAnchor(ConditionalValue(modeIsMini, GUIItem.Left, GUIItem.Center), ConditionalValue(modeIsMini, GUIItem.Bottom, GUIItem.Middle))
    // We want the background to sit "inside" the border so move it up and to the right a bit.
    local defaultPosition = Vector(borderExtraSize / 2, -self:GetBackgroundSize() - borderExtraSize / 2, 0)
    local modePosition = ConditionalValue(modeIsMini, defaultPosition, Vector(-modeSize / 2, -modeSize / 2, 0))
    self.background:SetPosition(modePosition)
    
end

function GUIMinimap:GetBackgroundSize()

    local multiplier = ConditionalValue(self.mode == GUIMinimap.kModeMini, 1, 3)
    return GUIMinimap.kMinimapSize * multiplier
    
end

function GUIMinimap:GetPositionOnBackground(xPos, yPos, currentSize)

    local backgroundScreenPosition = self.background:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
    local inBackgroundPosition = Vector((xPos * self:GetBackgroundSize()) - (currentSize.x / 2), (yPos * self:GetBackgroundSize()) - (currentSize.y / 2), 0)
    return backgroundScreenPosition + inBackgroundPosition

end

function GUIMinimap:SendKeyEvent(key, down)

    //CommanderUI_MapClicked(x, y, button, index)
    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
        self.mousePressed["LMB"]["Down"] = down
        local mouseX, mouseY = Client.GetCursorPosScreen()
        /*if down and self.background:ContainsPoint(Vector(mouseX, mouseY, 0)) then
            CommanderUI_MapClicked(mouseXNormalized, mouseYNormalized, 0, nil)
            return true
        end*/
    elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"]  ~= down then
        self.mousePressed["RMB"]["Down"]  = down
        local mouseX, mouseY = Client.GetCursorPosScreen()
        /*if down and self.background:ContainsPoint(Vector(mouseX, mouseY, 0)) then
            CommanderUI_MapClicked(mouseXNormalized, mouseYNormalized, 1, nil)
            return true
        end*/
    // Disabled for now.
    /*elseif key == InputKey.M then
        self:SetBackgroundMode(ConditionalValue(down, GUIMinimap.kModeBig, GUIMinimap.kModeMini))
        return true*/
    end
    
    return false

end