// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Commander:CopyPlayerDataFrom(player)

    Player.CopyPlayerDataFrom(self, player)

    self.gameStarted = player.gameStarted
    self.countingDown = player.countingDown
    self.frozen = player.frozen
    self.alive = player.alive
    
    self.health = player.health
    self.maxHealth = player.maxHealth

    local commanderStartOrigin = Vector(player:GetOrigin())
    commanderStartOrigin.y = commanderStartOrigin.y + 5    
    self:SetOrigin(commanderStartOrigin)
    
    self:SetVelocity(Vector(0, 0, 0))

    // For knowing how to create the player class when leaving commander mode
    self.previousMapName = player:GetMapName()
    
    // Save previous weapon name so we can switch back to it when we logout
    self.previousWeaponMapName = ""
    local activeWeapon = player:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        self.previousWeaponMapName = activeWeapon:GetMapName()
    end        
    
    self.previousHealth = player:GetHealth()
    self.previousArmor = player:GetArmor()
    
    self.previousAngles = Angles(player:GetAngles())
end

// Returns nearest unattached entity of specified classtype within radius of position (nil otherwise)
function GetUnattachedEntityWithinRadius(attachclass, position, radius)

    local nearestDistance = 0
    local nearestEntity = nil
    
    local entities = GetEntitiesIsa(attachclass)
    
    for index, current in ipairs(entities) do
    
        local currentOrigin = Vector()
        VectorCopy(current:GetOrigin(), currentOrigin)
        
        if(current:GetAttached() == nil) then
            
            local distance = (position - currentOrigin):GetLength()
            
            if ( (distance <= radius) and ( (nearestEntity == nil) or ( distance < nearestDistance) ) ) then
                
                nearestEntity = current
                nearestDistance = distance
                
            end
        
        end
    
    end
    
    return nearestEntity
    
end

function Commander:TakeDamage(damage, attacker, doer, point, direction)
    // Do nothing, can't take damage
end

function Commander:AttemptToResearchOrUpgrade(techNode, force)

    // Make sure we have a valid and available structure selected
    if (table.maxn(self.selectedSubGroupEntities) == 1 or force) then
    
        local entity = self.selectedSubGroupEntities[1]
        
        // Don't allow it to be researched while researching
        if( (entity ~= nil and entity:isa("Structure") and entity:GetCanResearch() and techNode:GetCanResearch()) or force) then
        
            entity:SetResearching(techNode, self)
            entity:OnResearch(techNode:GetTechId())
            
            if not techNode:GetIsUpgrade() and not techNode:GetIsEnergyBuild() then
                techNode:SetResearching()
            end
            
            self:GetTechTree():SetTechNodeChanged(techNode)
            
            return true
        
        end
        
    end    

    return false
    
end

// Returns true or false, as well as the entity id of the new structure (or -1 if false)
// pickVec optional (for AI units). In those cases, builderEntity will be the entity doing the building.
function Commander:AttemptToBuild(techId, origin, pickVec, buildTech, builderEntity)

    local legalBuildPosition = false
    local position = nil
    local attachEntity = nil

    if pickVec == nil then
    
        // When Drifters and MACs build, or untargeted build/buy actions, no pickVec. Trace from order point down to see
        // if they're trying to build on top of anything and if that's OK.
        local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), PhysicsMask.CommanderBuild, EntityFilterOne(builderEntity))
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, trace.endPoint, Commander.kStructureSnapRadius, self)

    else
    
        // Make sure entity is near enough to attach class if required (snap to it as well)
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, origin, snapRadius, self)
        
    end
    
    if legalBuildPosition then
    
        local newEnt = CreateEntityForCommander(techId, position, self)
        
        if newEnt ~= nil then
            
            newEnt:PlaySound(self:GetPlaceBuildingSound())
            
            // Play private version for commander too 
            Shared.PlayPrivateSound(self, self:GetPlaceBuildingSound(), nil, 1.0, self:GetOrigin())
            
            local replicateEffect = ConditionalValue(GetTechUpgradesFromTech(techId, kTechId.CommandStation), CommandStation.kMarineReplicateBigEffect, CommandStation.kMarineReplicateEffect)
            Shared.CreateEffect(nil, replicateEffect, newEnt, nil)
            
            if newEnt.GetPlaceBuildingEffect then
                Shared.CreateEffect(nil, newEnt:GetPlaceBuildingEffect(), newEnt)
            end
            
            return true, newEnt:GetId()
                        
        end
        
    end
    
    return false, -1
            
end

