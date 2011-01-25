// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Selection.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Shared code that handles selection.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Commander:SetDefaultSelection()

    // Select nearest command structure so new player knows what to do.
    self.selectedEntities = {}

    // Find nearest hive or command station and select it
    local commandStructures = GetEntitiesIsa("CommandStructure", -1)
    
    local nearestCommandStructure = nil
    local nearestCommandStructureDistance = 0
    
    for index, currentStructure in pairs(commandStructures) do
    
        local distance = (currentStructure:GetOrigin() - self:GetOrigin()):GetLength()
        if(nearestCommandStructure == nil or distance < nearestCommandStructureDistance) then
        
            nearestCommandStructure = currentStructure
            nearestCommandStructureDistance = distance
            
        end
        
    end
    
    if(nearestCommandStructure ~= nil) then
        
        table.insertunique(self.selectedEntities, {nearestCommandStructure:GetId(), Shared.GetTime()} )
        self:OnSelectionChanged()
        
    end
    
end

// Set the menu from a list of entities (typically structures). Pass nil if none are selected.
// If more than one entity is passed in, only show build menu icons that they all share.
function Commander:OnSelectionChanged()
    if(Client) then
        self.menuTechId = kTechId.RootMenu
        self.createSelectionCircles = true
        self:UpdateSelectionCircles()
    else
        self:ProcessTechTreeAction(kTechId.RootMenu, nil, nil)
    end
    
    // Clear last hotkey group when we change selection so next time
    // we press the hotkey, we select instead of go to it    
    self.gotoHotKeyGroup = 0

end

function Commander:GetEntitiesBetweenVecs(potentialEntities, pickStartVec, pickEndVec, entityList)

    local minX = math.min(pickStartVec.x, pickEndVec.x)
    local minZ = math.min(pickStartVec.z, pickEndVec.z)
    
    local maxX = math.max(pickStartVec.x, pickEndVec.x)
    local maxZ = math.max(pickStartVec.z, pickEndVec.z)

    for index, entity in pairs(potentialEntities) do
    
        // Filter selection
        if( self:GetIsEntityValidForSelection(entity) ) then

            // Get normalized vector to entity
            local toEntity = entity:GetOrigin() - self:GetOrigin()
            toEntity:Normalize()
                       
            // It should be selected if this vector lies between the pick vectors
            if( ( minX < toEntity.x and minZ < toEntity.z ) and
                ( maxX > toEntity.x and maxZ > toEntity.z ) ) then
        
                // Insert entity along with current time for fading
                table.insertunique(entityList, {entity:GetId(), Shared.GetTime()} )
                //DebugLine(self:GetOrigin(), entity:GetOrigin(), 10, 0, 1, 0, 1)
            else
                //DebugLine(self:GetOrigin(), entity:GetOrigin(), 10, 1, 0, 0, 1)                
            end
            
        end
    
    end
    
end

// If selected entities include structures and non-structures, get rid of the structures (ala modern RTS')
function Commander:FilterOutStructures(selection)
    
    local foundStructure = false
    local foundNonStructure = false
    
    for index, entityPair in ipairs(selection) do
    
        local entity = Shared.GetEntity(entityPair[1])
        if(entity:isa("Structure")) then
            foundStructure = true
        else
            foundNonStructure = true
        end
    
    end
    
    if(foundStructure and foundNonStructure) then
    
        local toRemove = {}
        
        for index, entityPair in ipairs(selection) do
        
            local entity = Shared.GetEntity(entityPair[1])
            
            if(entity:isa("Structure")) then
            
                table.insertunique(toRemove, entityPair)

            end
        
        end
        
        for index, entityPair in ipairs(toRemove) do
        
            if(not table.removevalue(selection, entityPair)) then
                
                Print("Commander:FilterOutStructures(): Unable to remove entityPair (%s)", entity:GetClassName())
                    
            end
            
        end

    end

end

function Commander:SortSelection(newSelection)

    function sortSelection(entPair1, entPair2)
    
        // Sort by tech id
        local ent1 = Shared.GetEntity(entPair1[1])
        local ent2 = Shared.GetEntity(entPair2[1])
        
        if ent1 and ent2 then
        
            if ent1:GetTechId() ~= ent2:GetTechId() then
                return ent1:GetTechId() < ent2:GetTechId()
            else
                // Then sort by health
                return ent1:GetHealth() > ent2:GetHealth()
            end
            
        end
        
    end

    table.sort(newSelection, sortSelection)
    
end

// Input vectors are normalized world vectors emanating from player, representing a selection region where the marquee 
// existed (or they were created around the vector where the mouse was clicked for a single selction). 
// Pass 1 as selectone to select only one entity (click select)
function Commander:MarqueeSelectEntities(pickStartVec, pickEndVec)

    local newSelection = {}

    // Add more class names here to allow selection of other entity types
    local potentials = {}
    table.adduniquetable(GetEntitiesIsa("LiveScriptActor", -1), potentials)
    
    self:GetEntitiesBetweenVecs(potentials, pickStartVec, pickEndVec, newSelection)

    if(table.maxn(newSelection) > 1) then
    
        self:FilterOutStructures(newSelection)
        self:SortSelection(newSelection)
        
    end
    
    return self:InternalSetSelection(newSelection)
        
