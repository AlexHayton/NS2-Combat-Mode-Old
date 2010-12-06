// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Gamerules.lua")

class 'NS2Gamerules' (Gamerules)

NS2Gamerules.kMapName = "ns2_gamerules"

NS2Gamerules.kGamerulesThinkInterval = .5
NS2Gamerules.kGameEndCheckInterval = .75

////////////
// Server //
////////////
if(Server) then

Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/ReadyRoomTeam.lua")
Script.Load("lua/SpectatingTeam.lua")

NS2Gamerules.kMarineStartSound   = PrecacheAsset("sound/ns2.fev/marine/voiceovers/game_start")
NS2Gamerules.kAlienStartSound    = PrecacheAsset("sound/ns2.fev/alien/voiceovers/game_start")
NS2Gamerules.kVictorySound       = PrecacheAsset("sound/ns2.fev/common/victory")
NS2Gamerules.kDefeatSound        = PrecacheAsset("sound/ns2.fev/common/loss")
NS2Gamerules.kCountdownSound     = PrecacheAsset("sound/ns2.fev/common/countdown")

function NS2Gamerules:BuildTeam(teamType)

    if(teamType == kAlienTeamType) then
        return AlienTeam()
    end
    
    return MarineTeam()
    
end

function NS2Gamerules:OnCreate()

    // Calls SetGamerules()
    Gamerules.OnCreate(self)
    
    // Create team objects
    self.team1 = self:BuildTeam(kTeam1Type)
    self.team1:Initialize(kTeam1Name, kTeam1Index)

    self.team2 = self:BuildTeam(kTeam2Type)
    self.team2:Initialize(kTeam2Name, kTeam2Index)

    self.worldTeam = ReadyRoomTeam()
    self.worldTeam:Initialize("World", kTeamReadyRoom)

    self.spectatorTeam = SpectatingTeam()
    self.spectatorTeam:Initialize("Spectator", kSpectatorIndex)
    
    self.gameStarted = false
    self.timeGameStarted = nil
    self.countingDown = false
    self.countdownTime = 0
    self.timeGameEnded = nil
    self.allTech = false
    self.orderSelf = false
  
    self:SetIsVisible(false)
    self:SetPropagate(Entity.Propagate_Always)
    
    self.justCreated = true
    
end

function NS2Gamerules:GetFriendlyFire()
    return false
end

