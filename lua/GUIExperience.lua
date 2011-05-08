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
GUIExperience.kMinimisedTextAlpha = 0.6
GUIExperience.kMinimisedAlpha = 0.4

GUIExperience.kBarFadeInRate = 0.2
GUIExperience.kBarFadeOutDelay = 0.4
GUIExperience.kBarFadeOutRate = 0.05
GUIExperience.kBackgroundBarRate = 80
GUIExperience.kTextIncreaseRate = 30


function GUIExperience:Initialize()
	self:CreateExperienceBar()
	self.rankIncreased = false
	self.currentExperience = 0
	self.showExperience = false
	self.experienceAlpha = GUIExperience.kNormalAlpha
	self.experienceTextAlpha = GUIExperience.kNormalAlpha
	self.barMoving = false
	self.playerTeam = "None"
	self.fadeOutTime = Shared.GetTime()
end

function GUIExperience:CreateExperienceBar()
    self.experienceBarBackground = GUIManager.CreateGraphicsItem()
    self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, GUIExperience.kExperienceBackgroundMinimisedHeight, 0))
    self.experienceBarBackground:SetAnchor(GUIItem.Center, GUIItem.Bottom)
    self.experienceBarBackground:SetPosition(GUIExperience.kExperienceBackgroundOffset)
    self.experienceBarBackground:SetColor(GUIExperience.kExperienceBackgroundColor)
    self.experienceBarBackground:SetTexture(GUIExperience.kTextureName)
    self.experienceBarBackground:SetTexturePixelCoordinates(GUIExperience.kExperienceBackgroundTextureX1, GUIExperience.kExperienceBackgroundTextureY1, GUIExperience.kExperienceBackgroundTextureX2, GUIExperience.kExperienceBackgroundTextureY2)
    self.experienceBarBackground:SetIsVisible(false)
    
    self.experienceBar = GUIManager.CreateGraphicsItem()
    self.experienceBar:SetSize(Vector(GUIExperience.kExperienceBarWidth, GUIExperience.kExperienceBarHeight, 0))
    self.experienceBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.experienceBar:SetPosition(GUIExperience.kExperienceBarOffset)
    self.experienceBar:SetTexture(GUIExperience.kTextureName)
    self.experienceBar:SetTexturePixelCoordinates(GUIExperience.kExperienceBarTextureX1, GUIExperience.kExperienceBarTextureY1, GUIExperience.kExperienceBarTextureX2, GUIExperience.kExperienceBarTextureY2)
    self.experienceBar:SetIsVisible(false)
    self.experienceBarBackground:AddChild(self.experienceBar)
    
    self.experienceText = GUIManager.CreateTextItem()
    self.experienceText:SetFontSize(GUIExperience.kExperienceTextFontSize)
    self.experienceText:SetFontName(GUIExperience.kTextFontName)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetAnchor(GUIItem.Center, GUIItem.Top)
    self.experienceText:SetTextAlignmentX(GUIItem.Align_Center)
    self.experienceText:SetTextAlignmentY(GUIItem.Align_Center)
    self.experienceText:SetPosition(GUIExperience.kExperienceTextOffset)
    self.experienceText:SetIsVisible(false)
    self.experienceBarBackground:AddChild(self.experienceText)
end

function GUIExperience:Update(deltaTime)
	// Alter the display based on team, status.
	local newTeam = false
	if (self.playerTeam ~= PlayerUI_GetTeamType()) then
		self.playerTeam = PlayerUI_GetTeamType()
		newTeam = true
	end
	
	// We have switched teams.
	if (newTeam) then
		if (self.playerTeam == "Marines") then
			self.experienceBarBackground:SetIsVisible(true)
			self.experienceBar:SetIsVisible(true)
			self.experienceText:SetIsVisible(true)
			self.experienceBar:SetColor(GUIExperience.kMarineGUIColor)
			self.experienceText:SetColor(GUIExperience.kMarineTextColor)
			self.experienceAlpha = 1.0
			self.showExperience = true
		elseif (self.playerTeam == "Aliens") then
			self.experienceBarBackground:SetIsVisible(true)
			self.experienceBar:SetIsVisible(true)
			self.experienceText:SetIsVisible(true)
			self.experienceBar:SetColor(GUIExperience.kAlienGUIColor)	
			self.experienceText:SetColor(GUIExperience.kAlienTextColor)
			self.experienceAlpha = 1.0
			self.showExperience = true
		else
			self.experienceBarBackground:SetIsVisible(false)
			self.experienceBar:SetIsVisible(false)
			self.experienceText:SetIsVisible(false)
			self.showExperience = false
		end
	end
		
	// Recalculate, tween and fade
	if (self.showExperience) then
		self:UpdateExperienceBar(deltaTime)
		self:UpdateFading(deltaTime)
		self:UpdateText(deltaTime)
	end
end

