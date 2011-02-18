
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIScoreboard.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the player scoreboard (scores, pings, etc).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIScoreboard' (GUIScript)

// Shared constants.
GUIScoreboard.kFontName = "Calibri"
GUIScoreboard.kLowPingThreshold = 100
GUIScoreboard.kLowPingColor = Color(0, 1, 0, 1)
GUIScoreboard.kMedPingThreshold = 249
GUIScoreboard.kMedPingColor = Color(1, 1, 0, 1)
GUIScoreboard.kHighPingThreshold = 499
GUIScoreboard.kHighPingColor = Color(1, 0.5, 0, 1)
GUIScoreboard.kInsanePingColor = Color(1, 0, 0, 1)

// Team constants.
GUIScoreboard.kTeamNameFontSize = 26
GUIScoreboard.kTeamInfoFontSize = 16
GUIScoreboard.kTeamItemWidth = 700
GUIScoreboard.kTeamItemHeight = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 8
GUIScoreboard.kTeamSpacing = 32
GUIScoreboard.kTeamScoreColumnStartX = 250
GUIScoreboard.kTeamColumnSpacingX = 50

// Player constants.
GUIScoreboard.kPlayerStatsFontSize = 16
GUIScoreboard.kPlayerItemWidthBuffer = 10
GUIScoreboard.kPlayerItemHeight = 32
GUIScoreboard.kPlayerSpacing = 4

// Color constants.
GUIScoreboard.kBlueColor = ColorIntToColor(kMarineTeamColor)
GUIScoreboard.kBlueHighlightColor = Color(0.30, 0.69, 1, 1)
GUIScoreboard.kRedColor = ColorIntToColor(kAlienTeamColor)
GUIScoreboard.kRedHighlightColor = Color(1, 0.79, 0.23, 1)
GUIScoreboard.kSpectatorColor = ColorIntToColor(kNeutralTeamColor)
GUIScoreboard.kSpectatorHighlightColor = Color(0.8, 0.8, 0.8, 1)

function GUIScoreboard:Initialize()
    
    self.teams = { }
    self.reusePlayerItems = { }
    
    // Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    // Blue team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kBlueColor), TeamName = ScoreboardUI_GetBlueTeamName(),
                               Color = GUIScoreboard.kBlueColor, PlayerList = { }, HighlightColor = GUIScoreboard.kBlueHighlightColor,
                               GetScores = ScoreboardUI_GetBlueScores, TeamNumber = kTeam1Index})
    // Red team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kRedColor), TeamName = ScoreboardUI_GetRedTeamName(),
                               Color = GUIScoreboard.kRedColor, PlayerList = { }, HighlightColor = GUIScoreboard.kRedHighlightColor,
                               GetScores = ScoreboardUI_GetRedScores, TeamNumber = kTeam2Index })
    
    // Spectator team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kSpectatorColor), TeamName = ScoreboardUI_GetSpectatorTeamName(),
                               Color = GUIScoreboard.kSpectatorColor, PlayerList = { }, HighlightColor = GUIScoreboard.kSpectatorHighlightColor,
                               GetScores = ScoreboardUI_GetSpectatorScores, TeamNumber = kTeamReadyRoom })

    self.playerHighlightItem = GUI.CreateGraphicsItem()
    self.playerHighlightItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0))
    self.playerHighlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerHighlightItem:SetColor(Color(1, 1, 1, 1))
    self.playerHighlightItem:SetTexture("ui/hud_elements.dds")
    self.playerHighlightItem:SetTextureCoordinates(0, 0.16, 0.558, 0.32)
    self.playerHighlightItem:SetIsVisible(false)

end

function GUIScoreboard:Uninitialize()

    for index, team in ipairs(self.teams) do
        GUI.DestroyItem(team["GUIs"]["Background"])
    end
    self.teams = { }
    
    for index, playerItem in ipairs(self.reusePlayerItems) do
        GUI.DestroyItem(playerItem["Background"])
    end
    self.reusePlayerItems = { }
    
end

function GUIScoreboard:CreateHeader()
    
    
    
end

