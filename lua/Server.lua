// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set the name of the VM for debugging
decoda_name = "Server"

Script.Load("lua/Shared.lua")
Script.Load("lua/Button.lua")
Script.Load("lua/TechData.lua")

Script.Load("lua/MarineTeam.lua")
Script.Load("lua/AlienTeam.lua")
Script.Load("lua/TeamJoin.lua")
Script.Load("lua/Bot.lua")

Script.Load("lua/ConsoleCommands_Server.lua")
Script.Load("lua/NetworkMessages_Server.lua")

Server.readyRoomSpawnList = {}
Server.playerSpawnList = {}
Server.locationList = {}

/**
 * Called as the map is being loaded to create the entities.
 */
function OnMapLoadEntity(mapName, groupName, values)

    // Skip the classes that are not true entities and are handled separately
    // on the client.
    
    if ( mapName ~= "prop_static"         
        and mapName ~= "light_point"
        and mapName ~= "light_spot"
        and mapName ~= "light_ambient"
        and mapName ~= "color_grading"
        and mapName ~= "cinematic"
        and mapName ~= "skybox"
        and mapName ~= "navigation_waypoint"
        and mapName ~= ReadyRoomSpawn.kMapName
        and mapName ~= PlayerSpawn.kMapName
        and mapName ~= AmbientSound.kMapName
        and mapName ~= Reverb.kMapName
        and mapName ~= Particles.kMapName) then
        
        local entity = Server.CreateEntity(mapName)
        
        if (entity ~= nil) then
               
            entity:SetMapEntity()
            LoadEntityFromValues(entity, values)
            
        end
        
    end    
    
    if (mapName == "prop_static") then
    
        local coords = values.angles:GetCoords(values.origin)
        
        coords.xAxis = coords.xAxis * values.scale.x
        coords.yAxis = coords.yAxis * values.scale.y
        coords.zAxis = coords.zAxis * values.scale.z
    
        // Create the physical representation of the prop.
        local physicsModel = Shared.CreatePhysicsModel(values.model, false, coords, CoordsArray(), nil) 
        
        // Handle commander mode properties
        local renderModelCommAlpha = GetAndCheckValue(values.commAlpha, 0, 1, "commAlpha", 1, true)
        
        // Make it not block selection and structure placement (GetCommanderPickTarget)
        if renderModelCommAlpha < 1 then
            physicsModel:SetGroup(PhysicsGroup.CommanderPropsGroup)
        end
    
    elseif (mapName == "navigation_waypoint") then
    
        if (groupName == "") then
            groupName = kDefaultWaypointGroup
        end
        
        Server.AddNavigationWaypoint( groupName, values.origin )
        
    elseif (mapName == ReadyRoomSpawn.kMapName) then
    
        local entity = ReadyRoomSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.readyRoomSpawnList, entity)
        
    elseif (mapName == PlayerSpawn.kMapName) then
    
        local entity = PlayerSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.playerSpawnList, entity)
        
    elseif (mapName == AmbientSound.kMapName) then
    
        // Make sure sound index is precached but only create ambient sound object on client
        Shared.PrecacheSound(values.eventName)

    elseif (mapName == Particles.kMapName) then
    
        Shared.PrecacheCinematic(values.cinematicName)        
        
    end

end

function OnMapPreLoad()

    Shared.PreLoadSetGroupNeverVisible(kCollisionGeometryGroupName)
    Shared.PreLoadSetGroupPhysicsId(kNonCollisionGeometryGroupName, 0)  

    // Any geometry in kCommanderInvisibleGroupName shouldn't interfere with selection or other commander actions
    Shared.PreLoadSetGroupPhysicsId(kCommanderInvisibleGroupName, PhysicsGroup.CommanderPropsGroup)   
    
    // Don't have bullets collide with collision geometry
    Shared.PreLoadSetGroupPhysicsId(kCollisionGeometryGroupName, PhysicsGroup.CollisionGeometryGroup)   
    
    // Clear spawn points
    Server.readyRoomSpawnList = {}
    Server.playerSpawnList = {}
    
    Server.locationList = {}
    
