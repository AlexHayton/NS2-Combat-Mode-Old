// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// NS2 Gamerules specific console commands. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")

function JoinTeamOne(player, force)
    // Team balance
    if GetGamerules():GetCanJoinTeamNumber(kTeam1Index) or force or Shared.GetCheatsEnabled() then
        return GetGamerules():JoinTeam(player, kTeam1Index, force)
    elseif (player:GetTeamNumber() ~= 1) then
        player:AddTooltipOncePer("This team has too many players.", 5)
    end
    
    return false
end

function JoinTeamTwo(player, force)
    if GetGamerules():GetCanJoinTeamNumber(kTeam2Index) or force or Shared.GetCheatsEnabled() then
        return GetGamerules():JoinTeam(player, kTeam2Index, force)
    elseif (player:GetTeamNumber() ~= 2) then        
        player:AddTooltipOncePer("This team has too many players.", 5)
    end
    
    return false
end

function ReadyRoom(player, force)
    return GetGamerules():JoinTeam(player, kTeamReadyRoom, force)
end

function Spectate(player)
    return GetGamerules():JoinTeam(player, kSpectatorIndex)
end

function OnCommandJoinTeamOne(client)
    local player = client:GetControllingPlayer()
    JoinTeamOne(player)
end

function OnCommandJoinTeamTwo(client)
    local player = client:GetControllingPlayer()
    JoinTeamTwo(player)
end

function OnCommandReadyRoom(client)
    local player = client:GetControllingPlayer()
    ReadyRoom(player)
end

function OnCommandSpectate(client)
    local player = client:GetControllingPlayer()
    Spectate(player)
end

/**
 * Forces the game to end for testing purposes
 */
function OnCommandEndGame(client)

    local player = client:GetControllingPlayer()

    if Shared.GetCheatsEnabled() and GetGamerules():GetGameStarted() then
        GetGamerules():EndGame(player:GetTeam())
    end
    
end

