// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Entity.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * Iterator over entities in the world of a specific class. This is used
 * similarly to the built-in Lua ipairs function.
 */
function ientities(className)
    return Shared.FindEntityWithClassname, className, nil
end

function EntityToString(entity)

    if (entity == nil) then
        return "nil"
    elseif (type(entity) == "number") then
        string.format("EntityToString(): Parameter is a number (%s) instead of entity ", tostring(entity))
    elseif (entity:isa("Entity")) then
        return entity:GetClassName()
    end
    
    return string.format("EntityToString(): Parameter isn't an entity but %s instead", tostring(entity))
    
end

// Pass team number or -1 or nil to ignore team number.
// Don't call often, it's relatively slow. Compute the results 
// once per frame and store them if needed.
function GetEntitiesIsa(isaName, teamNumber, silent)

    PROFILE("GetEntitiesIsa")
    
    //if not silent then
    //    Print("GetEntitiesIsa(%s) - %.2f", isaName, Shared.GetTime())
    //end
    
    local entities = {}

    local startEntity = nil
    local currentEntity = nil
    
    repeat
        
        currentEntity = Shared.FindNextEntity(startEntity)
        if(currentEntity and currentEntity:isa(isaName)) then
            if(teamNumber == nil or teamNumber == -1) or (currentEntity:isa("ScriptActor") and (teamNumber == currentEntity:GetTeamNumber())) then
                table.insert(entities, currentEntity)
            end
        end
        
        startEntity = currentEntity
        
    until currentEntity == nil

    return entities
    
end

function GetEntitiesInViewFunctor(player, functor)

    local entities = {}

    local startEntity = nil
    local currentEntity = nil
    
    repeat
        
        currentEntity = Shared.FindNextEntity(startEntity)
        
        if currentEntity and currentEntity:isa("ScriptActor") then
        
            if(functor(currentEntity)) then
            
                if(player:GetCanSeeEntity(currentEntity)) then
                
                    table.insert(entities, currentEntity)
                    
                end
                
            end
            
        end
        
        startEntity = currentEntity
        
    until currentEntity == nil

    return entities
    
end

function GetNearbyGameEntitiesInView(player, radius)

    function teamEntityNearby(entity)
    
        if(entity:isa("ScriptActor")) then
        
            local dist = player:GetDistance(entity)
            
            if(dist < radius) then
            
                return true
                
            end
            
        end
        
        return false
        
    end
    
    return GetEntitiesInViewFunctor(player, teamEntityNearby)
    
end

// Get entities of a class name, but use functor to determine if we should return them
function GetEntitiesIsaFunctor(isaName, functor)

    //Print("GetEntitiesIsaFunctor(%s) - %.2f", isaName, Shared.GetTime())

    local entities = {}

    local startEntity = nil
    local currentEntity = nil
    
    repeat
        
        currentEntity = Shared.FindNextEntity(startEntity)
        
        if(currentEntity and currentEntity:isa(isaName)) then
        
            if(functor(currentEntity)) then
                table.insert(entities, currentEntity)
            end
            
        end
        
        startEntity = currentEntity
        
    until currentEntity == nil

    return entities
    
end

/**
 * Returns list of entities that are in the isaNames table of class names.
 * Pass -1 for teamNumber if you want to ignore.
 */
function GetEntitiesIsaMultiple(isaNames, teamNumber)

    //Print("GetEntitiesIsaFunctor - %.2f", Shared.GetTime())

    local entities = {}

    local startEntity = nil
    local currentEntity = nil
    
    repeat
        
        currentEntity = Shared.FindNextEntity(startEntity)
        
        if(currentEntity ~= nil) then
        
            for index, isaName in ipairs(isaNames) do
                
                if(teamNumber == nil or teamNumber == -1) or (currentEntity:isa("ScriptActor") and teamNumber == currentEntity:GetTeamNumber()) then
                
                    if(currentEntity:isa(isaName)) then
                    
                        table.insert(entities, currentEntity)  
                  
                        break
                    
                    end
                    
                end
                
            end
            
        end
        
        startEntity = currentEntity
        
    until currentEntity == nil

    return entities

end

function GetEntitiesWithName(targetName)

    local entities = {}
    local startEntity = nil
    local currentEntity = nil
    
    if(targetName ~= nil) then
    
        repeat
            
            currentEntity = Shared.FindNextEntity(startEntity)
            if(currentEntity and (currentEntity.targetname == targetName)) then
                table.insert(entities, currentEntity)
            end
            
            startEntity = currentEntity
            
        until currentEntity == nil
        
    end
    
    return entities

end

function GetFirstEntityId(targetName)

    local entityId = -1
    local entities = GetEntitiesWithName(targetName)
    
    if(table.maxn(entities) > 0) then
        entityId = entities[1]:GetId()
    end
    
    return entityId
    
end

/** 
 * Returns entities that are derived from specified class-name, on specified team and within 
 * radius of origin. Pass -1 for team to not filter on team. Pass checkXZOnly as true to 
 * check XZ (top-down) distance.
 */
