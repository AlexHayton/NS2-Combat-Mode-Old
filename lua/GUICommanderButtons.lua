// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderButtons.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the right commander panel used to display buttons for commander actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIBorderBackground.lua")
Script.Load("lua/GUICommanderTooltip.lua")

class 'GUICommanderButtons' (GUIScript)

GUICommanderButtons.kButtonStatusDisabled = { Id = 0, Color = Color(0, 0, 0, 0), Visible = false }
GUICommanderButtons.kButtonStatusEnabled = { Id = 1, Color = Color(1, 1, 1, 1), Visible = true }
GUICommanderButtons.kButtonStatusRed = { Id = 2, Color = Color(1, 0, 0, 1), Visible = true }
GUICommanderButtons.kButtonStatusOff = { Id = 3, Color = Color(0.3, 0.3, 0.3, 1), Visible = true }
GUICommanderButtons.kButtonStatusData = { }
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusDisabled.Id] = GUICommanderButtons.kButtonStatusDisabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusEnabled.Id] = GUICommanderButtons.kButtonStatusEnabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusRed.Id] = GUICommanderButtons.kButtonStatusRed
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusOff.Id] = GUICommanderButtons.kButtonStatusOff

GUICommanderButtons.kBackgroundTexture = "ui/marine_commander_background.dds"
GUICommanderButtons.kBackgroundTexturePartWidth = 60
GUICommanderButtons.kBackgroundTexturePartHeight = 46
GUICommanderButtons.kBackgroundWidth = 285
GUICommanderButtons.kBackgroundHeight = 225
// The background is offset from the edge of the screen.
GUICommanderButtons.kBackgroundOffset = 10

// Used just for testing.
GUICommanderButtons.kExtraYOffset = 0

GUICommanderButtons.kButtonWidth = 65
GUICommanderButtons.kButtonHeight = 65
GUICommanderButtons.kButtonXOffset = 10
GUICommanderButtons.kButtonYOffset = 10

GUICommanderButtons.kNumberMarineButtonRows = 3
GUICommanderButtons.kNumberMarineButtonColumns = 4
GUICommanderButtons.kNumberMarineButtons = GUICommanderButtons.kNumberMarineButtonRows * GUICommanderButtons.kNumberMarineButtonColumns

GUICommanderButtons.kIdleWorkersSize = 48
GUICommanderButtons.kIdleWorkersXOffset = 5
GUICommanderButtons.kIdleWorkersTextureWidth = 80
GUICommanderButtons.kIdleWorkersTextureHeight = 80
GUICommanderButtons.kIdleWorkersFontSize = 20

function GUICommanderButtons:Initialize()

    self.buttons = { }
    
    self.alienCommander = CommanderUI_IsAlienCommander()
    
    if self.alienCommander then
        self:InitializeAlienBackground()
        self:InitializeAlienButtons()
    else
        self:InitializeMarineBackground()
        self:InitializeMarineButtons()
    end
    
    self:InitializeTooltip()
    
    self:InitializeIdleWorkersIcon()
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
end

function GUICommanderButtons:InitializeAlienBackground()

end

function GUICommanderButtons:InitializeMarineBackground()

    local settingsTable = { }
    settingsTable.Width = GUICommanderButtons.kBackgroundWidth
    settingsTable.Height = GUICommanderButtons.kBackgroundHeight
    settingsTable.X = -settingsTable.Width - GUICommanderButtons.kBackgroundOffset
    settingsTable.Y = -settingsTable.Height - GUICommanderButtons.kBackgroundOffset - GUICommanderButtons.kExtraYOffset
    settingsTable.TexturePartWidth = GUICommanderButtons.kBackgroundTexturePartWidth
    settingsTable.TexturePartHeight = GUICommanderButtons.kBackgroundTexturePartHeight
    settingsTable.TextureName = GUICommanderButtons.kBackgroundTexture
    settingsTable.TextureCoordinates = { }
    table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 0, X2 = 60, Y2 = 46 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 100, Y1 = 0, X2 = 158, Y2 = 46 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 0, X2 = 255, Y2 = 46 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 106, X2 = 60, Y2 = 148 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 101, Y1 = 106, X2 = 158, Y2 = 148 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 106, X2 = 255, Y2 = 148 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 210, X2 = 60, Y2 = 255 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 100, Y1 = 210, X2 = 158, Y2 = 255 })
    table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 210, X2 = 255, Y2 = 255 })

    self.background = GUIBorderBackground()
    self.background:Initialize(settingsTable)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Bottom)

