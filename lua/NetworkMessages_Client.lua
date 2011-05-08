// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NetworkMessages_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// See the Messages section of the Networking docs in Spark Engine scripting docs for details.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandPing(pingTable)
    local playerId, ping = ParsePingMessage(pingTable)    
    Scoreboard_SetPing(playerId, ping)   
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

function OnCommandTracer(tracerTable)
    CreateTracer(ParseTracerMessage(tracerTable))
end

function OnCommandDebugLine(debugLineMessage)
    DebugLine(ParseDebugLineMessage(debugLineMessage))
end

Client.HookNetworkMessage("Ping",               OnCommandPing)
Client.HookNetworkMessage("Scores",             OnCommandScores)
Client.HookNetworkMessage("EntityChanged",      OnCommandEntityChanged)

Client.HookNetworkMessage("ClearTechTree",      OnCommandClearTechTree)
Client.HookNetworkMessage("TechNodeBase",       OnCommandTechNodeBase)
Client.HookNetworkMessage("TechNodeUpdate",     OnCommandTechNodeUpdate)

Client.HookNetworkMessage("ResetMouse",         OnCommandResetMouse)
Client.HookNetworkMessage("Tracer",             OnCommandTracer)

Client.HookNetworkMessage("DebugLine",          OnCommandDebugLine)