// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the other commander UIs and input for the commander UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIButton.lua")
Script.Load("lua/GUIResourceDisplay.lua")

class 'GUICommanderManager' (GUIScript)

// The number of pixels that the cursor needs to move in order
// to enable the marquee selector.
GUICommanderManager.kEnableSelectorMoveAmount = 5
GUICommanderManager.kSelectorColor = Color(0.0, 0, 0.5, 0.15)

GUICommanderManager.kLogoutWidth = 80
GUICommanderManager.kLogoutHeight = 80
GUICommanderManager.kLogoutOffset = 10
GUICommanderManager.kLogoutTextureName = "ui/logout.dds"
GUICommanderManager.kLogoutButtonWidth = 80
GUICommanderManager.kLogoutButtonHeight = 80

GUICommanderManager.kLocationTextOffset = 10

GUICommanderManager.kResourceDisplayOffset = 10
GUICommanderManager.kResourceDisplayWidth = 128

function GUICommanderManager:Initialize()

    self.mousePressed = { nil, nil }
    self.mouseDownPointX = 0
    self.mouseDownPointY = 0
    
    self.selectorCursorDown = false
    self.selectorStartX = 0
    self.selectorStartY = 0
    
    // Only marine GUI is updated for now.
    if not CommanderUI_IsAlienCommander() then
    
        self:CreateSelector()
        
        self:CreateLogoutButton()
        
        self:CreateLocationText()
        
        self:CreateResourceDisplay()
        
    end
    
end

function GUICommanderManager:CreateSelector()

    self.selector = GUI.CreateGraphicsItem()
    self.selector:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.selector:SetIsVisible(self.selectorCursorDown)
    
end

function GUICommanderManager:CreateLogoutButton()

    local settingsTable = { }
    settingsTable.Width = GUICommanderManager.kLogoutWidth
    settingsTable.Height = GUICommanderManager.kLogoutHeight
    settingsTable.X = -settingsTable.Width - GUICommanderManager.kLogoutOffset
    settingsTable.Y = GUICommanderManager.kLogoutOffset
    settingsTable.TextureName = GUICommanderManager.kLogoutTextureName
    
    local textureCoordYOffset = 0
    if CommanderUI_IsAlienCommander() then
        // The alien button is below the marine in the texture.
        textureCoordYOffset = GUICommanderManager.kLogoutButtonHeight * 3
    end
    settingsTable.DefaultState = { X1 = 0, Y1 = textureCoordYOffset, X2 = GUICommanderManager.kLogoutButtonWidth, Y2 = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight }
    textureCoordYOffset = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight
    settingsTable.PressState = { X1 = 0, Y1 = textureCoordYOffset, X2 = GUICommanderManager.kLogoutButtonWidth, Y2 = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight }
    textureCoordYOffset = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight
    settingsTable.HoverState = { X1 = 0, Y1 = textureCoordYOffset, X2 = GUICommanderManager.kLogoutButtonWidth, Y2 = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight }
    textureCoordYOffset = textureCoordYOffset + GUICommanderManager.kLogoutButtonHeight
    
    settingsTable.PressCallback = CommanderUI_Logout

    self.logoutButton = GUIButton()
    self.logoutButton:Initialize(settingsTable)
    self.logoutButton:SetAnchor(GUIItem.Right, GUIItem.Top)

end

function GUICommanderManager:CreateLocationText()

    self.locationText = GUI.CreateTextItem()
    self.locationText:SetFontSize(40)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUITextItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUITextItem.Align_Min)
    self.locationText:SetPosition(Vector(GUICommanderManager.kLocationTextOffset, GUICommanderManager.kLocationTextOffset, 0))
    self.locationText:SetColor(Color(1, 1, 1, 0.5))
    self.locationText:SetText(PlayerUI_GetLocationName())

end

function GUICommanderManager:CreateResourceDisplay()

    local settingsTable = { }
    settingsTable.Width = GUICommanderManager.kResourceDisplayWidth
    settingsTable.BackgroundAnchorX = GUIItem.Middle
    settingsTable.BackgroundAnchorY = GUIItem.Top
    settingsTable.X = -settingsTable.Width / 2
    settingsTable.Y = GUICommanderManager.kResourceDisplayOffset

    self.resourceDisplay = GUIResourceDisplay()
    self.resourceDisplay:Initialize(settingsTable)

