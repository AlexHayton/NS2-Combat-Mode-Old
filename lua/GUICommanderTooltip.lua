
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderTooltip.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a tooltip for the commander when mousing over the UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUICommanderTooltip' (GUIScript)

// settingsTable.Width
// settingsTable.Height
// settingsTable.X
// settingsTable.Y
// settingsTable.TexturePartWidth
// settingsTable.TexturePartHeight
// settingsTable.IsAlienTooltip

GUICommanderTooltip.kAlienBackgroundTexture = "ui/alien_buildmenu.dds"
GUICommanderTooltip.kMarineBackgroundTexture = "ui/marine_commander_background.dds"

GUICommanderTooltip.kResourceIconTexture = "ui/resources.dds"

GUICommanderTooltip.kTextFontSize = 16
GUICommanderTooltip.kTextXOffset = 10
GUICommanderTooltip.kTextYOffset = GUICommanderTooltip.kTextFontSize - 4

GUICommanderTooltip.kHotkeyFontSize = 16
GUICommanderTooltip.kHotkeyXOffset = 5

GUICommanderTooltip.kResourceIconSize = 32
GUICommanderTooltip.kResourceIconTextureWidth = 32
GUICommanderTooltip.kResourceIconTextureHeight = 32
GUICommanderTooltip.kResourceIconXOffset = -5
GUICommanderTooltip.kResourceIconYOffset = 5

GUICommanderTooltip.kResourceColors = { Color(0, 1, 0, 1), Color(0.2, 0.4, 1, 1), Color(1, 0, 1, 1) }

GUICommanderTooltip.kCostFontSize = 16
GUICommanderTooltip.kCostXOffset = -2

GUICommanderTooltip.kRequiresFontSize = 16
GUICommanderTooltip.kRequiresTextMaxHeight = 32
GUICommanderTooltip.kRequiresYOffset = 10

GUICommanderTooltip.kEnablesFontSize = 16
GUICommanderTooltip.kEnablesTextMaxHeight = 48
GUICommanderTooltip.kEnablesYOffset = 10

GUICommanderTooltip.kInfoFontSize = 16
GUICommanderTooltip.kInfoTextMaxHeight = 48
GUICommanderTooltip.kInfoYOffset = 10

