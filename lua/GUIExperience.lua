//
// lua\GUIScoreboard.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
// Based on GUIExperience.lua
//
// Manages the experience bar for both teams
//

class 'GUIExperience' (GUIScript)

GUIExperience.kTextureName = "ui/alien_hud_health.dds"
GUIExperience.kTextFontName = "MicrogrammaDMedExt"

GUIExperience.kExperienceBackgroundWidth = 300
GUIExperience.kExperienceBackgroundHeight = 50
GUIExperience.kExperienceBarOffset = Vector(30, 30, 0)
GUIExperience.kExperienceBackgroundTextureX1 = 0
GUIExperience.kExperienceBackgroundTextureY1 = 0
GUIExperience.kExperienceBackgroundTextureX2 = 128
GUIExperience.kExperienceBackgroundTextureY2 = 128

GUIExperience.kFontColor = Color(0.8, 0.4, 0.4, 1)

GUIExperience.kExperienceTextFontSize = 15
GUIExperience.kExperienceTextOffset = Vector(52, 40, 0)

function GUIExperience:Initialize()
	self:CreateExperienceBar()
end

function GUIExperience:CreateExperienceBar()
    self.experienceBarBackground = GUI.CreateGraphicsItem()
    self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, GUIExperience.kExperienceBackgroundHeight, 0))
    self.experienceBarBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.experienceBarBackground:SetPosition(Vector(0, 0, 0) + GUIExperience.kExperienceBarOffset)
    self.experienceBarBackground:SetColor(GUIExperience.kFontColor)
    self.experienceBarBackground:SetTexture(GUIExperience.kTextureName)
    self.experienceBarBackground:SetTexturePixelCoordinates(GUIExperience.kExperienceBackgroundTextureX1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureY2)
    self.experienceBarBackgroundXCoord = GUIExperience.kExperienceBackgroundTextureX2
    self.experienceBarBackground:SetIsVisible(true)
    
    self.experienceBar = GUI.CreateGraphicsItem()
    self.experienceBar:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, GUIExperience.kExperienceBackgroundHeight, 0))
    self.experienceBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.experienceBar:SetPosition(Vector(0, 0, 0) + GUIExperience.kExperienceBarOffset)
    self.experienceBar:SetColor(Color(GUIExperience.kFontColor))
    self.experienceBar:SetTexture(GUIExperience.kTextureName)
    self.experienceBar:SetTexturePixelCoordinates(GUIExperience.kExperienceBackgroundTextureX1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureY2)
    self.experienceBar:SetInheritsParentAlpha(true)
    self.experienceBar:SetIsVisible(true)
    self.experienceBarBackground:AddChild(self.experienceBar)
    
    self.experienceText = GUI.CreateTextItem()
    self.experienceText:SetFontSize(GUIExperience.kExperienceTextFontSize)
    self.experienceText:SetFontName(GUIExperience.kTextFontName)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.experienceText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.experienceText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.experienceText:SetPosition(GUIExperience.kExperienceTextOffset)
    self.experienceText:SetColor(GUIExperience.kFontColor)
    self.experienceText:SetInheritsParentAlpha(true)
    self.experienceText:SetIsVisible(true)
    self.experienceBarBackground:AddChild(self.experienceText)
end

function GUIExperience:Update(deltatime)
	self:UpdateExperienceBar(deltaTime)
end

function GUIExperience:UpdateExperienceBar(deltaTime)
    local expBarPercentage = PlayerUI_GetPlayerExperience() / Experience_GetMaxExperience()
    local barSize = Vector(GUIExperience.kExperienceBackgroundWidth * expBarPercentage, GUIExperience.kExperienceBackgroundHeight, 0)
    self.experienceBar:SetSize(barSize)
		
	self.experienceText:SetText(tostring(math.ceil(PlayerUI_GetPlayerExperience())) .. " (" .. PlayerUI_GetPlayerRankName() .. ")")
end

function GUIExperience:Uninitialize()

	if self.experienceBar then
        GUI.DestroyItem(self.experienceBarBackground)
        self.experienceBar = nil
        self.experienceBarText = nil
        self.experienceBarBackground = nil
    end
    
end