// All damage is routed through here.
function NS2Gamerules:CanEntityDoDamageTo(attacker, target)
   
    if not target:isa("LiveScriptActor") then
        return false
    end
   
    if (target == nil or target == {} or self:GetDarwinMode()) then
        return false
    elseif(Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        return true
    elseif attacker == nil then
        return true
    end

    // You can always do damage to yourself
    if (attacker == target) then
        return true
    end
    
    // Command stations can kill even friendlies trapped inside
    if attacker ~= nil and attacker:isa("CommandStation") then
        return true
    end
    
    // Your own grenades can hurt you
    local owner = attacker:GetOwner()
    if attacker:isa("Grenade") and owner and owner:GetId() == target:GetId() then
        return true
    end
    
    // Same teams not allowed to hurt each other unless friendly fire enabled
    local teamsOK = true
    if attacker ~= nil then

        teamsOK = (attacker:GetTeamNumber() ~= target:GetTeamNumber()) or self:GetFriendlyFire()
        
    end
    
    // Allow damage of own stuff when testing
    return target:GetCanTakeDamage() and teamsOK

end

function NS2Gamerules:ComputeDamageFromType(damage, damageType, entity)

    // StructuresOnly damage
    if (damageType == kDamageType.StructuresOnly and not entity:isa("Structure")) then
    
        damage = 0
        
    // Extra damage to structures
    elseif damageType == kDamageType.Structural and entity:isa("Structure") then
    
        damage = damage * kStructuralDamageScalar 

    elseif damageType ==  kDamageType.Puncture and entity:isa("Player") then
    
       damage = damage * kPuncturePlayerDamageScalar

    // Breathing targets only - not exosuits
    elseif damageType == kDamageType.Gas and (not entity:isa("Player") or entity:isa("Heavy")) then
    
        damage = 0

    elseif damageType == kDamageType.Biological then
    
        // Hurt non-mechanical players and alien structures only
        if ( (entity:isa("Player") and not entity:isa("Heavy")) or (entity:isa("Structure") and (entity:GetTeamType() == kAlienTeamType))) then

        else
            damage = 0
        end

    elseif damageType == kDamageType.Falling then
    
        if entity:isa("Skulk") then
            damage = 0
        end        
        
    end
    
    return damage
    
end

function NS2Gamerules:UpdateEntityLists(oldId, newId)

    local oldEnt = nil
    if oldId ~= nil then
        oldEnt = Shared.GetEntity(oldId)
    end
    
    local newEnt = nil
    if newId then
        newEnt = Shared.GetEntity(newId)
    end
    
    function inList(elem) 
        return elem == oldEnt 
    end
    
    if not self.playerList then
        self:UpdatePlayerList()
    end

    table.removeConditional(self.playerList, inList)
    
    if newEnt and newEnt:isa("Player") then
        table.insertunique(self.playerList, newEnt)
    end        
        
    if not self.scriptActorList then
        self:UpdateScriptActorList()
    end

    table.removeConditional(self.scriptActorList, inList)
    
    if newEnt and newEnt:isa("ScriptActor") then
        table.insertunique(self.scriptActorList, newEnt)
    end
    
end

// Update player and entity lists
function NS2Gamerules:OnEntityChange(oldId, newId)

    self:UpdateEntityLists(oldId, newId)
    
    self.worldTeam:OnEntityChange(oldId, newId)
    self.team1:OnEntityChange(oldId, newId)
    self.team2:OnEntityChange(oldId, newId)
    self.spectatorTeam:OnEntityChange(oldId, newId)
    
end

// Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
function NS2Gamerules:OnKill(targetEntity, damage, attacker, doer, point, direction)

    self.team1:OnKill(targetEntity, damage, attacker, doer, point, direction)
    self.team2:OnKill(targetEntity, damage, attacker, doer, point, direction)
    
    self:UpdateEntityLists(targetEntity:GetId(), nil)
    
end

// Find team start with team 0 or for specified team. Remove it from the list so other teams don't start there. Return nil if there are none.
function NS2Gamerules:ChooseTeamLocation(teamLocations, teamNumber)

    local teamLocation = nil
    local validLocations = {}
    local currentIndex = 1
    
    // Build list of valid starts (marked as "neutral" or for this team in map)
    for index, currentLocation in pairs(teamLocations) do
    
        local teamNum = currentLocation:GetTeamNumber()
        if(teamNum == 0 or teamNum == teamNumber) then
        
            validLocations[currentIndex] = currentLocation
            currentIndex = currentIndex + 1
            
        end
        
    end
    
    // Select entry randomly
    teamLocation = table.random(validLocations)
    if(teamLocation ~= nil) then
    
        // Remove it from the list so it isn't chosen by other team
        table.removevalue(teamLocations, teamLocation) 
        
    else    
        Print("ChooseTeamStart couldn't find a remaining team start location for team %d", teamNumber)   
    end    
    
    return teamLocation
    
end

// Use this function to change damage according to current upgrades
function NS2Gamerules:GetUpgradedDamage(entity, damage, damageType)

    local damageScalar = 1

    if entity ~= nil then
    
        // Check damage type. We can only have one of these at a time.
        if (damageType == kDamageType.Normal) then    
        
            if(GetTechSupported(entity, kTechId.Weapons3, true)) then
            
                damageScalar = kWeapons3DamageScalar
                
            elseif(GetTechSupported(entity, kTechId.Weapons2, true)) then
            
                damageScalar = kWeapons2DamageScalar
                
            elseif(GetTechSupported(entity, kTechId.Weapons1, true)) then
            
                damageScalar = kWeapons1DamageScalar
                
            elseif(GetTechSupported(entity, kTechId.Melee3Tech, true)) then
            
                damageScalar = kMelee3DamageScalar
                
            elseif(GetTechSupported(entity, kTechId.Melee2Tech, true)) then
            
                damageScalar = kMelee2DamageScalar
                
            elseif(GetTechSupported(entity, kTechId.Melee1Tech, true)) then
            
                damageScalar = kMelee1DamageScalar
                
            end
            
        end
        
        // Add more if under influence of whip. This looks like it should be revisited.
        if entity:isa("LiveScriptActor") then
        
            local numFuries = entity:GetStackableGameEffectCount(kFuryGameEffect)
            if numFuries > 0 then
                damageScalar = damageScalar * (1 + numFuries * Whip.kFuryDamageBoost)
            end
            
        end
        
    end
        
    return damage * damageScalar
    
end

function NS2Gamerules:GetAllPlayers()

    if not self.playerList then
        self:UpdatePlayerList()
    end
    
    return self.playerList
end

function NS2Gamerules:GetAllScriptActors()

    if not self.scriptActorList then
        self:UpdateScriptActorList()
    end
    
    return self.scriptActorList    
    
end

// Call with class name, optional teamNumber (-1 or nil for all), and optional class name and origin/range to get entities in radius
// TODO: Implement optionalXZOnly
function NS2Gamerules:GetEntities(className, teamNumber, optionalOrigin, optionalRange, optionalXZOnly)

    if not self.scriptActorList then
        self:UpdateScriptActorList()
    end
    
    local entities = {}
    
    for index, scriptActor in ipairs(self.scriptActorList) do
    
        if scriptActor:isa(className) then
        
            if (teamNumber == -1) or (teamNumber == nil) or (scriptActor:GetTeamNumber() == teamNumber) then
        
                if not optionalOrigin or ((scriptActor:GetOrigin() - optionalOrigin):GetLength() < optionalRange) then
                
                    table.insert(entities, scriptActor)
                    
                end
                
            end
            
        end
        
    end
    
    return entities
    
end

function NS2Gamerules:GetPlayers(teamNumber)

    if not self.playerList then
        self:UpdatePlayerList()
    end

    local players = {}
    
    for index, player in ipairs(self.playerList) do
    
        if player:GetTeamNumber() == teamNumber then
        
            table.insert(players, player)
            
        end
        
    end
    
    return players
    
end
 
/**
 * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
 * respawn playing players.
 */
function NS2Gamerules:ResetGame()

    // Reset all players and entities, delete other entities that were created during 
    // the game (hives, command structures, initial resource towers, etc)

    local entityList = GetEntitiesIsa("Entity", -1)
    for index, entity in pairs(entityList) do

        // Don't reset/delete gamerules!    
        if(entity ~= self) then
        
            local isMapEntity = entity:GetIsMapEntity()
            local mapName = entity:GetMapName()
            
            if ( (entity:GetIsMapEntity() and entity:isa("ScriptActor")) or entity:isa("Player") ) then
                entity:Reset()
            else
                DestroyEntity(entity)
            end

        end       
 
    end
    
    
    // Build list of team locations
    local teamLocations = GetEntitiesIsa("TeamLocation", -1)
    local numTeamLocations = table.maxn(teamLocations)
    if(numTeamLocations < 2) then
        Print("Warning -- Found only %d %s entities.", numTeamLocations, TeamLocation.kMapName)
    end
    
    local resourcePoints = GetEntitiesIsa("ResourcePoint", 0)
    local numResourcePoints = table.maxn(resourcePoints)
    if(numResourcePoints < 2) then
        Print("Warning -- Found only %d %s entities.", numResourcePoints, ResourcePoint.kPointMapName)
    end
    
    // Reset teams (keep players on them)    
    self.team1:ResetPreservePlayers(self:ChooseTeamLocation(teamLocations, kTeam1Index))
    self.team2:ResetPreservePlayers(self:ChooseTeamLocation(teamLocations, kTeam2Index))
    self.worldTeam:ResetPreservePlayers(nil)
    self.spectatorTeam:ResetPreservePlayers(nil)
            
    // Replace players with their starting classes with default loadouts at spawn locations
    self.team1:ReplaceRespawnAllPlayers()
    self.team2:ReplaceRespawnAllPlayers()
    
    self.gameStarted = false
    self.countingDown = false
    self.countdownTime = 0
    self.timeGameEnded = nil
    self.forceGameStart = false
    self.losingTeam = nil
    self.timeToReadyRoom = nil
    self.preventGameEnd = nil
    
    // Send scoreboard update, ignoring other scoreboard updates (clearscores resets everything)
    local allPlayers = GetEntitiesIsa("Player")    
    for index, player in ipairs(allPlayers) do
        Server.SendCommand(player, "onresetgame")
        //player:SetScoreboardChanged(false)
    end
    
end

function NS2Gamerules:GetTeam1()
    return self.team1
end

function NS2Gamerules:GetTeam2()
    return self.team2
end

function NS2Gamerules:GetWorldTeam()
    return self.worldTeam
end

function NS2Gamerules:GetSpectatorTeam()
    return self.spectatorTeam
end

function NS2Gamerules:UpdateCountdown(timePassed)

    if(self.countingDown) then
    
        self.countdownTime = self.countdownTime - timePassed

        local countDownSeconds = math.ceil(self.countdownTime)
        if(self.lastCountdownPlayed ~= countDownSeconds) then        
        
            self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
            self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
            
            self.lastCountdownPlayed = countDownSeconds
            
        end
        
        if(self.countdownTime <= 0) then
        
            self.countingDown = false    
            self.countdownTime = 0
        
            if(not Shared.GetDevMode()) then
           
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                
            end
            
            self.gameStarted = true   
            self.timeGameStarted = Shared.GetTime() 
            
        end
        
    end
    
end

function NS2Gamerules:UpdateScores()

    if(self.timeToSendScores == nil or Shared.GetTime() > self.timeToSendScores) then
    
        local allPlayers = self:GetAllPlayers()

        // If any player scoreboard info has changed, send those updates to everyone
        for index, fromPlayer in ipairs(allPlayers) do
        
            // Send full update if any part of it changed
            if(fromPlayer:GetScoreboardChanged()) then
            
                if(fromPlayer:GetName() ~= "") then
                
                    // Now send scoreboard info to everyone, including fromPlayer                    
                    local scoresMessage = BuildScoresMessage(fromPlayer)
                    Server.SendNetworkMessage("Scores", scoresMessage, true)
                    
                    fromPlayer:SetScoreboardChanged(false)
                    
                else
                    Print("Player name empty, can't send scoreboard update.")
                end
                
            end
            
        end
        
        // When players connect to server, they send up a request for scores (as they 
        // may not have finished connecting when the scores where previously sent)    
        for index, requestingPlayer in ipairs(allPlayers) do

            // Check for empty name string because player isn't connected yet
            if(requestingPlayer:GetRequestsScores() and requestingPlayer:GetName() ~= "") then
            
                // Send player all scores
                for index, fromPlayer in ipairs(allPlayers) do
                
                    local scoresMessage = BuildScoresMessage(fromPlayer)
                    Server.SendNetworkMessage(requestingPlayer, "Scores", scoresMessage, true)
                    
                end
                
                requestingPlayer:SetRequestsScores(false)
                
            end
            
        end
            
        // Time to send next score
        self.timeToSendScores = Shared.GetTime() + kScoreboardUpdateInterval
        
    end

end

// Batch together string with pings of every player to update scoreboard. This is a separate
// command to keep network utilization down.
function NS2Gamerules:UpdatePings()

    if(self.timeToSendPings == nil or Shared.GetTime() > self.timeToSendPings) then
    
        for index, player in ipairs(self:GetAllPlayers()) do
        
            Server.SendNetworkMessage( "Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), true )

        end
        
        self.timeToSendPings = Shared.GetTime() + kUpdatePingsInterval
        
    end            

end

function NS2Gamerules:UpdateMinimapBlips()

    if(self.timeToSendMinimapBlips == nil or Shared.GetTime() > self.timeToSendMinimapBlips) then
    
        self.team1:SendBlipList()
        self.team2:SendBlipList()
        
        self.timeToSendMinimapBlips = Shared.GetTime() + kMinimapBlipLifetime
        
    end     
    

end

function NS2Gamerules:OnMapPostLoad()

    Gamerules.OnMapPostLoad(self)
    
    Server.locationList = GetEntitiesIsa("Location")
    
    // Now allow script actors to hook post load
    for index, scriptActor in ipairs(self:GetAllScriptActors()) do
        scriptActor:OnMapPostLoad()
    end
    
end

// Update list of players so players can be retrieved efficiently
function NS2Gamerules:UpdatePlayerList()

    self.playerList = {}
    
    table.adduniquetable(self.worldTeam:GetPlayers(), self.playerList)
    table.adduniquetable(self.team1:GetPlayers(), self.playerList)
    table.adduniquetable(self.team2:GetPlayers(), self.playerList)
    table.adduniquetable(self.spectatorTeam:GetPlayers(), self.playerList)    

end

function NS2Gamerules:UpdateScriptActorList()
    self.scriptActorList = GetEntitiesIsa("ScriptActor", nil, true)
end

function NS2Gamerules:UpdateToReadyRoom(timePassed)

    if(self.timeToReadyRoom ~= nil and self.timeToReadyRoom > 0) then
    
        self.timeToReadyRoom = self.timeToReadyRoom - timePassed
        if(self.timeToReadyRoom <= 0) then
        
            // Set all players to ready room team
            local function SetReadyRoomTeam(player)
                self:JoinTeam(player, kTeamReadyRoom)
            end
            Server.ForAllPlayers(SetReadyRoomTeam)

            // Spawn them there and reset teams
            self:ResetGame()

        end
        
    end
    
end

function NS2Gamerules:OnUpdate(timePassed)

    if self.justCreated then
    
        if not self.gameStarted then
            self:ResetGame()
        end
        
        self.justCreated = false

    end
    
    if self:GetMapLoaded() then
    
        self:CheckGameStart()
        self:CheckGameEnd()

        self:UpdateCountdown(timePassed)
        self:UpdateToReadyRoom(timePassed)
        
        self.worldTeam:Update(timePassed)
        self.team1:Update(timePassed)
        self.team2:Update(timePassed)
        self.spectatorTeam:Update(timePassed)
        
        // Send scores every so often
        self:UpdateScores()
        self:UpdatePings()
        self:UpdateMinimapBlips()
        self:UpdatePlayerList()
        self:UpdateScriptActorList()
        
    end
    
end

function NS2Gamerules:GetGameEnded()
    return self.timeGameEnded ~= nil
end

/**
 * Ends the current game
 */
function NS2Gamerules:EndGame(winningTeam)

    if(self.timeGameEnded == nil) then
    
        self.timeGameEnded = Shared.GetTime()

        // Set losing team        
        local losingTeam = nil
        if(winningTeam == self.team1) then
            losingTeam = self.team2
        else
            losingTeam = self.team1
        end
        
        self.losingTeam = losingTeam

        // Play win/loss sounds
        winningTeam:PlayPrivateTeamSound(NS2Gamerules.kVictorySound)
        losingTeam:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)

        // Display win/loss message
        local winMsg = "Your team won the game!"
        winningTeam:AddTooltip(winMsg)

        local loseMsg = "Your team lost the game."
        losingTeam:AddTooltip(loseMsg)
        
        self.team1:ClearRespawnQueue()
        self.team2:ClearRespawnQueue()  
        
        // Set timer to put everyone back in ready room after music plays
        self.timeToReadyRoom = 8

    end

end

function NS2Gamerules:DrawGame()

    if(self.timeGameEnded == nil) then
    
        self.timeGameEnded = Shared.GetTime()

        // Play loss sounds for both teams
        self.team1:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)
        self.team2:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)
        
        // Display "draw" message
        local drawMessage = "The game was a draw!"
        self.team1:BroadcastMessage(drawMessage)
        self.team2:BroadcastMessage(drawMessage)
        
        self.team1:AddTooltip(drawMessage)
        self.team2:AddTooltip(drawMessage)

        self.team1:ClearRespawnQueue()
        self.team2:ClearRespawnQueue()  

        // Set timer to put everyone back in ready room after music plays
        self.timeToReadyRoom = 8

    end