end

function Commander:InternalClickSelectEntities(pickVec)

    // Trace to the first entity we can select
    local trace = Shared.TraceRay(self:GetOrigin(), self:GetOrigin() + pickVec*1000, PhysicsMask.CommanderSelect, EntityFilterOne(self))
    
    if trace.entity ~= nil and self:GetIsEntityValidForSelection(trace.entity) then
    
        return {trace.entity}            
        
    end
    
    return nil

end

// Compares entities in each list and sees if they look the same to the user. Doesn't check selection times, only entity indices
function Commander:SelectionEntitiesEquivalent(entityList1, entityList2)

    local equivalent = false
    
    if (entityList1 == nil or entityList2 == nil) then
        return (entityList1 == entityList2)
    end
    
    if(table.maxn(entityList1) == table.maxn(entityList2)) then
    
        equivalent = true
    
        for index, entityPair in ipairs(entityList1) do
        
            if(entityPair[1] ~= entityList2[index][1]) then
            
                equivalent = false
                break
                
            end
        
        end
    
    end

    return equivalent
    
end

function Commander:GetUnitIdUnderCursor(pickVec)

    local ents = self:InternalClickSelectEntities(pickVec)
    
    if(ents ~= nil) then
        return ents[1]:GetId()
    end
    
    return Entity.invalidId

end

function Commander:ClickSelectEntities(pickVec)

    local newSelection = {}

    local clickEntities = self:InternalClickSelectEntities(pickVec)
    
    if(clickEntities ~= nil) then
        
        for index, entity in ipairs(clickEntities) do  
        
            table.insertunique(newSelection, {entity:GetId(), Shared.GetTime()} )
            
        end
        
    end
        
    return self:InternalSetSelection(newSelection)
    
end

// If control/crouch is pressed, select all units of this type on the screen
function Commander:ControlClickSelectEntities(pickVec, screenStartVec, screenEndVec)
    
    local newSelection = {}

    local clickEntities = self:InternalClickSelectEntities(pickVec)
    if(clickEntities ~= nil and table.count(clickEntities) > 0) then
    
        local clickEntity = clickEntities[1]
        
        if(clickEntity ~= nil) then

            // Select all units of this type on screen (represented by startVec and endVec).
            // TODO: Figure out what the behavior should be for squads
            local classname = clickEntity:GetClassName()
            if(classname ~= nil) then
            
                local potentials = {}
                table.addtable(GetEntitiesIsa(classname, -1), potentials)
                self:GetEntitiesBetweenVecs(potentials, screenStartVec, screenEndVec, newSelection)
                
            end
            
        end
        
    end
    
    return self:InternalSetSelection(newSelection)
    
end

function Commander:SelectAllPlayers()

    local selectionIds = {}
    
    local players = {}
    if Server then
        players = GetGamerules():GetPlayers(self:GetTeamNumber())
    else
        players = GetEntitiesIsa("Player", self:GetTeamNumber())
    end
    
    for index, player in ipairs(players) do
    
        if player:GetIsAlive() and not player:isa("Commander") then
        
            table.insert(selectionIds, player:GetId())
            
        end
        
    end
    
    if table.count(selectionIds) > 0 then
        self:SetSelection(selectionIds)
    end
    
end

// Convenience function that takes list of entity ids and converts to {entityId, timeSelected} pairs. 
// Tests and external code will want to use this instead of InternalSetSelection(). Can also take
// an entityId by itself.
function Commander:SetSelection(entsOrId)

    local time = Shared.GetTime()
    local pairTable = {}
    
    if (type(entsOrId) == "number") then

        table.insert( pairTable, {entsOrId, time} )
        
    elseif (type(entsOrId) == "table") then
    
        for index, entId in ipairs(entsOrId) do        
            table.insert( pairTable, {entId, time} )
        end
        
    else
        return false
    end

    return self:InternalSetSelection( pairTable )    
    
end

function Commander:GetNumSubGroups()

    local numSubGroups = 0
    
    if (self.selectedEntities ~= nil) then
    
        local prevTechId = nil

        // Count number of groups. Assumes selection is in order by tech id.
        for index, pair in ipairs(self.selectedEntities) do
        
            local ent = Shared.GetEntity(pair[1])
            
            if ent ~= nil and (prevTechId == nil or (ent:GetTechId() ~= prevTechId)) then
                prevTechId = ent:GetTechId()
                numSubGroups = numSubGroups + 1
            end
            
        end
        
    end
    
    return numSubGroups
    
end

