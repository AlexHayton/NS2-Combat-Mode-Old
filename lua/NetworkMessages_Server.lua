// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NetworkMessages_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// See the Messages section of the Networking docs in Spark Engine scripting docs for details.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandCommMarqueeSelect(client, message)
    
    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:MarqueeSelectEntities(ParseCommMarqueeSelectMessage(message))
        
    end
    
end

function OnCommandCommClickSelect(client, message)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:ClickSelectEntities(ParseCommClickSelectMessage(message))
        
    end

end

function OnCommandCommControlClickSelect(client, message)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:ControlClickSelectEntities(ParseControlClickSelectMessage(message))
        
    end

end

function OnCommandCommAction(client, message)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:ProcessTechTreeAction(ParseCommActionMessage(message), nil, nil)
        
    end
    
end

function OnCommandCommTargetedAction(client, message)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        local techId, pickVec, orientation = ParseCommTargetedActionMessage(message)
        player:ProcessTechTreeAction(techId, pickVec, orientation)
    
    end
    
end

function OnCommandCommTargetedActionWorld(client, message)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        local techId, pickVec, orientation = ParseCommTargetedActionMessage(message)
        player:ProcessTechTreeAction(techId, pickVec, orientation, true)
    
    end
    
end

Server.HookNetworkMessage("MarqueeSelect",              OnCommandCommMarqueeSelect)
Server.HookNetworkMessage("ClickSelect",                OnCommandCommClickSelect)
Server.HookNetworkMessage("ControlClickSelect",         OnCommandCommControlClickSelect)
Server.HookNetworkMessage("CommAction",                 OnCommandCommAction)
Server.HookNetworkMessage("CommTargetedAction",         OnCommandCommTargetedAction)
Server.HookNetworkMessage("CommTargetedActionWorld",    OnCommandCommTargetedActionWorld)

