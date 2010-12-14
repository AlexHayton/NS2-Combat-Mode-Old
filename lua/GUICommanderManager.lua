// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the other commander UIs and input for the commander UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICommanderManager' (GUIScript)

// The number of pixels that the cursor needs to move in order
// to enable the marquee selector.
GUICommanderManager.kEnableSelectorMoveAmount = 5
GUICommanderManager.kSelectorColor = Color(0.0, 0, 0.5, 0.15)

// The following is temp code until the commander UI is replaced, COMM_REPLACE_TAG
GUICommanderManager.kSelectorColor.a = 0

function GUICommanderManager:Initialize()

    self.mousePressed = { nil, nil }
    self.mouseDownPointX = 0
    self.mouseDownPointY = 0
    
    self.selectorCursorDown = false
    self.selectorStartX = 0
    self.selectorStartY = 0
    
    self:CreateSelector()
    
end

function GUICommanderManager:CreateSelector()

    self.selector = GUI.CreateGraphicsItem()
    self.selector:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.selector:SetIsVisible(self.selectorCursorDown)
    
end

function GUICommanderManager:Uninitialize()

    if self.selector then
        GUI.DestroyItem(self.selector)
        self.selector = nil
    end
    
end

function GUICommanderManager:SendKeyEvent(key, down)

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
    
end

function GUICommanderManager:UpdateInput(deltaTime)
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    local scrollX = 0
    local scrollY = 0
    local screenWidth = Client.GetScreenWidth()
    local screenHeight = Client.GetScreenHeight()
    
    if mouseX <= 0 then
        scrollX = -1
    elseif mouseX >= screenWidth - 2 then
        scrollX = 1
    end

    if mouseY <= 0 then
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

    self.selector:SetIsVisible(self.selectorCursorDown)
    
    if self.selectorCursorDown then
        self.selector:SetPosition(Vector(self.selectorStartX, self.selectorStartY, 0))
        local mouseX, mouseY = Client.GetCursorPosScreen()
        self.selector:SetSize(Vector(mouseX - self.selectorStartX, mouseY - self.selectorStartY, 0))
        self.selector:SetColor(GUICommanderManager.kSelectorColor)
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