end

function NS2Gamerules:GetTeam(teamNum)

    local team = nil    
    if(teamNum == kTeamReadyRoom) then
        team = self.worldTeam
    elseif(teamNum == kTeam1Index) then
        team = self.team1
    elseif(teamNum == kTeam2Index) then
        team = self.team2
    elseif(teamNum == kSpectatorIndex) then
        team = self.spectatorTeam
    end
    return team
    
end

function NS2Gamerules:GetRandomTeamNumber()

    // Return lesser of two teams, or random one if they are the same
    local team1Players = self.team1:GetNumPlayers()
    local team2Players = self.team2:GetNumPlayers()
    
    if team1Players < team2Players then
        return self.team1:GetTeamNumber()
    elseif team2Players < team1Players then
        return self.team2:GetTeamNumber()
    end
    
    return ConditionalValue(math.random() < .5, kTeam1Index, kTeam2Index)
    
end

// Enforce balanced teams
function NS2Gamerules:GetCanJoinTeamNumber(teamNumber)

    local team1Players = self.team1:GetNumPlayers()
    local team2Players = self.team2:GetNumPlayers()
    
    if (team1Players > team2Players) and (teamNumber == self.team1:GetTeamNumber()) then
        return false
    elseif (team2Players > team1Players) and (teamNumber == self.team2:GetTeamNumber()) then
        return false
    end
    
    return true

