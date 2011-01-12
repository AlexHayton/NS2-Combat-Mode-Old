// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISelectionPanel.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the middle commander panel used to display info related to what is currently selected.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIIncrementBar.lua")

class 'GUISelectionPanel' (GUIScript)

GUISelectionPanel.kFontName = "Arial"
GUISelectionPanel.kFontColor = Color(1, 1, 1)

GUISelectionPanel.kSelectionTexture = "ui/marine_commander.dds"

// The panel will scale with the screen resolution. It is based on
// this screen width.
GUISelectionPanel.kPanelReferenceScreenWidth = 1280
GUISelectionPanel.kPanelWidth = 550
GUISelectionPanel.kPanelHeight = 150
GUISelectionPanel.kPanelEndCapWidth = 38

GUISelectionPanel.kYOffset = -150 - 10

GUISelectionPanel.kSelectedIconXOffset = 20
GUISelectionPanel.kSelectedIconYOffset = 20
GUISelectionPanel.kSelectedIconSize = 60
GUISelectionPanel.kSelectedIconTextureWidth = 80
GUISelectionPanel.kSelectedIconTextureHeight = 80

GUISelectionPanel.kSelectedNameFontSize = 22
GUISelectionPanel.kSelectedNameXOffset = 8

GUISelectionPanel.kSelectedLocationTextFontSize = 18

GUISelectionPanel.kSelectedSquadTextFontSize = 18

GUISelectionPanel.kSelectedHealthTextFontSize = 22

GUISelectionPanel.kSelectedCustomTextFontSize = 20
GUISelectionPanel.kSelectedCustomTextXOffset = -20
GUISelectionPanel.kSelectedCustomTextYOffset = 20

function GUISelectionPanel:Initialize()

    self.background = GUI.CreateGraphicsItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.background:SetTexture(GUISelectionPanel.kSelectionTexture)
    self.background:SetTexturePixelCoordinates(50, 0, 50 + 182, 165)
    
    self.backgroundRightEndCap = GUI.CreateGraphicsItem()
    self.backgroundRightEndCap:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.backgroundRightEndCap:SetSize(Vector(GUISelectionPanel.kPanelEndCapWidth, GUISelectionPanel.kPanelHeight, 0))
    self.backgroundRightEndCap:SetPosition(Vector(-GUISelectionPanel.kPanelEndCapWidth, 0, 0))
    self.backgroundRightEndCap:SetTexture(GUISelectionPanel.kSelectionTexture)
    self.backgroundRightEndCap:SetTexturePixelCoordinates(240, 0, 240 + 36, 165)
    self.background:AddChild(self.backgroundRightEndCap)
    
    self.backgroundLeftEndCap = GUI.CreateGraphicsItem()
    self.backgroundLeftEndCap:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.backgroundLeftEndCap:SetSize(Vector(GUISelectionPanel.kPanelEndCapWidth, GUISelectionPanel.kPanelHeight, 0))
    self.backgroundLeftEndCap:SetPosition(Vector(-GUISelectionPanel.kPanelEndCapWidth, 0, 0))
    self.backgroundLeftEndCap:SetTexture(GUISelectionPanel.kSelectionTexture)
    self.backgroundLeftEndCap:SetTexturePixelCoordinates(0, 0, 36, 165)
    self.background:AddChild(self.backgroundLeftEndCap)
    
    self:InitializeSingleSelectionItems()
    self:InitializeMultiSelectionItems()

end