function GUIScoreboard:CreateTeamBackground(color)

    // Create background.
    local teamItem = GUI.CreateGraphicsItem()
    teamItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth, GUIScoreboard.kTeamItemHeight, 0))
    teamItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
    teamItem:SetPosition(Vector(-GUIScoreboard.kTeamItemWidth / 2, -GUIScoreboard.kTeamItemHeight / 2, 0))
    teamItem:SetColor(Color(0, 0, 0, 0.75))
    teamItem:SetIsVisible(ScoreboardUI_GetVisible())
    
    // Team name text item.
    local teamNameItem = GUI.CreateTextItem()
    teamNameItem:SetFontName(GUIScoreboard.kFontName)
    teamNameItem:SetFontSize(GUIScoreboard.kTeamNameFontSize)
    teamNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamNameItem:SetTextAlignmentX(GUITextItem.Align_Min)
    teamNameItem:SetTextAlignmentY(GUITextItem.Align_Min)
    teamNameItem:SetPosition(Vector(5, 5, 0))
    teamNameItem:SetColor(color)
    teamItem:AddChild(teamNameItem)
    
    // Add team info (carbon and number of players)
    local teamInfoItem = GUI.CreateTextItem()
    teamInfoItem:SetFontName(GUIScoreboard.kFontName)
    teamInfoItem:SetFontSize(GUIScoreboard.kTeamInfoFontSize)
    teamInfoItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamInfoItem:SetTextAlignmentX(GUITextItem.Align_Min)
    teamInfoItem:SetTextAlignmentY(GUITextItem.Align_Min)
    teamInfoItem:SetPosition(Vector(15, GUIScoreboard.kTeamNameFontSize, 0))
    teamInfoItem:SetColor(color)
    teamItem:AddChild(teamInfoItem)
    
    local currentColumnX = GUIScoreboard.kTeamScoreColumnStartX
    
    // Status text item.
    local statusItem = GUI.CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kFontName)
    statusItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUITextItem.Align_Min)
    statusItem:SetTextAlignmentY(GUITextItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX, 5, 0))
    statusItem:SetColor(color)
    statusItem:SetText("")
    teamItem:AddChild(statusItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 3
    
    // Score text item.
    local scoreItem = GUI.CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kFontName)
    scoreItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUITextItem.Align_Min)
    scoreItem:SetTextAlignmentY(GUITextItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX, 5, 0))
    scoreItem:SetColor(color)
    scoreItem:SetText("Score")
    teamItem:AddChild(scoreItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Rank text item.
    local rankItem = GUI.CreateTextItem()
    rankItem:SetFontName(GUIScoreboard.kFontName)
    rankItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    rankItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    rankItem:SetTextAlignmentX(GUITextItem.Align_Min)
    rankItem:SetTextAlignmentY(GUITextItem.Align_Min)
    rankItem:SetPosition(Vector(currentColumnX, 5, 0))
    rankItem:SetColor(color)
    rankItem:SetText("Rank")
    teamItem:AddChild(rankItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Kill text item.
    local killsItem = GUI.CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kFontName)
    killsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUITextItem.Align_Min)
    killsItem:SetTextAlignmentY(GUITextItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, 5, 0))
    killsItem:SetColor(color)
    killsItem:SetText("Kills")
    teamItem:AddChild(killsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Deaths text item.
    local deathsItem = GUI.CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kFontName)
    deathsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUITextItem.Align_Min)
    deathsItem:SetTextAlignmentY(GUITextItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, 5, 0))
    deathsItem:SetColor(color)
    deathsItem:SetText("Deaths")
    teamItem:AddChild(deathsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
   
    // Resources text item.
    local resItem = GUI.CreateTextItem()
    resItem:SetFontName(GUIScoreboard.kFontName)
    resItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    resItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    resItem:SetTextAlignmentX(GUITextItem.Align_Min)
    resItem:SetTextAlignmentY(GUITextItem.Align_Min)
    resItem:SetPosition(Vector(currentColumnX, 5, 0))
    resItem:SetColor(color)
    resItem:SetText("Plasma")
    teamItem:AddChild(resItem)
	
	// Combat mode: plasma is kind of irrelevant!
    resItem:SetIsVisible(false)
	
    //currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Ping text item.
    local pingItem = GUI.CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kFontName)
    pingItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUITextItem.Align_Min)
    pingItem:SetTextAlignmentY(GUITextItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, 5, 0))
    pingItem:SetColor(color)
    pingItem:SetText("Ping")
    teamItem:AddChild(pingItem)
    
    return { Background = teamItem, TeamName = teamNameItem, TeamInfo = teamInfoItem }
    
end

