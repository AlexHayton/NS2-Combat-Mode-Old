//=============================================================================
//
// lua\Bot.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

if (not Server) then
    error("Bot.lua should only be included on the Server")
end

class 'Bot'

function Bot:__init(forceTeam)

    // Create a virtual client for the bot
    self.client = Server.AddVirtualClient()
    self.forceTeam = forceTeam
    
end

function Bot:Disconnect()
    Server.DisconnectClient(self.client)    
    self.client = nil
end

// Stores all of the bots
local bots = { }

function OnConsoleAddBots(client, numBotsParam, forceTeam)

    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        for index = 1, numBots do
        
            local bot = Bot(tonumber(forceTeam))
            table.insert( bots, bot )
            
        end
        
    end
    
end

function OnConsoleRemoveBots(client, numBotsParam)
    
    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        for index = 1, numBots do

            local bot = table.remove(bots)
            
            if bot then        
                bot:Disconnect()            
            end
            
        end
        
    end
    
end

function OnVirtualClientMove(client)

    // If the client corresponds to one of our bots, generate a move from it.
    for i,bot in ipairs(bots) do
    
        if (bot.client == client) then
        
            local player = client:GetControllingPlayer()
            if player then
            
                return player:GenerateMove()
                
            end
            
        end
        
    end

end

function OnVirtualClientThink(client, deltaTime)

    // If the client corresponds to one of our bots, allow it to think.
    for i, bot in ipairs(bots) do
    
        if bot.client == client then
        
            local player = bot.client:GetControllingPlayer()
            
            if player then
            
                player:InitializeBot()
            
                player:UpdateName()
                
                player:UpdateTeam(bot.forceTeam)
            
                // Orders update and completed in Player:UpdateOrder()
                // Don't give orders to bots that are waiting to spawn.
                if not player:isa("Spectator") then
                    player:ChooseOrder()
                end
                
                player:UpdateOrder()
                
            end

        end
        
    end

    return true
    
end

// Register the bot console commands
Event.Hook("Console_addbot",         OnConsoleAddBots)
Event.Hook("Console_removebot",      OnConsoleRemoveBots)
Event.Hook("Console_addbots",        OnConsoleAddBots)
Event.Hook("Console_removebots",     OnConsoleRemoveBots)

// Register to handle when the server wants this bot to
// process orders
Event.Hook("VirtualClientThink",    OnVirtualClientThink)

// Register to handle when the server wants to generate a move
// for one of the virtual clients
Event.Hook("VirtualClientMove",     OnVirtualClientMove)