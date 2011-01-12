
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIResourceDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying plasma, carbon, and number of resource towers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIResourceDisplay' (GUIScript)

// Settings:
// settingsTable.Width
// settingsTable.BackgroundAnchorX
// settingsTable.BackgroundAnchorY
// settingsTable.X
// settingsTable.Y
// settingsTable.IsAlien

GUIResourceDisplay.kIconSize = 24
GUIResourceDisplay.kFontSize = 16
GUIResourceDisplay.kIconTextureName = "ui/resources.dds"
GUIResourceDisplay.kIconTextureWidth = 32
GUIResourceDisplay.kIconTextureHeight = 32
GUIResourceDisplay.kIconXOffset = 5

function GUIResourceDisplay:Initialize(settingsTable)

    // Background.
    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize(Vector(settingsTable.Width, GUIResourceDisplay.kIconSize, 0))
    self.background:SetAnchor(settingsTable.BackgroundAnchorX, settingsTable.BackgroundAnchorY)
    self.background:SetPosition(Vector(settingsTable.X, settingsTable.Y, 0))
    // The background is an invisible container only.
    self.background:SetColor(Color(0, 0, 0, 0))
    
    // Plasma display.
    self.plasmaIcon = GUI.CreateGraphicsItem()
    self.plasmaIcon:SetSize(Vector(GUIResourceDisplay.kIconSize, GUIResourceDisplay.kIconSize, 0))
    self.plasmaIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.plasmaIcon:SetTexture(GUIResourceDisplay.kIconTextureName)
    self.plasmaIcon:SetTexturePixelCoordinates(0, GUIResourceDisplay.kIconTextureHeight,
                                               GUIResourceDisplay.kIconTextureWidth, GUIResourceDisplay.kIconTextureHeight * 2)
    self.background:AddChild(self.plasmaIcon)

    self.plasmaText = GUI.CreateTextItem()
    self.plasmaText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.plasmaText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.plasmaText:SetTextAlignmentX(GUITextItem.Align_Min)
    self.plasmaText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.plasmaText:SetPosition(Vector(GUIResourceDisplay.kIconXOffset, 0, 0))
    self.plasmaText:SetColor(Color(1, 1, 1, 1))
    self.plasmaText:SetFontIsBold(true)
    self.plasmaIcon:AddChild(self.plasmaText)
    
    // Carbon display.
    self.carbonIcon = GUI.CreateGraphicsItem()
    self.carbonIcon:SetSize(Vector(GUIResourceDisplay.kIconSize, GUIResourceDisplay.kIconSize, 0))
    self.carbonIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.carbonIcon:SetPosition(Vector(-GUIResourceDisplay.kIconSize / 2, 0, 0))
    self.carbonIcon:SetTexture(GUIResourceDisplay.kIconTextureName)
    self.carbonIcon:SetTexturePixelCoordinates(0, 0,
                                               GUIResourceDisplay.kIconTextureWidth, GUIResourceDisplay.kIconTextureHeight)
    self.background:AddChild(self.carbonIcon)

    self.carbonText = GUI.CreateTextItem()
    self.carbonText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.carbonText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.carbonText:SetTextAlignmentX(GUITextItem.Align_Min)
    self.carbonText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.carbonText:SetPosition(Vector(GUIResourceDisplay.kIconXOffset, 0, 0))
    self.carbonText:SetColor(Color(1, 1, 1, 1))
    self.carbonText:SetFontIsBold(true)
    self.carbonIcon:AddChild(self.carbonText)
    
    // Tower display.
    self.towerIcon = GUI.CreateGraphicsItem()
    self.towerIcon:SetSize(Vector(GUIResourceDisplay.kIconSize, GUIResourceDisplay.kIconSize, 0))
    self.towerIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.towerIcon:SetPosition(Vector(-GUIResourceDisplay.kIconSize, 0, 0))
    self.towerIcon:SetTexture(GUIResourceDisplay.kIconTextureName)
    self.towerIcon:SetTexturePixelCoordinates(0, GUIResourceDisplay.kIconTextureHeight * ConditionalValue(settingsTable.IsAlien, 3, 4),
                                              GUIResourceDisplay.kIconTextureWidth, GUIResourceDisplay.kIconTextureHeight * ConditionalValue(settingsTable.IsAlien, 4, 5))
    self.background:AddChild(self.towerIcon)

    self.towerText = GUI.CreateTextItem()
    self.towerText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.towerText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.towerText:SetTextAlignmentX(GUITextItem.Align_Min)
    self.towerText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.towerText:SetPosition(Vector(GUIResourceDisplay.kIconXOffset, 0, 0))
    self.towerText:SetColor(Color(1, 1, 1, 1))
    self.towerText:SetFontIsBold(true)
    self.towerIcon:AddChild(self.towerText)
    
end

function GUIResourceDisplay:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIResourceDisplay:Update(deltaTime)

    self.plasmaText:SetText(ToString(PlayerUI_GetPlayerResources()))
    
    self.carbonText:SetText(ToString(PlayerUI_GetTeamResources()))
    
    self.towerText:SetText(ToString(CommanderUI_GetTeamHarvesterCount()))
    
end