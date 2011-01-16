
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIButton.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a button with a call back when pressed.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIButton' (GUIScript)

// Settings:
// settingsTable.Width
// settingsTable.Height
// settingsTable.X
// settingsTable.Y
// settingsTable.TextureName
// settingsTable.DefaultState, HoverState, and PressState table with X1, Y1, X2, Y2 texture coordinates
// settingsTable.PressCallback function with no parameters

function GUIButton:Initialize(settingsTable)
    
    self.button = GUI.CreateGraphicsItem()
    self.button:SetSize(Vector(settingsTable.Width, settingsTable.Height, 0))
    self.button:SetPosition(Vector(settingsTable.X, settingsTable.Y, 0))
    self.button:SetTexture(settingsTable.TextureName)
    
    self.defaultState = { X1 = settingsTable.DefaultState.X1, Y1 = settingsTable.DefaultState.Y1, X2 = settingsTable.DefaultState.X2, Y2 = settingsTable.DefaultState.Y2 }
    self.hoverState = { X1 = settingsTable.HoverState.X1, Y1 = settingsTable.HoverState.Y1, X2 = settingsTable.HoverState.X2, Y2 = settingsTable.HoverState.Y2 }
    self.pressState = { X1 = settingsTable.PressState.X1, Y1 = settingsTable.PressState.Y1, X2 = settingsTable.PressState.X2, Y2 = settingsTable.PressState.Y2 }
    
    self.pressCallback = settingsTable.PressCallback
    
    self.currentState = self.defaultState
    self:SetState(self.defaultState)
    
end

function GUIButton:Uninitialize()

    GUI.DestroyItem(self.button)
    self.button = nil
    
end

function GUIButton:Update(deltaTime)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    local containsPoint, withinX, withinY = GUIItemContainsPoint(self.button, mouseX, mouseY)
    if containsPoint then
        if self.mousePressed then
            self:SetState(self.pressState)
        else
            self:SetState(self.hoverState)
        end
    else
        self:SetState(self.defaultState)
    end
    
end

function GUIButton:SendKeyEvent(key, down)

    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
        self.mousePressed = down
        // Check if the button was pressed.
        if not self.mousePressed then
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.button, mouseX, mouseY)
            if containsPoint then
                self.pressCallback()
                return true
            end
        end
    end
    
    return false
    
end

function GUIButton:SetState(stateTable)

    self.currentState = stateTable
    self.button:SetTexturePixelCoordinates(stateTable.X1, stateTable.Y1, stateTable.X2, stateTable.Y2)
    
end

function GUIButton:SetAnchor(horzAnchor, vertAnchor)

    self.button:SetAnchor(horzAnchor, vertAnchor)

end

function GUIButton:GetBackground()

    return self.button

end