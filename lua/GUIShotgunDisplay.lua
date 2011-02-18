// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIShotgunDisplay.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// Displays the ammo counter for the shotgun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0

bulletDisplay  = nil

class 'GUIShotgunDisplay'

function GUIShotgunDisplay:Initialize()

    self.weaponClip     = 0
    self.weaponAmmo     = 0
    self.weaponClipSize = 50

    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize( Vector(256, 128, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/ShotgunDisplay.dds")
    
    self.clipText, self.clipTextBg = self:CreateTextItem(52, 66)
    self.ammoText, self.ammoTextBg = self:CreateTextItem(177, 66)
    
    local slash, slashBg = self:CreateTextItem(100, 66)
    slash:SetText("/")
    slashBg:SetText("/")
    
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIShotgunDisplay:CreateTextItem(x, y)

    local textBg = GUI.CreateTextItem()
    textBg:SetFontName("MicrogrammaDMedExt")
    textBg:SetFontSize(85)
    textBg:SetTextAlignmentX(GUITextItem.Align_Center)
    textBg:SetTextAlignmentY(GUITextItem.Align_Center)
    textBg:SetPosition(Vector(x, y, 0))
    textBg:SetColor(Color(0.88, 0.98, 1, 0.25))

    // Text displaying the amount of reserve ammo
    local text = GUI.CreateTextItem()
    text:SetFontName("MicrogrammaDMedExt")
    text:SetFontSize(75)
    text:SetTextAlignmentX(GUITextItem.Align_Center)
    text:SetTextAlignmentY(GUITextItem.Align_Center)
    text:SetPosition(Vector(x, y, 0))
    text:SetColor(Color(0.88, 0.98, 1))
    
    return text, textBg
    
end

function GUIShotgunDisplay:Update(deltaTime)
    
    // Update the ammo counter.
    
    local clipFormat = string.format("%d", self.weaponClip) 
    local ammoFormat = string.format("%02d", self.weaponAmmo) 
    
    self.clipText:SetText( clipFormat )
    self.clipTextBg:SetText( clipFormat )
    
    self.ammoText:SetText( ammoFormat )
    self.ammoTextBg:SetText( ammoFormat )
    
end

function GUIShotgunDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUIShotgunDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUIShotgunDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:Update(deltaTime)
        
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 128 )

    bulletDisplay = GUIShotgunDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(50)

end

Initialize()