function GUIScoreboard:Update(deltaTime)

    local teamsVisible = ScoreboardUI_GetVisible()
    
    ASSERT(teamsVisible ~= nil)
    
    //First, update teams.
    for index, team in ipairs(self.teams) do
    
        // Don't draw if no players on team
        local numPlayers = table.count(team["GetScores"]())    
        team["GUIs"]["Background"]:SetIsVisible(teamsVisible and (numPlayers > 0))
        
        if teamsVisible then
            self:UpdateTeam(team)
        end
    end
    
    // Next, position teams.
    if teamsVisible then
        
        local numTeams = table.count(self.teams)
        if numTeams > 0 then
        
            // Count the size the team tables are going to take up on the screen.
            local sizeOfAllTeams = 0
            for index, team in ipairs(self.teams) do
                if team["GUIs"]["Background"]:GetIsVisible() then
                    sizeOfAllTeams = sizeOfAllTeams + team["GUIs"]["Background"]:GetSize().y + GUIScoreboard.kTeamSpacing 
                end
            end
            
            local currentY = -(sizeOfAllTeams / 2)
            for index, team in ipairs(self.teams) do
                local newPosition = Vector(-GUIScoreboard.kTeamItemWidth / 2, 0, 0)
                newPosition.y = currentY
                currentY = currentY + team["GUIs"]["Background"]:GetSize().y + GUIScoreboard.kTeamSpacing
                team["GUIs"]["Background"]:SetPosition(newPosition)
            end
            
        end
        
    end
    
end

function GUIScoreboard:UpdateTeam(updateTeam)
    
    local teamGUIItem = updateTeam["GUIs"]["Background"]
    local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
    local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
    local teamNameText = updateTeam["TeamName"]
    local teamColor = updateTeam["Color"]
    local localPlayerHighlightColor = updateTeam["HighlightColor"]
    local playerList = updateTeam["PlayerList"]
    local teamScores = updateTeam["GetScores"]()
    
    local isLocalTeam = false
    local player = Client.GetLocalPlayer()
    if player and player:GetTeamNumber() == updateTeam["TeamNumber"] then
        isLocalTeam = true
    end

    // How many items per player.
    local numElementsPerPlayerRecord = 10
    local numPlayers = table.count(teamScores) / numElementsPerPlayerRecord
    
    // Update the team name text.
    teamNameGUIItem:SetText(string.format("%s (%s)", teamNameText, Pluralize(numPlayers, "Player")))
    
    // Update carbon display
    local carbonString = ConditionalValue(isLocalTeam, string.format("%d Carbon", player:GetTeamCarbon()), "")
    teamInfoGUIItem:SetText(string.format("%s", carbonString))
    
    // Make sure there is enough room for all players on this team GUI.
    teamGUIItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth, (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0))
    
    // Resize the player list if it doesn't match.
    if table.count(playerList) ~= numPlayers then
        self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    end
    
    local currentY = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize
    local currentPlayerIndex = 1
    for index, player in pairs(playerList) do
        // GetScores table format: Name, score, kills, deaths, ping.
        local playerName = teamScores[currentPlayerIndex]
        local score = tostring(teamScores[currentPlayerIndex + 1])
        local kills = tostring(teamScores[currentPlayerIndex + 2])
        local deaths = tostring(teamScores[currentPlayerIndex + 3])
		// Uncomment this to enable display of rank name. It doesn't look quite right because the column width is too small!
        //local rankStr= ConditionalValue(tostring(Experience_GetRankName(updateTeam["TeamNumber"], teamScores[currentPlayerIndex + 7])), "-")
		local rankStr= ConditionalValue(isLocalTeam, tostring(teamScores[currentPlayerIndex + 9]), "-")
        local plasmaStr = ConditionalValue(isLocalTeam, tostring(teamScores[currentPlayerIndex + 5]), "-")
        local ping = teamScores[currentPlayerIndex + 6]
        local pingStr = tostring(ping)
        local currentPosition = Vector(player["Background"]:GetPosition())
        local playerStatus = teamScores[currentPlayerIndex + 7]
        local isSpectator = teamScores[currentPlayerIndex + 8]
        
        if (isSpectator == true and (updateTeam["TeamNumber"] == kAlienTeamType or updateTeam["TeamNumber"] == kMarineTeamType)) then
            playerStatus = "Dead"
        end
        
        local status = ConditionalValue(isLocalTeam, playerStatus, "-")
        if (playerStatus == "Dead") then
            status = playerStatus
        end
        
        currentPosition.y = currentY
        player["Background"]:SetPosition(currentPosition)
        player["Background"]:SetColor(teamColor)
        
        // Handle local player highlight
        if ScoreboardUI_IsPlayerLocal(playerName) then
            if self.playerHighlightItem:GetParent() ~= player["Background"] then
                if self.playerHighlightItem:GetParent() ~= nil then
                    self.playerHighlightItem:GetParent():RemoveChild(self.playerHighlightItem)
                end
                player["Background"]:AddChild(self.playerHighlightItem)
                self.playerHighlightItem:SetIsVisible(true)
                self.playerHighlightItem:SetColor(localPlayerHighlightColor)
            end
        end
        
        player["Name"]:SetText(playerName)
        player["Score"]:SetText(score)
        player["Kills"]:SetText(kills)
        player["Deaths"]:SetText(deaths)
        player["Status"]:SetText(status)
        player["Plasma"]:SetText(plasmaStr)
        player["Ping"]:SetText(pingStr)
        player["Rank"]:SetText(rankStr)
        if ping < GUIScoreboard.kLowPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kLowPingColor)
        elseif ping < GUIScoreboard.kMedPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kMedPingColor)
        elseif ping < GUIScoreboard.kHighPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kHighPingColor)
        else
            player["Ping"]:SetColor(GUIScoreboard.kInsanePingColor)
        end
        currentY = currentY + GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing
        currentPlayerIndex = currentPlayerIndex + numElementsPerPlayerRecord
    end

