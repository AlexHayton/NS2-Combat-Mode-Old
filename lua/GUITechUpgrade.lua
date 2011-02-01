
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUITechUpgrade.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
// Modified by: Alex Hayton
//
// Manages the upgrade menu
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUITechUpgrade' (GUIScript)

// Background constants.
GUITechUpgrade.kBackgroundXOffset = 0
GUITechUpgrade.kBackgroundYOffset = 200
GUITechUpgrade.kBackgroundWidth = 200
GUITechUpgrade.kBackgroundColor = Color(0.1, 0.1, 0.1, 0.5)
// How many seconds for the background to fade in.
GUITechUpgrade.kBackgroundFadeRate = 0.25

// Text constants.
GUITechUpgrade.kTextFontSize = 18
GUITechUpgrade.kTextSayingColor = Color(1, 1, 1, 1)
// This is how much of a buffer around the text the background extends.
GUITechUpgrade.kTextBackgroundWidthBuffer = 4
GUITechUpgrade.kTextBackgroundHeightBuffer = 2
// This is the amount of space between text background items.
GUITechUpgrade.kTextBackgroundItemBuffer = 2
GUITechUpgrade.kTextBackgroundColor = Color(0.4, 0.4, 0.4, 1)

function GUITechUpgrade:Initialize()
    
    self.background = GUI.CreateGraphicsItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    // Start off-screen.
    self.background:SetPosition(Vector(GUITechUpgrade.kBackgroundXOffset, GUITechUpgrade.kBackgroundYOffset, 0))
    self.background:SetSize(Vector(GUITechUpgrade.kBackgroundWidth, 0, 0))
    self.background:SetColor(GUITechUpgrade.kBackgroundColor)
    self.background:SetIsVisible(false)
    
    self.textTechUpgrades = { }
    self.reuseTechUpgradeItems = { }

end

function GUITechUpgrade:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUITechUpgrade:Update(deltaTime)
    
    local visible = PlayerUI_ShowTechUpgrades()
    if visible then
        local upgradeList = PlayerUI_GetTechUpgrades()
        self:UpdateTechUpgrades(upgradeList)
    end
    
    self:UpdateFading(deltaTime, visible)
    
end

function GUITechUpgrade:UpdateFading(deltaTime, visible)
    
    if visible then
        self.background:SetIsVisible(true)
        self.background:SetColor(GUITechUpgrade.kBackgroundColor)
    end
    
    local fadeAmt = deltaTime * (1 / GUITechUpgrade.kBackgroundFadeRate)
    local currentColor = self.background:GetColor()
    if not visible and currentColor.a ~= 0 then
        currentColor.a = Slerp(currentColor.a, 0, fadeAmt)
        self.background:SetColor(currentColor)
        if currentColor.a == 0 then
            self.background:SetIsVisible(false)
        end
    end
    
end

function GUITechUpgrade:UpdateTechUpgrades(techUpgrades)

    if techUpgrades ~= nil then
        if table.count(self.textTechUpgrades) ~= table.count(techUpgrades) then
            self:ResizeTechUpgradesList(techUpgrades)
        end

        local currentYPos = 0
        for i, textSaying in ipairs(self.textTechUpgrades) do
            textSaying["Text"]:SetText(techUpgrades[i])
            
            currentYPos = currentYPos + GUITechUpgrade.kTextBackgroundItemBuffer + GUITechUpgrade.kTextBackgroundHeightBuffer
            textSaying["Background"]:SetPosition(Vector(0, currentYPos, 0))
            currentYPos = currentYPos + GUITechUpgrade.kTextFontSize + GUITechUpgrade.kTextBackgroundItemBuffer + GUITechUpgrade.kTextBackgroundHeightBuffer
            
            local totalWidth = GUITechUpgrade.kBackgroundWidth - (GUITechUpgrade.kTextBackgroundWidthBuffer * 2)
            local totalHeight = GUITechUpgrade.kTextFontSize + (GUITechUpgrade.kTextBackgroundHeightBuffer * 2)
            textSaying["Background"]:SetSize(Vector(totalWidth, totalHeight, 0))
        end
        
        local totalBackgroundHeight = GUITechUpgrade.kTextFontSize + (GUITechUpgrade.kTextBackgroundItemBuffer * 2) + (GUITechUpgrade.kTextBackgroundHeightBuffer * 2)
        totalBackgroundHeight = (table.count(self.textTechUpgrades) * totalBackgroundHeight) + (GUITechUpgrade.kTextBackgroundItemBuffer * 2)
        self.background:SetSize(Vector(GUITechUpgrade.kBackgroundWidth, totalBackgroundHeight, 0))
    end

end

function GUITechUpgrade:ResizeTechUpgradesList(techUpgrades)
    
    while table.count(techUpgrades) > table.count(self.textTechUpgrades) do
        local newTechUpgradeItem = self:CreateTechUpgradeItem()
        table.insert(self.textTechUpgrades, newTechUpgradeItem)
        self.background:AddChild(newTechUpgradeItem["Background"])
        newTechUpgradeItem["Background"]:SetIsVisible(true)
    end
    
    while table.count(techUpgrades) < table.count(self.textTechUpgrades) do
        self.background:RemoveChild(self.textTechUpgrades[1]["Background"])
        self.textTechUpgrades[1]["Background"]:SetIsVisible(false)
        table.insert(self.reuseTechUpgradeItems, self.textTechUpgrades[1])
        table.remove(self.textTechUpgrades, 1)
    end

end

function GUITechUpgrade:CreateTechUpgradeItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseTechUpgradeItems) > 0 then
        local returnTechUpgradeItem = self.reuseTechUpgradeItems[1]
        table.remove(self.reuseTechUpgradeItems, 1)
        return returnTechUpgradeItem
    end
    
    local textBackground = GUI.CreateGraphicsItem()
    textBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    textBackground:SetColor(GUITechUpgrade.kTextBackgroundColor)
    textBackground:SetInheritsParentAlpha(true)
    
    local newTechUpgradeItem = GUI.CreateTextItem()
    newTechUpgradeItem:SetFontSize(GUITechUpgrade.kTextFontSize)
    newTechUpgradeItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    newTechUpgradeItem:SetPosition(Vector(GUITechUpgrade.kTextBackgroundWidthBuffer, 0, 0))
    newTechUpgradeItem:SetTextAlignmentX(GUITextItem.Align_Min)
    newTechUpgradeItem:SetTextAlignmentY(GUITextItem.Align_Center)
    newTechUpgradeItem:SetColor(GUITechUpgrade.kTextSayingColor)
    newTechUpgradeItem:SetInheritsParentAlpha(true)
    textBackground:AddChild(newTechUpgradeItem)
    
    return { Background = textBackground, Text = newTechUpgradeItem }
    
end