end

function GUICommanderButtons:InitializeAlienButtons()

end

function GUICommanderButtons:InitializeMarineButtons()

    self.highlightItem = GUI.CreateGraphicsItem()
    self.highlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.highlightItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
    self.highlightItem:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    local textureWidth, textureHeight = CommanderUI_MenuImageSize()
    local buttonWidth = CommanderUI_MenuButtonWidth()
    local buttonHeight = CommanderUI_MenuButtonHeight()
    self.highlightItem:SetTexturePixelCoordinates(textureWidth - buttonWidth, textureHeight - buttonHeight, textureWidth, textureHeight)
    self.highlightItem:SetIsVisible(false)
    
    for i = 1, GUICommanderButtons.kNumberMarineButtons do
        local buttonItem = GUI.CreateGraphicsItem()
        buttonItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        buttonItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
        local xPos = ((i - 1) % GUICommanderButtons.kNumberMarineButtonColumns) * GUICommanderButtons.kButtonWidth
        local yPos = math.floor(((i - 1) / GUICommanderButtons.kNumberMarineButtonColumns)) * GUICommanderButtons.kButtonHeight
        buttonItem:SetPosition(Vector(xPos + GUICommanderButtons.kButtonXOffset, yPos + GUICommanderButtons.kButtonYOffset, 0))
        buttonItem:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
        self.background:AddChild(buttonItem)
        table.insert(self.buttons, buttonItem)
        self:UpdateButtonStatus(i)
    end

end

function GUICommanderButtons:InitializeTooltip()

    local settingsTable = { }
    settingsTable.Width = GUICommanderButtons.kBackgroundWidth
    settingsTable.Height = 80
    settingsTable.X = 0
    settingsTable.Y = -80
    settingsTable.TexturePartWidth = GUICommanderButtons.kBackgroundTexturePartWidth
    settingsTable.TexturePartHeight = GUICommanderButtons.kBackgroundTexturePartHeight
    settingsTable.IsAlienTooltip = self.alienCommander

    self.tooltip = GUICommanderTooltip()
    self.tooltip:Initialize(settingsTable)
    self.background:AddChild(self.tooltip:GetBackground())

end

function GUICommanderButtons:InitializeIdleWorkersIcon()

    self.idleWorkers = GUI.CreateGraphicsItem()
    self.idleWorkers:SetSize(Vector(GUICommanderButtons.kIdleWorkersSize, GUICommanderButtons.kIdleWorkersSize, 0))
    self.idleWorkers:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.idleWorkers:SetPosition(Vector(-GUICommanderButtons.kIdleWorkersSize - GUICommanderButtons.kIdleWorkersXOffset, 0, 0))
    self.idleWorkers:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    local coordinates = CommanderUI_GetIdleWorkerOffset()
    local x1 = GUICommanderButtons.kIdleWorkersTextureWidth * coordinates[1]
    local x2 = x1 + GUICommanderButtons.kIdleWorkersTextureWidth
    local y1 = GUICommanderButtons.kIdleWorkersTextureHeight * coordinates[2]
    local y2 = y1 + GUICommanderButtons.kIdleWorkersTextureHeight
    self.idleWorkers:SetTexturePixelCoordinates(x1, y1, x2, y2)
    self.idleWorkers:SetIsVisible(false)
    self.background:AddChild(self.idleWorkers)
    
    self.idleWorkersText = GUI.CreateTextItem()
    self.idleWorkersText:SetFontSize(GUICommanderButtons.kIdleWorkersFontSize)
    self.idleWorkersText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.idleWorkersText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.idleWorkersText:SetTextAlignmentY(GUITextItem.Align_Min)
    self.idleWorkersText:SetColor(Color(1, 1, 1, 1))
    self.idleWorkers:AddChild(self.idleWorkersText)

