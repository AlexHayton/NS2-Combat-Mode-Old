// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Gamerules.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")

class "ScenarioHandler"

ScenarioHandler.kStartTag = "--- SCENARIO START ---"
ScenarioHandler.kEndTag = "--- SCENARIO END ---"

function ScenarioHandler:Init()
    
    // aliens
    self.handlers = self:InitHandlers({}, kAlienTeamType, {
        Infestation = InfestationHandler(),
        Hydra = OrientedEntityHandler(),
        Whip = OrientedEntityHandler(),
        Crag = OrientedEntityHandler(),
        Hive = OrientedEntityHandler(),
        //HiveMass = OrientedEntityHandler(),
        //HiveColony = OrientedEntityHandler(),
        Harvester = OrientedEntityHandler()
    })
    // marines   
    self.handlers = self:InitHandlers(self.handlers, kMarineTeamType, {
        CommandStation = OrientedEntityHandler(),
        CommandFacility = OrientedEntityHandler(),
        CommandCenter = OrientedEntityHandler(),
        Sentry = OrientedEntityHandler(),
        Armory = OrientedEntityHandler(),
        AdvancedArmory = OrientedEntityHandler(),
        Observatory = OrientedEntityHandler(),
        RoboticsFactory = OrientedEntityHandler(),
        InfantryPortal = OrientedEntityHandler(),
        Extractor = OrientedEntityHandler()
    })

    return self
end

function ScenarioHandler:InitHandlers(result, teamType, dataTable)
    for name, value in pairs(dataTable) do
        value:Init(name, teamType)
        result[name] = value
    end
    return result
end


//
// checkpoint the state of the game. Only entites created AFTER the checkpoint will be saved. 
//
function ScenarioHandler:Checkpoint()
    self.excludeTable = {}
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("LiveScriptActor")) do
        self.excludeTable["" .. entity:GetId()] = true
    end
end


//
// Save the current scenario
// This just dumps formatted strings for all structures and non-building-owned infestations that allows
// the Load() method to easily reconstruct them
// The data is written to the server log. The user should just cut out the chunk of the log containing the
// scenario and put in on a webserver
//
function ScenarioHandler:Save()
    if not self.excludeTable then
        Log("NO CHECKPOINT HAS BEEN MADE - ALL ENTITIES WILL BE SAVED, INCLUDING MAP-CREATED ENTITIES!")
        Log("Use scencp to checkpoint the current state of the game")
    end
    Shared.Message(ScenarioHandler.kStartTag)
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("LiveScriptActor")) do
        local cname = entity:GetClassName()
        local excluded = self.excludeTable and self.excludeTable["" .. entity:GetId()]
        local handler = self.handlers[cname]
        local accepted = handler and handler:Accept(entity)
        if not excluded and accepted then
            Shared.Message(cname .. "|" .. handler:Save(entity))
        end
    end
    Shared.Message(ScenarioHandler.kEndTag)    
end

function ScenarioHandler:Load(data)
    Shared.Message("LOAD: ")
    local startTagFound, endTagFound = false, false
    local lines = data:gmatch("[^\n]+")
    for line in lines do
        if line == ScenarioHandler.kStartTag then
            startTagFound = true
        elseif line == ScenarioHandler.kEndTag then
            endTagFound = true
            break
        else 
            local args = line:gmatch("[^|]+")
            local cname = args()
            if self.handlers[cname] then
                Log("Created %s", self.handlers[cname]:Load(args, cname))
            end
        end
    end
    Shared.Message("END LOAD")
end

class "ScenarioEntityHandler"

function ScenarioEntityHandler:Init(name, teamType)
    self.teamType = teamType
    self.name = name
    self.techId = kTechId[self.name]
    if not self.techId then
        Log("Unable to determine techId for %s", self.name)
    end
    return self
end

// return true if this entity should be accepted for saving
function ScenarioEntityHandler:Accept(entity)
    return true
end

function ScenarioEntityHandler:WriteVector(vec)
    return string.format("%f,%f,%f", vec.x, vec.y, vec.z)
end

function ScenarioEntityHandler:ReadVector(text)
    local p = text:gmatch("[^, ]+")
    local x,y,z = tonumber(p()),tonumber(p()),tonumber(p())
    return Vector(x,y,z)
end

function ScenarioEntityHandler:WriteAngles(angles)
    return string.format("%f,%f,%f", angles.pitch, angles.yaw, angles.roll)
end

function ScenarioEntityHandler:ReadAngles(text)
    local p = text:gmatch("[^, ]+")
    local pitch,yaw,roll = tonumber(p()),tonumber(p()),tonumber(p())
    return Angles(pitch,yaw,roll)
end

//
// Oriented entity handlers have an origin and an angles
//
class "OrientedEntityHandler" (ScenarioEntityHandler)

function OrientedEntityHandler:Save(entity)
    // re-offset the extra spawn height added to it... otherwise our hives will stick up in the roof, and all other things will float
    // 5cm off the ground..
    local spawnOffset = LookupTechData(self.techId, kTechDataSpawnHeightOffset, .05)
    local origin = entity:GetOrigin() - Vector(0, spawnOffset, 0)
    return self:WriteVector(origin) .. "|" .. self:WriteAngles(entity:GetAngles())
end

function OrientedEntityHandler:Load(args, classname)
    local origin = self:ReadVector(args())
    local angles = self:ReadAngles(args())

    // Log("For %s(%s), team %s at %s, %s", classname, self.techId, self.teamType, origin, angles)
    local result = self:Create(origin)
    result:SetAngles(angles)
    if self.teamType == kMarineTeamType then
        result:SetConstructionComplete()
    end
    return result
end

function OrientedEntityHandler:Create(origin)
    return CreateEntityForTeam( self.techId, origin, self.teamType, nil )
end 

//
// Special case infestations.
// - we don't want derived infestations (we detect that by checking for size)
// - when loading them, set them to max size right away to avoid having other structs dying
// - The kMapName is missing from the tech table for some reason... so we need a custom
//    Create() as well
//
class "InfestationHandler" (OrientedEntityHandler)

function InfestationHandler:Load(args, classname)
    local infestation = OrientedEntityHandler.Load(self, args, classname)
    infestation.radius = infestation.maxRadius
    return infestation
end

function InfestationHandler:Create(origin)
    return CreateEntity( Infestation.kMapName, origin, self.teamType )
end

function InfestationHandler:Accept(entity)
    // only accept "real" infestations, not those belong to other entities
    return entity.maxRadius == kInfestationRadius
end

// create the singleton instance
ScenarioHandler.instance = ScenarioHandler():Init()