// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfestationManager.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Manages relationship between infestation entities and hives. Grows and shrinks infestation 
// accordingly.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


function SetAsConnected(infestation)

    PROFILE("InfestationManager:SetAsConnected")
    
    if not infestation:GetConnectedToHive() then
    
        infestation:SetConnectedToHive(true)
        
        for peer, _ in pairs(infestation:GetConnections()) do
        
            SetAsConnected(peer)
            
        end
        
    end
    
end

function UpdateInfestationConnections(infestations)

    PROFILE("InfestationManager:UpdateInfestationConnections")
    
    // Reconnect them according to how close they are
    for index, infestation in ipairs(infestations) do        
    
        // Not connected to hive
        infestation:SetConnectedToHive(false)
        
        infestation.connections = Server.infestationMap:GetConnections(infestation)
        
    end
    
    // run through all connections and make sure that they connect to each other properly
    //  (the 20m connections need to be reverse connected)
    for index, infestation in ipairs(infestations) do
        for peer, _ in pairs(infestation.connections) do
            peer.connections[infestation] = true
        end
    end

    for index, infestation in ipairs(infestations) do
    
        // Recursively set nodes as connected
        if infestation:GetGeneratorState() then
        
            SetAsConnected(infestation)
            
        end

    end
    
end

function UpdateInfestation(teamNumber)

    PROFILE("InfestationManager:UpdateInfestation")
    
    // Get all infestation nodes
    local infestations = GetEntitiesForTeam("Infestation", teamNumber)
    
    UpdateInfestationConnections(infestations)
    
end

function UpdateInfestationMasks(entityList)

    PROFILE("InfestationManager:UpdateInfestationMasks")

    for index, entity in ientitylist(entityList) do
        // Don't do this for infestations.
        if not entity:isa("Infestation") then
            UpdateInfestationMask(entity)
        end
    end
    
end

// Clear OnInfestation game effect mask on all entities, unless they are standing on infestation
function UpdateInfestationMask(forEntity)
    
    // See if entity is on infestation.
    local onInfestation = Server.infestationMap:GetIsOnInfestation(forEntity:GetOrigin())

    // Set the mask
    if forEntity.GetGameEffectMask and (forEntity:GetGameEffectMask(kGameEffect.OnInfestation) ~= onInfestation) then
        forEntity:SetGameEffectMask(kGameEffect.OnInfestation, onInfestation)
    end
        
end