function GUISelectionPanel:InitializeSingleSelectionItems()

    self.singleSelectionItems = { }
    
    self.selectedIcon = GUI.CreateGraphicsItem()
    self.selectedIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedIcon:SetSize(Vector(GUISelectionPanel.kSelectedIconSize, GUISelectionPanel.kSelectedIconSize, 0))
    self.selectedIcon:SetPosition(Vector(GUISelectionPanel.kSelectedIconXOffset, GUISelectionPanel.kSelectedIconYOffset, 0))
    self.selectedIcon:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    self.selectedIcon:SetIsVisible(false)
    table.insert(self.singleSelectionItems, self.selectedIcon)
    self.backgroundLeftEndCap:AddChild(self.selectedIcon)
    
    self.selectedName = GUI.CreateTextItem()
    self.selectedName:SetFontSize(GUISelectionPanel.kSelectedNameFontSize)
    self.selectedName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedName:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.selectedName:SetPosition(Vector(GUISelectionPanel.kSelectedNameXOffset, 0, 0))
    self.selectedName:SetTextAlignmentX(GUITextItem.Align_Min)
    self.selectedName:SetTextAlignmentY(GUITextItem.Align_Min)
    self.selectedName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedName)
    self.selectedIcon:AddChild(self.selectedName)
    
    self.selectedLocationName = GUI.CreateTextItem()
    self.selectedLocationName:SetFontSize(GUISelectionPanel.kSelectedLocationTextFontSize)
    self.selectedLocationName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedLocationName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedLocationName:SetPosition(Vector(0, GUISelectionPanel.kSelectedNameFontSize, 0))
    self.selectedLocationName:SetTextAlignmentX(GUITextItem.Align_Min)
    self.selectedLocationName:SetTextAlignmentY(GUITextItem.Align_Min)
    self.selectedLocationName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedLocationName)
    self.selectedName:AddChild(self.selectedLocationName)
    
    self.selectedSquadName = GUI.CreateTextItem()
    self.selectedSquadName:SetFontSize(GUISelectionPanel.kSelectedSquadTextFontSize)
    self.selectedSquadName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedSquadName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedSquadName:SetPosition(Vector(0, GUISelectionPanel.kSelectedLocationTextFontSize, 0))
    self.selectedSquadName:SetTextAlignmentX(GUITextItem.Align_Min)
    self.selectedSquadName:SetTextAlignmentY(GUITextItem.Align_Min)
    self.selectedSquadName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedSquadName)
    self.selectedLocationName:AddChild(self.selectedSquadName)
    
    self.healthText = GUI.CreateTextItem()
    self.healthText:SetFontSize(GUISelectionPanel.kSelectedHealthTextFontSize)
    self.healthText:SetFontName(GUISelectionPanel.kFontName)
    self.healthText:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.healthText:SetPosition(Vector(0, 0, 0))
    self.healthText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.healthText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.healthText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.healthText)
    self.background:AddChild(self.healthText)
    
    local incrementBarSettings = { }
    incrementBarSettings.NumberOfIncrements = 20
    incrementBarSettings.IncrementWidth = 7
    incrementBarSettings.IncrementHeight = 12
    incrementBarSettings.IncrementSpacing = 2
    incrementBarSettings.TextureName = GUISelectionPanel.kSelectionTexture
    incrementBarSettings.TextureCoordinates = { X = 0, Y = 244, Width = 7, Height = 12 }
    incrementBarSettings.IncrementColor = CommanderUI_GetTeamColor()
    incrementBarSettings.LowPercentage = 0.25
    incrementBarSettings.LowPercentageIncrementColor = Color(1, 0, 0, 1)
    self.healthBar = GUIIncrementBar()
    self.healthBar:Initialize(incrementBarSettings)
    self.healthBar:GetBackground():SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.healthBar:GetBackground():SetPosition(Vector(-self.healthBar:GetWidth() / 2, GUISelectionPanel.kSelectedHealthTextFontSize / 2, 0))
    table.insert(self.singleSelectionItems, self.healthBar)
    self.background:AddChild(self.healthBar:GetBackground())
    
    local statusYOffset = GUISelectionPanel.kSelectedHealthTextFontSize + self.healthBar:GetHeight()
    self.statusText = GUI.CreateTextItem()
    self.statusText:SetFontSize(GUISelectionPanel.kSelectedHealthTextFontSize)
    self.statusText:SetFontName(GUISelectionPanel.kFontName)
    self.statusText:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.statusText:SetPosition(Vector(0, statusYOffset, 0))
    self.statusText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.statusText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.statusText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.statusText)
    self.background:AddChild(self.statusText)
    
    self.statusBar = GUIIncrementBar()
    // Don't use the lower percentage color for the status bar.
    incrementBarSettings.LowPercentage = 0
    self.statusBar:Initialize(incrementBarSettings)
    self.statusBar:GetBackground():SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.statusBar:GetBackground():SetPosition(Vector(-self.statusBar:GetWidth() / 2, statusYOffset + GUISelectionPanel.kSelectedHealthTextFontSize / 2, 0))
    table.insert(self.singleSelectionItems, self.statusBar)
    self.background:AddChild(self.statusBar:GetBackground())
    
    self.customText = GUI.CreateTextItem()
    self.customText:SetFontSize(GUISelectionPanel.kSelectedCustomTextFontSize)
    self.customText:SetFontName(GUISelectionPanel.kFontName)
    self.customText:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.customText:SetPosition(Vector(GUISelectionPanel.kSelectedCustomTextXOffset, GUISelectionPanel.kSelectedCustomTextYOffset, 0))
    self.customText:SetTextAlignmentX(GUITextItem.Align_Max)
    self.customText:SetTextAlignmentY(GUITextItem.Align_Min)
    self.customText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.customText)
    self.background:AddChild(self.customText)