function GUICommanderTooltip:Initialize(settingsTable)

    local textureName = GUICommanderTooltip.kMarineBackgroundTexture
    if settingsTable.IsAlienTooltip then
        textureName = GUICommanderTooltip.kAlienBackgroundTexture
    end
    settingsTable.TextureName = textureName
    settingsTable.TextureCoordinates = { }
    if settingsTable.IsAlienTooltip then
    else
        table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 0, X2 = 60, Y2 = 46 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 100, Y1 = 0, X2 = 158, Y2 = 46 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 0, X2 = 255, Y2 = 46 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 106, X2 = 60, Y2 = 148 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 101, Y1 = 106, X2 = 158, Y2 = 148 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 106, X2 = 255, Y2 = 148 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 0, Y1 = 210, X2 = 60, Y2 = 255 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 100, Y1 = 210, X2 = 158, Y2 = 255 })
        table.insert(settingsTable.TextureCoordinates, { X1 = 196, Y1 = 210, X2 = 255, Y2 = 255 })
    end

    self.background = GUIBorderBackground()
    self.background:Initialize(settingsTable)
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    
    self.tooltipWidth = settingsTable.Width
    self.tooltipHeight = settingsTable.Height
    
    self.tooltipX = settingsTable.X
    self.tooltipY = settingsTable.Y
    
    self.text = GUI.CreateTextItem()
    self.text:SetFontSize(GUICommanderTooltip.kTextFontSize)
    self.text:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.text:SetTextAlignmentX(GUITextItem.Align_Min)
    self.text:SetTextAlignmentY(GUITextItem.Align_Min)
    self.text:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, GUICommanderTooltip.kTextYOffset, 0))
    self.text:SetColor(Color(1, 1, 1, 1))
    self.text:SetText("")
    self.background:AddChild(self.text)
    
    self.text = GUI.CreateTextItem()
    self.text:SetFontSize(GUICommanderTooltip.kTextFontSize)
    self.text:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.text:SetTextAlignmentX(GUITextItem.Align_Min)
    self.text:SetTextAlignmentY(GUITextItem.Align_Min)
    self.text:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, GUICommanderTooltip.kTextYOffset, 0))
    self.text:SetColor(Color(1, 1, 1, 1))
    self.text:SetFontIsBold(true)
    self.background:AddChild(self.text)
    
    self.hotkey = GUI.CreateTextItem()
    self.hotkey:SetFontSize(GUICommanderTooltip.kHotkeyFontSize)
    self.hotkey:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.hotkey:SetTextAlignmentX(GUITextItem.Align_Min)
    self.hotkey:SetTextAlignmentY(GUITextItem.Align_Min)
    self.hotkey:SetPosition(Vector(GUICommanderTooltip.kHotkeyXOffset, 0, 0))
    self.hotkey:SetColor(Color(1, 1, 1, 1))
    self.hotkey:SetFontIsBold(true)
    self.text:AddChild(self.hotkey)
    
    self.resourceIcon = GUI.CreateGraphicsItem()
    self.resourceIcon:SetSize(Vector(GUICommanderTooltip.kResourceIconSize, GUICommanderTooltip.kResourceIconSize, 0))
    self.resourceIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.resourceIcon:SetPosition(Vector(-GUICommanderTooltip.kResourceIconSize + GUICommanderTooltip.kResourceIconXOffset, GUICommanderTooltip.kResourceIconYOffset, 0))
    self.resourceIcon:SetTexture(GUICommanderTooltip.kResourceIconTexture)
    self.resourceIcon:SetIsVisible(false)
    self.background:AddChild(self.resourceIcon)
    
    self.cost = GUI.CreateTextItem()
    self.cost:SetFontSize(GUICommanderTooltip.kCostFontSize)
    self.cost:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.cost:SetTextAlignmentX(GUITextItem.Align_Max)
    self.cost:SetTextAlignmentY(GUITextItem.Align_Center)
    self.cost:SetPosition(Vector(GUICommanderTooltip.kCostXOffset, GUICommanderTooltip.kResourceIconSize / 2, 0))
    self.cost:SetColor(Color(1, 1, 1, 1))
    self.cost:SetFontIsBold(true)
    self.resourceIcon:AddChild(self.cost)
    
    self.requires = GUI.CreateTextItem()
    self.requires:SetFontSize(GUICommanderTooltip.kRequiresFontSize)
    self.requires:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.requires:SetTextAlignmentX(GUITextItem.Align_Min)
    self.requires:SetTextAlignmentY(GUITextItem.Align_Min)
    self.requires:SetColor(Color(1, 0, 0, 1))
    self.requires:SetText("Requires:")
    self.requires:SetFontIsBold(true)
    self.requires:SetIsVisible(false)
    self.background:AddChild(self.requires)
    
    self.requiresInfo = GUI.CreateTextItem()
    self.requiresInfo:SetFontSize(GUICommanderTooltip.kRequiresFontSize)
    self.requiresInfo:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.requiresInfo:SetTextAlignmentX(GUITextItem.Align_Min)
    self.requiresInfo:SetTextAlignmentY(GUITextItem.Align_Min)
    self.requiresInfo:SetPosition(Vector(0, 0, 0))
    self.requiresInfo:SetColor(Color(1, 1, 1, 1))
    self.requiresInfo:SetFontIsBold(true)
    self.requiresInfo:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kRequiresTextMaxHeight)
    self.requires:AddChild(self.requiresInfo)
    
    self.enables = GUI.CreateTextItem()
    self.enables:SetFontSize(GUICommanderTooltip.kEnablesFontSize)
    self.enables:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.enables:SetTextAlignmentX(GUITextItem.Align_Min)
    self.enables:SetTextAlignmentY(GUITextItem.Align_Min)
    self.enables:SetColor(Color(0, 1, 0, 1))
    self.enables:SetText("Enables:")
    self.enables:SetFontIsBold(true)
    self.enables:SetIsVisible(false)
    self.background:AddChild(self.enables)
    
    self.enablesInfo = GUI.CreateTextItem()
    self.enablesInfo:SetFontSize(GUICommanderTooltip.kEnablesFontSize)
    self.enablesInfo:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.enablesInfo:SetTextAlignmentX(GUITextItem.Align_Min)
    self.enablesInfo:SetTextAlignmentY(GUITextItem.Align_Min)
    self.enablesInfo:SetPosition(Vector(0, 0, 0))
    self.enablesInfo:SetColor(Color(1, 1, 1, 1))
    self.enablesInfo:SetFontIsBold(true)
    self.enablesInfo:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kEnablesTextMaxHeight)
    self.enables:AddChild(self.enablesInfo)
    
    self.info = GUI.CreateTextItem()
    self.info:SetFontSize(GUICommanderTooltip.kInfoFontSize)
    self.info:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.info:SetTextAlignmentX(GUITextItem.Align_Min)
    self.info:SetTextAlignmentY(GUITextItem.Align_Min)
    self.info:SetColor(Color(1, 1, 1, 1))
    self.info:SetFontIsBold(true)
    self.info:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kInfoTextMaxHeight)
    self.info:SetIsVisible(false)
    self.background:AddChild(self.info)
    
