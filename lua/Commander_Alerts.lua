//=============================================================================
//
// lua/Commander_Alerts.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2010, Unknown Worlds Entertainment
//
//=============================================================================


/**
 * Send any new alerts to the commander ui
 * Format is:
 *  Location -> text, icon x offset, icon y offset, map x, map y
 *  Entity -> text, icon x offset, icon y offset, -1, entity id
 */
function CommanderUI_GetAlertMessages()
    local messages = Client.GetLocalPlayer():GetAndClearAlertMessages()
    /*
    if table.count(messages) > 0 then
        Print("CommanderUI_GetAlertMessages() returning %s", table.tostring(messages))
    end
    */
    return messages
end

/**
 * Notify that Entity-type alert was clicked
 */
function CommanderUI_ClickedEntityAlert(entityId)

    local player = Client.GetLocalPlayer()
    if player:isa("Commander") then
        local entity = Shared.GetEntity(entityId)
        if entity ~= nil then
            player:SetWorldScrollPosition(entity:GetOrigin().x, entity:GetOrigin().z)
        end
    end
    
end

/**
 * Notify that Location-type alert was clicked
 */
function CommanderUI_ClickedLocationAlert(xp, zp)

    local player = Client.GetLocalPlayer()
    if player:isa("Commander") then
        player:SetWorldScrollPosition(xp, zp)
    end
    
end
