//=============================================================================
//
// lua/Commander_ResourcePanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2010, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Get total # of team harvesters
 */
local harvesterCount = 0
function CommanderUI_GetTeamHarvesterCount()
    return harvesterCount
end

/**
 * Indicates user clicked on the harvester count
 */
function CommanderUI_ClickedTeamHarvesterCount()
end

function CommanderUI_SetTeamHarvesterCount(count)
    harvesterCount = count
end
