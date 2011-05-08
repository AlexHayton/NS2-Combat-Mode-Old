// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Only loaded when game rules are set and propagated to client.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandSelectAndGoto(selectAndGotoMessage)

    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
    
        local entityId = ParseSelectAndGotoMessage(selectAndGotoMessage)
        player:SetSelection({entityId})
        
        local entity = Shared.GetEntity(entityId)
        if entity ~= nil then
        
            player:SetWorldScrollPosition(entity:GetOrigin().x, entity:GetOrigin().z)
            
        else
            Print("OnCommandSelectAndGoto() - Couldn't goto position of entity %d", entityId)
        end
        
    end
    
end

function OnCommandTakeDamageIndicator(damageIndicatorMessage)
    
    local player = Client.GetLocalPlayer()
    local worldX, worldZ, damage = ParseTakeDamageIndicatorMessage(damageIndicatorMessage)
    player:AddTakeDamageIndicator(worldX, worldZ)
    
    // Shake the camera if this player supports it
    if(player.SetCameraShake ~= nil) then
        local shakeDir = Vector(worldX, player:GetOrigin().y, worldZ) - player:GetOrigin()
        shakeDir:Normalize()
        player:SetCameraShake(damage * Player.kDamageCameraShakeAmount, Player.kDamageCameraShakeSpeed, Player.kDamageCameraShakeTime, shakeDir)
    end
    
end

function OnCommandGiveDamageIndicator(damageIndicatorMessage)

    local damageAmount = ParseGiveDamageIndicatorMessage(damageIndicatorMessage)
    local player = Client.GetLocalPlayer()
    player:AddGiveDamageIndicator(damageAmount)

end

function OnCommandHotgroup(number, hotgroupString)

    local player = Client.GetLocalPlayer()

    // Read hotgroup number and list of entities (separated by _)
    local hotgroupNumber = tonumber(number)
    local entityList = {}    
    
    if(hotgroupString ~= nil) then 
   
        for currentInt in string.gmatch(hotgroupString, "[0-9]+") do 
        
            table.insert(entityList, tonumber(currentInt))
            
        end
        
    end
    
    player:SetHotgroup(hotgroupNumber, entityList)
        
end

function OnCommandMinimapAlert(techId, worldX, worldZ, entityId, entityTechId)
    local player = Client.GetLocalPlayer()
    if player:isa("Commander") then
        player:AddAlert(tonumber(techId), tonumber(worldX), tonumber(worldZ), tonumber(entityId), tonumber(entityTechId))
    end
end

function OnCommandTraceReticle()
    if Shared.GetCheatsEnabled() then
        Print("Toggling tracereticle cheat.")        
        Client.GetLocalPlayer():ToggleTraceReticle()
    end
end

function OnCommandViewHeight()
    if Shared.GetCheatsEnabled() then
        Print("Toggling viewheight cheat.")
        Client.GetLocalPlayer():ToggleViewHeight()
    end
end

function OnCommandTestSentry()

    local player = Client.GetLocalPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        // Look for nearest sentry and have it show us what it sees
        local sentries = GetEntitiesForTeamWithinRange("Sentry", player:GetTeamNumber(), player:GetOrigin(), 20)    
        for index, sentry in ipairs(sentries) do
            
            local targets = GetEntitiesWithinRange("LiveScriptActor", sentry:GetOrigin(), Sentry.kRange)
            for index, target in pairs(targets) do
            
                if sentry ~= target then
                    sentry:GetCanSeeEntity(target)
                end
                //local validTarget, distanceToTarget = sentry:GetTargetValid(target)

            end
        end
        
    end
    
end

function OnCommandRandomDebug()

    if Shared.GetCheatsEnabled() then
        local newState = not gRandomDebugEnabled
        gRandomDebugEnabled = newState
    end
    
end

function OnCommandLocation(client)

    local player = Client.GetLocalPlayer()

    local locationName = player:GetLocationName()
    if(locationName ~= "") then
        Print("You are in \"%s\".", locationName)
    else
        Print("You are nowhere.")
    end
    
end

function OnCommandChangeGCSettingClient(settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing client GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

Event.Hook("Console_hotgroup",              OnCommandHotgroup)
Event.Hook("Console_minimapalert",          OnCommandMinimapAlert)
Event.Hook("Console_tracereticle",          OnCommandTraceReticle)
Event.Hook("Console_viewheight",            OnCommandViewHeight)
Event.Hook("Console_testsentry",            OnCommandTestSentry)
Event.Hook("Console_random_debug",          OnCommandRandomDebug)
Event.Hook("Console_location",              OnCommandLocation)
Event.Hook("Console_changegcsettingclient", OnCommandChangeGCSettingClient)

Client.HookNetworkMessage("SelectAndGoto",      OnCommandSelectAndGoto)
Client.HookNetworkMessage("TakeDamageIndicator",    OnCommandTakeDamageIndicator)
Client.HookNetworkMessage("GiveDamageIndicator",    OnCommandGiveDamageIndicator)