end

function GUISelectionPanel:InitializeMultiSelectionItems()

    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:Uninitialize()

    // Everything is attached to the background so destroying it will
    // destroy everything else.
    GUI.DestroyItem(self.background)
    self.background = nil
    self.selectedIcon = nil
    self.selectedName = nil
    self.selectedLocationName = nil
    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:Update(deltaTime)

    // Update the size of the whole panel based on the screen resolution.
    local panelWidth = (Client.GetScreenWidth() / GUISelectionPanel.kPanelReferenceScreenWidth) * GUISelectionPanel.kPanelWidth
    self.background:SetSize(Vector(panelWidth, GUISelectionPanel.kPanelHeight, 0))
    self.background:SetPosition(Vector(-panelWidth / 2, GUISelectionPanel.kYOffset, 0))
    
    self:UpdateSelected()
    
end

function GUISelectionPanel:UpdateSelected()

    local selectedEntities = CommanderUI_GetSelectedEntities()
    local numberSelectedEntities = table.count(selectedEntities)
    self.selectedIcon:SetIsVisible(false)
    if numberSelectedEntities > 0 then
        if numberSelectedEntities == 1 then
            self:UpdateSingleSelection(selectedEntities[1])
        else
            self:UpdateMultiSelection(selectedEntities)
        end
    end
    
end

