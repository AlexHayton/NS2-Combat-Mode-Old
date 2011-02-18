// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Team.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Tracks players on a team.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Team'

function Team:Initialize(teamName, teamNumber)

    self.teamName = teamName
    self.teamNumber = teamNumber
    self.playerIds = {}
    self.respawnQueue = {}
    self.kills = 0
    
end

function Team:OnCreate()
end

function Team:OnInit()
end

function Team:OnKill(targetEntity, damage, killer, doer, point, direction)
end

/**
 * Adds a player to the team. This generally does not need to be called directly. Called only
 * by Player:OnTeamChange().
 */
function Team:AddPlayer(player)
    
    if(player ~= nil and player:isa("Player")) then
    
        local id = player:GetId()
        
        if(id ~= Entity.invalidId) then
            table.insertunique( self.playerIds, id )
        else
            Print("Team:AddPlayer(player): Player is valid but id is -1, skipping.")
        end
        
    else    
        Print("%s", ConditionalValue(player == nil, "Team:AddPlayer(nil): Player is nil.", string.format("Team:AddPlayer(): Tried to add entity of type \"%s\"", player:GetMapName())))
    end
    
end

function Team:OnEntityChange(oldId, newId)
end

function Team:GetPlayer(playerIndex)

    if (playerIndex >= 1 and playerIndex <= table.count(self.playerIds)) then
        return Shared.GetEntity( self.playerIds[playerIndex] )
    end
    
    Print("Team:GetPlayer(%d): Invalid index specified (%d players on team, starts at index 1)", playerIndex, table.count(self.playerIds))
    return nil
    
end

/**
 * Removes a player from the team. This generally does not need to be called directly. Called only
 * by Player:OnTeamChange().
 */
function Team:RemovePlayer(player)


    if(not table.removevalue( self.playerIds, player:GetId() )) then
        Print("Team:RemovePlayer(%s): Player id %d not in playerId list.", player:GetClassName(), player:GetId())
    end
    
    self:RemovePlayerFromRespawnQueue(player)    

    
end

function Team:GetNumPlayers()

    local numPlayers = 0
    
    function CountPlayer(player)
        numPlayers = numPlayers + 1
    end
    
    self:ForEachPlayer(CountPlayer)
    
    return numPlayers
    
end

function Team:GetPlayers()

    local playerList = {}
    for index, playerId in ipairs(self.playerIds) do

        local player = Shared.GetEntity(playerId)
        if player ~= nil and player:GetId() ~= Entity.invalidId then
        
            table.insert(playerList, player)
            
        end
        
    end
    
    return playerList
    
end

function Team:AddTooltip(tooltipText)

    function t(player)
        player:AddTooltip(tooltipText)
    end
    
    self:ForEachPlayer(t)
    
end

function Team:tostring()

    local numPlayers = self:GetNumPlayers()
    local s = string.format("Team num players: %d ", numPlayers)
    
    for index, playerId in ipairs(self.playerIds) do
    
        local player = Shared.GetEntity(playerId)
        s = s .. string.format("Player %d, entId %d, mapName %s ", index, playerId, player:GetMapName())
    end
    
    s = s .. " respawnQueue: (" .. table.tostring(self.respawnQueue) .. ")"
    
    return s
    
end

function Team:GetTeamLocation()
    return self.teamLocation
end

function Team:GetTeamNumber()
    return self.teamNumber
end

// Called on game start or end. Reset everything but teamNumber and teamName.
function Team:Reset()

    self.kills = 0
        
    self.respawnQueue = {}
    
    // Clear players
    self.playerIds = {}
    
end

function Team:ResetPreservePlayers(teamLocation)

    local playersOnTeam = {}
    table.copy(self.playerIds, playersOnTeam)
    
    self.teamLocation = teamLocation
    
    self:Reset()

    table.copy(playersOnTeam, self.playerIds)    
    
end

/**
 * Queues a player to be spawned.
 */
function Team:PutPlayerInRespawnQueue(player, time)
    
    // Save time
    player:SetRespawnQueueEntryTime(time)
    table.insertunique(self.respawnQueue, player:GetId())

end

/** 
 * Play sound for every player on the team.
 */
function Team:PlayPrivateTeamSound(soundName, origin, commandersOnly, excludePlayer)

    local function PlayPrivateSound(player)
    
        if not commandersOnly or player:isa("Commander") then
            if excludePlayer ~= player then
                if not origin then
                    Server.PlayPrivateSound(player, soundName, player, 1.0, Vector(0, 0, 0))
                else
                    Server.PlayPrivateSound(player, soundName, nil, 1.0, origin)
                end
            end
        end
        
    end
    
    self:ForEachPlayer(PlayPrivateSound)
    
end

function Team:SetFrozenState(state)

    local function SetFrozen(player)
        player.frozen = state
    end
    
    self:ForEachPlayer(SetFrozen)
    
end

function Team:GetIsPlayerInRespawnQueue(player)
    return (table.find(self.respawnQueue, player:GetId()) ~= nil)
end

/**
 * Removes the player from the team's spawn queue (if he's in it, otherwise has
 * no effect).
 */
