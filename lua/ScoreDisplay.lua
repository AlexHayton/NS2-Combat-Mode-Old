//=============================================================================
//
// lua/ScoreDisplay.lua
// 
// Created by Henry Kropf
// Copyright 2010, Unknown Worlds Entertainment
//
//=============================================================================

local pendingScore = 0



/**
 * Gets current score variable, returns it and sets var to 0
 */
function ScoreDisplayUI_GetNewScore()
    local tempScore = pendingScore
    pendingScore = 0
    
    return tempScore
end


/**
 * Called to set latest score
 */
function ScoreDisplayUI_SetNewScore(score)
    pendingScore = score
end
