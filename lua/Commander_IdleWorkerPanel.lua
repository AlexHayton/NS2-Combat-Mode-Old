//=============================================================================
//
// lua/Commander_IdleWorkerPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of idle workers
 */
function CommanderUI_GetIdleWorkerCount()
    
    local player = Client.GetLocalPlayer()
    
    if player.GetNumIdleWorkers ~= nil then
        return player:GetNumIdleWorkers()
    end
    
    return 0
    
end

/**
 * Get idle worker icon (x,y) in linear array.
 * These coords are multiplied by 80.
 */
function CommanderUI_GetIdleWorkerOffset()
    
    if Client.GetLocalPlayer():isa("AlienCommander") then
        return {4, 3}
    end
    
    return {2, 0}
    
end

/**
 * Indicates that user clicked on the idle worker
 */
function CommanderUI_ClickedIdleWorker()
    
    Client.ConsoleCommand("gotoidleworker")
    
end