function GetEntitiesIsaInRadius(className, teamNumber, origin, radius, checkXZOnly, visibleOnly, log)

    //Print("GetEntitiesIsaInRadius(%s) - %.2f", className, Shared.GetTime())

    local entities = GetEntitiesIsa(className, teamNumber)
    
    local returnEntities = {}
    
    for index, current in ipairs(entities) do
    
        if (teamNumber == -1 or (current:isa("ScriptActor") and (current:GetTeamNumber() == teamNumber))) then
        
            local currentOrigin = current:GetOrigin()
            local diff = currentOrigin - origin
            local distance = ConditionalValue(checkXZOnly, diff:GetLengthXZ(), diff:GetLength())
            
            if(distance <= radius) then
            
                if not visibleOnly or current:GetIsVisible() then
                
                    if log then
                        Print("GetEntitiesIsaInRadius(%s, %d, %s, %.2f, %s, %s) - Inserting %s (visible: %s)", 
                            className, teamNumber, origin:tostring(), radius, tostring(checkXZOnly), tostring(visibleOnly), current:GetClassName(), tostring(current:GetIsVisible()) )
                    end
                    
                    table.insert(returnEntities, current)
                    
                end
                
            end
            
        end            
        
    end
    
    return returnEntities
        
end

// Fades damage linearly from center point to radius (0 at far end of radius)
function RadiusDamage(entities, centerOrigin, radius, fullDamage, attacker)

    // Do damage to every target in range
    for index, target in ipairs(entities) do
    
        local damageDirection = target:GetOrigin() - centerOrigin
        damageDirection:Normalize()
        
        // Damage falloff
        local distanceFromTarget = (centerOrigin - target:GetOrigin()):GetLength()
        local damageScalar = 1 - math.min(math.max(0, distanceFromTarget/radius), 1)
        local damage = fullDamage*damageScalar
        
        // Trace line to each target to make sure it's not blocked by a wall 
        local targetOrigin = target:GetModelOrigin()
        if target.GetEngagementPoint then
            targetOrigin = target:GetEngagementPoint()
        end
        
        if not GetWallBetween(centerOrigin, targetOrigin, attacker) then
        
            target:TakeDamage(damage, attacker, attacker, target:GetOrigin(), damageDirection)

        end
        
    end
    
end

/**
 * Get list of child entities for player. Pass optional class name
 * to get only entities of that type. Don't call often, it's
 * relatively slow. Get the results every frame and store them if
 * needed.
 */
function GetChildEntities(player, isaClassName)

    local childEntities = {}
    local currentEntity = player:FindChildEntity(nil)
    
    while(currentEntity ~= nil) do

        if(isaClassName == nil or currentEntity:isa(isaClassName)) then
            table.insert(childEntities, currentEntity)
        end
        
        currentEntity = player:FindChildEntity(currentEntity)
        
    end   
    
    return childEntities

end

// Return entity number or -1 if not found
function FindNearestEntityId(className, location)

    local entityId = -1
    local shortestDistance = nil
    
    local entities = GetEntitiesIsa(className)    
    
    for index, current in ipairs(entities) do

        local distance = (current:GetOrigin() - location):GetLength()
        
        if(shortestDistance == nil or distance < shortestDistance) then
        
            entityId = current:GetId()
            shortestDistance = distance
            
        end
            
    end    
    
    return entityId
    
end

/**
 * Given a list of entities (representing spawn points), returns a randomly chosen
 * one which is unobstructed for the player. If none of them are unobstructed, the
 * method returns nil.
 */
function GetRandomClearSpawnPoint(player, spawnPoints)

    local numSpawnPoints = table.maxn(spawnPoints)
    
    // Start with random spawn point then move up from there
    local baseSpawnIndex = NetworkRandomInt(1, numSpawnPoints)

    for i = 1, numSpawnPoints do

        local spawnPointIndex = ((baseSpawnIndex + i) % numSpawnPoints) + 1
        local spawnPoint = spawnPoints[spawnPointIndex]

        // Check to see if the spot is clear to spawn the player.
        local spawnOrigin = Vector(spawnPoint:GetOrigin())
        local spawnAngles = Angles(spawnPoint:GetAngles())
        spawnOrigin.y = spawnOrigin.y + .5
        
        spawnAngles.pitch = 0
        spawnAngles.roll  = 0
        
        player:SpaceClearForEntity(spawnOrigin)
        
        return spawnPoint
            
    end
    
    Print("GetRandomClearSpawnPoint - No unobstructed spawn point to spawn %s (tried %d)", player:GetName(), numSpawnPoints)
    
    return nil

end

// Look for unoccupied spawn point nearest given position
function GetClearSpawnPointNearest(player, spawnPoints, position)

    // Build sorted list of spawns, closest to farthest
    local sortedSpawnPoints = {}
    table.copy(spawnPoints, sortedSpawnPoints)
    
    // The comparison function must return a boolean value specifying whether the first argument should 
    // be before the second argument in the sequence (he default behavior is <).
    function sort(spawn1, spawn2)
        return (spawn1:GetOrigin() - position):GetLength() < (spawn2:GetOrigin() - position):GetLength()
    end    
    table.sort(sortedSpawnPoints, sort)

    // Build list of spawns in 
    for i = 1, table.maxn(sortedSpawnPoints) do 

        // Check to see if the spot is clear to spawn the player.
        local spawnPoint = sortedSpawnPoints[i]
        local spawnOrigin = Vector(spawnPoint:GetOrigin())

        if (player:SpaceClearForEntity(spawnOrigin)) then
        
            return spawnPoint
            
        end
        
    end
    
    Print("GetClearSpawnPointNearest - No unobstructed spawn point to spawn " , player:GetName())
    
    return nil

end