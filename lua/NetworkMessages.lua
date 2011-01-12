// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NetworkMessages.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// See the Messages section of the Networking docs in Spark Engine scripting docs for details.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/TechTreeConstants.lua")

// From TechNode.kTechNodeVars
local kTechNodeUpdateMessage = 
{
    techId              = "enum kTechId",
    available           = "boolean",
    researchProgress    = "float",
    researched          = "boolean",
    researching         = "boolean",
    hasTech             = "boolean"
}

// Tech node messages. Base message is in TechNode.lua
function BuildTechNodeUpdateMessage(techNode)

    local t = {}
    
    t.techId            = techNode.techId
    t.available         = techNode.available
    t.researchProgress  = techNode.researchProgress
    t.researched        = techNode.researched
    t.researching       = techNode.researching
    t.hasTech           = techNode.hasTech
    
    return t
    
end

Shared.RegisterNetworkMessage( "TechNodeUpdate", kTechNodeUpdateMessage )

local kMaxPing = 999

local kPingMessage = 
{
    clientIndex = "integer",
    ping = "integer (0 to " .. kMaxPing .. ")"
}

function BuildPingMessage(clientIndex, ping)

    local t = {}
    
    t.clientIndex       = clientIndex
    t.ping              = math.min(ping, kMaxPing)
    
    return t
    
end

function ParsePingMessage(message)
    return message.clientIndex, message.ping
end

Shared.RegisterNetworkMessage( "Ping", kPingMessage )

// Scores 
local kScoresMessage = 
{
    clientId = "integer",
    playerName = string.format("string (%d)", kMaxNameLength),
    teamNumber = string.format("integer (0 to %d)", kRandomTeamType),
    score = string.format("integer (0 to %d)", kMaxScore),
    kills = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    plasma = string.format("integer (0 to %d)", kMaxResources),
    isCommander = "boolean"
}

function BuildScoresMessage(player)

    local t = {}

    t.clientId = player:GetClientIndex()
    t.playerName = string.sub(player:GetName(), 0, kMaxNameLength)
    t.teamNumber = player:GetTeamNumber()
    t.score = player:GetScore()
    t.kills = player:GetKills()
    t.deaths = player:GetDeaths()
    t.plasma = player:GetPlasma()
    t.isCommander = player:isa("Commander")
    
    return t
    
end

Shared.RegisterNetworkMessage("Scores", kScoresMessage)

// For idle workers
local kSelectAndGotoMessage = 
{
    entityId = "entityid"
}

function BuildSelectAndGotoMessage(entId)
    local t = {}
    t.entityId = entId
    return t   
end

function ParseSelectAndGotoMessage(message)
    return message.entityId
end

Shared.RegisterNetworkMessage("SelectAndGoto", kSelectAndGotoMessage)

// For taking damage
local kDamageIndicator =
{
    worldX = "float",
    worldZ = "float",
    damage = "float"
}

function BuildDamageIndicatorMessage(sourceVec, damage)
    local t = {}
    t.worldX = sourceVec.x
    t.worldZ = sourceVec.z
    t.damage = damage
    return t
end

function ParseDamageIndicatorMessage(message)
    return message.worldX, message.worldZ, message.damage
end

Shared.RegisterNetworkMessage("DamageIndicator", kDamageIndicator)

// Player id changed 
local kEntityChangedMessage = 
{
    oldEntityId = "entityid",
    newEntityId = "entityid",
}

function BuildEntityChangedMessage(oldId, newId)

    local t = {}
    
    t.oldEntityId = oldId
    t.newEntityId = newId
    
    return t
    
end

// entityId, worldPosition (Vector), kMinimapBlipType, kMinimapBlipTeam
local kBlipMessage =
{
    entityId = "entityid",                  // 2 bytes
    minimapX = "integer (0 to 511)",        // 9 bits
    minimapY = "integer (0 to 511)",        // 9 bits
    blipType = "enum kMinimapBlipType",     // 2 bits
    blipTeam = "enum kMinimapBlipTeam",     // 2 bits
}

function BuildMinimapBlipMessage(entId, mapX, mapY, type, team)

    local t = {}
    
    t.entityId = entId
    t.minimapX = mapX * 511
    t.minimapY = mapY * 511
    t.blipType = type
    t.blipTeam = team
    
    return t

end

function ParseMinimapBlipMessage(blipMessage)
    return blipMessage.entityId, blipMessage.minimapX/511, blipMessage.minimapY/511, blipMessage.blipType, blipMessage.blipTeam