end

// Use minimap extents object to create grid of waypoints throughout map
function GenerateWaypoints()
    
    local ents = GetGamerules():GetEntities("MinimapExtents")
    
    if table.count(ents) == 1 then
        
        local minimapExtents = ents[1]
        
        local kWaypointGridSizeXZ = 2
        local kWaypointGridSizeY = 1
        
        local worldOrigin = Vector(minimapExtents:GetOrigin())
        local worldExtents = Vector(minimapExtents:GetExtents())
        
        local origin = Vector()
        local numWaypoints = 0
        
        local y = worldOrigin.y - worldExtents.y
        while y < (worldOrigin.y + worldExtents.y) do
        
            origin.y = y
            local z = worldOrigin.z - worldExtents.z
            while z < (worldOrigin.z + worldExtents.z) do
        
                origin.z = z
                local x = worldOrigin.x - worldExtents.x    
                while x < (worldOrigin.x + worldExtents.x) do
                
                    origin.x = x
                    
                    // TODO: If they're close to the ground, they are ground waypoints
                    local groupName = kAirWaypointsGroup                    
                    
                    Server.AddNavigationWaypoint( groupName, origin )
                    
                    numWaypoints = numWaypoints + 1
                
                    x = x + kWaypointGridSizeXZ    
                    
                end
                
                z = z + kWaypointGridSizeXZ
                
            end        
            
            y = y + kWaypointGridSizeY
            
        end 
       
        // Return dimensions of waypoint grid
        local dimensions = {
                math.floor((worldExtents.x * 2)/kWaypointGridSizeXZ), 
                math.floor((worldExtents.y * 2)/kWaypointGridSizeY), 
                math.floor((worldExtents.z * 2)/kWaypointGridSizeXZ)
                }
                
        Print("Auto-generated %s waypoints (%d, %d, %d)", ToString(numWaypoints), dimensions[1], dimensions[2], dimensions[3])
        
        return dimensions
        
    elseif table.count(ents) > 1 then
        Print("Server:GenerateWaypoints() - Error, multiple minimap extents objects found.")
    else
        Print("Server:GenerateWaypoints() - Couldn't find minimap_extents entity, no waypoints generated.")
    end
    
end

/**
 * Callback handler for when the map is finished loading.
 */
function OnMapPostLoad()

    // Build the data for pathing around the map.
    /*local dimensions = GenerateWaypoints()
    if dimensions then 
        //Print("Server.BuildNavigation(%d, %d, %d)", dimensions[1], dimensions[2], dimensions[3])
        Server.BuildNavigation(dimensions[1], dimensions[2], dimensions[3]) 
    end*/
    
    Server.BuildNavigation() 
    
    GetGamerules():OnMapPostLoad()
    
end

function GetConsoleCommandWebForm()

    local result = "<form action=\"http://[[webdomain]]:[[webport]]/\" method=\"post\">"
                .. "<p>"
                .. "<label for=\"command\">Console Command: </label>"
                .. "<input type=\"text\" name=\"command\"> "
                .. "<input type=\"submit\" value=\"Send\">"
                .. "</p>"
                .. "</form>"
    return result

end

function ProcessConsoleCommand(command)

    Shared.ConsoleCommand(command)
    return "Processing: " .. command
    
end

function OnWebRequest(requestTable)   
    
    local result = ""
    
    for key,value in pairs(requestTable) do 
        if (key == "command") then
            result = result .. ProcessConsoleCommand(value) .. "</br>"
        end
    end

    return result .. GetConsoleCommandWebForm()
    
end

Event.Hook("MapPreLoad",            OnMapPreLoad)
Event.Hook("MapPostLoad",           OnMapPostLoad)
Event.Hook("MapLoadEntity",         OnMapLoadEntity)
Event.Hook("WebRequest",            OnWebRequest)