function GUISelectionPanel:UpdateSingleSelection(entityId)

    // Make all multiselection icons invisible.
    function SetItemInvisible(item) item:SetIsVisible(false) end
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    
    self.selectedIcon:SetIsVisible(true)
    self:SetIconTextureCoordinates(self.selectedIcon, entityId)
    if not self.selectedIcon:GetIsVisible() then
        return
    end
    
    local selectedDescription = CommanderUI_GetSelectedDescriptor(entityId)
    self.selectedName:SetIsVisible(true)
    self.selectedName:SetText(selectedDescription)
    local selectedLocationText = CommanderUI_GetSelectedLocation(entityId)
    self.selectedLocationName:SetIsVisible(true)
    self.selectedLocationName:SetText(selectedLocationText)
    
    local selectedBargraphs = CommanderUI_GetSelectedBargraphs(entityId)
    local healthText = selectedBargraphs[1]
    self.healthText:SetText(healthText)
    self.healthText:SetIsVisible(true)
    local healthPercentage = selectedBargraphs[2]
    self.healthBar:SetPercentage(healthPercentage)
    self.healthBar:SetIsVisible(true)
    self.statusText:SetIsVisible(false)
    self.statusBar:SetIsVisible(false)
    if table.count(selectedBargraphs) > 2 and selectedBargraphs[4] then
        local statusText = selectedBargraphs[3]
        self.statusText:SetIsVisible(true)
        self.statusText:SetText(statusText)
        local statusPercentage = selectedBargraphs[4]
        self.statusBar:SetIsVisible(true)
        self.statusBar:SetPercentage(statusPercentage)
    end
    
    local selectedSquadName = CommanderUI_GetSelectedSquad(entityId)
    self.selectedSquadName:SetIsVisible(false)
    if string.len(selectedSquadName) > 0 then
        self.selectedSquadName:SetIsVisible(true)
        self.selectedSquadName:SetText(selectedSquadName)
        local selectedSquadColor = CommanderUI_GetSelectedSquadColor(entityId)
        self.selectedSquadName:SetColor(ColorIntToColor(selectedSquadColor))
    end
    
    local singleSelectionCustomText = CommanderUI_GetSingleSelectionCustomText(entityId)
    if singleSelectionCustomText and string.len(singleSelectionCustomText) > 0 then
        self.customText:SetIsVisible(true)
        self.customText:SetText(singleSelectionCustomText)
    else
        self.customText:SetIsVisible(false)
    end

end

function GUISelectionPanel:UpdateMultiSelection(selectedEntityIds)

    // Make sure all the single selection items are invisible.
    function SetItemInvisible(item) item:SetIsVisible(false) end
    table.foreachfunctor(self.singleSelectionItems, SetItemInvisible)
    
    // Make all previous selection icons invisible.
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    
    local currentIconIndex = 1
    for i, selectedEntityId in ipairs(selectedEntityIds) do
        local selectedIcon = nil
        if table.count(self.multiSelectionIcons) >= currentIconIndex then
            selectedIcon = self.multiSelectionIcons[currentIconIndex]
        else
            selectedIcon = self:CreateMultiSelectionIcon()
        end
        selectedIcon:SetIsVisible(true)
        self:SetIconTextureCoordinates(selectedIcon, selectedEntityId)
        currentIconIndex = currentIconIndex + 1
    end

end

function GUISelectionPanel:CreateMultiSelectionIcon()

    local createdIcon = GUI.CreateGraphicsItem()
    createdIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    createdIcon:SetSize(Vector(GUISelectionPanel.kSelectedIconSize, GUISelectionPanel.kSelectedIconSize, 0))
    local xOffset = GUISelectionPanel.kSelectedIconXOffset + (GUISelectionPanel.kSelectedIconSize * table.count(self.multiSelectionIcons))
    createdIcon:SetPosition(Vector(xOffset, GUISelectionPanel.kSelectedIconYOffset, 0))
    createdIcon:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    self.backgroundLeftEndCap:AddChild(createdIcon)
    table.insert(self.multiSelectionIcons, createdIcon)
    return createdIcon

end

function GUISelectionPanel:SetIconTextureCoordinates(selectedIcon, entityId)

    local textureOffsets = CommanderUI_GetSelectedIconOffset(entityId)
    if textureOffsets and textureOffsets[1] and textureOffsets[2] then
        local pixelXOffset = textureOffsets[1] * GUISelectionPanel.kSelectedIconTextureWidth
        local pixelYOffset = textureOffsets[2] * GUISelectionPanel.kSelectedIconTextureHeight
        selectedIcon:SetTexturePixelCoordinates(pixelXOffset, pixelYOffset, pixelXOffset + GUISelectionPanel.kSelectedIconTextureWidth, pixelYOffset + GUISelectionPanel.kSelectedIconTextureHeight)
    else
        Shared.Message("Warning: Missing texture coordinates for selection panel icon")
        selectedIcon:SetIsVisible(false)
    end
    
end