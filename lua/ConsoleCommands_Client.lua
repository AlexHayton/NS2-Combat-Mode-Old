// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandTooltip(tooltipText)
    local player = Client.GetLocalPlayer()
    if (player ~= nil) then
        player:AddTooltip(tooltipText)
    end
end

function OnCommandRoundReset()
end

function OnCommandDeathMsg(killerIsPlayer, killerId, killerTeamNumber, iconIndex, targetIsPlayer, targetId, targetTeamNumber)
    AddDeathMessage(tonumber(killerIsPlayer), tonumber(killerId), tonumber(killerTeamNumber), tonumber(iconIndex), tonumber(targetIsPlayer), tonumber(targetId), tonumber(targetTeamNumber))
end

function OnCommandOnResetGame()

    Scoreboard_OnResetGame()
    CommanderUI_SetTeamHarvesterCount(0)

    ResetLights()
    
end

function OnCommandOnClientDisconnect(clientIndexString)
    Scoreboard_OnClientDisconnect(tonumber(clientIndexString))
end

function OnCommandScores(scoreTable)
    Scoreboard_SetPlayerData(scoreTable.clientId, scoreTable.playerName, scoreTable.teamNumber, scoreTable.score, scoreTable.kills, scoreTable.deaths, scoreTable.plasma, scoreTable.isCommander, scoreTable.experience)
end

// Notify scoreboard and anything else when a player changes into a new player
function OnCommandEntityChanged(entityChangedTable)

    local newId = ConditionalValue(entityChangedTable.newEntityId == -1, nil, entityChangedTable.newEntityId)
    
    for index, entity in ipairs(GetEntitiesIsa("ScriptActor")) do
    
        // Allow player to update selection, etc. with entity replacement
        entity:OnEntityChange(entityChangedTable.oldEntityId, newId)
        
    end
       
end

// Called when player receives points from an action
function OnCommandPoints(pointsString)
    local points = tonumber(pointsString)
    ScoreDisplayUI_SetNewScore(points)
end

function OnCommandTeamHarvesterCount(numResourceTowersString)
    CommanderUI_SetTeamHarvesterCount(tonumber(numResourceTowersString))
end

function OnCommandSoundGeometry(enabled)

    enabled = enabled ~= "false"
    Shared.Message("Sound geometry occlusion enabled: " .. tostring(enabled))
    Client.SetSoundGeometryEnabled(enabled)
    
end

function OnCommandReloadSoundGeometry(soundOcclusionFactor, reverbOcclusionFactor)

    if soundOcclusionFactor == nil or reverbOcclusionFactor == nil then
        Shared.Message("A sound occlusion factor and reverb occlusion factor (between 0-1) must be passed in.")
        return
    end
    Client.LoadSoundGeometry(tonumber(soundOcclusionFactor), tonumber(reverbOcclusionFactor))

end

function OnCommandPing(pingTable)
    local clientIndex, ping = ParsePingMessage(pingTable)    
    Scoreboard_SetPing(clientIndex, ping)   
end

function OnCommandClearTechTree()
    ClearTechTree()
end

function OnCommandTechNodeBase(techNodeBaseTable)
    GetTechTree():CreateTechNodeFromNetwork(techNodeBaseTable)
end

function OnCommandTechNodeUpdate(techNodeUpdateTable)
    GetTechTree():UpdateTechNodeFromNetwork(techNodeUpdateTable)
end

function OnCommandResetMouse()
    Client.SetYaw(0)
    Client.SetPitch(0)
end

function OnCommandAnimDebug(className)

    // Messages printed by server
    if Shared.GetDevMode() then
    
        if className then
            gActorAnimDebugClass = className
        elseif gActorAnimDebugClass ~= "" then
            gActorAnimDebugClass = ""
        end
    end
    
end

Event.Hook("Console_tooltip",                   OnCommandTooltip)
Event.Hook("Console_reset",                     OnCommandRoundReset)
Event.Hook("Console_deathmsg",                  OnCommandDeathMsg)
Event.Hook("Console_onresetgame",               OnCommandOnResetGame)
Event.Hook("Console_clientdisconnect",          OnCommandOnClientDisconnect)
Event.Hook("Console_points",                    OnCommandPoints)
Event.Hook("Console_harvestercount",            OnCommandTeamHarvesterCount)
Event.Hook("Console_soundgeometry",             OnCommandSoundGeometry)
Event.Hook("Console_reloadsoundgeometry",       OnCommandReloadSoundGeometry)
Event.Hook("Console_onanimdebug",               OnCommandAnimDebug)

Client.HookNetworkMessage("Ping",               OnCommandPing)
Client.HookNetworkMessage("Scores",             OnCommandScores)
Client.HookNetworkMessage("EntityChanged",      OnCommandEntityChanged)

Client.HookNetworkMessage("ClearTechTree",      OnCommandClearTechTree)
Client.HookNetworkMessage("TechNodeBase",       OnCommandTechNodeBase)
Client.HookNetworkMessage("TechNodeUpdate",     OnCommandTechNodeUpdate)

Client.HookNetworkMessage("ResetMouse",         OnCommandResetMouse)