end

// Selection
local kMarqueeSelectMessage =
{
    pickStartVec = "vector",
    pickEndVec = "vector",
}

function BuildMarqueeSelectCommand(pickStartVec, pickEndVec)

    local t = {}
    
    t.pickStartVec = Vector()
    VectorCopy(pickStartVec, t.pickStartVec)

    t.pickEndVec = Vector()
    VectorCopy(pickEndVec, t.pickEndVec)

    return t
    
end

function ParseCommMarqueeSelectMessage(message)
    return message.pickStartVec, message.pickEndVec
end

local kClickSelectMessage =
{
    pickVec = "vector"
}

function BuildClickSelectCommand(pickVec)

    local t = {}
    
    t.pickVec = Vector()
    VectorCopy(pickVec, t.pickVec)
    
    return t
    
end

function ParseCommClickSelectMessage(message)
    return message.pickVec
end

local kControlClickSelectMessage =
{
    pickVec = "vector",
    screenStartVec = "vector",
    screenEndVec = "vector"
}

function BuildControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)

    local t = {}
    
    t.pickVec = Vector()
    VectorCopy(pickVec, t.pickVec)

    t.screenStartVec = Vector()
    VectorCopy(screenStartVec, t.screenStartVec)

    t.screenEndVec = Vector()
    VectorCopy(screenEndVec, t.screenEndVec)
    
    return t
    
end

function ParseControlClickSelectMessage(message)
    return message.pickVec, message.screenStartVec, message.screenEndVec
end

// Commander actions
local kCommAction = 
{
    techId              = "enum kTechId"
}

function BuildCommActionMessage(techId)

    local t = {}
    
    t.techId = techId
    
    return t
    
end

function ParseCommActionMessage(t)
    return t.techId
end

local kCommTargetedAction = 
{
    techId              = "enum kTechId",
    
    // normalized pick coords for CommTargetedAction
    // or world coords for kCommTargetedAction
    x                   = "float",
    y                   = "float",
    z                   = "float",
    
    orientationRadians  = "float"
}

function BuildCommTargetedActionMessage(techId, x, y, z, orientationRadians)

    local t = {}
    
    t.techId = techId
    t.x = x
    t.y = y
    t.z = z
    t.orientationRadians = orientationRadians
    
    return t
    
end

function ParseCommTargetedActionMessage(t)
    return t.techId, Vector(t.x, t.y, t.z), t.orientationRadius
end

local kTracerMessage = 
{
    startPoint  = "vector",
    endPoint    = "vector",
    velocity    = "vector"
}

function BuildTracerMessage(startPoint, endPoint, velocity)

    local t = {}
    
    t.startPoint = Vector(startPoint)
    t.endPoint = Vector(endPoint)
    t.velocity = Vector(velocity)
    
    return t
    
end

function ParseTracerMessage(t)
    return t.startPoint, t.endPoint, t.velocity
end

local kExecuteSayingMessage = 
{
    sayingIndex = "integer (1 to 5)",
    sayingsMenu = "integer (1 to 2)"
}

function BuildExecuteSayingMessage(sayingIndex, sayingsMenu)

    local t = {}
    
    t.sayingIndex = sayingIndex
    t.sayingsMenu = sayingsMenu
    
    return t
    
end

function ParseExecuteSayingMessage(t)
    return t.sayingIndex, t.sayingsMenu
end

Shared.RegisterNetworkMessage("EntityChanged", kEntityChangedMessage)
Shared.RegisterNetworkMessage("ResetMouse", {} )
Shared.RegisterNetworkMessage("MinimapBlipMessage", kBlipMessage)

// Selection
Shared.RegisterNetworkMessage("MarqueeSelect", kMarqueeSelectMessage)
Shared.RegisterNetworkMessage("ClickSelect", kClickSelectMessage)
Shared.RegisterNetworkMessage("ControlClickSelect", kControlClickSelectMessage)

// Commander actions
Shared.RegisterNetworkMessage("CommAction", kCommAction)
Shared.RegisterNetworkMessage("CommTargetedAction", kCommTargetedAction)
Shared.RegisterNetworkMessage("CommTargetedActionWorld", kCommTargetedAction)

// Tracer effect
Shared.RegisterNetworkMessage("Tracer", kTracerMessage)

// Player actions
Shared.RegisterNetworkMessage("ExecuteSaying", kExecuteSayingMessage)