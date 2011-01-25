// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

function OnCommandDamageIndicator(damageIndicatorMessage)
    
    local player = Client.GetLocalPlayer()
    local worldX, worldZ, damage = ParseDamageIndicatorMessage(damageIndicatorMessage)
    player:AddDamageIndicator(worldX, worldZ)
    
    // Shake the camera if this player supports it
    if(player.SetCameraShake ~= nil) then
        local shakeDir = Vector(worldX, player:GetOrigin().y, worldZ) - player:GetOrigin()
        shakeDir:Normalize()
        player:SetCameraShake(damage * Player.kDamageCameraShakeAmount, Player.kDamageCameraShakeSpeed, Player.kDamageCameraShakeTime, shakeDir)
    end
    
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

function OnCommandToggleSpawnBuyMenu(client)

    local player = Client.GetLocalPlayer()

    if player:isa("AlienSpectator") or player:isa("Alien") then

        local mouseState = true
        
        if(not Client.GetMouseVisible()) then

            player:OpenMenu(AlienSpectator.kBuyMenuFlash)
            
            GetFlashPlayer(kMenuFlashIndex):Load(AlienSpectator.kBuyMenuFlash)
            GetFlashPlayer(kMenuFlashIndex):SetBackgroundOpacity(0)
            
            //Client.BindFlashTexture("marine_buymenu", Armory.kBuyMenuTexture)
            //Client.BindFlashTexture("marine_buymenu_upgrades", Armory.kBuyMenuUpgradesTexture)            
            
        else
            mouseState = false
        end
        
        Client.SetMouseVisible(mouseState)
        Client.SetMouseCaptured(mouseState)
        Client.SetMouseClipped(mouseState)
        
        Shared.PlaySound(Client.GetLocalPlayer(), AlienSpectator.kOpenSound)

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
        local sentries = GetEntitiesIsaInRadius("Sentry", player:GetTeamNumber(), player:GetOrigin(), 20)    
        for index, sentry in ipairs(sentries) do
            
            local targets = GetEntitiesIsaInRadius("LiveScriptActor", -1, sentry:GetOrigin(), Sentry.kRange)
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

Event.Hook("Console_debugspawn",            OnCommandDebugSpawn)
Event.Hook("Console_hotgroup",              OnCommandHotgroup)
Event.Hook("Console_minimapalert",          OnCommandMinimapAlert)
Event.Hook("Console_togglespawnbuymenu",    OnCommandToggleSpawnBuyMenu)
Event.Hook("Console_tracereticle",          OnCommandTraceReticle)
Event.Hook("Console_viewheight",            OnCommandViewHeight)
Event.Hook("Console_testsentry",            OnCommandTestSentry)
Event.Hook("Console_random_debug",          OnCommandRandomDebug)
Event.Hook("Console_location",              OnCommandLocation)
Event.Hook("Console_changegcsettingclient", OnCommandChangeGCSettingClient)

Client.HookNetworkMessage("SelectAndGoto",      OnCommandSelectAndGoto)
Client.HookNetworkMessage("DamageIndicator",    OnCommandDamageIndicator)