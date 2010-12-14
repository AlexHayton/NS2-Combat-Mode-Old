// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayingTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Team.lua")

class 'SpectatingTeam' (Team)

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 */
function SpectatingTeam:ReplaceRespawnPlayer(player, origin, angles)
    
    local spectatorPlayer = player:Replace(Spectator.kMapName)
   
    return true, spectatorPlayer

end