end

function GUIScoreboard:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    
    while table.count(playerList) > numPlayers do
        teamGUIItem:RemoveChild(playerList[1]["Background"])
        playerList[1]["Background"]:SetIsVisible(false)
        table.insert(self.reusePlayerItems, playerList[1])
        table.remove(playerList, 1)
    end
    
    while table.count(playerList) < numPlayers do
        local newPlayerItem = self:CreatePlayerItem()
        table.insert(playerList, newPlayerItem)
        teamGUIItem:AddChild(newPlayerItem["Background"])
        newPlayerItem["Background"]:SetIsVisible(true)
    end

end

function GUIScoreboard:CreatePlayerItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reusePlayerItems) > 0 then
        local returnPlayerItem = self.reusePlayerItems[1]
        table.remove(self.reusePlayerItems, 1)
        return returnPlayerItem
    end
    
    // Create background.
    local playerItem = GUI.CreateGraphicsItem()
    playerItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0))
    playerItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerItem:SetPosition(Vector(GUIScoreboard.kPlayerItemWidthBuffer, GUIScoreboard.kPlayerItemHeight / 2, 0))
    playerItem:SetColor(Color(1, 1, 1, 1))
    playerItem:SetTexture("ui/hud_elements.dds")
    playerItem:SetTextureCoordinates(0, 0, 0.558, 0.16)
    
    // Player name text item.
    local playerNameItem = GUI.CreateTextItem()
    playerNameItem:SetFontName(GUIScoreboard.kFontName)
    playerNameItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    playerNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerNameItem:SetTextAlignmentX(GUITextItem.Align_Min)
    playerNameItem:SetTextAlignmentY(GUITextItem.Align_Min)
    playerNameItem:SetPosition(Vector(5, 5, 0))
    playerNameItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(playerNameItem)
    
    local currentColumnX = GUIScoreboard.kTeamScoreColumnStartX
    
    // Status text item.
    local statusItem = GUI.CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kFontName)
    statusItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUITextItem.Align_Min)
    statusItem:SetTextAlignmentY(GUITextItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX, 5, 0))
    statusItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(statusItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 3
    
    // Score text item.
    local scoreItem = GUI.CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kFontName)
    scoreItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUITextItem.Align_Min)
    scoreItem:SetTextAlignmentY(GUITextItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX, 5, 0))
    scoreItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(scoreItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Rank text item.
    local rankItem = GUI.CreateTextItem()
    rankItem:SetFontName(GUIScoreboard.kFontName)
    rankItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    rankItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    rankItem:SetTextAlignmentX(GUITextItem.Align_Min)
    rankItem:SetTextAlignmentY(GUITextItem.Align_Min)
    rankItem:SetPosition(Vector(currentColumnX, 5, 0))
    rankItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(rankItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX    
    
    // Kill text item.
    local killsItem = GUI.CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kFontName)
    killsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUITextItem.Align_Min)
    killsItem:SetTextAlignmentY(GUITextItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, 5, 0))
    killsItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(killsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Deaths text item.
    local deathsItem = GUI.CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kFontName)
    deathsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUITextItem.Align_Min)
    deathsItem:SetTextAlignmentY(GUITextItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, 5, 0))
    deathsItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(deathsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Resources text item.
    local resItem = GUI.CreateTextItem()
    resItem:SetFontName(GUIScoreboard.kFontName)
    resItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    resItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    resItem:SetTextAlignmentX(GUITextItem.Align_Min)
    resItem:SetTextAlignmentY(GUITextItem.Align_Min)
    resItem:SetPosition(Vector(currentColumnX, 5, 0))
    resItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(resItem)
	
	// Combat mode: plasma is kind of irrelevant!
    resItem:SetIsVisible(false)
	
    //currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Ping text item.
    local pingItem = GUI.CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kFontName)
    pingItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUITextItem.Align_Min)
    pingItem:SetTextAlignmentY(GUITextItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, 5, 0))
    pingItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(pingItem)
    
    return { Background = playerItem, Name = playerNameItem, Status = statusItem, Score = scoreItem, Kills = killsItem, Deaths = deathsItem, Plasma = resItem, Ping = pingItem, Rank = rankItem }
    
end