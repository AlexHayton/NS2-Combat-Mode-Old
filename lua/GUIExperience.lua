//
// lua\GUIExperience.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
//
// Manages the experience bar for both teams
//

class 'GUIExperience' (GUIScript)

GUIExperience.kTextureName = "ui/experience.dds"
GUIExperience.kTextFontName = "MicrogrammaDBolExt"

GUIExperience.kExperienceBackgroundWidth = 400
GUIExperience.kExperienceBackgroundHeight = 20
GUIExperience.kExperienceBackgroundMinimisedHeight = 10
GUIExperience.kExperienceBackgroundOffset = Vector(-GUIExperience.kExperienceBackgroundWidth/2, -GUIExperience.kExperienceBackgroundHeight-10, 0)
GUIExperience.kExperienceBackgroundColor = Color(0, 0, 0, 0.3)

GUIExperience.kExperienceBorder = 3

GUIExperience.kExperienceBarOffset = Vector(GUIExperience.kExperienceBorder, GUIExperience.kExperienceBorder, 0)
GUIExperience.kExperienceBarWidth = GUIExperience.kExperienceBackgroundWidth - GUIExperience.kExperienceBorder*2
GUIExperience.kExperienceBarHeight = GUIExperience.kExperienceBackgroundHeight - GUIExperience.kExperienceBorder*2
GUIExperience.kExperienceBarMinimisedHeight = GUIExperience.kExperienceBackgroundMinimisedHeight - GUIExperience.kExperienceBorder*2
GUIExperience.kExperienceBackgroundTextureX1 = 10
GUIExperience.kExperienceBackgroundTextureY1 = 10
GUIExperience.kExperienceBackgroundTextureX2 = 11
GUIExperience.kExperienceBackgroundTextureY2 = 11

GUIExperience.kExperienceBarTextureX1 = 10
GUIExperience.kExperienceBarTextureY1 = 60
GUIExperience.kExperienceBarTextureX2 = 11
GUIExperience.kExperienceBarTextureY2 = 61

GUIExperience.kMarineGUIColor = Color(0.0, 0.6, 1.0, 1)
GUIExperience.kAlienGUIColor = Color(1.0, 0.4, 0.4, 1)
GUIExperience.kMarineTextColor = Color(0.0, 0.6, 0.9, 1)
GUIExperience.kAlienTextColor = Color(0.8, 0.4, 0.4, 1)
GUIExperience.kExperienceTextFontSize = 15
GUIExperience.kExperienceTextOffset = Vector(0, -10, 0)
GUIExperience.kNormalAlpha = 1.0
GUIExperience.kMinimisedAlpha = 0.6

GUIExperience.kBarFadeInRate = 0.2
GUIExperience.kBarFadeOutDelay = 1000
GUIExperience.kBarFadeOutRate = 1
GUIExperience.kBackgroundBarRate = 90
GUIExperience.kTextIncreaseRate = 10


function GUIExperience:Initialize()
	self:CreateExperienceBar()
	self.rankIncreased = false
	self.currentExperience = 0
	self.barMoving = false
end

function GUIExperience:CreateExperienceBar()
    self.experienceBarBackground = GUI.CreateGraphicsItem()
    self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, GUIExperience.kExperienceBackgroundMinimisedHeight, 0))
    self.experienceBarBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
    self.experienceBarBackground:SetPosition(GUIExperience.kExperienceBackgroundOffset)
    self.experienceBarBackground:SetColor(GUIExperience.kExperienceBackgroundColor)
    self.experienceBarBackground:SetTexture(GUIExperience.kTextureName)
    self.experienceBarBackground:SetTexturePixelCoordinates(GUIExperience.kExperienceBackgroundTextureX1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureX2, GUIExperience.kExperienceBackgroundTextureY2)
    self.experienceBarBackground:SetIsVisible(false)
    
    self.experienceBar = GUI.CreateGraphicsItem()
    self.experienceBar:SetSize(Vector(GUIExperience.kExperienceBarWidth, GUIExperience.kExperienceBarHeight, 0))
    self.experienceBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.experienceBar:SetPosition(GUIExperience.kExperienceBarOffset)
    self.experienceBar:SetTexture(GUIExperience.kTextureName)
    self.experienceBar:SetTexturePixelCoordinates(GUIExperience.kExperienceBarTextureX1, GUIExperience.kExperienceBarTextureY1, GUIExperience.kExperienceBarTextureX2, GUIExperience.kExperienceBarTextureY2)
    self.experienceBar:SetIsVisible(false)
    self.experienceBarBackground:AddChild(self.experienceBar)
    
    self.experienceText = GUI.CreateTextItem()
    self.experienceText:SetFontSize(GUIExperience.kExperienceTextFontSize)
    self.experienceText:SetFontName(GUIExperience.kTextFontName)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetAnchor(GUIItem.Center, GUIItem.Top)
    self.experienceText:SetTextAlignmentX(GUITextItem.Align_Center)
    self.experienceText:SetTextAlignmentY(GUITextItem.Align_Center)
    self.experienceText:SetPosition(GUIExperience.kExperienceTextOffset)
    self.experienceText:SetIsVisible(false)
    self.experienceBarBackground:AddChild(self.experienceText)