end

/**
 * Changes the team of the specified player. Returns two return codes: success and the new player.
 * If player is already on that team, false and the original player are returned. Pass force 
 * to make player change team no matter what and to respawn immediately.
 */
function NS2Gamerules:JoinTeam(player, newTeamNumber, force)

    local success = false
    local newPlayer = player
    local currentTeamNumber = player:GetTeamNumber()
    
    // Join new team
    if(player:GetTeamNumber() ~= newTeamNumber or force) then
    
        player:SetTeamNumber(newTeamNumber)
        
        local team = self:GetTeam(newTeamNumber)

        // Spawn immediately if going to ready room, game hasn't started or cheats on        
        if (newTeamNumber == kTeamReadyRoom) or not self:GetGameStarted() or Shared.GetCheatsEnabled() or force then
        
            success, newPlayer = team:ReplaceRespawnPlayer(player, nil, nil)
        
        else
        
            // Destroy the existing player and create a spectator in their place.
            local mapName = ConditionalValue(team:isa("AlienTeam"), AlienSpectator.kMapName, Spectator.kMapName)
            newPlayer = player:Replace(mapName)
            
            // Queue up the spectator for respawn.
            team:PutPlayerInRespawnQueue(newPlayer, Shared.GetTime())
            
            success = true
            
        end
                       
    end
    
    return success, newPlayer