function GUIExperience:UpdateExperienceBar(deltaTime)
    local expBarPercentage = PlayerUI_GetExperienceProgression()
	local calculatedBarWidth = GUIExperience.kExperienceBarWidth * expBarPercentage
	local currentBarWidth = self.experienceBar:GetSize().x
	local targetBarWidth = calculatedBarWidth
	
	// Method to allow proper tweening visualisation when you go up a rank.
	// Currently detecting this by examining old vs new size.
	if (math.floor(calculatedBarWidth) < math.floor(currentBarWidth)) then
		self.rankIncreased = true
	end
	
	if (self.rankIncreased) then
		targetBarWidth = GUIExperience.kExperienceBarWidth
		// Once we reach the end, reset the bar back to the beginning.
		if (currentBarWidth >= targetBarWidth) then
			self.rankIncreased = false
			currentBarWidth = 0
			targetBarWidth = calculatedBarWidth
		end
	end
	
	if (PlayerUI_GetPlayerExperience() == kMaxExperience) then
		currentBarWidth = GUIExperience.kExperienceBarWidth
		targetBarWidth = GUIExperience.kExperienceBarWidth
		calculatedBarWidth = GUIExperience.kExperienceBarWidth
		self.rankIncreased = false
	end
	
	self.experienceBar:SetSize(Vector(Slerp(currentBarWidth, targetBarWidth, deltaTime*GUIExperience.kBackgroundBarRate), self.experienceBar:GetSize().y, 0))
	
	// Detect and register if the bar is moving
	if (math.abs(currentBarWidth - calculatedBarWidth) > 0.01) then
		self.barMoving = true
	else
		// Delay the fade out by a while
		if (self.barMoving) then
			self.fadeOutTime = Shared.GetTime() + GUIExperience.kBarFadeOutDelay
		end
		self.barMoving = false
	end
end

function GUIExperience:UpdateFading(deltaTime)
	local currentBarHeight = self.experienceBar:GetSize().y
	local currentBackgroundHeight = self.experienceBarBackground:GetSize().y
	local currentBarColor = self.experienceBar:GetColor()
	local currentTextColor = self.experienceText:GetColor()
	local targetBarHeight = currentBarHeight
	local targetBackgroundHeight = currentBackgroundHeight
	local targetBarColor = currentBarColor
	local targetAlpha = GUIExperience.kNormalAlpha
	local targetTextAlpha = GUIExperience.kNormalAlpha
		
	if (self.barMoving or Shared.GetTime() < self.fadeOutTime) then
		targetBarHeight = GUIExperience.kExperienceBarHeight
		targetBackgroundHeight = GUIExperience.kExperienceBackgroundHeight
	else
		targetBarHeight = GUIExperience.kExperienceBarMinimisedHeight
		targetBackgroundHeight = GUIExperience.kExperienceBackgroundMinimisedHeight
		targetAlpha = GUIExperience.kMinimisedAlpha
		targetTextAlpha = GUIExperience.kMinimisedTextAlpha
	end
	
	self.experienceAlpha = Slerp(self.experienceAlpha, targetAlpha, deltaTime*GUIExperience.kBarFadeOutRate)
	self.experienceTextAlpha = Slerp(self.experienceTextAlpha, targetTextAlpha, deltaTime*GUIExperience.kBarFadeOutRate)
	
	self.experienceBarBackground:SetSize(Vector(GUIExperience.kExperienceBackgroundWidth, Slerp(currentBackgroundHeight, targetBackgroundHeight, deltaTime*GUIExperience.kBackgroundBarRate), 0))
	self.experienceBar:SetSize(Vector(self.experienceBar:GetSize().x, Slerp(currentBarHeight, targetBarHeight, deltaTime*GUIExperience.kBackgroundBarRate), 0))
	self.experienceBar:SetColor(Color(currentBarColor.r, currentBarColor.g, currentBarColor.b, self.experienceAlpha))
	self.experienceText:SetColor(Color(currentTextColor.r, currentTextColor.g, currentTextColor.b, self.experienceAlpha))
end

function GUIExperience:UpdateText(deltaTime)
	// Tween the experience text too!
	self.currentExperience = Slerp(self.currentExperience, PlayerUI_GetPlayerExperience(), deltaTime*GUIExperience.kTextIncreaseRate)
	if (PlayerUI_GetPlayerExperience() == kMaxExperience) then
		self.experienceText:SetText(tostring(math.ceil(self.currentExperience)) .. " (" .. PlayerUI_GetPlayerRankName() .. ")")
	else
		self.experienceText:SetText(tostring(math.ceil(self.currentExperience)) .. " / " .. Experience_GetNextRankExp(PlayerUI_GetPlayerRank()) .. " (" .. PlayerUI_GetPlayerRankName() .. ")")
	end
end

function GUIExperience:Uninitialize()

	if self.experienceBar then
        GUIManager.DestroyItem(self.experienceBarBackground)
        self.experienceBar = nil
        self.experienceBarText = nil
        self.experienceBarBackground = nil
    end
    
end