end

function GUICommanderButtons:Uninitialize()

    if self.highlightItem then
        GUI.DestroyItem(self.highlightItem)
        self.highlightItem = nil
    end
    
    if self.tooltip then
        self.tooltip:Uninitialize()
        self.tooltip = nil    
    end
    
    if self.idleWorkers then
        GUI.DestroyItem(self.idleWorkers)
        self.idleWorkers = nil
    end
    
    // Everything is attached to the background so destroying it will
    // destroy everything else.
    if self.background then
        self.background:Uninitialize()
        self.background = nil
        self.buttons = { }
    end
    
end

function GUICommanderButtons:Update(deltaTime)

    local tooltipButtonIndex = self:UpdateInput()
    
    self:UpdateTooltip(tooltipButtonIndex)
    
    self:UpdateIdleWorkersIcon()
    
    for i, buttonItem in ipairs(self.buttons) do
        self:UpdateButtonStatus(i)
    end
    
    self:UpdateButtonHotkeys()
    
end

function GUICommanderButtons:UpdateInput()

    local tooltipButtonIndex = nil
    
    if self.highlightItem then
        self.highlightItem:SetIsVisible(false)
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if GUIItemContainsPoint(self.background:GetBackground(), mouseX, mouseY) then
            for i, buttonItem in ipairs(self.buttons) do
                local buttonStatus = CommanderUI_MenuButtonStatus(i)
                if GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                    if (buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id) and
                       (self.targetedButton == nil or self.targetedButton == i) then
                        if self.highlightItem:GetParent() then
                            self.highlightItem:GetParent():RemoveChild(self.highlightItem)
                        end
                        buttonItem:AddChild(self.highlightItem)
                        self.highlightItem:SetIsVisible(true)
                        tooltipButtonIndex = i
                        break
                    // Off or red buttons can still have a tooltip.
                    elseif buttonStatus == GUICommanderButtons.kButtonStatusOff.Id or buttonStatus == GUICommanderButtons.kButtonStatusRed.Id then
                        tooltipButtonIndex = i
                        break
                    end
                end
            end
        elseif self.targetedButton ~= nil then
            CommanderUI_MousingAction(self.targetedButton, mouseX, mouseY)
        end
    end
    
    return tooltipButtonIndex

end

function GUICommanderButtons:UpdateTooltip(tooltipButtonIndex)

    local visible = tooltipButtonIndex ~= nil
    self.tooltip:SetIsVisible(visible)
    if visible then
        local tooltipData = CommanderUI_MenuButtonTooltip(tooltipButtonIndex)
        local text = tooltipData[1]
        local hotKey = tooltipData[2]
        local costNumber = tooltipData[3]
        local requires = tooltipData[4]
        local enabled = tooltipData[5]
        local info = tooltipData[6]
        local typeNumber = tooltipData[7]
        self.tooltip:UpdateData(text, hotKey, costNumber, requires, enabled, info, typeNumber)
    end

end

function GUICommanderButtons:UpdateIdleWorkersIcon()

    local numIdleWorkers = CommanderUI_GetIdleWorkerCount()
    if numIdleWorkers > 0 then
        self.idleWorkers:SetIsVisible(true)
        self.idleWorkersText:SetText(ToString(numIdleWorkers))
    else
        self.idleWorkers:SetIsVisible(false)
    end

end

