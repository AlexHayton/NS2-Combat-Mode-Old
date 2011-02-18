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

    if not infestation:GetConnectedToHive() then
    
        infestation:SetConnectedToHive(true)
        
        for index, connectedInfestation in ipairs(infestation:GetConnections()) do
        
            SetAsConnected(connectedInfestation)
            
        end
        
    end
    
end

function UpdateInfestationConnections(infestations)

    for index, infestation in ipairs(infestations) do        
    
        // Not connected to hive
        infestation:SetConnectedToHive(false)
    
        // Update connections
        local connections = {}
        
        for index, infestation2 in ipairs(infestations) do        
        
            if infestation ~= infestation2 then
            
                local dist = infestation:GetOrigin():GetDistanceTo(infestation2:GetOrigin())

                local connected = (dist < (infestation:GetRadius() + infestation2:GetRadius()))
                if connected then
                
                    table.insert(connections, infestation2)
                    
                end
                
            end    
            
        end
        
        infestation:SetConnections(connections)
        
    end
    
    // Reconnect them according to how close they are
    for index, infestation in ipairs(infestations) do
    
        // Recursively set nodes as connected
        if infestation:GetGeneratorState() then
        
            SetAsConnected(infestation)
            
        end

    end
    
    local totalConnected = 0
    for index, infestation in ipairs(infestations) do
        if infestation:GetConnectedToHive() then
            totalConnected = totalConnected + 1
        end
    end
    
end

function UpdateInfestation(teamNumber)

    // Get all infestation nodes
    local infestations = GetGamerules():GetEntities("Infestation", teamNumber)
    
    UpdateInfestationConnections(infestations)
    
end

// Clear OnInfestation game effect mask on all entities, unless they are standing on infestation
function UpdateInfestationMask(liveScriptActorList)

    // Use all infestation entities, regardless of team number
    local infestations = GetGamerules():GetEntities("Infestation")

    for entIndex, entity in ipairs(liveScriptActorList) do
    
        local onInfestation = false
        local entOrigin = entity:GetOrigin()            
        
        // See if entity is on infestation
        for infestationIndex, infestation in ipairs(infestations) do
        
            if infestation:GetIsPointOnInfestation(entOrigin) then
            
                onInfestation = true
                break
                
            end
            
        end
        
        // Set the mask
        if entity.GetGameEffectMask and (entity:GetGameEffectMask(kGameEffect.OnInfestation) ~= onInfestation) then
            entity:SetGameEffectMask(kGameEffect.OnInfestation, onInfestation)
        end
        
    end
        
end



