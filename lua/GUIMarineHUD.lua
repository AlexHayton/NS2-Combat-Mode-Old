
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the health and armor HUD information for the marine.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMarineHUD' (GUIScript)

GUIMarineHUD.kTextureName = "ui/marine_health_bg.dds"
GUIMarineHUD.kTextFontName = "MicrogrammaDBolExt"

GUIMarineHUD.kBackgroundWidth = 232
GUIMarineHUD.kBackgroundHeight = 50
GUIMarineHUD.kBackgroundOffset = Vector(30, -30, 0)
GUIMarineHUD.kBackgroundTextureX1 = 0
GUIMarineHUD.kBackgroundTextureY1 = 0
GUIMarineHUD.kBackgroundTextureX2 = 228
GUIMarineHUD.kBackgroundTextureY2 = 52

// Health bar constants.
GUIMarineHUD.kHealthTextFontSize = 18
GUIMarineHUD.kHealthTextOffset = Vector(52, 16, 0)

GUIMarineHUD.kHealthBarWidth = 200
GUIMarineHUD.kHealthBarHeight = 25
GUIMarineHUD.kHealthBarColor = Color(0.0, 0.6, 0.9, .4)
GUIMarineHUD.kHealthBarLowColor = Color(0.9, 0, 0, 1)
GUIMarineHUD.kHealthBarOffset = Vector(0, 4, 0)
// NOTE: This is a VERY specific color. If this is changed the whole game will break! (According to Matt)
GUIMarineHUD.kHealthBackgroundBarColor = Color(0.0, 0.24313725490196078431372549019608, 0.48235294117647058823529411764706, .4)
GUIMarineHUD.kHealthBackgroundBarLowColor = Color(0.4, 0, 0, 1)
GUIMarineHUD.kHealthBarTextureX1 = 0
GUIMarineHUD.kHealthBarTextureY1 = 53
GUIMarineHUD.kHealthBarTextureX2 = 200
GUIMarineHUD.kHealthBarTextureY2 = 80

// Armor bar constants.
GUIMarineHUD.kArmorTextFontSize = 14
GUIMarineHUD.kArmorTextOffset = Vector(52, 40, 0)

GUIMarineHUD.kArmorBarWidth = GUIMarineHUD.kHealthBarWidth
GUIMarineHUD.kArmorBarHeight = 15
GUIMarineHUD.kArmorBarOffset = Vector(0, GUIMarineHUD.kHealthBarOffset.y + GUIMarineHUD.kHealthBarHeight + 4, 0)
GUIMarineHUD.kArmorBarColor = Color(0.0, 0.7, 0.7, 1)
GUIMarineHUD.kArmorBackgroundBarColor = GUIMarineHUD.kHealthBackgroundBarColor
GUIMarineHUD.kArmorBarTextureX1 = 0
GUIMarineHUD.kArmorBarTextureY1 = 81
GUIMarineHUD.kArmorBarTextureX2 = 200
GUIMarineHUD.kArmorBarTextureY2 = 96

// Number of pixels a second the background bars move.
GUIMarineHUD.kBackgroundBarRate = 75

GUIMarineHUD.kLowHealthPercent = 0.2

