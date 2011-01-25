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

Script.Load("lua/EggSpawn.lua")
Script.Load("lua/MarineTeam.lua")
Script.Load("lua/AlienTeam.lua")
Script.Load("lua/TeamJoin.lua")
Script.Load("lua/Bot.lua")

Script.Load("lua/ConsoleCommands_Server.lua")
Script.Load("lua/NetworkMessages_Server.lua")

Server.readyRoomSpawnList = {}
Server.playerSpawnList = {}
Server.eggSpawnList = {}
Server.locationList = {}

// map name, group name and values keys for all map entities loaded to
// be created on game reset
Server.mapLoadLiveEntityValues = {}

// Game entity indices created from mapLoadLiveEntityValues. They are all deleted
// on and rebuilt on map reset.
Server.mapLiveEntities = {}

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
        if entity then

            entity:SetMapEntity()
            LoadEntityFromValues(entity, values)

            // LiveScriptActors can be destroyed during the game so
            if entity:isa("LiveScriptActor") then

                // Insert into table so we can re-create them all on map post load (and game reset)
                table.insert(Server.mapLoadLiveEntityValues, {mapName, groupName, values})

                // Delete it because we're going to recreate it on map reset
                table.insert(Server.mapLiveEntities, entity:GetId())

            end

        end

    end

    if (mapName == "prop_static") then

        local coords = values.angles:GetCoords(values.origin)

        coords.xAxis = coords.xAxis * values.scale.x
        coords.yAxis = coords.yAxis * values.scale.y
        coords.zAxis = coords.zAxis * values.scale.z

        // Create the physical representation of the prop.
        local physicsModel = Shared.CreatePhysicsModel(values.model, false, coords, CoordsArray(), nil) 
        physicsModel:SetPhysicsType(CollisionObject.Static)
        
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

    elseif (mapName == EggSpawn.kMapName) then

        local entity = EggSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.eggSpawnList, entity)

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
    Server.eggSpawnList = {}

    Server.locationList = {}

    Server.mapLoadLiveEntityValues = {}
    Server.mapLiveEntities = {}

end

function DestroyLiveMapEntities()

    // Delete any map entities that have been created
    for index, mapEntId in ipairs(Server.mapLiveEntities) do

        local ent = Shared.GetEntity(mapEntId)
        if ent then
            DestroyEntity(ent)
        end

    end

end

function CreateLiveMapEntities()

    // Create new LiveScriptActor map entities
    for index, triple in ipairs(Server.mapLoadLiveEntityValues) do

        // {mapName, groupName, keyvalues}
        local entity = Server.CreateEntity(triple[1])
        LoadEntityFromValues(entity, triple[3], true)

        // Store so we can track it during the game and delete it on game reset if not dead yet
        table.insert(Server.mapLiveEntities, entity:GetId())

    end

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


--SERVER WEB API
--Data process functions

	--Server Status functions
function webServerUpTime(returnType)

	local unit = {
	   year		= 29030400,
	   month	= 2419200,
	   week		= 604800,
	   day		= 86400,
	   hour		= 3600,
	   minute	= 60
	}

	local totalSeconds = math.floor(Shared.GetTime()) or 0

	if(returnType == 'json') then
		return totalSeconds
	else
		local days = math.floor(totalSeconds / unit['day']) or 0
		local hours = math.floor(totalSeconds / unit['hour']) or 0
		local mins = math.floor(totalSeconds / unit['minute']) or 0
		local seconds = ((totalSeconds / 60) * 60) - (60 * mins)
		return days .. ' day(s), ' .. hours .. ' hour(s), ' .. mins .. ' minute(s), ' .. seconds .. ' second(s) '
	end
end

	--Get Player stats
function webIsCommander(player, returnType)
	local data = nil
	if (player:GetIsCommander()) then
		if (returnType == 'json') then data = 1 else data = '(Commanding)' end
	else
		if (returnType == 'json') then data = 0 else data = '' end
	end
	return data
end

function webGetTeam(player, returnType)
	local team = { 'Joining Server','Ready Room','Marine','Alien','Spectator' }
	local teamid = tonumber(player:GetTeamNumber()) or -1
	if (returnType == 'json') then
		return teamid
	else
		teamid = teamid + 2
		return team[teamid]
	end
end

function webFindPlayer(steamid)
	local list = nil
	local victim = nil
	for list, victim in ipairs(GetGamerules():GetAllPlayers()) do
		if Server.GetOwner(victim):GetUserId() == tonumber(steamid) then
			return victim
		end
	end
	return false
end