function GUICommanderButtons:UpdateButtonStatus(buttonIndex)

    local buttonStatus = CommanderUI_MenuButtonStatus(buttonIndex)
    local buttonItem = self.buttons[buttonIndex]
    
    buttonItem:SetIsVisible(GUICommanderButtons.kButtonStatusData[buttonStatus].Visible)
    buttonItem:SetColor(GUICommanderButtons.kButtonStatusData[buttonStatus].Color)
    
    if buttonItem:GetIsVisible() then
        local buttonWidth = CommanderUI_MenuButtonWidth()
        local buttonHeight = CommanderUI_MenuButtonHeight()
        local buttonXOffset = CommanderUI_MenuButtonXOffset(buttonIndex)
        local buttonYOffset = CommanderUI_MenuButtonYOffset(buttonIndex)

        if buttonXOffset and buttonYOffset then
            local textureXOffset = buttonXOffset * buttonWidth
            local textureYOffset = buttonYOffset * buttonHeight
            buttonItem:SetTexturePixelCoordinates(textureXOffset, textureYOffset, textureXOffset + buttonWidth, textureYOffset + buttonHeight)
        else
            // Display the whole texture if the offsets were not found.
            buttonItem:SetTextureCoordinates(0, 0, 1, 1)
        end
    end
    
    if self.targetedButton ~= nil then
        if self.targetedButton == buttonIndex then
            buttonItem:SetColor(GUICommanderButtons.kButtonStatusEnabled.Color)
        else
            buttonItem:SetColor(GUICommanderButtons.kButtonStatusOff.Color)
        end
    end

end

function GUICommanderButtons:UpdateButtonHotkeys()

    local triggeredButton = CommanderUI_HotkeyTriggeredButton()
    if triggeredButton ~= nil then
        local buttonStatus = CommanderUI_MenuButtonStatus(triggeredButton)
        // Only allow hotkeys on enabled buttons.
        if buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id then
            if CommanderUI_MenuButtonRequiresTarget(triggeredButton) then
                self:SetTargetedButton(triggeredButton)
                local mouseX, mouseY = Client.GetCursorPosScreen()
                CommanderUI_MousingAction(triggeredButton, mouseX, mouseY)
            else
                CommanderUI_MenuButtonAction(triggeredButton)
            end
        end
    end

end

function GUICommanderButtons:SetTargetedButton(setButton)

    self.targetedButton = setButton
    for i, buttonItem in ipairs(self.buttons) do
        self:UpdateButtonStatus(i)
    end

end

function GUICommanderButtons:SendKeyEvent(key, down)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
        self.mousePressed["LMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
    elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
        self.mousePressed["RMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
    end
    
end

function GUICommanderButtons:MousePressed(key, mouseX, mouseY)

    if key == InputKey.MouseButton1 then
        // Cancel targeted button upon right mouse press.
        if self.targetedButton ~= nil then
            self:SetTargetedButton(nil)
        end
    elseif key == InputKey.MouseButton0 then
        if self.idleWorkers:GetIsVisible() and GUIItemContainsPoint(self.idleWorkers, mouseX, mouseY) then
            CommanderUI_ClickedIdleWorker()
        elseif self.targetedButton ~= nil then
            if CommanderUI_IsValid(self.targetedButton, mouseX, mouseY) then
                CommanderUI_TargetedAction(self.targetedButton, mouseX, mouseY, 1)
            else
                CommanderUI_ActionCancelled()
            end
            self:SetTargetedButton(nil)
        else
            for i, buttonItem in ipairs(self.buttons) do
                local buttonStatus = CommanderUI_MenuButtonStatus(i)
                if buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id and
                   GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                    if CommanderUI_MenuButtonRequiresTarget(i) then
                        self:SetTargetedButton(i)
                        CommanderUI_MousingAction(i, mouseX, mouseY)
                    elseif self.targetedButton == nil then
                        CommanderUI_MenuButtonAction(i)
                    end
                    break
                end
            end
        end
    end

end