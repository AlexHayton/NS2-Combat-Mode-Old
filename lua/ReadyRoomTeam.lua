// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ReadyRoomTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for the team that is for players that are in the ready room.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Team.lua")

class 'ReadyRoomTeam' (Team)

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 */
function ReadyRoomTeam:ReplaceRespawnPlayer(player, origin, angles)

    local mapName = player.kMapName
    
    // no Spectator model, Embryo can't move, and Marine class doesn't play well with Player.InitWeapons(newPlayer)
    if (mapName == Spectator.kMapName) or (mapName == Marine.kMapName) or (mapName == Embryo.kMapName) then 
        mapName = Player.kMapName
    end
    
    local newPlayer = player:Replace(mapName, self:GetTeamNumber(), false)
    
    //still allow embryos to show.
    if(mapName == Embryo.kMapName) then
        newPlayer:SetModel(Embryo.kModelName)
    end
    
    // clear out weapons
    Player.InitWeapons(newPlayer)
    
    self:RespawnPlayer(newPlayer, origin, angles)

    newPlayer:ClearGameEffects()
    
    return (newPlayer ~= nil), newPlayer
    
end

function ReadyRoomTeam:GetSupportsOrders()
    return false
end