// TODO: Add parameters for energy, carbon or plasma
function Commander:TriggerNotEnoughResourcesAlert()

    local team = self:GetTeam()
    local alertType = ConditionalValue(team:GetTeamType() == kMarineTeamType, kTechId.MarineAlertNotEnoughResources, kTechId.AlienAlertNotEnoughResources)
    team:TriggerAlert(alertType, self)

end

// Return whether action should continue to be processed for the next selected unit. Position will be nil
// for non-targeted actions and will be the world position target for the action for targeted actions.
function Commander:ProcessTechTreeActionForEntity(techNode, position, pickVec, entity, force)

    local success = false
    local keepProcessing = true

    // First make sure tech is allowed for entity
    local techId = techNode:GetTechId()
    local techButtons = self:GetCurrentTechButtons(self.currentMenu, entity)
    
    if(techButtons == nil or table.find(techButtons, techId) == nil) then
        return success, keepProcessing
    end
    
    // Cost is in carbon, energy or plasma, depending on tech node type        
    local cost = LookupTechData(techId, kTechDataCostKey, 0)
    local team = self:GetTeam()
    
    // Let entities override actions themselves (eg, so buildbots can execute a move-build order instead of building structure immediately)
    success, keepProcessing = entity:OverrideTechTreeAction(techNode, position, nil, self)
    if(success) then
        return success, keepProcessing
    end        
    
    // Handle tech tree actions that cost carbon    
    if(techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsBuild() or techNode:GetIsEnergyBuild()) then

        local costsEnergy = techNode:GetIsEnergyBuild()

        local teamCarbon = team:GetCarbon()
        local energy = entity:GetEnergy()
        
        if (not costsEnergy and cost <= teamCarbon) or (costsEnergy and cost <= energy) then
        
            if(techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsEnergyBuild()) then
            
                success = self:AttemptToResearchOrUpgrade(techNode, force)
                if success then 
                    keepProcessing = false
                end
                                
            elseif(techNode:GetIsBuild()) then
            
                success = self:AttemptToBuild(techId, position, pickVec, false)
                if success then 
                    keepProcessing = false
                end
                
            end

            if success then 
            
                if costsEnergy then            
                    entity:SetEnergy(entity:GetEnergy() - cost)                
                else                
                    team:AddCarbon(-cost)                    
                end
                
                Shared.PlayPrivateSound(self, Commander.kSpendCarbonSoundName, nil, 1.0, self:GetOrigin())
                
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
                        
    // Handle plasma-based abilities
    elseif(techNode:GetIsAction() or techNode:GetIsBuy()) then
    
        local playerPlasma = self:GetPlasma()
        if(cost == nil or cost <= playerPlasma) then
        
            if(techNode:GetIsAction()) then
            
                success = entity:PerformAction(techNode, position)
                
            elseif(techNode:GetIsBuy()) then
            
                success = self:AttemptToBuild(techId, position, pickVec, false)
                
            end
            
            if(success and cost ~= nil) then
            
                self:AddPlasma(-cost)
                Shared.PlayPrivateSound(self, Commander.kSpendPlasmaSoundName, nil, 1.0, self:GetOrigin())
                
            end
            
        else
            self:TriggerNotEnoughResourcesAlert()
        end
    
    // Energy-based and misc. abilities        
    elseif(techNode:GetIsActivation()) then

        // Deduct energy cost if any 
        if(cost == 0 or cost <= entity:GetEnergy()) then
                    
            success = entity:PerformActivation(techId, position, self)
            
            if success then
            
                entity:AddEnergy(-cost)
                
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
        
    end
    
    return success, keepProcessing
    
end

function Commander:PerformCommanderTrace(normPickVec)

    local startPoint = self:GetOrigin()
    local trace = Shared.TraceRay(startPoint, startPoint + normPickVec * 1000, PhysicsMask.AllButPCs, EntityFilterOne(self))
    return trace
    
end

// Send techId of action and normalized pick vector. Issues order to selected units to the world position represented by
// the pick vector, or to the entity that it hits.
function Commander:OrderEntities(orderTechId, trace, orientation)

    local invalid = false
    
    local targetId = Entity.invalidId
    if(trace.entity ~= nil) then
        targetId = trace.entity:GetId()
    end
    
    if (trace.fraction < 1) then

        local orderEntities = {}
        table.copy(self.selectedSubGroupEntities, orderEntities)
        
        // Give order to ourselves for testing
        if GetGamerules():GetOrderSelf() then
            table.insert(orderEntities, self)
        end
        
        local orderTechIdGiven = orderTechId
        
        for tableIndex, entity in ipairs(orderEntities) do

            local type = entity:GiveOrder(orderTechId, targetId, trace.endPoint, orientation, not self.queuingOrders, false)
                            
            
            if(type == kTechId.None) then            
                invalid = true    
            end
                
        end
        
        self:OnOrderEntities(orderTechIdGiven, orderEntities)
        
    end

    if(invalid) then    
    
        // Play invalid sound once
        Shared.PlayPrivateSound(self, Player.kInvalidSound, nil, 1.0, self:GetOrigin())     
        
    end
    
