//
// lua\GUIScoreboard.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
// Based on GUIExperience.lua
//
// Manages the experience bar for both teams
//

class 'GUIExperience' (GUIScript)

GUIExperience.kTextureName = "ui/marine_health_bg.dds"
GUIExperience.kTextFontName = "MicrogrammaDBolExt"

GUIExperience.kExperienceBackgroundWidth = 400
GUIExperience.kExperienceBackgroundHeight = 20
GUIExperience.kExperienceBackgroundOffset = Vector(-GUIExperience.kExperienceBackgroundWidth/2, -GUIExperience.kExperienceBackgroundHeight-10, 0)
GUIExperience.kExperienceBackgroundColor = Color(0, 0, 0, 0.3)
GUIExperience.kExperienceBorder = 5

GUIExperience.kExperienceBarOffset = Vector(GUIExperience.kExperienceBorder, GUIExperience.kExperienceBorder, 0)
GUIExperience.kExperienceBarWidth = GUIExperience.kExperienceBackgroundWidth - GUIExperience.kExperienceBorder*2
GUIExperience.kExperienceBarHeight = GUIExperience.kExperienceBackgroundHeight - GUIExperience.kExperienceBorder*2
GUIExperience.kExperienceBackgroundTextureX1 = 10
GUIExperience.kExperienceBackgroundTextureY1 = 10
GUIExperience.kExperienceBackgroundTextureX2 = 11
GUIExperience.kExperienceBackgroundTextureY2 = 11

GUIExperience.kExperienceBarTextureX1 = 10
GUIExperience.kExperienceBarTextureY1 = 10
GUIExperience.kExperienceBarTextureX2 = 11
GUIExperience.kExperienceBarTextureY2 = 11

GUIExperience.kMarineGUIColor = Color(0.0, 0.6, 1.0, 1)
GUIExperience.kAlienGUIColor = Color(1.0, 0.4, 0.4, 1)
GUIExperience.kMarineTextColor = Color(0.0, 0.6, 0.9, 1)
GUIExperience.kAlienTextColor = Color(0.8, 0.4, 0.4, 1)
GUIExperience.kExperienceTextFontSize = 15
GUIExperience.kExperienceTextOffset = Vector(0, -10, 0)

GUIExperience.kBackgroundBarRate = 90

function GUIExperience:Initialize()
	self:CreateExperienceBar()
	self.rankIncreased = false
end

function GUIExperience:CreateExperienceBar()
    self.experienceBarBackground = GUI.CreateGraphicsItem()
    self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, GUIExperience.kExperienceBackgroundHeight, 0))
    self.experienceBarBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
    self.experienceBarBackground:SetPosition(GUIExperience.kExperienceBackgroundOffset)
    self.experienceBarBackground:SetColor(GUIExperience.kExperienceBackgroundColor)
    self.experienceBarBackground:SetTexture(GUIExperience.kTextureName)
    self.experienceBarBackground:SetTexturePixelCoordinates(GUIExperience.kExperienceBackgroundTextureX1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureX2, GUIExperience.kExperienceBackgroundTextureY2)
    self.experienceBarBackground:SetIsVisible(true)
    
    self.experienceBar = GUI.CreateGraphicsItem()
    self.experienceBar:SetSize(Vector(GUIExperience.kExperienceBarWidth, GUIExperience.kExperienceBarHeight, 0))
    self.experienceBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.experienceBar:SetPosition(GUIExperience.kExperienceBarOffset)
	if (PlayerUI_GetTeamType() == "Marines") then
		self.experienceBar:SetColor(GUIExperience.kMarineGUIColor)
	else
		self.experienceBar:SetColor(GUIExperience.kAlienGUIColor)
	end
    self.experienceBar:SetTexture(GUIExperience.kTextureName)
    self.experienceBar:SetTexturePixelCoordinates(GUIExperience.kExperienceBarTextureX1, GUIExperience.kExperienceBarTextureY1, GUIExperience.kExperienceBarTextureX2, GUIExperience.kExperienceBarTextureY2)
    self.experienceBar:SetIsVisible(true)
    self.experienceBarBackground:AddChild(self.experienceBar)
    
    self.experienceText = GUI.CreateTextItem()
    self.experienceText:SetFontSize(GUIExperience.kExperienceTextFontSize)
    self.experienceText:SetFontName(GUIExperience.kTextFontName)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetAnchor(GUIItem.Center, GUIItem.Top)
    self.experienceText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.experienceText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.experienceText:SetPosition(GUIExperience.kExperienceTextOffset)
	if (PlayerUI_GetTeamType() == "Marines") then
		self.experienceText:SetColor(GUIExperience.kMarineTextColor)
	else
		self.experienceText:SetColor(GUIExperience.kAlienTextColor)
	end
    self.experienceText:SetIsVisible(true)
    self.experienceBarBackground:AddChild(self.experienceText)
end

function GUIExperience:Update(deltaTime)
	self:UpdateExperienceBar(deltaTime)
end

function GUIExperience:UpdateExperienceBar(deltaTime)
    local expBarPercentage = PlayerUI_GetExperienceProgression()
	local calculatedBarSize = GUIExperience.kExperienceBackgroundWidth * expBarPercentage
	local currentBarSize = self.experienceBar:GetSize().x
	local targetBarSize = calculatedBarSize
	
	// Method to allow proper tweening visualisation when you go up a rank.
	// Currently detecting this by examining relative size.
	if (calculatedBarSize < currentBarSize) then
		self.rankIncreased = true
	end
	
	if (self.rankIncreased) then
		targetBarSize = GUIExperience.kExperienceBackgroundWidth
		// Once we reach the end, reset the bar back to the beginning.
		if (currentBarSize >= targetBarSize) then
			self.rankIncreased = false
			currentBarSize = 0
			targetBarSize = calculatedBarSize
		end
	end
    self.experienceBar:SetSize(Vector(Slerp(currentBarSize, targetBarSize, deltaTime*GUIExperience.kBackgroundBarRate), GUIExperience.kExperienceBackgroundHeight, 0))
		
	self.experienceText:SetText(tostring(math.ceil(PlayerUI_GetPlayerExperience())) .. " / " .. Experience_GetNextRankExp(PlayerUI_GetPlayerRank()) .. " (" .. PlayerUI_GetPlayerRankName() .. ")")
	
	self:UpdateFading()
end

function GUIExperience:UpdateFading()
end

function GUIExperience:Uninitialize()

	if self.experienceBar then
        GUI.DestroyItem(self.experienceBarBackground)
        self.experienceBar = nil
        self.experienceBarText = nil
        self.experienceBarBackground = nil
    end
    
end