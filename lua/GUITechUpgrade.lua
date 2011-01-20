
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
GUIRequests.kBackgroundXOffset = 0
GUIRequests.kBackgroundYOffset = 200
GUIRequests.kBackgroundWidth = 200
GUIRequests.kBackgroundColor = Color(0.1, 0.1, 0.1, 0.5)
// How many seconds for the background to fade in.
GUIRequests.kBackgroundFadeRate = 0.25

// Text constants.
GUIRequests.kTextFontSize = 18
GUIRequests.kTextSayingColor = Color(1, 1, 1, 1)
// This is how much of a buffer around the text the background extends.
GUIRequests.kTextBackgroundWidthBuffer = 4
GUIRequests.kTextBackgroundHeightBuffer = 2
// This is the amount of space between text background items.
GUIRequests.kTextBackgroundItemBuffer = 2
GUIRequests.kTextBackgroundColor = Color(0.4, 0.4, 0.4, 1)

function GUIRequests:Initialize()
    
    self.background = GUI.CreateGraphicsItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    // Start off-screen.
    self.background:SetPosition(Vector(GUIRequests.kBackgroundXOffset, GUIRequests.kBackgroundYOffset, 0))
    self.background:SetSize(Vector(GUIRequests.kBackgroundWidth, 0, 0))
    self.background:SetColor(GUIRequests.kBackgroundColor)
    self.background:SetIsVisible(false)
    
    self.textTechUpgrades = { }
    self.reuseTechUpgradeItems = { }

end

function GUIRequests:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIRequests:Update(deltaTime)
    
    local visible = PlayerUI_ShowTechUpgrades()
    if visible then
        local upgradeList = PlayerUI_GetTechUpgrades()
        self:UpdateTechUpgrades(upgradeList)
    end
    
    self:UpdateFading(deltaTime, visible)
    
end

function GUIRequests:UpdateFading(deltaTime, visible)
    
    if visible then
        self.background:SetIsVisible(true)
        self.background:SetColor(GUIRequests.kBackgroundColor)
    end
    
    local fadeAmt = deltaTime * (1 / GUIRequests.kBackgroundFadeRate)
    local currentColor = self.background:GetColor()
    if not visible and currentColor.a ~= 0 then
        currentColor.a = Slerp(currentColor.a, 0, fadeAmt)
        self.background:SetColor(currentColor)
        if currentColor.a == 0 then
            self.background:SetIsVisible(false)
        end
    end
    
end

function GUIRequests:UpdateTechUpgrades(techUpgrades)

    if techUpgrades ~= nil then
        if table.count(self.textTechUpgrades) ~= table.count(techUpgrades) then
            self:ResizeTechUpgradesList(techUpgrades)
        end

        local currentYPos = 0
        for i, textSaying in ipairs(self.textTechUpgrades) do
            textSaying["Text"]:SetText(techUpgrades[i])
            
            currentYPos = currentYPos + GUIRequests.kTextBackgroundItemBuffer + GUIRequests.kTextBackgroundHeightBuffer
            textSaying["Background"]:SetPosition(Vector(0, currentYPos, 0))
            currentYPos = currentYPos + GUIRequests.kTextFontSize + GUIRequests.kTextBackgroundItemBuffer + GUIRequests.kTextBackgroundHeightBuffer
            
            local totalWidth = GUIRequests.kBackgroundWidth - (GUIRequests.kTextBackgroundWidthBuffer * 2)
            local totalHeight = GUIRequests.kTextFontSize + (GUIRequests.kTextBackgroundHeightBuffer * 2)
            textSaying["Background"]:SetSize(Vector(totalWidth, totalHeight, 0))
        end
        
        local totalBackgroundHeight = GUIRequests.kTextFontSize + (GUIRequests.kTextBackgroundItemBuffer * 2) + (GUIRequests.kTextBackgroundHeightBuffer * 2)
        totalBackgroundHeight = (table.count(self.textTechUpgrades) * totalBackgroundHeight) + (GUIRequests.kTextBackgroundItemBuffer * 2)
        self.background:SetSize(Vector(GUIRequests.kBackgroundWidth, totalBackgroundHeight, 0))
    end

end

function GUIRequests:ResizeTechUpgradesList(techUpgrades)
    
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

function GUIRequests:CreateTechUpgradeItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseTechUpgradeItems) > 0 then
        local returnTechUpgradeItem = self.reuseTechUpgradeItems[1]
        table.remove(self.reuseTechUpgradeItems, 1)
        return returnTechUpgradeItem
    end
    
    local textBackground = GUI.CreateGraphicsItem()
    textBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    textBackground:SetColor(GUIRequests.kTextBackgroundColor)
    textBackground:SetInheritsParentAlpha(true)
    
    local newTechUpgradeItem = GUI.CreateTextItem()
    newTechUpgradeItem:SetFontSize(GUIRequests.kTextFontSize)
    newTechUpgradeItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    newTechUpgradeItem:SetPosition(Vector(GUIRequests.kTextBackgroundWidthBuffer, 0, 0))
    newTechUpgradeItem:SetTextAlignmentX(GUITextItem.Align_Min)
    newTechUpgradeItem:SetTextAlignmentY(GUITextItem.Align_Center)
    newTechUpgradeItem:SetColor(GUIRequests.kTextSayingColor)
    newTechUpgradeItem:SetInheritsParentAlpha(true)
    textBackground:AddChild(newTechUpgradeItem)
    
    return { Background = textBackground, Text = newTechUpgradeItem }
    
end