function Commander:GetSelectedSubGroup()

    if (self.selectedEntities ~= nil) then
    
        local numTypes = self:GetNumSubGroups()
        local groupIndex = 1 + (self.focusGroupIndex % numTypes)
        
        if groupIndex > numTypes then
            Print("Commander:GetSelectedSubGroup(): groupIndex %d, but only %d selectedEntityTypes", groupIndex, table.count(selectedEntityTypes))
        else
    
            // Now build list of ents
            local subGroupEnts = {}            
            local numTypes = 0
            local prevTechId = nil

            // Assumes selection is in order by tech id
            for index, pair in ipairs(self.selectedEntities) do
            
                local ent = Shared.GetEntity(pair[1])
                
                if ent then
                
                    if (prevTechId == nil or (ent:GetTechId() ~= prevTechId)) then
                    
                        prevTechId = ent:GetTechId()
                        numTypes = numTypes + 1
                        
                    end
                    
                    // Insert entity if in this subgroup
                    if groupIndex == numTypes then
                    
                        table.insert(subGroupEnts, ent)
                        
                    end
                    
                end
                
            end
            
            return subGroupEnts
            
        end
        
    end
    
    return {}
    
end

// Takes table of {entityId, timeSelected} pairs. Calls OnSelectionChanged() if it does. Doesn't allow setting
// selection to empty unless allowEmpty is passed. Returns true if selection is different after calling.
function Commander:InternalSetSelection(newSelection, allowEmpty)

    if (table.maxn(newSelection) > 0 or allowEmpty) then
    
        // Reset sub group
        self.focusGroupIndex = 1
    
        if not self:SelectionEntitiesEquivalent(newSelection, self.selectedEntities) then
        
            self.selectedEntities = newSelection
            self.selectedSubGroupEntities = self:GetSelectedSubGroup()
            self:OnSelectionChanged()
            return true
            
        end
        
    end
    
    return false
    
end

// Returns table of sorted selected entities 
function Commander:GetSelection()

    local selected = {}
    
    if (self.selectedEntities ~= nil) then
    
        for index, pair in ipairs(self.selectedEntities) do
            table.insert(selected, pair[1])
        end
        
    end
    
    return selected
    
end

function Commander:GetIsSelected(entityId, debug)

    for index, pair in ipairs(self.selectedEntities) do
    
        if(pair[1] == entityId) then
        
            return true
            
        end
        
    end
    
    return false
    
end

// selectedEntities is a list of {entityId, timeSelected} pairs
function Commander:ClearSelection()
    return self:InternalSetSelection({}, true)    
end

function Commander:GetIsEntityValidForSelection(entity)
            // Select living things on our team that aren't us
            // For now, don't allow even click selection of enemy units or structures
    return ( entity ~= nil and entity:isa("LiveScriptActor") and (entity:GetTeamNumber() == self:GetTeamNumber()) and (entity:GetIsSelectable()) and (entity ~= self) and entity:GetIsAlive() ) or
            // ...and doors
            (entity ~= nil and entity:isa("Door")) or
            // ...and power points
            (entity ~= nil and entity:isa("PowerPoint")) 
end

function Commander:UpdateSelection(deltaTime)

    /*local entPairsToDelete = {}
    
    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        if( not self:GetIsEntityValidForSelection(entity) ) then
        
            table.insert(entPairsToDelete, entityPair)
        
        end        
    
    end
    
    for index, entityPair in ipairs(entPairsToDelete) do
        table.removevalue(self.selectedEntities, entityPair)
    end*/
    
    // Recompute our sub-group
    self.selectedSubGroupEntities = self:GetSelectedSubGroup()

end

function Commander:GetIsEntitySelected(entity)

    for index, entityPair in pairs(self.selectedEntities) do

        local selectedEntity = Shared.GetEntity(entityPair[1])
        if(selectedEntity ~= nil and entity:GetId() == selectedEntity:GetId()) then
        
            return true
            
        end
        
    end
    
    return false

end


function Commander:GetIsEntityInSelectedSubGroup(entity)
    return (table.find(self.selectedSubGroupEntities, entity) ~= nil)
end

// Returns true if hotkey exists and was selected
function Commander:SelectHotkeyGroup(number)

    if (number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        if (table.count(self.hotkeyGroups[number]) > 0) then
        
            local selection = {}
            
            for i = 1, table.count(self.hotkeyGroups[number]) do
            
                table.insert(selection, self.hotkeyGroups[number][i])
                
            end
            
            local success = self:SetSelection(selection)
            
            self.gotoHotKeyGroup = number
            
            return success
            
        end
        
    end
    
    return false
    
end

function Commander:GotoHotkeyGroup(number, position)

    if (number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        if (table.count(self.hotkeyGroups[number]) > 0) then
        
            // Goto first unit in group
            local entityId = self.hotkeyGroups[number][1]
            local entity = Shared.GetEntity(entityId)
            
            VectorCopy(entity:GetOrigin(), position)

            // Add in extra x offset to center view where we're told, not ourselves            
            position.x = position.x - Commander.kViewOffsetXHeight
            
        end
        
    end 
           
end