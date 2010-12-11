// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules.lua")

// Called when player first connects to server
// TODO: Move this into NS specific player class
function Player:OnClientConnect(client)
    self:SetRequestsScores(true)   
    self.clientIndex = client:GetId()
end

function Player:GetClient()
    return self.client
end

// Returns true if this player is a bot
function Player:GetIsVirtual()

    local isVirtual = false
    
    if self.client then
        isVirtual = self.client:GetIsVirtual()
    end
    
    return isVirtual
    
end

function Player:OnReset()

    LiveScriptActor.OnReset(self)
    
    self.score = 0
    self.kills = 0
    self.deaths = 0

end

/**
 * Called when the player entity is destroyed.
 */
function Player:OnDestroy()

    LiveScriptActor.OnDestroy(self)
    
    Shared.DestroyPhysicsController(self.controller)
    self.controller = nil
   
    local team = self:GetTeam()
    if(team ~= nil) then
        team:RemovePlayer(self)
    end
    
    self:RemoveChildren()
        
end

function Player:ClearEffects()
end

// ESC was hit on client or menu closed
function Player:CloseMenu()
end

function Player:GetName()
    return self.name
end

function Player:SetName(name)

    // If player is just changing the case on their own name, allow it.
    // Otherwise, make sure it's a unique name on the server.
    
    // Strip out surrounding "s
    local newName = string.gsub(name, "\"(.*)\"", "%1")
    
    // Make sure it's not too long
    newName = string.sub(newName, 0, kMaxNameLength)
    
    local currentName = self:GetName()
    if(currentName ~= newName or string.lower(newName) ~= string.lower(currentName)) then
        newName = GetUniqueNameForPlayer(newName)        
    end
    
    if(newName ~= self.name) then
    
        self.name = newName
        
        self:SetScoreboardChanged(true)
            
    end
    
end

// Changes the visual appearance of the player to the special edition version.
function Player:MakeSpecialEdition()
end

// Not authoritative, only visual and information. Carbon is stored in the team.
function Player:SetCarbon(carbon)
    self.teamCarbon = math.max(math.min(carbon, 1000), 0)
end

function Player:GetSendTechTreeBase()
    return self.sendTechTreeBase
end

function Player:ClearSendTechTreeBase()
    self.sendTechTreeBase = false
end

function Player:OnTeamChange(newTeamNumber)

    LiveScriptActor.OnTeamChange(self, newTeamNumber)
    
    if(newTeamNumber ~= self:GetTeamNumber()) then

        // Remove from the old team, if non-nil
        if(self:GetTeamNumber() ~= -1) then
            
            self:RemoveChildren()
        
            local oldTeam = GetGamerules():GetTeam(self:GetTeamNumber())
            if(oldTeam ~= nil) then
                oldTeam:RemovePlayer(self)
            end
            
        end
        
        
        // Add to new team
        local newTeam = GetGamerules():GetTeam(newTeamNumber)
        if(newTeam ~= nil) then
        
            newTeam:AddPlayer(self)
            
        end

        // Send scoreboard changes to everyone    
        self:SetScoreboardChanged(true)
        
        // Tell team to send entire tech tree
        self.sendTechTreeBase = true
        
    end
    
end

function Player:GetRequestsScores()
    return self.requestsScores
end

function Player:SetRequestsScores(state)
    self.requestsScores = state
end

// Have gamerules determine who can hear voice
function Player:GetCanPlayerHearPlayer(speakerPlayer)
    return GetGamerules():GetCanPlayerHearPlayer(self, speakerPlayer)    
end

// Call to give player default weapons, abilities, equipment, etc. Usually called after CreateEntity() and OnInit()
function Player:InitWeapons()
    self:ClearActivity()
    self.activeWeaponIndex = 0
    self.hudOrderedWeaponList = nil
end

function Player:OnTakeDamage(damage, doer, point)

    LiveScriptActor.OnTakeDamage(self, damage, doer, point)
    
    // Play damage indicator for player
    if point ~= nil then
        Server.SendNetworkMessage(self, "DamageIndicator", BuildDamageIndicatorMessage(point, damage), true)
    end
    
end


/**
 * Called when the player is killed. Point and direction specify the world
 * space location and direction of the damage that killed the player. These
 * may be nil if the damage wasn't directional.
 */