end

function NS2Gamerules:GetGameStarted()
    return self.gameStarted
end

/* For test framework only. Prevents game from ending on its own also. */
function NS2Gamerules:SetGameStarted()
    self.gameStarted = true
    self.preventGameEnd = true
end

function NS2Gamerules:SetPreventGameEnd(state)
    self.preventGameEnd = state
end

function NS2Gamerules:GetCountingDown()
    return self.countingDown
end

function NS2Gamerules:StartGameCountdown()

    if(not Shared.GetDevMode()) then
        self:ResetGame()
    else
        // TODO: Remove this once Decoda performance is higher for deleting entities while debugging
        Print("NS2Gamerules:StartGameCountdown(): Skipping game reset in dev mode.")
    end
    
    self.countingDown = true
    self.countdownTime = 4
    self.lastCountdownPlayed = nil
    
    if(Shared.GetDevMode() or Shared.GetCheatsEnabled()) then
        self.countdownTime = 0
    end    
   
end

function NS2Gamerules:CheckGameStart()

    if(not self.gameStarted and not self.countingDown) then
    
        // Start when both teams have players or when once side does if cheats are enabled
        local team1Players = self.team1:GetNumPlayers()
        local team2Players = self.team2:GetNumPlayers()
        
        if  (team1Players > 0 and team2Players > 0) or (Shared.GetCheatsEnabled() and (team1Players > 0 or team2Players > 0)) then
            
            self:StartGameCountdown()
            
        end
        
    end
    