function webKickPlayer(steamid, playerRecords)
	if not steamid == nil or 0 then
		local kickthis = webFindPlayer(steamid, playerRecords) or false
		if kickthis ~= false then
			local kickent = Server.GetOwner(kickthis)
			local kickname = ''
			if kickent:GetIsVirtual() == false then
				kickname = kickthis:GetName()
				Server.DisconnectClient(kickent)
				Shared.Message(string.format("Server: %s was kicked from the server", kickname))
			else
				OnConsoleRemoveBots()
				kickname = 'bot'
			end
			return 'Kicking ' .. kickname
		end
	end
	return 'Cant kick player'
end

function ProcessConsoleCommand(command)
    Shared.ConsoleCommand(command)
    return command
end

	--Returns web api with type requested (json string or HTML Page (Default))
function getWebApi(returnType, command, kickedId)

	--Force Json string by default
	--returnType = 'json'

	local listdlc = {
		specialEdition = kSpecialEditionProductId or false
	}

	local playerRecords = GetGamerules():GetAllPlayers()
	local entity = nil

	local stats = {
				cheats = tostring(Shared.GetCheatsEnabled()),
				devmode = tostring(Shared.GetDevMode()),
				map = tostring(Shared.GetMapName()),
				uptime = webServerUpTime(returnType),
				players = table.maxn(playerRecords),
				playersMarine = GetGamerules():GetTeam1():GetNumPlayers(),
				playersAlien = GetGamerules():GetTeam2():GetNumPlayers(),
				marineCarbon = nil,
				alienCarbon = nil
	}

	local result = ''

	if (returnType == 'json') then

		if not command then
			command = false
		end

		result = result ..'{'
							.. '"server":'
							.. '{'
								.. '"webdomain":"[[webdomain]]"'
								.. ',"webport":"[[webport]]"'
								.. ',"command":"' .. tostring(command) .. '"'
								.. ',"cheats":"' .. stats['cheats'] .. '"'
								.. ',"devmode":"' .. stats['devmode'] .. '"'
								.. ',"map":"' .. stats['map'] .. '"'
								.. ',"players":"' .. stats['players'] .. '"'
								.. ',"marines":"' .. stats['playersMarine'] .. '"'
								.. ',"aliens":"' .. stats['playersAlien'] .. '"'
								.. ',"uptime":"' .. stats['uptime'] .. '"'
							.. '}'
							.. ',"players":{'

							for index,player in ipairs(playerRecords) do

								entity = Server.GetOwner(player)

								result = result .. '"' .. index .. '":'
								.. '{'
									.. '"name":"' .. player:GetName() .. '",'
									.. '"steamid":"' .. entity:GetUserId() .. '",'
									.. '"team":"' .. webGetTeam(player, returnType) .. '",'
									.. '"iscomm":"' .. webIsCommander(player, returnType) .. '",'
									.. '"score":"' .. player:GetScore() .. '",'
									.. '"kills":"' .. player:GetKills() .. '",'
									.. '"deaths":"' .. player:GetDeaths() .. '",'
									.. '"plasma":"' .. player:GetPlasma() .. '",'
									.. '"ping":"' .. entity:GetPing() .. '",'
									.. '"dlc":{'

									for dlci,dlcc in pairs(listdlc) do
										if dlcc then
											result = result .. '"' .. dlci .. '":"' .. tostring(Server.GetIsDlcAuthorized(entity, dlcc)) .. '",'
										end
									end

					result = result .. '}'
								.. '},'

							end

		result = result .. '}}'

	else

	--If no header type is specified then return the standard webform

		result = result .. '<html><head>'.."\n"
						.. '<title>Spark Web API</title>'.."\n"
						.. '<style type="text/css">'.."\n"
						.. '.bb {border-bottom:1px dashed #C8C8C8;background-color:#EBEBEB;}'.."\n"
						.. 'body, td, div { font-size:11px;font-family: Arial, Helvetica; }'.."\n"
						.. '.t {margin:auto;border:2px solid #1e1e1e;}'.."\n"
						.. 'div {width:660;margin:auto;}'.."\n"
						.. '</style>'.."\n"
						.. '</head><body>'.."\n"
						.. '<div><h1><a href="http://[[webdomain]]:[[webport]]/" target="_self">NS2 Server Manager</a></h1></div><br clear="all" />'.."\n"
						.. '<table width="660" cellspacing="2" cellpadding="2" class="t">'.."\n"
						.. '<tr><td colspan="2"><b>Server Uptime:</b> ' .. stats['uptime'] .. '</td></tr>'.."\n"
						.. '<tr><td class="bb" width="100"><b>Currently Playing:</td><td class="bb">' .. stats['map'] .. '</td></tr>'.."\n"
						.. '<tr><td class="bb"><b>Players Online:</b></td><td class="bb"><b>' .. stats['players'] .. '</b> &nbsp; &nbsp; &nbsp; Marine: <b>' .. stats['playersMarine'] .. '</b> | Alien: <b>' .. stats['playersAlien'] .. '</b></td></tr>'.."\n"
						.. '<tr><td class="bb"><b>Developer Mode:</b></td><td class="bb">' .. stats['devmode'] .. '</td></tr>'.."\n"
						.. '<tr><td class="bb"><b>Cheats Enabled:</b></td><td class="bb">' .. stats['cheats'] .. '</td></tr>'.."\n"

						.. '<tr><td colspan="2"><form name="send_rcon" action="http://[[webdomain]]:[[webport]]/" method="post">'
						.. '<p>'
						.. '<label for="command"><b>Console Command:</b> </label>'
						.. '<input type="text" name="rcon"> '
						.. '<input type="submit" name="command" value="Send">'
						.. ' <input type="submit" name="addbot" value="Add Bot" /> '
						.. ' <input type="submit" name="removebot" value="Remove Bot" /> '
						.. '</p>'
						.. '</form></td></tr>'

		if command then
			result = result .. '<tr><td><b>Command Sent:</b></td><td>' .. command .. '</td></tr>'.."\n"
		end
		result = result	.. '</table><br clear="all"/>'.."\n"

						.. '<table width="660" class="t" cellspacing="4" cellpadding="2">'.."\n"
						.. '<tr>'
						.. '<td><b>Player Name</b></td>'
						.. '<td><b>Team</b></td>'
						.. '<td align="center"><b>Score</b></td>'
						.. '<td align="center"><b>Kills</b></td>'
						.. '<td align="center"><b>Deaths</b></td>'
						.. '<td align="center"><b>Plasma</b></td>'
						.. '<td><b>Steam ID</b></td>'
						.. '<td align="center"><b>Ping</b></td>'
						.. '<td></td>'
						.. '</tr>'

		local kickbutton = ''
		local kickbtext = ''
		local steamid = 0

		for index, player in ipairs(playerRecords) do

			entity = Server.GetOwner(player)
			steamid = entity:GetUserId()

			if (entity:GetIsVirtual() == true) then
				kickbtext = 'Bot'
				kickbutton = 'disabled'
			elseif (tonumber(kickedId) == tonumber(steamid)) then
				kickbtext = 'Kicked...'
				kickbutton = 'disabled'
			else
				kickbtext = 'Kick'
				kickbutton = ''
			end

			result = result .. '<tr>'
							.. '<td valign="middle" class="bb"><b>' .. player:GetName() .. '</b> ' .. webIsCommander(player, returnType) .. '</td>'
							.. '<td valign="middle" class="bb">' .. webGetTeam(player, returnType) .. '</td>'
							.. '<td valign="middle" align="center" class="bb">' .. player:GetScore() .. '</td>'
							.. '<td valign="middle" align="center" class="bb">' .. player:GetKills() .. '</td>'
							.. '<td valign="middle" align="center" class="bb">' .. player:GetDeaths() .. '</td>'
							.. '<td valign="middle" align="center" class="bb">' .. player:GetPlasma() .. '</td>'
							.. '<td valign="middle" class="bb">' .. steamid .. '</td>'
							.. '<td valign="middle" align="center" class="bb">' .. entity:GetPing() .. '</td>'
							.. '<td valign="middle"><form name="' .. steamid .. '" action="http://[[webdomain]]:[[webport]]/" method="post" style="display:inline;"><input type="hidden" name="kickid" value="' .. tonumber(steamid) .. '" /><input type="submit" name="kick" value="' .. kickbtext .. '" style="padding:1px;margin:1px;line-height:10px;" ' .. kickbutton .. ' /></form></td>'
							.. '</tr>'.."\n"
		end

		result = result .. '</table>'.."\n"
						.. '</body></html>'

	end

    return result

end

function OnWebRequest(action)

	local returnType = 'html'
	local command = nil
	local kickedId = nil

	--Get requested header
	if action['header'] == 'json' then
		local returnType = 'json'
	end

	--Command switch
	if action['command'] then
		command = ProcessConsoleCommand(action['rcon'])

	elseif action['addbot'] then
		command = ProcessConsoleCommand('addbot')

	elseif action['removebot'] then
		command = ProcessConsoleCommand('removebot')

	elseif action['kick'] then
		command = webKickPlayer(action['kickid'])
		kickedId = action['kickid']

--TODO
--	elseif action['tempban'] then
--		command = webTempBan(action['banid'], action['duration'])

	end
    return getWebApi(returnType, command, kickedId)

end

Event.Hook("MapPreLoad",            OnMapPreLoad)
Event.Hook("MapPostLoad",           OnMapPostLoad)
Event.Hook("MapLoadEntity",         OnMapLoadEntity)
Event.Hook("WebRequest",            OnWebRequest)