function Player:OnKill(damage, killer, doer, point, direction)

    local killedSound = self:GetKilledSound(doer)
    if killedSound ~= nil then
    
        // Play world sound instead of parented sound as entity is going away
        Shared.PlayWorldSound(nil, killedSound, nil, self:GetOrigin())
        
    end

    local killerName = nil
    
    local pointOwner = killer
    // If the pointOwner is not a player, award it's points to it's owner.
    if pointOwner ~= nil and not pointOwner:isa("Player") then
        pointOwner = pointOwner:GetOwner()
    end
    if(pointOwner and pointOwner:isa("Player") and pointOwner ~= self and pointOwner:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
   
        killerName = pointOwner:GetName()
        pointOwner:AddKill()        
        pointOwner:AddScore(self:GetPointValue())
        
    end        

    // Save death to server log
    if(killer == self) then        
        PrintToLog("%s committed suicide", self:GetName())
    elseif(killerName ~= nil) then
        PrintToLog("%s was killed by %s", self:GetName(), killerName)
    else
        PrintToLog("%s died", self:GetName())
    end
    
    // Go to third person so we can see ragdoll and avoid HUD effects (but keep short so it's personal)
    self:SetIsThirdPerson(4)

    self:AddDeaths()
    
    // Don't allow us to do anything
    self.alive = false

    // On fire, in umbra, etc.
    self:ClearGameEffects()
    
    // Fade out screen
    self.timeOfDeath = Shared.GetTime()
    
    // So we aren't moving in spectator mode
    self:SetVelocity(Vector(0, 0, 0))
    
    // Remove our weapons and viewmodel
    self:RemoveChildren()

    // Create a rag doll
    self:SetPhysicsType(Actor.PhysicsType.Dynamic)
    self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
    
    // Set next think to 0 to disable
    self:SetNextThink(0)
        
end

function Player:SetControllingPlayer(client)

    // Entity passed to SetControllingPlayer must be an Actor
    if (client ~= nil) then
        client:SetControllingPlayer(self)
    end
    
    // Save client for later
    self.client = client
    
end

function Player:SetPlasma(amount)

    self.plasma = math.max(math.min(amount, kMaxResources), 0)
    
end

function Player:GetDeathMapName()
    return Spectator.kMapName
end

function Player:OnUpdate(deltaTime)

    PROFILE("Player_Server:OnUpdate")
    
    LiveScriptActor.OnUpdate(self, deltaTime)

    self:UpdateOrder()
    
    self:UpdateOrderWaypoint()

    if (not self.alive and not self:isa("Spectator")) then
    
        local time = Shared.GetTime()
        
        if ((self.timeOfDeath ~= nil) and (time - self.timeOfDeath > kFadeToBlackTime)) then
        
            // Destroy the existing player and create a spectator in their place.
            local spectator = self:Replace(self:GetDeathMapName())
            
            // Queue up the spectator for respawn.
            self:GetTeam():PutPlayerInRespawnQueue(spectator, Shared.GetTime())             
            
        end

    else
        self:UpdateUse(deltaTime)
    end 

    /*local viewModel = self:GetViewModelEntity()
    if viewModel ~= nil then
        viewModel:SetIsVisible(not self:GetWeaponHolstered())
    end*/

    local gamerules = GetGamerules()
    self.gameStarted = gamerules:GetGameStarted()
    // TODO: Change this after making NS2Player
    self.countingDown = false //gamerules:GetCountingDown()
    self.teamLastThink = self:GetTeam()  

end

// Remember game time player enters queue so they can be spawned in FIFO order
function Player:SetRespawnQueueEntryTime(time)

    self.respawnQueueEntryTime = time
    
end

function Player:ReplaceRespawn()
    return self:GetTeam():ReplaceRespawnPlayer(self, nil, nil)
end

function Player:GetRespawnQueueEntryTime()

    return self.respawnQueueEntryTime
    
end

function Player:CanDoDamageTo(entity)

    return CanEntityDoDamageTo(self, entity)
    
end

function Player:CopyPlayerDataFrom(player)

    LiveScriptActor.CopyDataFrom(self, player)

    // ScriptActor and Actor fields
    self:SetAngles(player:GetAngles())
    self:SetOrigin(Vector(player:GetOrigin()))
    self:SetViewAngles(player:GetViewAngles())
    
    self.baseYaw = player.baseYaw
    self.basePitch = player.basePitch
    self.baseRoll = player.baseRoll

    // Player fields   
    //self:SetFov(player:GetFov())
    self:SetVelocity(player:GetVelocity())
    self.gravityEnabled = player.gravityEnabled
    
    // Don't copy over fields that are class-specific. We give new weapons to players
    // when they change class.
    //self.activeWeaponIndex = player.activeWeaponIndex
    //self.activeWeaponHolstered = player.activeWeaponHolstered
    //self.viewModelId = player.viewModelId
    
    self.name = player.name
    self.clientIndex = player.clientIndex
    
    // Preserve hotkeys when logging in/out of command structures
    table.copy(player.hotkeyGroups, self.hotkeyGroups)
    
    // Copy network data over because it won't be necessarily be resent
    self.plasma = player.plasma
    self.teamCarbon = player.teamCarbon
    self.gameStarted = player.gameStarted
    self.countingDown = player.countingDown
    self.frozen = player.frozen
    table.copy(player.displayedTooltips, self.displayedTooltips)
    
    // Don't copy alive, health, maxhealth, armor, maxArmor, smoothCamera - they are set in Spawn()
    
    self.showScoreboard = player.showScoreboard
    self.score = player.score
    self.kills = player.kills
    self.deaths = player.deaths
    
    self.timeOfDeath = player.timeOfDeath
    self.timeOfLastUse = player.timeOfLastUse
    self.timeOfLastWeaponSwitch = player.timeOfLastWeaponSwitch
    self.crouching = player.crouching
    self.timeOfCrouchChange = player.timeOfCrouchChange   
    self.timeOfLastPoseUpdate = player.timeOfLastPoseUpdate

    self.timeLastBuyMenu = player.timeLastBuyMenu
    
    // Include here so it propagates through Spectator
    self.lastSquad = player.lastSquad
    
    self.sighted = player.sighted
    self.jumpHandled = player.jumpHandled
    self.timeOfLastJump = player.timeOfLastJump

    self.mode = player.mode
    self.modeTime = player.modeTime
    self.outOfBreath = player.outOfBreath
    
    self.scoreboardChanged = player.scoreboardChanged
    self.requestsScores = player.requestsScores
    self.sendTechTreeBase = player.sendTechTreeBase
    
    // Don't lose purchased upgrades when becoming commander
    self.upgrade1 = player.upgrade1
    self.upgrade2 = player.upgrade2
    self.upgrade3 = player.upgrade3
    self.upgrade4 = player.upgrade4
    
    // Copy waypoint
    if player.nextOrderWaypoint and self.nextOrderWaypoint then
        VectorCopy(player.nextOrderWaypoint, self.nextOrderWaypoint)
    end
    
    if player.finalWaypoint and self.finalWaypoint then
        VectorCopy(player.finalWaypoint, self.finalWaypoint)
    end
    
    self.nextOrderWaypointActive = player.nextOrderWaypointActive
    
    self.waypointType = player.waypointType
    
    self:CopyOrdersFrom(player)
        
end

/**
 * Replaces the existing player with a new player of the specified map name.
 * Removes old player off its team and adds new player to newTeamNumber parameter
 * if specified. Note this destroys self, so it should be called carefully. Returns 
 * the new player. If preserve children is true, then InitWeapons() isn't called
 * and old ones are kept (including view model).
 */
function Player:Replace(mapName, newTeamNumber, preserveChildren)

    local team = self:GetTeam()
    if(team == nil) then
        return self
    end
    
    local teamNumber = team:GetTeamNumber()    
    local owner  = Server.GetOwner(self)
    
    // Add new player to new team if specified
    // Both nil and -1 are possible invalid team numbers.
    if(newTeamNumber ~= nil and newTeamNumber ~= -1) then
        teamNumber = newTeamNumber
    end

    local player = CreateEntity(mapName, Vector(self:GetOrigin()), teamNumber)
    
    // Copy over the relevant fields to the new player, before we delete it
    player:CopyPlayerDataFrom(self)
    
    // Remove newly spawned weapons and reparent originals
    if preserveChildren then

        player:RemoveChildren()
        
        local childEntities = GetChildEntities(self)
        for index, entity in ipairs(childEntities) do

            entity:SetParent(player)

        end
        
        // Update the weapon list now that the weapons have been assigned to the new player.
        player:ComputeHUDOrderedWeaponList()
        
    end
    
    // Notify others of the change     
    self:SendEntityChanged(player:GetId())
    
    // Update scoreboard because of new entity and potentially new team
    player:SetScoreboardChanged(true)
    
    // Now destroy old player (and child entities too)
    // This will remove player from old team
    // This called EntityChange as well.
    DestroyEntity(self)
    
    player:SetControllingPlayer(owner)
    
    // Set up special armor marines if player owns special edition 
    if Server.GetIsDlcAuthorized(owner, kSpecialEditionProductId) then
        player:MakeSpecialEdition()
    end

    return player

end

function Player:ProcessBuyAction(techId)

    // Make sure tech is available
    local techTree = self:GetTechTree()
    
    local techNode = techTree:GetTechNode(techId)
    if(techNode ~= nil and techNode.available) then
    
        // Make sure we have enough resources
        local cost = LookupTechData(techId, kTechDataCostKey)
        
        if(cost ~= nil) then
        
            if( cost <= self:GetPlasma() ) then
                
                // buy it
                if self:AttemptToBuy(techId) then
                
                    self:AddPlasma(-cost)
                    
                    return true
                
                end                
                
            else
            
                self:PlaySound(self:GetNotEnoughResourcesSound())
                
            end
            
        end
        
    end

    return false
    
end

/* Spawns an item based on the entity (map) name and adds it to the player's inventory. */
/* Make it the active weapon. */
function Player:GiveItem(itemMapName)

    local newItem = nil

    // Don't give it to the player if they already have it
    if (itemMapName ~= nil and (self:GetItem(itemMapName) == nil)) then
    
        // Calls OnSpawn    
        newItem = CreateEntity(itemMapName, self:GetOrigin(), self:GetTeamNumber())
        if(newItem ~= nil) then
    
            // Call OnTouch manually because collision not in yet
            newItem:OnTouch(self)
            
        else
        
            Shared.Message("Couldn't create entity named " .. itemMapName .. ".")
            
        end
        
    end
    
    return newItem
    
end

function Player:AddWeapon(weapon, setActive)
    
    weapon:SetParent(self)
    
    self:ComputeHUDOrderedWeaponList()
    
    if setActive then
        self:SetActiveWeapon(weapon:GetMapName())
    end
    
end

function Player:RemoveWeapon(weapon)

    // Switch weapons if we're dropping our current weapon
    local activeWeapon = self:GetActiveWeapon()    
    if activeWeapon ~= nil and weapon:GetId() == activeWeapon:GetId() then
        self:SelectNextWeapon()        
    end
    
    // Delete weapon 
    weapon:SetParent(nil)
    DestroyEntity(weapon)
    
end

function Player:RemoveWeapons()

    self.activeWeaponIndex = 0
    
    // Loop through all child weapons and delete them 
    local childEntities = GetChildEntities(self, "Weapon")
    for index, entity in ipairs(childEntities) do
        DestroyEntity(entity)
    end    

end

// Removes all child weapons and view model
function Player:RemoveChildren()

    self.activeWeaponIndex = 0
    
    // Loop through all child weapons and delete them 
    local childEntities = GetChildEntities(self, "Actor")
    for index, entity in ipairs(childEntities) do
        DestroyEntity(entity)
    end
    
    self.viewModelId = Entity.invalidId

end

function Player:InitViewModel()

    if(self.viewModelId == Entity.invalidId) then
    
        local viewModel = CreateEntity(ViewModel.mapName)
        viewModel:SetOrigin(self:GetOrigin())
        viewModel:SetParent(self)
        self.viewModelId = viewModel:GetId()
        
        // Set default blend length for all the player's view model animations
        viewModel:SetBlendTime( self:GetViewModelBlendTime() )
        
    end
    
end

function Player:GetViewModelBlendTime()
    return .1
end

function Player:GetScore()
    return self.score
end

function Player:AddScore(points)
    
    // Tell client to display cool effect
    if(points ~= nil and points ~= 0) then
        Server.SendCommand(self, "points " .. tostring(points))
        self.score = Clamp(self.score + points, 0, kMaxScore)
        self:SetScoreboardChanged(true)        
    end
    
end

function Player:GetKills()
    return self.kills
end

function Player:AddKill()
    self.kills = Clamp(self.kills + 1, 0, kMaxKills)
    self:SetScoreboardChanged(true)
end

function Player:GetDeaths()
    return self.deaths
end

function Player:AddDeaths()
    self.deaths = Clamp(self.deaths + 1, 0, kMaxDeaths)
    self:SetScoreboardChanged(true)
end

function Player:GetPing()
    
    local client = Server.GetOwner(self)
    
    if (client ~= nil) then
        return client:GetPing()
    else
        return 0
    end
    
end

// To be overridden by children
function Player:AttemptToBuy(techId)
    return false
end

function Player:OnResearchComplete(structure, researchId)
    self:AddTooltip(string.format("%s research complete.", tostring(LookupTechData(researchId, kTechDataDisplayName))))    
    return true
end

function Player:UpdateMisc(input)

    self:UpdateSharedMisc(input)

    // Update target under reticle (put back in when we're using it)
    /*
    local enemyUnderReticle = false
    local activeWeapon = self:GetActiveWeapon()    

    if(activeWeapon ~= nil) then
    
        local viewCoords = self:GetViewAngles():GetCoords()
        local trace = Shared.TraceRay(self:GetEyePos(), self:GetEyePos() + viewCoords.zAxis*100, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))            
        if(trace.entity ~= nil and trace.fraction ~= 1) then
        
            enemyUnderReticle = GetGamerules():CanEntityDoDamageTo(self, trace.entity)
            
        end
        
    end*/
    
    // Set near death mask so we can add sound/visual effects
    self:SetGameEffectMask(kGameEffect.NearDeath, self:GetHealth() < .2*self:GetMaxHealth())
    
    // TODO: Put this back in once colors look right
    //self:SetReticleTarget(enemyUnderReticle)
    self:SetReticleTarget(true)
    
    // Flare updating
    if(self.flareStartTime > 0) then
        if(Shared.GetTime() > self.flareStopTime) then
            self.flareStartTime = 0
            self.flareStopTime = 0
        end
    end
    
end

function Player:SetFlare(startTime, endTime, scalar)
    self.flareStartTime = startTime
    self.flareStopTime = endTime
    self.flareScalar = Clamp(scalar, 0, 1)
end

// For signaling reticle hit feedback on client
function Player:SetTimeTargetHit()
    self.timeTargetHit = Shared.GetTime()
end

function Player:SetReticleTarget(state)
    self.reticleTarget = state
end

function Player:AddTooltip(tooltipText)

    Server.SendCommand(self, string.format("%s \"%s\"", "tooltip", tooltipText))
    self:AddDisplayedTooltip(tooltipText)
    self.timeOfLastTooltip = Shared.GetTime()
    
end

function Player:GetTechTree()

    local techTree = nil
    
    local team = self:GetTeam()
    if team ~= nil and team:isa("PlayingTeam") then
        techTree = team:GetTechTree()
    end
    
    return techTree

end

function Player:UpdateOrder()

    local currentOrder = self:GetCurrentOrder()
    
    if(currentOrder ~= nil) then
    
        local orderType = currentOrder:GetType()
        
        if orderType == kTechId.Move then
        
            if (currentOrder:GetLocation() - self:GetOrigin()):GetLength() < 1.5 then
                
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                
                self:CompletedCurrentOrder()
                
            end
        
        elseif orderType == kTechId.Construct then
        
            local orderTarget = Shared.GetEntity(currentOrder:GetParam())
            
            if orderTarget == nil or not orderTarget:GetIsAlive() or orderTarget:GetIsBuilt() then
                self:CompletedCurrentOrder()
            end
            
            if orderTarget ~= nil and orderTarget:GetIsBuilt() then
            
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                
            end

        elseif orderType == kTechId.Attack then

            local orderTarget = Shared.GetEntity(currentOrder:GetParam())

            if not orderTarget or orderTarget:GetId() == Entity.invalidId then
            
                self:ClearOrders()
                
            elseif not orderTarget:GetIsAlive() then
            
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                
                self:CompletedCurrentOrder()
                
            end
            
        end
        
    end
    
end

function Player:UpdateOrderWaypoint()

    local currentOrder = self:GetCurrentOrder()
    
    if(currentOrder ~= nil) then
    
        local targetLoc = Vector(currentOrder:GetLocation())
        self.nextOrderWaypoint = Server.GetNextWaypoint(PhysicsMask.AIMovement, self, self:GetWaypointGroupName(), targetLoc)
        self.finalWaypoint = Vector(targetLoc)
        self.nextOrderWaypointActive = true
        self.waypointType = currentOrder:GetType()
        
    else
    
        self.nextOrderWaypoint = nil
        self.finalWaypoint = nil
        self.nextOrderWaypointActive = false
        self.waypointType = kTechId.None
        
    end

end