end

function NS2Gamerules:CheckGameEnd()
    
    if(self.gameStarted and self.timeGameEnded == nil and not Shared.GetCheatsEnabled() and not self.preventGameEnd) then
    
        if self.timeLastGameEndCheck == nil or (Shared.GetTime() > self.timeLastGameEndCheck + NS2Gamerules.kGameEndCheckInterval) then
        
            local team1Lost = self.team1:GetHasTeamLost()
            local team2Lost = self.team2:GetHasTeamLost()
            local team1Won = self.team1:GetHasTeamWon()
            local team2Won = self.team2:GetHasTeamWon()
            
            if((team1Lost and team2Lost) or (team1Won and team2Won)) then
                self:DrawGame()
            elseif(team1Lost or team2Won) then
                self:EndGame(self.team2)
            elseif(team2Lost or team1Won) then
                self:EndGame(self.team1)
            end
            
            self.timeLastGameEndCheck = Shared.GetTime()
            
        end
                
    end
    
end

// Returns true if entity should be propagated to player
// NOTE: this is only called for ScriptActors, so if your object extents
// off Entity it needs to call this
function NS2Gamerules:GetIsRelevant(player, entity, noRecurse)

    local relevant = false
    
    // Hive sight blips only go to aliens and also have a bigger range
    local dist = player:GetDistance(entity)
    
    if player:isa("Alien") and entity:isa("Blip") then
    
        if (entity.entId ~= player:GetId()) then
            relevant = (dist < kHiveSightMaxRange)
        end
        
    // Remove LOS check for perf while debugging
    elseif(player:GetIsCommander() and not entity:isa("Blip")) then
    
        // Don't return dynamic props with commAlpha < 1
        if entity:isa("PropDynamic") and entity.commAlpha ~= nil and entity.commAlpha < 1 then
        
            relevant = false
            
        // Send our hotgroups and also the command station we're in
        elseif(player:GetIsEntitySelected(entity) or player:GetIsEntityHotgrouped(entity) or player:GetIsEntityIdleWorker(entity) or (player:GetHostCommandStructure():GetId() == entity:GetId())) then
        
            relevant = true
            
        elseif( GetEnemyTeamNumber(entity:GetTeamNumber()) == player:GetTeamNumber()) then
        
            // Enemy seen only if friendly entity has LOS to it
            relevant = entity.sighted or GetIsDebugging()
            
        else
        
            // Friendly entities
            if (dist < kMaxRelevancyDistance) /*or GetCanSeeEntity(player, entity)*/ then

                relevant = true
                
            end
        
        end        
        
    else
    
        // Check the distance to determine if the entity is relevant.
        if(dist < kMaxRelevancyDistance /*or GetCanSeeEntity(player, entity)*/) then

            relevant = true
            
        // Special case active weapons so they are always propagated with their parent, but don't
        // recurse infinitely!
        elseif not noRecurse then

            if entity:isa("Weapon") then
            
                local parent = entity:GetParent()
                if parent:GetActiveWeapon() == entity then
                
                    relevant = self:GetIsRelevant(player, parent, true)
                    
                end

            elseif entity:isa("Player") then
            
                local children = GetChildEntities(entity, "ScriptActor")
                for index, child in ipairs(children) do
                
                    if self:GetIsRelevant(player, child, true) then
                    
                        relevant = true
                        break
                        
                    end
                    
                end
                
            end
            
        end
    
    end
    
    return relevant

