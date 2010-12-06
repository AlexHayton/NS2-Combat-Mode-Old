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
function CommanderUI_ClickedEntityAlert(eid)
    Print("CommanderUI_ClickedEntityAlert(%s)", ToString(eid))	
end

/**
 * Notify that Location-type alert was clicked
 */
function CommanderUI_ClickedLocationAlert(xp, yp)
    Print("CommanderUI_ClickedLocationAlert(%s, %s)", ToString(xp), ToString(yp))
end