function GUIMarineHUD:Initialize()

    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize(Vector(GUIMarineHUD.kBackgroundWidth, GUIMarineHUD.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.background:SetPosition(Vector(0, -GUIMarineHUD.kBackgroundHeight, 0) + GUIMarineHUD.kBackgroundOffset)
    self.background:SetTexture(GUIMarineHUD.kTextureName)
    self.background:SetTexturePixelCoordinates(GUIMarineHUD.kBackgroundTextureX1, GUIMarineHUD.kBackgroundTextureY1, GUIMarineHUD.kBackgroundTextureX2, GUIMarineHUD.kBackgroundTextureY2)
    self.background:SetColor(GUIMarineHUD.kHealthBarColor)
    
    self:CreateHealthBar()
    
    self:CreateArmorBar()

end

function GUIMarineHUD:CreateHealthBar()

    self.healthBarBackground = GUI.CreateGraphicsItem()
    self.healthBarBackground:SetSize(Vector(GUIMarineHUD.kHealthBarWidth, GUIMarineHUD.kHealthBarHeight, 0))
    self.healthBarBackground:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.healthBarBackground:SetPosition(Vector(-GUIMarineHUD.kHealthBarWidth, 0, 0) + GUIMarineHUD.kHealthBarOffset)
    self.healthBarBackground:SetColor(Color(GUIMarineHUD.kHealthBackgroundBarColor))
    self.healthBarBackground:SetTexture(GUIMarineHUD.kTextureName)
    self.healthBarBackground:SetTexturePixelCoordinates(GUIMarineHUD.kHealthBarTextureX1, GUIMarineHUD.kHealthBarTextureY1, GUIMarineHUD.kHealthBarTextureX2, GUIMarineHUD.kHealthBarTextureY2)
    self.healthBarBackgroundXCoord = GUIMarineHUD.kHealthBarTextureX2
    
    self.healthBar = GUI.CreateGraphicsItem()
    self.healthBar:SetSize(Vector(GUIMarineHUD.kHealthBarWidth, GUIMarineHUD.kHealthBarHeight, 0))
    self.healthBar:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.healthBar:SetPosition(Vector(-GUIMarineHUD.kHealthBarWidth, 0, 0) + GUIMarineHUD.kHealthBarOffset)
    self.healthBar:SetColor(Color(GUIMarineHUD.kHealthBarColor))
    self.healthBar:SetTexture(GUIMarineHUD.kTextureName)
    self.healthBar:SetTexturePixelCoordinates(GUIMarineHUD.kHealthBarTextureX1, GUIMarineHUD.kHealthBarTextureY1, GUIMarineHUD.kHealthBarTextureX2, GUIMarineHUD.kHealthBarTextureY2)
    
    self.healthText = GUI.CreateTextItem()
    self.healthText:SetFontSize(GUIMarineHUD.kHealthTextFontSize)
    self.healthText:SetFontName(GUIMarineHUD.kTextFontName)
    self.healthText:SetFontIsBold(false)
    self.healthText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.healthText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.healthText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.healthText:SetPosition(GUIMarineHUD.kHealthTextOffset)
    self.healthText:SetColor(Color(1, 1, 1, 1))
    
    self.background:AddChild(self.healthBarBackground)
    self.background:AddChild(self.healthBar)
    self.background:AddChild(self.healthText)
    
end

function GUIMarineHUD:CreateArmorBar()

    self.armorBarBackground = GUI.CreateGraphicsItem()
    self.armorBarBackground:SetSize(Vector(GUIMarineHUD.kArmorBarWidth, GUIMarineHUD.kArmorBarHeight, 0))
    self.armorBarBackground:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.armorBarBackground:SetPosition(Vector(-GUIMarineHUD.kArmorBarWidth, 0, 0) + GUIMarineHUD.kArmorBarOffset)
    self.armorBarBackground:SetColor(Color(GUIMarineHUD.kArmorBackgroundBarColor))
    self.armorBarBackground:SetTexture(GUIMarineHUD.kTextureName)
    self.armorBarBackground:SetTexturePixelCoordinates(GUIMarineHUD.kArmorBarTextureX1, GUIMarineHUD.kArmorBarTextureY1, GUIMarineHUD.kArmorBarTextureX2, GUIMarineHUD.kArmorBarTextureY2)
    self.armorBarBackgroundXCoord = GUIMarineHUD.kArmorBarTextureX2
    
    self.armorBar = GUI.CreateGraphicsItem()
    self.armorBar:SetSize(Vector(GUIMarineHUD.kArmorBarWidth, GUIMarineHUD.kArmorBarHeight, 0))
    self.armorBar:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.armorBar:SetPosition(Vector(-GUIMarineHUD.kArmorBarWidth, 0, 0) + GUIMarineHUD.kArmorBarOffset)
    self.armorBar:SetColor(Color(GUIMarineHUD.kArmorBarColor))
    self.armorBar:SetTexture(GUIMarineHUD.kTextureName)
    self.armorBar:SetTexturePixelCoordinates(GUIMarineHUD.kArmorBarTextureX1, GUIMarineHUD.kArmorBarTextureY1, GUIMarineHUD.kArmorBarTextureX2, GUIMarineHUD.kArmorBarTextureY2)
    
    self.armorText = GUI.CreateTextItem()
    self.armorText:SetFontSize(GUIMarineHUD.kArmorTextFontSize)
    self.armorText:SetFontName(GUIMarineHUD.kTextFontName)
    self.armorText:SetFontIsBold(false)
    self.armorText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.armorText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.armorText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.armorText:SetPosition(GUIMarineHUD.kArmorTextOffset)
    self.armorText:SetColor(Color(1, 1, 1, 1))

    self.background:AddChild(self.armorBarBackground)
    self.background:AddChild(self.armorBar)
    self.background:AddChild(self.armorText)

end

function GUIMarineHUD:Uninitialize()

    // Destroying the background will destroy all it's children too.
    GUI.DestroyItem(self.background)
    self.background = nil
    self.healthText = nil
    self.healthBar = nil
    self.healthBarBackground = nil
    
end

function GUIMarineHUD:Update(deltaTime)
    
    self:UpdateHealthBar(deltaTime)
    self:UpdateArmorBar(deltaTime)
    
end

function GUIMarineHUD:UpdateHealthBar(deltaTime)

    if self.healthBar then
        local healthBarPercentage = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
        local barSize = Vector(GUIMarineHUD.kHealthBarWidth * healthBarPercentage, GUIMarineHUD.kHealthBarHeight, 0)
        self.healthBar:SetSize(barSize)
        local backgroundSize = Vector(self.healthBarBackground:GetSize())
        backgroundSize.x = Slerp(backgroundSize.x, barSize.x, deltaTime * GUIMarineHUD.kBackgroundBarRate)
        self.healthBarBackground:SetSize(backgroundSize)
        
        // Change the texture coordinates based on the current health percent.
        self.healthBar:SetTexturePixelCoordinates(GUIMarineHUD.kHealthBarTextureX1, GUIMarineHUD.kHealthBarTextureY1, GUIMarineHUD.kHealthBarTextureX2 * healthBarPercentage, GUIMarineHUD.kHealthBarTextureY2)
        self.healthBarBackgroundXCoord = Slerp(self.healthBarBackgroundXCoord, GUIMarineHUD.kHealthBarTextureX2 * healthBarPercentage, deltaTime * GUIMarineHUD.kBackgroundBarRate)
        self.healthBarBackground:SetTexturePixelCoordinates(GUIMarineHUD.kHealthBarTextureX1, GUIMarineHUD.kHealthBarTextureY1, self.healthBarBackgroundXCoord, GUIMarineHUD.kHealthBarTextureY2)
        
        local barColor = GUIMarineHUD.kHealthBarColor
        local barBackgroundColor = GUIMarineHUD.kHealthBackgroundBarColor
        if healthBarPercentage <= GUIMarineHUD.kLowHealthPercent then
            barColor = GUIMarineHUD.kHealthBarLowColor
            barBackgroundColor = GUIMarineHUD.kHealthBackgroundBarLowColor
        end
        self.healthBar:SetColor(barColor)
        self.healthBarBackground:SetColor(barBackgroundColor)
        self.background:SetColor(barColor)
        
        // Update text.
        self.healthText:SetText(tostring(math.ceil(PlayerUI_GetPlayerHealth())))
    end
    
end

function GUIMarineHUD:UpdateArmorBar(deltaTime)

    if self.armorBar then
        local armorBarPercentage = PlayerUI_GetPlayerArmor() / PlayerUI_GetPlayerMaxArmor()
        local barSize = Vector(GUIMarineHUD.kArmorBarWidth * armorBarPercentage, GUIMarineHUD.kArmorBarHeight, 0)
        self.armorBar:SetSize(barSize)
        local backgroundSize = Vector(self.armorBarBackground:GetSize())
        backgroundSize.x = Slerp(backgroundSize.x, barSize.x, deltaTime * GUIMarineHUD.kBackgroundBarRate)
        self.armorBarBackground:SetSize(backgroundSize)
        
        // Change the texture coordinates based on the current armor percent.
        self.armorBar:SetTexturePixelCoordinates(GUIMarineHUD.kArmorBarTextureX1, GUIMarineHUD.kArmorBarTextureY1, GUIMarineHUD.kArmorBarTextureX2 * armorBarPercentage, GUIMarineHUD.kArmorBarTextureY2)
        self.armorBarBackgroundXCoord = Slerp(self.armorBarBackgroundXCoord, GUIMarineHUD.kArmorBarTextureX2 * armorBarPercentage, deltaTime * GUIMarineHUD.kBackgroundBarRate)
        self.armorBarBackground:SetTexturePixelCoordinates(GUIMarineHUD.kArmorBarTextureX1, GUIMarineHUD.kArmorBarTextureY1, self.armorBarBackgroundXCoord, GUIMarineHUD.kArmorBarTextureY2)
        
        // Update text.
        self.armorText:SetText(tostring(math.ceil(PlayerUI_GetPlayerArmor())))
    end
    
end