function OnCommandTeamResources(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:GetTeam():AddTeamResources(100)
    end
    
end

function OnCommandResources(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:AddResources(100)
    end
    
end

function OnCommandAutobuild(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetAutobuild(not GetGamerules():GetAutobuild())
        Print("Autobuild now %s", ToString(GetGamerules():GetAutobuild()))
    end
    
end

function OnCommandEnergy(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        // Give energy to all structures on our team
        for index, ent in ipairs(GetEntitiesForTeam("LiveScriptActor", player:GetTeamNumber())) do
        
            ent:SetEnergy(LiveScriptActor.kMaxEnergy)
            
        end
        
    end
    
end


function OnCommandTakeDamage(client, amount)

    local player = client:GetControllingPlayer()
    
    if(Shared.GetCheatsEnabled()) then
    
        local damage = tonumber(amount)
        if(damage == nil) then
            damage = 20 + NetworkRandom() * 10
        end        
        
        player:TakeDamage(damage, player, player, player:GetOrigin() + Vector(1, 0, 0))
        
    end
    
end

function OnCommandGiveAmmo(client)

    local player = client:GetControllingPlayer()
    
    if(Shared.GetCheatsEnabled()) then
        local weapon = player:GetActiveWeapon()
        if(weapon ~= nil and weapon:isa("ClipWeapon")) then
            weapon:GiveAmmo(1)
        end
    end
    
end

/**
 * Creates an entity in front of the player.
 */
function OnCommandSpawn(client, className)

    local player = client:GetControllingPlayer()
    
    if (Shared.GetCheatsEnabled()) then
    
        // Trace a ray from the player's eye to figure out where to create
        // the new entity.
    
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
    
        local startPoint = player:GetViewOffset() + player:GetOrigin()
        
        // Filter ourself out of the trace so that we don't hit ourselves.
        local filter = EntityFilterOne(player)
        local range  = 100
   
        local endPoint = startPoint + viewCoords.zAxis * range
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, filter)
        
        if (trace.fraction < 1) then
            if (CreateEntity(className, trace.endPoint) == nil) then
                Server.Broadcast(player, "Couldn't create entity of class '" .. className .. "'")
            end
        end
    
    end

end

function OnCommandEnts(client, className)

    local player = client:GetControllingPlayer()
    if Shared.GetCheatsEnabled() then
    
        local entityCount = Shared.GetEntitiesWithClassname("Entity"):GetSize()
        
        local weaponCount = Shared.GetEntitiesWithClassname("Weapon"):GetSize()
        local playerCount = Shared.GetEntitiesWithClassname("Player"):GetSize()
        local structureCount = Shared.GetEntitiesWithClassname("Structure"):GetSize()
        local playersOnPlayingTeams = GetGamerules():GetTeam1():GetNumPlayers() + GetGamerules():GetTeam2():GetNumPlayers()
        local commandStationsOnTeams = GetGamerules():GetTeam1():GetNumCommandStructures() + GetGamerules():GetTeam2():GetNumCommandStructures()
        local blipCount = Shared.GetEntitiesWithClassname("Blip"):GetSize()
        local infestCount = Shared.GetEntitiesWithClassname("Infestation"):GetSize()
        
        if className then
            local numClassEnts = Shared.GetEntitiesWithClassname(className):GetSize()
            Server.Broadcast(player, Pluralize(numClassEnts, className))
        else
            Server.Broadcast(player, string.format("%d entities (%s, %d playing, %s, %s, %s, %s, %d command structures on teams).", 
                                                    entityCount, Pluralize(playerCount, "player"), playersOnPlayingTeams, Pluralize(weaponCount, "weapon"), Pluralize(structureCount, "structure"), Pluralize(blipCount, "blip"), Pluralize(infestCount, "infest"), commandStationsOnTeams))
        end
    end
    
end

// Switch player from one team to the other, while staying in the same place
function OnCommandSwitch(client)

    local player = client:GetControllingPlayer()
    local teamNumber = player:GetTeamNumber()
    if(Shared.GetCheatsEnabled() and (teamNumber == kTeam1Index or teamNumber == kTeam2Index)) then
    
        // Remember position and team for calling player for debugging
        local playerOrigin = player:GetOrigin()
        local playerViewAngles = player:GetViewAngles()
        
        local newTeamNumber = kTeam1Index
        if(teamNumber == kTeam1Index) then
            newTeamNumber = kTeam2Index
        end
        
        local success, newPlayer = GetGamerules():JoinTeam(player, kTeamReadyRoom)
        success, newPlayer = GetGamerules():JoinTeam(newPlayer, newTeamNumber)
        
        newPlayer:SetOrigin(playerOrigin)
        newPlayer:SetViewAngles(playerViewAngles)
        
    end
    
end

function OnCommandDamage(client,multiplier)

    if(Shared.GetCheatsEnabled()) then
        local m = multiplier and tonumber(multiplier) or 1
        GetGamerules():SetDamageMultiplier(m)
        Shared.Message("Damage multipler set to " .. m)
    end
    
end

function OnCommandHighDamage(client)

    if(Shared.GetCheatsEnabled()) then
        GetGamerules():SetDamageMultiplier(10)
    end
    
end

function OnCommandGive(client, itemName)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and itemName ~= nil) then
        player:GiveItem(itemName)
        player:SetActiveWeapon(itemName)
    end
    
end

function OnCommandGiveUpgrade(client, techIdString)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        
        if techId ~= nil then
        
            local player = client:GetControllingPlayer()
        
            if not player:GetTechTree():GiveUpgrade(techId) then
            
                if not player:GiveUpgrade(techId) then
                    Print("GiveUpgrade(%s) not research and not an upgraded, failed.", EnumToString(kTechId, techId))
                end
                
            end
            
        end
        
    end
    
end

function OnCommandLogout(client)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:Logout()
    
    end

end

function OnCommandBuy(client, techId)
    
    local player = client:GetControllingPlayer()
    player:ProcessBuyAction( tonumber(techId) )

end


function OnCommandClearSelect(client)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
        player:ClearSelection()
    end
    
end

function OnCommandGotoIdleWorker(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoIdleWorker()
    end
    
end

function OnCommandGotoPlayerAlert(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoPlayerAlert()
    end
    
end

function OnCommandSelectAllPlayers(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllPlayers then
        player:SelectAllPlayers()
    end
    
end

function OnCommandSetSquad(client, squadIndexString)

    local player = client:GetControllingPlayer()
    local squadIndex = tonumber(squadIndexString)
    
    if(Shared.GetCheatsEnabled() and player:isa("Marine") and squadIndex >= 0 and squadIndex <= GetMaxSquads()) then
        player:SetSquad(squadIndex)        
    end
    
end

function OnCommandSquadSpawn(client, squadIndexString)

    local player = client:GetControllingPlayer()
    local squadIndex = tonumber(squadIndexString)
    
    if(Shared.GetCheatsEnabled() and player:isa("Marine") and squadIndex >= 0 and squadIndex <= GetMaxSquads()) then
        player:SpawnInSquad(squadIndex)            
    end

end

function OnCommandFlare(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player.flareStartTime = Shared.GetTime()
        player.flareStopTime = player.flareStartTime + 5
        
    end
    
end

function OnCommandTooltipOnce(client, tooltipText)
    local player = client:GetControllingPlayer()
    AddTooltipOnce(player, tooltipText)
end

function OnCommandSetFOV(client, fovValue)
    local player = client:GetControllingPlayer()
    if Shared.GetDevMode() then
        player:SetFov(tonumber(fovValue))
    end
end

function OnCommandSkulk(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player:Replace(Skulk.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandGorge(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then   
    
        player:Replace(Gorge.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandLerk(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player:Replace(Lerk.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandFade(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player:Replace(Fade.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandOnos(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player:Replace(Onos.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandHeavy(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        player:Replace(Heavy.kMapName, player:GetTeamNumber(), false)
        
    end    
    
end

function OnCommandInfantryPortal(client)

    local player = client:GetControllingPlayer()
    if Shared.GetCheatsEnabled() then
    
        local success = false
        
        local team = player:GetTeam()
        if team:isa("MarineTeam") then
            success = team:SpawnIP(player:GetTeam():GetTeamLocation():GetOrigin())
        end
        
    end
    
end

function OnCommandCommand(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        // Find hive/command station on our team and use it
        local ents = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if(table.maxn(ents) > 0) then
            player:SetOrigin(ents[1]:GetOrigin() + Vector(0, 1, 0))
            ents[1]:OnUse(player, .1, true, ents[1]:GetModelOrigin())
            ents[1]:UpdateCommanderLogin(true)
        end
        
    end
    
end

function OnCommandCatPack(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and player:isa("Marine")) then
        player:ApplyCatPack()
    end
end

function OnCommandAllTech(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        local newAllTechState = not GetGamerules():GetAllTech()
        GetGamerules():SetAllTech(newAllTechState)
        Print("Setting alltech cheat %s", ConditionalValue(newAllTechState, "on", "off"))
        
    end
    
end

function OnCommandFlareDrifter(client)

    local player = client:GetControllingPlayer()
    local hives = GetEntitiesForTeam("CommandStructure", GetGamerules():GetTeam2():GetTeamNumber())
    if(table.maxn(hives) > 0) then
        local drifter = CreateEntity(Drifter.kMapName, hives[1]:GetOrigin() + Vector(-3, 0.5, 0), GetGamerules():GetTeam2():GetTeamNumber())
        drifter:PerformFlare()
    end

end

function OnCommandLocation(client)

    local player = client:GetControllingPlayer()
    local locationName = player:GetLocationName()
    if(locationName ~= "") then
        Print("You are in \"%s\".", locationName)
    else
        Print("You are nowhere.")
    end
end

function OnCommandCloseMenu(client)
    local player = client:GetControllingPlayer()
    player:CloseMenu()
end

// Weld all doors shut immediately
function OnCommandWeldDoors(client)

    if Shared.GetCheatsEnabled() then
    
        for index, door in ientitylist(Shared.GetEntitiesWithClassname("Door")) do 
        
            if door:GetIsAlive() then
                door:SetState(Door.kState.Welded)
            end
            
        end
        
    end
    
end

function OnCommandOrderSelf(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetOrderSelf(not GetGamerules():GetOrderSelf())
        Print("Order self is now %s.", ToString(GetGamerules():GetOrderSelf()))
    end
    
end

function techIdStringToTechId(techIdString)

    local techId = tonumber(techIdString)
    
    if type(techId) ~= "number" then
        techId = StringToEnum(kTechId, techIdString)
    end        
    
    return techId
    
end

// Create structure, weapon, etc. near player
function OnCommandCreate(client, techIdString, number)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        
        if (number == nil) then
            number = 1
        end
        
        if techId ~= nil then

            for i = 1, number do

                local player = client:GetControllingPlayer()        
                local success, position = GetRandomSpaceForEntity(player:GetOrigin(), 2, 10, 2, 2)
                
                if success then
                
                    CreateEntityForTeam(techId, position, player:GetTeamNumber(), player)

                else
                    Print("Create %s: Couldn't find space for entity", EnumToString(kTechId, techId))
                end
                
           end
            
        else
            Print("Usage: create (techId name)")
        end
        
    end
end

function OnCommandRandomDebug(s)

    if Shared.GetCheatsEnabled() then
    
        local newState = not gRandomDebugEnabled
        Print("OnCommandRandomDebug() now %s", ToString(newState))
        gRandomDebugEnabled = newState

    end
    
end

function OnCommandDistressBeacon()

    if Shared.GetCheatsEnabled() then
    
        local ents = Shared.GetEntitiesWithClassname("Observatory")
        if ents:Size() > 0 then
        
            ents:GetEntityAtIndex(0):TriggerDistressBeacon()
            
        end
        
    end

end

function OnCommandGiveGameEffect(client, gameEffectString, durationString)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()  
        
        local duration = nil
        if durationString then
            duration = tonumber(durationString)
        end
        
        player:AddStackableGameEffect(gameEffectString, duration, nil)
        Print("AddStackableGameEffect(%s, %s) (%d in effect)", gameEffectString, ToString(duration), player:GetStackableGameEffectCount(gameEffectString))
        
    end
    
end

function OnCommandSetGameEffect(client, gameEffectString, trueFalseString)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        local gameEffect = StringToEnum(kGameEffect, gameEffectString)
        
        local state = true
        if trueFalseString and ((trueFalseString == "false") or (trueFalseString == "0")) then
            state = false
        end
        
        player:SetGameEffectMask(gameEffect, state)
        
    end
    
end

function OnCommandChangeGCSettingServer(client, settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing server GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

function OnCommandEject(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        if player and player.Eject then
        
            player:Eject()        
            
        end
        
    end
    
end

// GC commands
Event.Hook("Console_changegcsettingserver", OnCommandChangeGCSettingServer)

// NS2 game mode console commands
Event.Hook("Console_jointeamone",           OnCommandJoinTeamOne)
Event.Hook("Console_jointeamtwo",           OnCommandJoinTeamTwo)
Event.Hook("Console_readyroom",             OnCommandReadyRoom)
Event.Hook("Console_spectate",              OnCommandSpectate)

// Shortcuts because we type them so much
Event.Hook("Console_j1",                    OnCommandJoinTeamOne)
Event.Hook("Console_j2",                    OnCommandJoinTeamTwo)
Event.Hook("Console_rr",                    OnCommandReadyRoom)

Event.Hook("Console_endgame",               OnCommandEndGame)
Event.Hook("Console_logout",                OnCommandLogout)
Event.Hook("Console_buy",                   OnCommandBuy)
Event.Hook("Console_clearselect",           OnCommandClearSelect)
Event.Hook("Console_gotoidleworker",        OnCommandGotoIdleWorker)
Event.Hook("Console_gotoplayeralert",       OnCommandGotoPlayerAlert)
Event.Hook("Console_selectallplayers",      OnCommandSelectAllPlayers)

// Cheats
Event.Hook("Console_teamresources",         OnCommandTeamResources)
Event.Hook("Console_resources",             OnCommandResources)
Event.Hook("Console_autobuild",             OnCommandAutobuild)
Event.Hook("Console_energy",                OnCommandEnergy)
Event.Hook("Console_takedamage",            OnCommandTakeDamage)
Event.Hook("Console_giveammo",              OnCommandGiveAmmo)
Event.Hook("Console_spawn",                 OnCommandSpawn)

Event.Hook("Console_ents",                  OnCommandEnts)

Event.Hook("Console_switch",                OnCommandSwitch)
Event.Hook("Console_damage",                OnCommandDamage)
Event.Hook("Console_highdamage",            OnCommandHighDamage)
Event.Hook("Console_give",                  OnCommandGive)
Event.Hook("Console_giveupgrade",           OnCommandGiveUpgrade)
Event.Hook("Console_setsquad",              OnCommandSetSquad)
Event.Hook("Console_squadspawn",            OnCommandSquadSpawn)
Event.Hook("Console_flare",                 OnCommandFlare)
Event.Hook("Console_tooltiponce",           OnCommandTooltipOnce)
Event.Hook("Console_setfov",                OnCommandSetFOV)

// For testing lifeforms
Event.Hook("Console_skulk",                 OnCommandSkulk)
Event.Hook("Console_gorge",                 OnCommandGorge)
Event.Hook("Console_lerk",                  OnCommandLerk)
Event.Hook("Console_fade",                  OnCommandFade)
Event.Hook("Console_onos",                  OnCommandOnos)
Event.Hook("Console_heavy",                 OnCommandHeavy)
Event.Hook("Console_infantryportal",        OnCommandInfantryPortal)

Event.Hook("Console_command",               OnCommandCommand)
Event.Hook("Console_catpack",               OnCommandCatPack)
Event.Hook("Console_alltech",               OnCommandAllTech)
Event.Hook("Console_flaredrifter",          OnCommandFlareDrifter)
Event.Hook("Console_location",              OnCommandLocation)

Event.Hook("Console_closemenu",             OnCommandCloseMenu)
Event.Hook("Console_welddoors",             OnCommandWeldDoors)
Event.Hook("Console_orderself",             OnCommandOrderSelf)

Event.Hook("Console_create",                OnCommandCreate)
Event.Hook("Console_random_debug",          OnCommandRandomDebug)
Event.Hook("Console_bacon",                 OnCommandDistressBeacon)
Event.Hook("Console_givegameeffect",        OnCommandGiveGameEffect)
Event.Hook("Console_setgameeffect",         OnCommandSetGameEffect)

Event.Hook("Console_eject",                 OnCommandEject)