function Team:RemovePlayerFromRespawnQueue(player)
    table.removevalue(self.respawnQueue, player:GetId())
end

function Team:ClearRespawnQueue()
    table.clear(self.respawnQueue)
end

// Find player that's been dead and waiting the longest. Return nil if there are none.
function Team:GetOldestQueuedPlayer()
    
    local playerToSpawn = nil
    local earliestTime = -1

    for i,playerId in ipairs(self.respawnQueue) do
        local player = Shared.GetEntity(playerId)
        local currentPlayerTime = player:GetRespawnQueueEntryTime()
        if((currentPlayerTime ~= nil) and ((earliestTime == -1) or (currentPlayerTime < earliestTime))) then
            playerToSpawn = player
            earliestTime = currentPlayerTime                        
        end        
    end

    return playerToSpawn

end

function Team:GetKills()
    return self.kills
end

function Team:AddKills(num)
    self.kills = self.kills + num
end

function Team:TechAdded(entity) 
end

function Team:TechRemoved(entity)    
end

function Team:TechBuilt(entity)
end

// Respawn all players that have been dead since at least the specified time (or pass nil to respawn all)
function Team:RespawnAllPlayers(spawnTime)

    local playerIds = table.duplicate(self.playerIds)
    
    for i, playerId in ipairs(playerIds) do
    
        local player = Shared.GetEntity(playerId)
        if(spawnTime == nil or (spawnTime > player:GetSpawnQueueEntryTime())) then

            self:RespawnPlayer(player, nil, nil)
            
        end
        
    end
    
end

function Team:GetIsPlayerOnTeam(player)
    return table.find(self.playerIds, player:GetId()) ~= nil    
end

function Team:ReplaceRespawnAllPlayers()

    local playerIds = table.duplicate(self.playerIds)

    for i, playerIndex in ipairs(playerIds) do
    
        local player = Shared.GetEntity(playerIndex)
        self:ReplaceRespawnPlayer(player, nil, nil)

    end
    
end

// For every player on team, call functor(player)
function Team:ForEachPlayer(functor)

    for i, playerIndex in ipairs(self.playerIds) do
    
        local player = Shared.GetEntity(playerIndex)
        if(player ~= nil and player:isa("Player")) then
            functor(player)
        else
            Print("Team:ForEachPlayer(): Couldn't find player for index %d", playerIndex)
        end
    end

end

function Team:GetHasActivePlayers()

    local hasActivePlayers = false
    local currentTeam = self

    local function HasActivePlayers(player)
        if(player:GetIsAlive() and (player:GetTeam() == currentTeam)) then
            hasActivePlayers = true
        end
    end

    self:ForEachPlayer(HasActivePlayers)
    return hasActivePlayers

end

function Team:GetHasAbilityToRespawn()
    return true
end

function Team:UpdateHelp()

    if(self.timeOfLastHelpCheck == nil or (Shared.GetTime() > self.timeOfLastHelpCheck + PlayingTeam.kTooltipHelpInterval)) then
    
        function ProcessPlayerHelp(player)

            if(player:AddTooltipOnce("Welcome to the Natural Selection 2 beta!")) then
                return true
            elseif(player:AddTooltipOncePer("You're in the ready room. In the console, type j1 or j2 to play (rr for ready room).", 30)) then
                return true
            end
            
        end

        self:ForEachPlayer(ProcessPlayerHelp)
    
        self.timeOfLastHelpCheck = Shared.GetTime()
        
    end 
    
end

function Team:Update(timePassed)

    self:UpdateHelp()
    
end

function Team:GetNumCommandStructures()

    local commandStructures = GetEntitiesIsa("CommandStructure", self:GetTeamNumber())
    return table.maxn(commandStructures)    
    
end

function Team:GetHasTeamLost()
    return false    
end

function Team:GetHasTeamWon()
    return false    
end

function Team:RespawnPlayer(player, origin, angles)

    if(self:GetIsPlayerOnTeam(player)) then
    
        if(origin == nil or angles == nil) then

            // Randomly choose unobstructed spawn points to respawn the player
            local spawnPoint = nil
            local spawnPoints = Server.readyRoomSpawnList
            local numSpawnPoints = table.maxn(spawnPoints)

            if(numSpawnPoints > 0) then
            
                local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
                if (spawnPoint ~= nil) then
                
                    origin = spawnPoint:GetOrigin()
                    angles = spawnPoint:GetAngles()
                    
                end
                
            end
            
        end
        
        // Move origin up and drop it to floor to prevent stuck issues with floating errors or slightly misplaced spawns
        if(origin ~= nil) then
        
            SpawnPlayerAtPoint(player, origin, angles)
            
            player:ClearEffects()
            
            return true
            
        else
            Print("Team:RespawnPlayer(player, %s, %s) - No origin/angles specified and no ReadyRoomSpawn entities found.", ToString(origin), ToString(angles))
        end
        
    else
        Print("Team:RespawnPlayer(player) - Player isn't on team.")
    end
    
    return false
    
end

function Team:BroadcastMessage(message)

    function sendMessage(player)
        Server.Broadcast(player, message)
    end
    
    self:ForEachPlayer( sendMessage )
    
end

