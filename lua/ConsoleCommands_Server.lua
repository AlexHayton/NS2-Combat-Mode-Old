// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// General purpose console commands (not game rules specific).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandSetName(client, name)

    if (client ~= nil) then

        local player = client:GetControllingPlayer()

        // Treat "NsPlayer" as special    
        if (name ~= player:GetName()) and (name ~= kDefaultPlayerName) then
        
            local prevName = player:GetName()
            player:SetName(name)
            
            if prevName == kDefaultPlayerName then
                Server.Broadcast(nil, string.format("%s connected.", player:GetName()))
            elseif prevName ~= player:GetName() then
                Server.Broadcast(nil, string.format("%s is now known as %s.", prevName, player:GetName()))
            end
            
        end
    
    end
    
end

// Chat message
function OnCommandSay(client, chatMessage)
    
    if (client ~= nil) then

        local player = client:GetControllingPlayer()
        
        if (player ~= nil) then
        
            // Broadcast a chat message to all players. Assumes incoming chatMessage
            // is a quoted string if it has spaces in it.
            local command = string.format("chat 0 %s %d %d %s", EncodeStringForNetwork(player:GetName()), player.locationId, player:GetTeamNumber(), chatMessage)
            
            Server.SendCommand(nil, command)
            
            Shared.Message("Chat All - " .. player:GetName() .. ": " .. chatMessage)
        
        end
        
    end

end

// Send chat message to everyone on the same team
function OnCommandTeamSay(client, chatMessage)
    
    if (client ~= nil) then

        local player = client:GetControllingPlayer()
        
        if (player ~= nil) then
        
            // Broadcast a chat message to all players. Assumes incoming chatMessage
            // is a quoted string if it has spaces in it.
            local players = GetGamerules():GetPlayers( player:GetTeamNumber() )

            local command = string.format("chat 1 %s %d %d %s", EncodeStringForNetwork(player:GetName()), player.locationId, player:GetTeamNumber(), chatMessage)
            
            for index, player in ipairs(players) do
                Server.SendCommand(player, command)
            end
            
            Shared.Message("Chat Team " .. tostring(player:GetTeamNumber()) .. " - " .. player:GetName() .. ": " .. chatMessage)
        
        end
        
    end
    
end

function OnCommandKill(client, otherPlayer)

    if (client ~= nil) then

        local player = client:GetControllingPlayer()
        
        if (otherPlayer ~= nil) then
        
            for index, currentPlayer in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                if(currentPlayer ~= nil and currentPlayer:GetName() == otherPlayer) then
                    otherPlayer = currentPlayer
                    break
                end
            end
            
        else
        
            otherPlayer = player
            
        end
        
        if (player ~= nil) then
            player:Kill(otherPlayer, otherPlayer, player:GetOrigin())
        end
        
    end
    
end

function OnCommandDarwinMode(client)

    if (client == nil or Shared.GetCheatsEnabled()) then
        GetGamerules():SetDarwinMode(not GetGamerules():GetDarwinMode())
    end
    
end

function OnCommandThirdperson(client, distance)

    if (client ~= nil and Shared.GetCheatsEnabled()) then
    
        local player = client:GetControllingPlayer()
        
        if (player ~= nil) then
    
            local numericDistance = 3
            if(distance ~= nil) then
                numericDistance = tonumber(distance)
            elseif(player:GetIsThirdPerson()) then
                numericDistance = 0
            end
            
            player:SetIsThirdPerson(numericDistance)
            
            if(numericDistance > 0) then
                Print("thirdperson enabled (distance = %0.2f)", numericDistance)
            else
                Print("thirdperson disabled.")
            end
        
        end
        
    end
    
end

// Cheat to grant experience. Saves me having to bite power nodes all day!
function OnCommandGrantExperience(client, experience)
	if (client ~= nil and Shared.GetCheatsEnabled()) then
		local player = client:GetControllingPlayer()
		player:AddExperience(experience)
		Print ("Granted " .. tostring(experience) .. " experience to the player")
	else
		Print ("Cheats are disabled")
	end
end

// Cheat to grant experience. Saves me having to bite power nodes all day!
function OnCommandClearSkills(client)
	if (client ~= nil and Shared.GetCheatsEnabled()) then
		local player = client:GetControllingPlayer()
		player:ClearSkills()
		Print ("Cleared all of your skills!")
	else
		Print ("Cheats are disabled")
	end
end


function OnCommandRoundReset(client)
    if (client ~= nil and Shared.GetCheatsEnabled()) then
        GetGamerules():ResetGame()    
    end
end

function OnCommandAnimDebug(client, className)

    if Shared.GetDevMode() then
    
        local player = client:GetControllingPlayer()
        
        if className then
        
            gActorAnimDebugClass = className
            Server.SendCommand(player, string.format("onanimdebug %s", className))
            Print("anim_debug enabled for \"%s\" objects.", className)
            
        elseif gActorAnimDebugClass ~= "" then
        
            gActorAnimDebugClass = ""
            Server.SendCommand(player, "onanimdebug")
            Print("anim_debug disabled.")
            
        else
            Print("anim_debug <class name>")
        end

    else
        Print("anim_debug <class name> (dev mode must be enabled)")
    end
    
end

function OnCommandEffectDebug(client, className)

    if Shared.GetDevMode() then
    
        local player = client:GetControllingPlayer()
        
        if className and className ~= "" then
        
            gEffectDebugClass = className
            Server.SendCommand(player, string.format("oneffectdebug %s", className))
            Print("effect_debug enabled for \"%s\" objects.", className)
            
        elseif gEffectDebugClass ~= nil then
        
            gEffectDebugClass = nil
            Server.SendCommand(player, "oneffectdebug")
            Print("effect_debug disabled.")
                
        else
        
            // Turn on debug of everything
            gEffectDebugClass = ""
            Server.SendCommand(player, "oneffectdebug")
            Print("effect_debug enabled.")
            
        end                

    else
        Print("effect_debug <class name> (dev mode must be enabled)")
    end
    
end
// Generic console commands
Event.Hook("Console_name",                  OnCommandSetName)
Event.Hook("Console_say",                   OnCommandSay)
Event.Hook("Console_teamsay",               OnCommandTeamSay)
Event.Hook("Console_kill",                  OnCommandKill)
Event.Hook("Console_darwinmode",            OnCommandDarwinMode)
Event.Hook("Console_thirdperson",           OnCommandThirdperson)
Event.Hook("Console_reset",                 OnCommandRoundReset)
Event.Hook("Console_anim_debug",            OnCommandAnimDebug)
Event.Hook("Console_effect_debug",          OnCommandEffectDebug)
Event.Hook("Console_grantexperience",     OnCommandGrantExperience)
Event.Hook("Console_clear_skills",     OnCommandClearSkills)