end

function NS2Gamerules:GetLosingTeam()
    return self.losingTeam
end

function NS2Gamerules:GetAllTech()
    return self.allTech
end

function NS2Gamerules:SetAllTech(state)

    if state ~= self.allTech then
    
        self.allTech = state
        
        self.team1:GetTechTree():SetTechChanged()
        self.team2:GetTechTree():SetTechChanged()
        
    end
    
end

function NS2Gamerules:SetOrderSelf(state)
    self.orderSelf = state
end

function NS2Gamerules:GetOrderSelf()
    return self.orderSelf
end

// Function for allowing teams to hear each other's voice chat
function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer)

    local success = false
    
    // If both players have the same team number, they can hear each other
    if(listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()) then
        success = true
    end
        
    // Or if cheats or dev mode is on, they can hear each other
    if(Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        success = true
    end
    
    // Or if game hasn't started
    if(not self:GetGameStarted()) then
        success = true
    end
    
    return success
    
end

function NS2Gamerules:RespawnPlayer(player)

    local team = player:GetTeam()
    team:AddPlayer(player)
    team:RespawnPlayer(player, nil, nil)
    
end

////////////////    
// End Server //
////////////////
end

////////////
// Shared //
////////////
function NS2Gamerules:SetupConsoleCommands()

    Gamerules.SetupConsoleCommands(self)
    
    if(Client) then
        Script.Load("lua/NS2ConsoleCommands_Client.lua")
    else
        Script.Load("lua/NS2ConsoleCommands_Server.lua")
    end
    
end

Shared.LinkClassToMap("NS2Gamerules", NS2Gamerules.kMapName, {})