end

function Commander:OnOrderEntities(orderTechId, orderEntities)

    // Get sound and play it locally for commander and every target player
    local soundName = LookupTechData(orderTechId, kTechDataOrderSound, nil)
    
    if soundName then

        // Play order sounds if we're ordering players only
        local playSound = false
        
        for index, entity in ipairs(orderEntities) do
        
            if entity:isa("Player") then
            
                playSound = true
                break
                
            end
            
        end
    
        if playSound then
        
            Server.PlayPrivateSound(self, soundName, self, 1.0, Vector(0, 0, 0))
            
            for index, player in ipairs(orderEntities) do
                Server.PlayPrivateSound(player, soundName, player, 1.0, Vector(0, 0, 0))
            end
            
        end
        
    end
    
end

// Takes a techId as the action type and normalized screen coords for the position. normPickVec will be nil
// for non-targeted actions. 
function Commander:ProcessTechTreeAction(techId, pickVec, orientation, worldCoordsSpecified)

    local success = false
    
    // Make sure tech is available
    local techNode = self:GetTechTree():GetTechNode(techId)
    if(techNode ~= nil and techNode.available) then

        // Trace along pick vector to find world position of action
        local targetPosition = Vector(0, 0, 0)
        local trace = nil
        if pickVec ~= nil then
        
            trace = GetCommanderPickTarget(self, pickVec, worldCoordsSpecified, techNode:GetIsBuild())
            
            if(trace ~= nil) then
                VectorCopy(trace.endPoint, targetPosition)
            end
                
        end
    
        // If techNode is a menu, remember it so we can validate actions
        if(techNode:GetIsMenu()) then
        
            self.currentMenu = techId
            
        elseif(techNode:GetIsOrder()) then
    
            self:OrderEntities(techId, trace, orientation)
            
        else        
           
            // For every selected entity, process this desired action. For some actions (research), only
            // process once, not on every entity.
            for index, selectedEntity in ipairs(self.selectedSubGroupEntities) do
            
                local actionSuccess = false
                local keepProcessing = false
                actionSuccess, keepProcessing = self:ProcessTechTreeActionForEntity(techNode, targetPosition, pickVec, selectedEntity)
                
                // Successful if just one of our entities handled action
                if(actionSuccess) then
                    success = true
                end
                
                if(not keepProcessing) then
                
                    break
                    
                end
                    
            end
            
            // On successful action, allow selection to receive orders
            //if success then
            //    for index, selectedEntity in ipairs(self.selectedSubGroupEntities) do
            //    end
            //end
            
        end
        
    end

    return success
    
end

function Commander:GetIsEntityHotgrouped(entity)

    local entityId = entity:GetId()
    
    // Loop through hotgroups, looking for entity
    for i = 1, Player.kMaxHotkeyGroups do
    
        for j = 1, table.count(self.hotkeyGroups[i]) do
        
            if(self.hotkeyGroups[i][j] == entityId) then
            
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function Commander:GiveOrderToSelection(orderType, targetId)

end

