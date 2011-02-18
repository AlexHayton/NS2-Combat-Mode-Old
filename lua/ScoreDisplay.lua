//=============================================================================
//
// lua/ScoreDisplay.lua
// 
// Created by Henry Kropf
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

local pendingScore = 0
local pendingRank = 0


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

/**
 * Gets current rank variable, returns it and sets var to 0
 */
function ScoreDisplayUI_GetNewRank()
    local tempRank = pendingRank
    pendingRank = 0
    
    return tempRank
end


/**
 * Called to set latest score
 */
function ScoreDisplayUI_SetNewRank(rank)
    pendingRank = rank
end