// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Base gamerules class that dictates the flow of the game or mode. Extend off gamerules, link
// to an entity and place entity in your map. Other script code can get the current gamerules
// object with GetGamerules().
//
// TODO: Should there be any concept of Teams here?
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

if(Server) then
    Script.Load("lua/Gamerules_Global.lua")
end

Script.Load("lua/Entity.lua")

// Base Gamerules entity
class 'Gamerules' (Entity)

Gamerules.kMapName = "gamerules"

function Gamerules:OnCreate()

    if(Server) then
    
        self:SetIsVisible(false)
        
        self:SetUpdates(true)
        
        self:SetPropagate(Entity.Propagate_Always)
        
        self.darwinMode = false
        
        self.damageMultiplier = 1
        
        // Set global gamerules whenever gamerules are built
    
        SetGamerules(self)
        
        self.mapLoaded = false
        
    end

    // This is about the only thing that happens on the client
    self:SetupConsoleCommands()
        
end

function Gamerules:OnLoad()
end

////////////
// Server //
////////////
if(Server) then

// TODO: Remove?
function Gamerules:GetGameStarted()
    return true
end

// TODO: Remove?
function Gamerules:GetTeam(teamNum)
    return nil
end

function Gamerules:CanEntityDoDamageTo(attacker, target)
    return true
end

// Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
function Gamerules:OnKill(damage, attacker, doer, point, direction)   
end
 
/**
 * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
 * respawn playing players.
 */
function Gamerules:ResetGame()

    local entityList = GetEntitiesIsa("Entity", -1)
    for index, entity in pairs(entityList) do

        // Don't reset/delete gamerules!    
        if(entity ~= self) then
        
            local isMapEntity = entity:GetIsMapEntity()
            local mapName = entity:GetMapName()
            
            if ( (entity:GetIsMapEntity() and entity:isa("ScriptActor")) or entity:isa("Player") ) then
                entity:Reset()
            else
                Server.DestroyEntity(entity)
            end

        end       
 
    end
    
    // Send scoreboard update, ignoring other scoreboard updates (clearscores resets everything)
    local allPlayers = GetEntitiesIsa("Player")    
    for index, player in ipairs(allPlayers) do
        Server.SendCommand(player, "onresetgame")
        //player:SetScoreboardChanged(false)
    end  
end

function Gamerules:OnUpdate(deltaTime)
end

// Returns true if entity should be propagated to player
function Gamerules:GetIsRelevant(playerEntity, entity)
    
    // Check the distance to determine if the entity is relevant.
    local relevanceDistance = 40
    
    local distanceSquared = (playerEntity:GetOrigin() - entity:GetOrigin()):GetLengthSquared()
    if(distanceSquared < relevanceDistance*relevanceDistance /*or GetCanSeeEntity(playerEntity, entity)*/) then

        return true
        
    end
        
    return false

end

// Function for allowing teams to hear each other's voice chat
function Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer)
    return true    
end

function Gamerules:RespawnPlayer(player)

    // Randomly choose unobstructed spawn points to respawn the player
    local success = false
    local spawnPoint = nil
    local spawnPoints = Server.readyRoomSpawnList
    local numSpawnPoints = table.maxn(spawnPoints)

    if(numSpawnPoints > 0) then
    
        local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
        if (spawnPoint ~= nil) then
        
            local origin = spawnPoint:GetOrigin()
            local angles = spawnPoint:GetAngles()
            
            SpawnPlayerAtPoint(player, origin, angles)
            
            player:ClearEffects()
            
            success = true
            
        end
        
    end
    
    if(not success) then
        Print("Gamerules:RespawnPlayer(player) - Couldn't find spawn point for player.")
    end
    
    return success
    
end

function Gamerules:GetPlayerConnectMapName(client)
    return Player.kMapName
end

/**
 * Called when a player first connects to the server. Passes client index.
 */
function Gamerules:OnClientConnect(client)

    local mapName = self:GetPlayerConnectMapName(client)
    local player = CreateEntity(mapName, nil, kTeamReadyRoom)
    
    if(player ~= nil) then
    
        // Tell engine that player is controlling this entity
        client:SetControllingPlayer(player)
        
        player:OnClientConnect(client)
        
        self:RespawnPlayer(player)
        
    else
        Print("Gamerules:OnClientConnect(): Couldn't create player entity of type \"%s\"", mapName)
    end
    
    return player

end

/**
 * Called when player disconnects from server. Passes client index
 * and player entity. Player could be nil if it has been deleted.
 */
function Gamerules:OnClientDisconnect(client)
    
    local player = client:GetControllingPlayer()

    // Tell all other clients that the player has disconnected
    if (player ~= nil) then
        Server.SendCommand(nil, string.format("clientdisconnect %d", player:GetClientIndex()))
    end
   
end

/**
 * Called after map loads.
 */
function Gamerules:OnMapPostLoad()
    self.mapLoaded = true
end

function Gamerules:GetMapLoaded()
    return self.mapLoaded
end

/**
 * Cheats and modes.
 */
function Gamerules:GetDarwinMode()
    return self.darwinMode
end

function Gamerules:SetDarwinMode(darwinMode)
    self.darwinMode = darwinMode
end

function Gamerules:GetDamageMultiplier()
    return self.damageMultiplier
end

function Gamerules:SetDamageMultiplier(multiplier)
    self.damageMultiplier = multiplier   
end

// Send simple trigger message from map entities
function Gamerules:SendTrigger(entity, triggerName)
    self:OnTrigger(entity, triggerName)
end

function Gamerules:OnTrigger(entity, triggerName)
end

////////////////    
// End Server //
////////////////

end

////////////
// Shared //
////////////
function Gamerules:SetupConsoleCommands()
end

Shared.LinkClassToMap("Gamerules", Gamerules.kMapName, {})