end

function GUIExperience:Update(deltaTime)
	// Alter the display based on team, status.
	if (PlayerUI_GetTeamType() == "Marines") then
		self.experienceBarBackground:SetIsVisible(true)
		self.experienceBar:SetIsVisible(true)
		self.experienceText:SetIsVisible(true)
		self.experienceBar:SetColor(GUIExperience.kMarineGUIColor)
		self.experienceText:SetColor(GUIExperience.kMarineTextColor)
	elseif (PlayerUI_GetTeamType() == "Aliens") then
		self.experienceBarBackground:SetIsVisible(true)
		self.experienceBar:SetIsVisible(true)
		self.experienceText:SetIsVisible(true)
		self.experienceBar:SetColor(GUIExperience.kAlienGUIColor)	
		self.experienceText:SetColor(GUIExperience.kAlienTextColor)
	else
		self.experienceBarBackground:SetIsVisible(false)
		self.experienceBar:SetIsVisible(false)
		self.experienceText:SetIsVisible(false)
	end
		
	// Recalculate, tween and fade
	self:UpdateExperienceBar(deltaTime)
	self:UpdateFading(deltaTime)
	self:UpdateText(deltaTime)
end

function GUIExperience:UpdateExperienceBar(deltaTime)
    local expBarPercentage = PlayerUI_GetExperienceProgression()
	local calculatedBarWidth = GUIExperience.kExperienceBackgroundWidth * expBarPercentage
	local currentBarWidth = self.experienceBar:GetSize().x
	local targetBarWidth = calculatedBarWidth
	
	// Method to allow proper tweening visualisation when you go up a rank.
	// Currently detecting this by examining old vs new size.
	if (calculatedBarWidth < currentBarWidth) then
		self.rankIncreased = true
	end
	
	if (self.rankIncreased) then
		targetBarSize = GUIExperience.kExperienceBackgroundWidth
		// Once we reach the end, reset the bar back to the beginning.
		if (currentBarWidth >= targetBarWidth) then
			self.rankIncreased = false
			currentBarWidth = 0
			targetBarWidth = calculatedBarWidth
		end
	end
    self.experienceBar:SetSize(Vector(Slerp(currentBarWidth, targetBarWidth, deltaTime*GUIExperience.kBackgroundBarRate), GUIExperience.kExperienceBackgroundHeight, 0))
	
	// Detect and register if the bar is moving
	if (math.abs(currentBarWidth - calculatedBarWidth) > 5) then
		self.barMoving = true
	else
		self.barMoving = false
	end
end

function GUIExperience:UpdateFading(deltaTime)
	local currentBarHeight = self.experienceBar:GetSize().y
	local currentBackgroundHeight = self.experienceBarBackground:GetSize().y
	local currentAlpha = self.experienceBar:GetColor().a
	local currentBarColor = self.experienceBar:GetColor()
	local targetBarHeight = currentBarHeight
	local targetBackgroundHeight = currentBackgroundHeight
	local targetBarColor = currentBarColor
		
	if (self.barMoving) then
		targetBarHeight = GUIExperience.kExperienceBarHeight
		targetBackgroundHeight = GUIExperience.kExperienceBackgroundMinimisedHeight
		targetAlpha = GUIExperience.kNormalAlpha
	else
		targetBarHeight = GUIExperience.kExperienceBarHeight
		targetBackgroundHeight = GUIExperience.kExperienceBackgroundMinimisedHeight
		targetAlpha = GUIExperience.kMinimisedAlpha
	end
	
	self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, Slerp(currentBackgroundHeight, targetBackgroundHeight, deltaTime*GUIExperience.kBackgroundBarRate), 0))
	self.experienceBar:SetSize(Vector(self.experienceBar:GetSize().x, Slerp(currentBarHeight, targetBarHeight, deltaTime*GUIExperience.kBackgroundBarRate), 0))
	self.experienceBar:SetColor(Color(currentBarColor.r, currentBarColor.g, currentBarColor.b, Slerp(currentAlpha, targetAlpha, deltaTime*GUIExperience.kBarFadeOutRate)))
end

function GUIExperience:UpdateText(deltaTime)
	// Tween the experience text too!
	self.currentExperience = Slerp(self.currentExperience, PlayerUI_GetPlayerExperience(), deltaTime*GUIExperience.kTextIncreaseRate)
	self.experienceText:SetText(tostring(math.ceil(self.currentExperience)) .. " / " .. Experience_GetNextRankExp(PlayerUI_GetPlayerRank()) .. " (" .. PlayerUI_GetPlayerRankName() .. ")")
end

function GUIExperience:Uninitialize()

	if self.experienceBar then
        GUI.DestroyItem(self.experienceBarBackground)
        self.experienceBar = nil
        self.experienceBarText = nil
        self.experienceBarBackground = nil
    end
    
end