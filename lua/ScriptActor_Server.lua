// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ScriptActor:SetOwner(player)

    local success = false
    
    if player ~= nil and self.ownerServerClient ~= nil then
        Shared.Message("Warning: A ScriptActor cannot have more than one owner!")
        return false
    end
    
    if player == nil then
        if self.ownerServerClient and self.ownerServerClient:GetControllingPlayer() then
            self.ownerServerClient:GetControllingPlayer():SetIsOwner(self, false)
        end
        self.ownerServerClient = nil
        success = true
    elseif player:isa("Player") then
        self.ownerServerClient = player:GetClient()
        player:SetIsOwner(self, true)
        success = true
    else
        Print("%s:SetOwner(): Must be called with a Player (not a %s)", self:GetClassName(), player:GetClassName())
    end
    
    return success
    
end

/**
 * Sets whether the ScriptActor is or isn't the owner of the passed in entity.
 * This is needed for proper destruction.
 */
function ScriptActor:SetIsOwner(ofEntity, isOwner)

    if isOwner then
        table.insertunique(self.ownedEntities, ofEntity)
    else
        table.removevalue(self.ownedEntities, ofEntity)
    end

end

function ScriptActor:GetOwner()

    if self.ownerServerClient ~= nil then
    
        return self.ownerServerClient:GetControllingPlayer()
        
    end
    
    return nil
    
end

function ScriptActor:AddScoreForOwner(score)

    local owner = self:GetOwner()
    if owner and (self:GetTeamNumber() == owner:GetTeamNumber()) and owner:isa("Player") and score > 0 then
        owner:AddScore(score)
    end

end

// Pass newId of object is turning into or 0/nil if it's being deleted. Called by Actor:OnDestroy() and Player:Replace(). 
// Called both on Client and Server.
function ScriptActor:SendEntityChanged(newId)

    // Process entity change server-side
    if Server then
    
        GetGamerules():OnEntityChange(self:GetId(), newId)
    
        local ents = GetGamerules():GetAllScriptActors()
        
        // Tell every ScriptActor we've changed ids been deleted (changed to nil)
        for index, ent in ipairs(ents) do
       
            if ent ~= self then
            
                ent:OnEntityChange(self:GetId(), newId)

            end
            
        end
        
    end
    
    if Server then
    
        // Send message to everyone that the player changed ids
        Server.SendNetworkMessage("EntityChanged", BuildEntityChangedMessage(self:GetId(), ConditionalValue(newId ~= nil, newId, -1)), true)
        
    end
    
end

function ScriptActor:OnKill(damage, attacker, doer, point, direction)

    // Remove links between objects on death
    self:ClearAttached()

end

function ScriptActor:ClearAttached()

    // Call attached entity's ClearAttached function
    local entity = Shared.GetEntity(self.attachedId)
    if entity ~= nil then

        // Set first so we don't call infinitely
        self.attachedId = Entity.invalidId    
        
        if entity:isa("ScriptActor") then
            entity:ClearAttached()
        end
        
    end
    
end


// All team changes are routed through here. Never set teamNumber directly.
function ScriptActor:SetTeamNumber(teamNumber)

    // Team number will be nil when called from OnCreate()
    if(teamNumber ~= self.teamNumber) then
    
        self:OnTeamChange(teamNumber)
        
    end
    
    // This is the only place teamNumber should ever be set
    self.teamNumber = teamNumber
    
end

function ScriptActor:OnDestroy()
    
    // Remove all owned entities.
    function RemoveOwnedEntityFunctor(entity)
        entity:SetOwner(nil)
    end
    table.foreachfunctor(self.ownedEntities, RemoveOwnedEntityFunctor)
    table.clear(self.ownedEntities)
    
    // Notify the owner of this ScriptActor it is no longer the owner.
    if self:GetOwner() then
        self:GetOwner():SetIsOwner(self, false)
    end
    
    // Notify others of the change 
    self:SendEntityChanged(nil)
    
    Actor.OnDestroy(self)
    
end

function ScriptActor:GetTeam()
    return GetGamerules():GetTeam(self:GetTeamNumber())    
end

// Used to react to team changes.
// Called whenever SetTeamNumber() is called with a new team number. Normally called after
// entity spawned, but is called after OnCreate() and before OnInit() during CreateEntity().
// The entity will have the newTeamNumber after set after OnTeamChange() is called.
// Current team number could be nil. 
function ScriptActor:OnTeamChange(newTeamNumber)

    self.teamType = kNeutralTeamType
    
    if(newTeamNumber == 1) then
        self.teamType = kTeam1Type
    elseif(newTeamNumber == 2) then
        self.teamType = kTeam2Type
    end
    
end

// Returns true if entity should be propagated to player
function ScriptActor:OnGetIsRelevant(player)
    return GetGamerules():GetIsRelevant(player, self)   
end

function ScriptActor:GetIsTargetValid(target)
    return target ~= self and target ~= nil
end

// Return valid taret within attack distance, if any
function ScriptActor:FindTarget(attackDistance)

    // Find enemy in range
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local potentialTargets = GetGamerules():GetEntities("LiveScriptActor", enemyTeamNumber, self:GetOrigin(), attackDistance)
    
    local nearestTarget = nil
    local nearestTargetDistance = 0
    
    // Get closest target
    for index, currentTarget in ipairs(potentialTargets) do
    
        if(self:GetIsTargetValid(currentTarget)) then
        
            local distance = self:GetDistance(currentTarget)
            if(nearestTarget == nil or distance < nearestTargetDistance) then
            
                nearestTarget = currentTarget
                nearestTargetDistance = distance
                
            end    
            
        end
        
    end

    return nearestTarget    
    
end

// Called when tech tree activation performed on entity. Return true if legal and action handled.
function ScriptActor:PerformActivation(techId, position, normal, commander)
    return false
end

// Called when tech tree action performed on entity. Return true if legal and action handled. Position passed if applicable.
function ScriptActor:PerformAction(techNode, position)
    return false
end

// Return true for first param if entity handles this action. Only technodes that specified by
// the entities techbuttons will be allowed to call this function. Orientation is in radians and is
// specified by commander when giving order.
function ScriptActor:OverrideTechTreeAction(techNode, position, orientation, commander)
    return false, true
end

function ScriptActor:OverrideOrder(order)
end

function ScriptActor:SetOrder(order, clearExisting, insertFirst)
end

// A structure can be attached to another structure (ie, resource tower to resource nozzle)
function ScriptActor:SetAttached(structure)
    
    if(structure ~= nil) then
    
        // Because they'll call SetAttached back on us
        if structure:GetId() ~= self.attachedId then
        
            self:ClearAttached()
            self.attachedId = structure:GetId()            
            structure:SetAngles(self:GetAngles()) 
            
            structure:SetAttached(self)
            
        end
        
    else
    
        self.attachedId = Entity.invalidId
        
    end

end

function ScriptActor:OnResearchComplete(structure, researchId)
end

function ScriptActor:SetLocationName(locationName, silent)

    local success = false
    
    self.locationId = Shared.GetStringIndex(locationName)
    
    if self.locationId ~= 0 then
        success = true
    elseif not silent then
        Print("%s:SetLocationName(%s): String not precached.", self:GetClassName(), ToString(locationName))
    end
    
    return success
    
end

// Called after all entities are loaded. Put code in here that depends on other entities being loaded.
function ScriptActor:OnMapPostLoad()
    self:ComputeLocation()
end
