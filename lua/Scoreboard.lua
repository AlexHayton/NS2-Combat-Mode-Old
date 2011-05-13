//=============================================================================
//
// lua/Scoreboard.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
local playerData = {}

kScoreboardDataIndexClientIndex = 1
kScoreboardDataIndexEntityId = 2
kScoreboardDataIndexName = 3
kScoreboardDataIndexEntityTeamNumber = 4
kScoreboardDataIndexScore = 5
kScoreboardDataIndexKills = 6
kScoreboardDataIndexDeaths = 7
kScoreboardDataIndexIsCommander = 8
kScoreboardDataIndexResources = 9
kScoreboardDataIndexPing = 10
kScoreboardDataIndexStatus = 11
kScoreboardDataIndexIsSpectator = 12
kScoreboardDataIndexRank = 13

function Scoreboard_Clear()

    playerData = { }
    
end

// Hooks from console commands coming from server
function Scoreboard_OnResetGame()

    // For each player, clear game data (on reset)
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        playerRecord[kScoreboardDataIndexEntityId] = 0
        playerRecord[kScoreboardDataIndexEntityTeamNumber] = 0
        playerRecord[kScoreboardDataIndexScore] = 0
        playerRecord[kScoreboardDataIndexKills] = 0
        playerRecord[kScoreboardDataIndexDeaths] = 0
        playerRecord[kScoreboardDataIndexIsCommander] = false
        playerRecord[kScoreboardDataIndexResources] = 0
        playerRecord[kScoreboardDataIndexStatus] = ""
        playerRecord[kScoreboardDataIndexIsSpectator] = false
        playerRecord[kScoreboardDataIndexRank] = 1
        
    end 

end

function Scoreboard_OnClientDisconnect(clientIndex)

    local success = false
    
    // Lookup record for player and delete it
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord[kScoreboardDataIndexClientIndex] == clientIndex then
            //Print("Scoreboard_OnClientDisconnect - removing record (%d => %s)", clientIndex, playerRecord[kScoreboardDataIndexName])
            success = table.removevalue(playerData, playerRecord)
            break
        end
        
    end
    
    return success
    
end

function Scoreboard_SetPlayerData(clientIndex, entityId, playerName, teamNumber, score, kills, deaths, resources, isCommander, status, isSpectator, rank)
    
    // Lookup record for player and update it
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord[kScoreboardDataIndexClientIndex] == clientIndex then

            // Update entry
            playerRecord[kScoreboardDataIndexEntityId] = entityId
            playerRecord[kScoreboardDataIndexName] = playerName
            playerRecord[kScoreboardDataIndexEntityTeamNumber] = teamNumber
            playerRecord[kScoreboardDataIndexScore] = score
            playerRecord[kScoreboardDataIndexKills] = kills
            playerRecord[kScoreboardDataIndexDeaths] = deaths
            playerRecord[kScoreboardDataIndexIsCommander] = isCommander
            playerRecord[kScoreboardDataIndexResources] = resources
            playerRecord[kScoreboardDataIndexStatus] = status
            playerRecord[kScoreboardDataIndexIsSpectator] = isSpectator
            playerRecord[kScoreboardDataIndexRank] = rank
            
            return
            
        end
        
    end
        
    // Otherwise insert a new record
    local playerRecord = {}
    playerRecord[kScoreboardDataIndexClientIndex] = clientIndex
    playerRecord[kScoreboardDataIndexEntityId] = entityId
    playerRecord[kScoreboardDataIndexName] = playerName
    playerRecord[kScoreboardDataIndexEntityTeamNumber] = teamNumber
    playerRecord[kScoreboardDataIndexScore] = score
    playerRecord[kScoreboardDataIndexKills] = kills
    playerRecord[kScoreboardDataIndexDeaths] = deaths
    playerRecord[kScoreboardDataIndexIsCommander] = isCommander
    playerRecord[kScoreboardDataIndexResources] = 0
    playerRecord[kScoreboardDataIndexPing] = 0
    playerRecord[kScoreboardDataIndexStatus] = status
    playerRecord[kScoreboardDataIndexIsSpectator] = isSpectator
    playerRecord[kScoreboardDataIndexRank] = rank
    
    table.insert(playerData, playerRecord )
    