// Creates hotkey for number out of current selection. Returns true on success.
// Replaces existing hotkey on this number if it exists.
function Commander:CreateHotkeyGroup(number)

    if(number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        local selection = self:GetSelection()
        if(selection ~= nil and table.count(selection) > 0) then
        
            // Don't update hotkeys if they are the same (also happens when key is held down)
            if (not table.getIsEquivalent(selection, self.hotkeyGroups[number])) then
        
                table.copy(selection, self.hotkeyGroups[number])
                
                self:SendHotkeyGroup(number)
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

// Deletes hotkey for number. Returns true if it exists and was deleted.
function Commander:DeleteHotkeyGroup(number)

    if (number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        if (table.count(self.hotkeyGroups[number]) > 0) then
        
            self.hotkeyGroups[number] = {}
            
            self:SendHotkeyGroup(number)
            
            return true
            
        end
        
    end
    
    return false
    
end

// Send data to client because it changed
function Commander:SendHotkeyGroup(number)

    local hotgroupCommand = string.format("hotgroup %d ", number)
    
    for j = 1, table.count(self.hotkeyGroups[number]) do
    
        // Need underscore between numbers so all ids are sent in one string
        hotgroupCommand = hotgroupCommand .. self.hotkeyGroups[number][j] .. "_"
        
    end
    
    Server.SendCommand(self, hotgroupCommand)
    
    return hotgroupCommand
    
end

// Send alert to player unless we recently sent the exact same alert. Returns true if it was sent.
function Commander:SendAlert(techId, entity)

    local entityId = entity:GetId()
    local time = Shared.GetTime()
    
    for index, alert in ipairs(self.sentAlerts) do
    
        if (alert[1] == techId) and (alert[2] == entityId) and (alert[3] > (time - PlayingTeam.kRepeatAlertInterval)) then
        
            return false
            
        end
        
    end
    
    local location = Vector(entity:GetOrigin())
    Server.SendCommand(self, string.format("minimapalert %d %.2f %.2f %d", techId, location.x, location.z, entity:GetId())) 

    // Insert new triple: techid/entityid/timesent
    table.insert(self.sentAlerts, {techId, entityId, time})
    
    return true
    
end

function Commander:GetSentAlerts()
    return self.sentAlerts
end

// After logging in to the command station, send all hotkey groups. After that, only
// send them when they change. We must wait a short time after after logging in before
// sending them, to be sure the client version of the player is a Commander (and not
// a marine or alien).
function Commander:UpdateHotkeyGroups()

    if (self.timeToSendHotkeyGroups ~= nil) then
    
        if (Shared.GetTime() > self.timeToSendHotkeyGroups) then
        
            for i = 1, Player.kMaxHotkeyGroups do
    
                self:SendHotkeyGroup(i)
                
            end
            
            self.timeToSendHotkeyGroups = nil
            
        end
        
    end
    
end

function Commander:UpdateTeamHarvesterCount()

    if self.timeToSendTeamHarvesterCount == nil or (Shared.GetTime() > (self.timeToSendTeamHarvesterCount + 1.5)) then
    
        local resourceTowerName = ConditionalValue(self:isa("MarineCommander"), "Extractor", "Harvester")
        local numResourceTowers = table.count(GetEntitiesIsa(resourceTowerName, self:GetTeamNumber()))
        
        Server.SendCommand(self, string.format("harvestercount %d", numResourceTowers))
        
        self.timeToSendTeamHarvesterCount = Shared.GetTime()
        
    end
    
end

function Commander:GetIsEntityIdleWorker(entity)
    local className = ConditionalValue(self:isa("AlienCommander"), "Drifter", "MAC")
    return entity:isa(className) and not entity:GetHasOrder()
end

function Commander:GetIdleWorkers()

    local className = ConditionalValue(self:isa("AlienCommander"), "Drifter", "MAC")
    
    local workers = GetEntitiesIsa(className, self:GetTeamNumber())
    
    local idleWorkers = {}
    
    for index, worker in ipairs(workers) do

        if not worker:GetHasOrder() then
        
            table.insert(idleWorkers, worker)
            
        end
        
    end    
    
    return idleWorkers

end

function Commander:UpdateNumIdleWorkers()
    
    if self.lastTimeUpdatedIdleWorkers == nil or (Shared.GetTime() > self.lastTimeUpdatedIdleWorkers + 1) then
    
        self.numIdleWorkers = Clamp(table.count(self:GetIdleWorkers()), 0, kMaxIdleWorkers)
        
        self.lastTimeUpdatedIdleWorkers = Shared.GetTime()
        
    end
    
end

function Commander:GotoIdleWorker()
    
    local success = false
    
    local workers = self:GetIdleWorkers()
    local numWorkers = table.count(workers)
    
    if numWorkers > 0 then
    
        if numWorkers == 1 or self.lastGotoIdleWorker == nil then
        
            self.lastGotoIdleWorker = workers[1]
                    
            success = true
        
        else
        
            local index = table.find(workers, self.lastGotoIdleWorker)
            
            if index ~= nil then
            
                local newIndex = ConditionalValue(index == table.count(workers), 1, index + 1)

                if newIndex ~= index then
                
                    self.lastGotoIdleWorker = workers[newIndex]
                    
                    //Print("index = %d, newIndex = %d, entityId = %d", index, newIndex, SafeId(self.lastGotoIdleWorker, -1))
                    
                    success = true
                    
                end
            
            end
        
        end
    
    end
    
    if success then
    
        // Select and goto self.lastGotoIdleWorker
        local entityId = self.lastGotoIdleWorker:GetId()
        
        self:SetSelection( {entityId} )
        
        Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(entityId), true)
        
    end
            
end

function Commander:Logout()

    local commandStructure = Shared.GetEntity(self.commandStationId)
    commandStructure:Logout()
        
end

function Commander:SetCommandStructure(commandStructure)
    self.commandStationId = commandStructure:GetId()
end