end

function GUICommanderManager:Uninitialize()

    if self.selector then
        GUI.DestroyItem(self.selector)
        self.selector = nil
    end
    
    if self.logoutButton then
        self.logoutButton:Uninitialize()
        self.logoutButton = nil
    end
    
    if self.locationText then
        GUI.DestroyItem(self.locationText)
        self.locationText = nil
    end
    
    if self.resourceDisplay then
        self.resourceDisplay:Uninitialize()
        self.resourceDisplay = nil
    end
    
end

function GUICommanderManager:SendKeyEvent(key, down)

    if self.logoutButton and self.logoutButton:SendKeyEvent(key, down) then
        return true
    end
    
    if key == InputKey.MouseButton0 and self.mousePressed[1] ~= down then
        self.mousePressed[1] = down
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if down then
            self.mouseDownPointX = mouseX
            self.mouseDownPointY = mouseY
            CommanderUI_OnMousePressGOBRIAN(0, mouseX, mouseY)
        else
            if self.selectorCursorDown == true then
                self:SelectorUp(mouseX, mouseY)
            else
                CommanderUI_OnMouseReleaseGOBRIAN(0, mouseX, mouseY)
            end
        end
        return true
    elseif key == InputKey.MouseButton1 and self.mousePressed[2] ~= down then
        self.mousePressed[2] = down
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if down then
            CommanderUI_OnMousePressGOBRIAN(1, mouseX, mouseY)
        else
            CommanderUI_OnMouseReleaseGOBRIAN(1, mouseX, mouseY)
        end
        return true
    end
    
    return false

end

function GUICommanderManager:Update(deltaTime)

    self:UpdateInput(deltaTime)
    self:UpdateSelector(deltaTime)
    
    if self.logoutButton then
        self.logoutButton:Update(deltaTime)
    end
    
    if self.locationText then
        self.locationText:SetText(PlayerUI_GetLocationName())
    end
    
    if self.resourceDisplay then
        self.resourceDisplay:Update(deltaTime)
    end
    
end

function GUICommanderManager:UpdateInput(deltaTime)
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    local scrollX = 0
    local scrollY = 0
    local screenWidth = Client.GetScreenWidth()
    local screenHeight = Client.GetScreenHeight()
    
    if mouseX <= 2 then
        scrollX = -1
    elseif mouseX >= screenWidth - 2 then
        scrollX = 1
    end

    if mouseY <= 2 then
        scrollY = -1
    elseif mouseY >= screenHeight - 2 then
        scrollY = 1
    end
    
    CommanderUI_ScrollViewGOBRIAN(scrollX, scrollY)
    
    // Check if the selector should be enabled.
    if self.mousePressed[1] == true then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        local diffX = math.abs(self.mouseDownPointX - mouseX)
        local diffY = math.abs(self.mouseDownPointY - mouseY)
        if diffX > GUICommanderManager.kEnableSelectorMoveAmount or diffY > GUICommanderManager.kEnableSelectorMoveAmount then
            self:SelectorDown(self.mouseDownPointX, self.mouseDownPointY)
        end
    end

end

function GUICommanderManager:UpdateSelector(deltaTime)

    if self.selector then
        self.selector:SetIsVisible(self.selectorCursorDown)
    
        if self.selectorCursorDown then
            self.selector:SetPosition(Vector(self.selectorStartX, self.selectorStartY, 0))
            local mouseX, mouseY = Client.GetCursorPosScreen()
            self.selector:SetSize(Vector(mouseX - self.selectorStartX, mouseY - self.selectorStartY, 0))
            self.selector:SetColor(GUICommanderManager.kSelectorColor)
        end
    end

end

function GUICommanderManager:SelectorDown(mouseX, mouseY)

    if self.selectorCursorDown == true then
        return
    end
    
	self.selectorCursorDown = true
	
	self.selectorStartX = mouseX
	self.selectorStartY = mouseY

end

function GUICommanderManager:SelectorUp(mouseX, mouseY)

	if self.selectorCursorDown ~= true then
	    return
	end
	
	self.selectorCursorDown = false
	
	CommanderUI_SelectMarqueeGOBRIAN(self.selectorStartX, self.selectorStartY, mouseX, mouseY)
	
end