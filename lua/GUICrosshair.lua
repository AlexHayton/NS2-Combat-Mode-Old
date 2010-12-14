
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICrosshair.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the crosshairs for aliens and marines.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICrosshair' (GUIScript)

GUICrosshair.kFontSize = 20
GUICrosshair.kTextFadeTime = 0.25
GUICrosshair.kCrosshairSize = 64
GUICrosshair.kTextYOffset = -40
GUICrosshair.kTextureWidth = 64
GUICrosshair.kTextureHeight = 512

function GUICrosshair:Initialize()

    self.crosshairs = GUI.CreateGraphicsItem()
    self.crosshairs:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0))
    self.crosshairs:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairs:SetPosition(Vector(-GUICrosshair.kCrosshairSize / 2, -GUICrosshair.kCrosshairSize / 2, 0))
    self.crosshairs:SetTexture("ui/crosshairs.dds")
    self.crosshairs:SetIsVisible(false)

    self.crosshairsText = GUI.CreateTextItem()
    self.crosshairsText:SetFontSize(GUICrosshair.kFontSize)
    self.crosshairsText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairsText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.crosshairsText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.crosshairsText:SetPosition(Vector(0, GUICrosshair.kTextYOffset, 0))
    self.crosshairsText:SetColor(Color(1, 1, 1, 1))
    self.crosshairsText:SetText("")
    self.crosshairs:AddChild(self.crosshairsText)
    
    self.currAlpha = 0

end

function GUICrosshair:Uninitialize()

    // Destroying the crosshair will destroy all it's children too.
    GUI.DestroyItem(self.crosshairs)
    self.crosshairs = nil
    self.crosshairsText = nil
    
end

function GUICrosshair:Update(deltaTime)

    local xCoord = PlayerUI_GetCrosshairX()
    local yCoord = PlayerUI_GetCrosshairY()
    if PlayerUI_GetCrosshairWidth() == 0 then
        self.crosshairs:SetIsVisible(false)
    else
        self.crosshairs:SetIsVisible(true)
        self.crosshairs:SetTextureCoordinates(xCoord / GUICrosshair.kTextureWidth, yCoord / GUICrosshair.kTextureHeight,
                                             (xCoord + PlayerUI_GetCrosshairWidth()) / GUICrosshair.kTextureWidth, (yCoord + PlayerUI_GetCrosshairHeight()) / GUICrosshair.kTextureHeight)
        local currentColor = ColorIntToColor(PlayerUI_GetCrosshairTextColor())
        local setText = PlayerUI_GetCrosshairText()
        local fadingIn = string.len(setText) > 0
        if fadingIn then
            self.crosshairsText:SetText(setText)
            self.currAlpha = math.min(1, self.currAlpha + deltaTime * (1 / GUICrosshair.kTextFadeTime))
        else
            self.currAlpha = math.max(0, self.currAlpha - deltaTime * (1 / GUICrosshair.kTextFadeTime))
        end
        currentColor.a = self.currAlpha
        self.crosshairsText:SetColor(currentColor)
    end
    
end