end

function Scoreboard_SetPing(clientIndex, ping)

    local setPing = false
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        if(playerRecord[kScoreboardDataIndexClientIndex] == clientIndex) then
            playerRecord[kScoreboardDataIndexPing] = ping
            setPing = true
        end
        
    end
    
end

// Set local data for player so scoreboard updates instantly
function Scoreboard_SetLocalPlayerData(playerName, index, data)
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if(playerRecord[kScoreboardDataIndexName] == playerName) then
        
            playerRecord[index] = data

            break
            
        end
        
    end
    
end

function Scoreboard_GetPlayerData(clientIndex, index)

    local data = nil
    
    // Lookup record for player and delete it
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord[kScoreboardDataIndexClientIndex] == clientIndex then

            // Update entry
            data = playerRecord[index]
            break
            
        end

    end
    
    return data
    
end

/**
 * Determine if scoreboard is visible
 */
function ScoreboardUI_GetVisible()
    local player = Client.GetLocalPlayer()
    return (player ~= nil) and player.showScoreboard
end

/**
 * Get linear array of scoreboard data for all players with team numbers in specified table.
 */
function GetScoreData(teamNumberTable)

    local scoreData = {}
    
    //Print("There are %d player records", table.count(playerData))
    
    for index, playerRecord in ipairs(playerData) do
    
        if(table.find(teamNumberTable, playerRecord[kScoreboardDataIndexEntityTeamNumber])) then
        
            // Name, score, kills, deaths, isCommander, ping, rank
            table.insert(scoreData, playerRecord[kScoreboardDataIndexName])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexScore])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexKills])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexDeaths])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexIsCommander])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexResources])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexPing])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexStatus])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexIsSpectator])
            table.insert(scoreData, playerRecord[kScoreboardDataIndexRank])
            
        end
        
    end
    
    return scoreData
    
end

/**
 * Get score data for the blue team
 */
function ScoreboardUI_GetBlueScores()
    return GetScoreData({kTeam1Index})
end

/**
 * Get score data for the red team
 */
function ScoreboardUI_GetRedScores()
    return GetScoreData({kTeam2Index})
end

/**
 * Get score data for everyone not playing.
 */
function ScoreboardUI_GetSpectatorScores()
    return GetScoreData({kTeamReadyRoom, kSpectatorIndex})
end

/**
 * Get the name of the blue team
 */
function ScoreboardUI_GetBlueTeamName()
    return kTeam1Name
end

/**
 * Get the name of the red team
 */
function ScoreboardUI_GetRedTeamName()
    return kTeam2Name
end

/**
 * Get the name of the spectator team
 */
function ScoreboardUI_GetSpectatorTeamName()
    return kSpectatorTeamName
end

/**
 * Return true if playerName is a local player.
 */
function ScoreboardUI_IsPlayerLocal(playerName)
    
    local player = Client.GetLocalPlayer()
    
    // Get entry with this name and check entity id
    if player then
    
        for i = 1, table.maxn(playerData) do

            local playerRecord = playerData[i]        
            if(playerRecord[kScoreboardDataIndexName] == playerName) then

                return (player:GetClientIndex() == playerRecord[kScoreboardDataIndexClientIndex])
                
            end
            
        end    
        
    end
    
    return false
    
end

function ScoreboardUI_GetOrderedCommanderNames(teamNumber)

    local commanders = {}
    
    // Create table of commander entity ids and names
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        // TODO: Remove "not" once done testing
        if (playerRecord[kScoreboardDataIndexEntityTeamNumber] == teamNumber) and not playerRecord[kScoreboardDataIndexIsCommander] then
            table.insert( commanders, {playerRecord[kScoreboardDataIndexEntityId], playerRecord[kScoreboardDataIndexName]} )
        end
        
    end
    
    function sortCommandersByEntity(pair1, pair2)
        return pair1[1] < pair2[1]
    end
    
    // Sort it by entity id
    table.sort(commanders, sortCommandersByEntity)
    
    // Return names in order
    local commanderNames = {}
    for index, pair in ipairs(commanders) do
        table.insert(commanderNames, pair[2])
    end
    
    return commanderNames
    
end