end

function GUICommanderTooltip:Uninitialize()

    // Everything is attached to the background so uninitializing it will destroy all items.
    self.background:Uninitialize()
    self.background = nil
    
end

function GUICommanderTooltip:UpdateData(text, hotkey, costNumber, requires, enables, info, typeNumber)

    local totalTextHeight = self:CalculateTotalTextHeight(text, requires, enables, info)
    self.background:SetSize(Vector(self.tooltipWidth, self.tooltipHeight + totalTextHeight, 0))
    self.background:GetBackground():SetPosition(Vector(self.tooltipX, self.tooltipY - totalTextHeight, 0))
    
    self.text:SetText(text)
    self.hotkey:SetText("( " .. hotkey .. " )")
    if costNumber > 0 then
        self.resourceIcon:SetIsVisible(true)
        self.resourceIcon:SetTexturePixelCoordinates(0, typeNumber * GUICommanderTooltip.kResourceIconTextureHeight,
                                                     GUICommanderTooltip.kResourceIconTextureWidth,
                                                     (typeNumber + 1) * GUICommanderTooltip.kResourceIconTextureHeight)
        self.cost:SetText(ToString(costNumber))
        self.cost:SetColor(GUICommanderTooltip.kResourceColors[typeNumber + 1])
    else
        self.resourceIcon:SetIsVisible(false)
    end
    
    local nextYPosition = self.text:GetPosition().y + self.text:GetTextHeight(text)
    if string.len(requires) > 0 then
        self.requires:SetIsVisible(true)
        nextYPosition = nextYPosition + GUICommanderTooltip.kRequiresYOffset
        self.requires:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.requiresInfo:SetText(requires)
    else
        self.requires:SetIsVisible(false)
    end
    
    if self.requires:GetIsVisible() then
        nextYPosition = self.requires:GetPosition().y + self.requires:GetTextHeight(self.requires:GetText()) + self.requiresInfo:GetTextHeight(self.requiresInfo:GetText())
    end
    
    if string.len(enables) > 0 then
        nextYPosition = nextYPosition + GUICommanderTooltip.kEnablesYOffset
        self.enables:SetIsVisible(true)
        self.enables:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.enablesInfo:SetText(enables)
    else
        self.enables:SetIsVisible(false)
    end
    
    if self.enables:GetIsVisible() then
        nextYPosition = self.enables:GetPosition().y + self.enables:GetTextHeight(self.enables:GetText()) + self.enablesInfo:GetTextHeight(self.enablesInfo:GetText())
    end

    if string.len(info) > 0 then
        nextYPosition = nextYPosition + GUICommanderTooltip.kInfoYOffset
        self.info:SetIsVisible(true)
        self.info:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.info:SetText(info)
    else
        self.info:SetIsVisible(false)
    end
    
end

// Determine the height of the tooltip based on all the text inside of it.
function GUICommanderTooltip:CalculateTotalTextHeight(text, requires, enables, info)

    local totalHeight = 0
    
    if string.len(text) > 0 then
        totalHeight = totalHeight + self.text:GetTextHeight(text)
    end
    
    if string.len(requires) > 0 then
        totalHeight = totalHeight + self.requiresInfo:GetTextHeight(requires)
    end
    
    if string.len(enables) > 0 then
        totalHeight = totalHeight + self.enablesInfo:GetTextHeight(enables)
    end
    
    if string.len(info) > 0 then
        totalHeight = totalHeight + self.info:GetTextHeight(info)
    end
    
    return totalHeight

end

function GUICommanderTooltip:SetIsVisible(setIsVisible)

    self.background:SetIsVisible(setIsVisible)

end

function GUICommanderTooltip:GetBackground()

    return self.background:GetBackground()

end