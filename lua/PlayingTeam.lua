// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

class 'PlayingTeam' (Team)

PlayingTeam.kObliterateVictoryCarbonNeeded = 500
PlayingTeam.kUnitMaxLOSDistance = 30
PlayingTeam.kUnitMinLOSDistance = 8
PlayingTeam.kTooltipHelpInterval = 1

// How often to compute LOS visibility for entities (seconds)
PlayingTeam.kLOSUpdateInterval = 1
PlayingTeam.kTechTreeUpdateTime = 1

PlayingTeam.kBaseAlertInterval = 6
PlayingTeam.kRepeatAlertInterval = 12

// How often to update clear and update game effects
PlayingTeam.kUpdateGameEffectsInterval = .3

/**
 * spawnEntity is the name of the map entity that will be created by default
 * when a player is spawned.
 */
function PlayingTeam:Initialize(teamName, teamNumber)

    Team.Initialize(self, teamName, teamNumber)

    self.respawnEntity = nil
    
    self:OnCreate()
        
    self.timeSinceLastLOSUpdate = Shared.GetTime()

end

function PlayingTeam:AddPlayer(player)

    Team.AddPlayer(self, player)
    
    player.teamCarbon = self.carbon
    
    // Reset each player to initial plasma
    // TODO: Make sure players don't leave server and come back to get resources
    player:SetPlasma( kPlayerInitialPlasma )
    
end

function PlayingTeam:OnCreate()

    Team.OnCreate(self)
    
    self.structures = {}
    self.towers = {}
      
end

function PlayingTeam:OnInit()

    Team.OnInit(self)
    
    self:InitTechTree()
    self.timeOfLastTechTreeUpdate = nil
    
    table.clear(self.structures)
    table.clear(self.towers)
    
    self.lastPlayedTeamAlertName = nil
    self.timeOfLastPlayedTeamAlert = nil
    self.alerts = {}
    
    self.carbon = 0
    self.totalCarbonCollected = 0
    self:AddCarbon(kPlayingTeamInitialCarbon)

    self.alertsEnabled = false
    self:SpawnInitialStructures(self.teamLocation)
    self.alertsEnabled = true

end

function PlayingTeam:Reset()

    self:OnInit()
    
    Team.Reset(self)

end

function PlayingTeam:InitTechTree()
   
    self.techTree = TechTree()
    
    self.techTree:Initialize()
    
    self.techTree:SetTeamNumber(self:GetTeamNumber())
    
    // Menus
    self.techTree:AddMenu(kTechId.RootMenu)
    self.techTree:AddMenu(kTechId.BuildMenu)
    self.techTree:AddMenu(kTechId.AdvancedMenu)
    self.techTree:AddMenu(kTechId.AssistMenu)
    self.techTree:AddMenu(kTechId.SquadMenu)
    
    // Orders
    self.techTree:AddOrder(kTechId.Default)
    self.techTree:AddOrder(kTechId.Move)
    self.techTree:AddOrder(kTechId.Attack)
    self.techTree:AddOrder(kTechId.Build)
    self.techTree:AddOrder(kTechId.Construct)
    
    self.techTree:AddAction(kTechId.Cancel)
    self.techTree:AddAction(kTechId.Recycle)
    
    self.techTree:AddOrder(kTechId.Weld)   
    
    self.techTree:AddAction(kTechId.Stop)
    
    self.techTree:AddOrder(kTechId.SetRally)
    self.techTree:AddOrder(kTechId.SetTarget)
    
end

// Returns marine or alien type
function PlayingTeam:GetTeamType()
    return self.teamType
end

function PlayingTeam:SendCommand(command)

    function PlayerSendCommand(player)
        Server.SendCommand(player, command)
    end
    
    self:ForEachPlayer(PlayerSendCommand)

end

function PlayingTeam:OnResearchComplete(structure, researchId)

    // Mark this tech node as researched
    local node = self.techTree:GetTechNode(researchId)
    if node == nil then
    
        Print("PlayingTeam:OnResearchComplete(): Couldn't find tech node %d", researchId)
        return false
        
    end
    
    node:SetResearched(true)
    
    // Loop through all entities on our team and tell them research was completed
    local teamEnts = GetEntitiesIsa("ScriptActor", self:GetTeamNumber())
    for index, ent in ipairs(teamEnts) do
        ent:OnResearchComplete(structure, researchId)
    end
    
    // Tell tech tree to recompute availability next think
    self:GetTechTree():SetTechNodeChanged(node)
    
    if structure then
        self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure)    
    end
    
    return true
    
end

// Returns sound name of last alert and time last alert played (for testing)
function PlayingTeam:GetLastAlert()
    return self.lastPlayedTeamAlertName, self.timeOfLastPlayedTeamAlert
end

// Play audio alert for all players, but don't trigger them too often. 
// This also allows neat tactics where players can time strikes to prevent the other team from instant notification of an alert, ala RTS.
// Returns true if the alert was played.
function PlayingTeam:TriggerAlert(techId, entity)

    ASSERT(entity ~= nil)
    ASSERT(entity:GetTechId() ~= kTechId.ReadyRoomPlayer, "Ready room entity TechId detected!")
    ASSERT(entity:GetTechId() ~= kTechId.None, "None entity TechId detected! Classname: " .. entity:GetClassName())
    ASSERT(techId ~= kTechId.None, "None TechId detected!")
    
    local triggeredAlert = false

    // Queue alert so commander can jump to it
    if techId ~= kTechId.None and techId ~= nil and entity ~= nil then
    
        if self.alertsEnabled then
        
            local location = Vector(entity:GetOrigin())
            table.insert(self.alerts, {techId, entity:GetId()})
        
            // Lookup sound name
            local soundName = LookupTechData(techId, kTechDataAlertSound, "")            
            if soundName ~= "" then
            
                local isRepeat = (self.lastPlayedTeamAlertName ~= nil and self.lastPlayedTeamAlertName == soundName)
            
                local timeElapsed = math.huge
                if self.timeOfLastPlayedTeamAlert ~= nil then
                    timeElapsed = Shared.GetTime() - self.timeOfLastPlayedTeamAlert
                end
                
                // If time elapsed > kBaseAlertInterval and not a repeat, play it OR
                // If time elapsed > kRepeatAlertInterval then play it no matter what
                if ((timeElapsed >= PlayingTeam.kBaseAlertInterval) and not isRepeat) or (timeElapsed >= PlayingTeam.kRepeatAlertInterval) then
                
                    // Play for commanders only or for the whole team
                    local commandersOnly = not LookupTechData(techId, kTechDataAlertTeam, false)
                    
                    self:PlayPrivateTeamSound(soundName, location, commandersOnly)
                    
                    self.lastPlayedTeamAlertName = soundName
                    self.timeOfLastPlayedTeamAlert = Shared.GetTime()
                    
                    triggeredAlert = true
                    
                end    
                
            end
            
            // Send minimap ping and alert notification to commanders
            for i, playerIndex in ipairs(self.playerIds) do

                local player = Shared.GetEntity(playerIndex)
                if(player ~= nil and player:isa("Commander")) then
                
                    player:TriggerAlert(techId, entity)                    
                    
                end
                
            end
            
        end
        
    else
        Print("PlayingTeam:TriggerAlert(%s, %s) called improperly.", ToString(techId), ToString(entity))
    end
    
    return triggeredAlert
    
end

function PlayingTeam:SetCarbon(amount)

    if(amount > self.carbon) then
    
        // Save towards victory condition
        self.totalCarbonCollected = self.totalCarbonCollected + (amount - self.carbon)
        
    end
    
    self.carbon = amount
    
    function PlayerSetCarbon(player)
        player.teamCarbon = self.carbon
    end
    
    self:ForEachPlayer(PlayerSetCarbon)
    
end

function PlayingTeam:GetCarbon()

    return self.carbon
    
end

function PlayingTeam:AddCarbon(amount)

    self:SetCarbon(self.carbon + amount)
    
end

function PlayingTeam:GetHasTeamLost()

    if(GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled()) then
    
        // Team can't respawn or last Command Station or Hive destroyed
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()
        local numCommandStructures = self:GetNumCommandStructures()
        
        if  ( not activePlayers and not abilityToRespawn) or
            ( numCommandStructures == 0 ) or
            ( self:GetNumPlayers() == 0 ) then
            
            return true
            
        end
            
    end

    return false    

end

// Returns true if team has acheived alternate victory condition - hive releases bio-plague and marines teleport
// away and nuke station from orbit!
function PlayingTeam:GetHasTeamWon()

    if(GetGamerules():GetGameStarted() /*and not Shared.GetCheatsEnabled()*/) then
        
        // If team has collected enough resources to achieve alternate victory condition
        //if( self.totalCarbonCollected >= PlayingTeam.kObliterateVictoryCarbonNeeded) then
        //
        //    return true
        //    
        //end
        
    end
    
end

function PlayingTeam:SpawnInitialStructures(teamLocation)

    if(teamLocation ~= nil) then

        // Spawn tower at nearest unoccupied resource point    
        //self:SpawnResourceTower(teamLocation)

        // Spawn hive/command station at team location
        self:SpawnCommandStructure(teamLocation)

    end
    
end

function PlayingTeam:GetHasAbilityToRespawn()
    return true
end

function PlayingTeam:SpawnResourceTower(teamLocation)

    local success = false
    if(teamLocation ~= nil) then
        local teamLocationOrigin = Vector(teamLocation:GetOrigin())
        
        local resourcePoints = GetEntitiesIsa("ResourcePoint", -1)
        local closestPoint = nil
        local closestPointDistance = 0
        
        for index, current in ipairs(resourcePoints) do
        
            local pointOrigin = Vector(current:GetOrigin())
            local distance = (pointOrigin - teamLocationOrigin):GetLength()
            
            if((current:GetAttached() == nil) and ((closestPoint == nil) or (distance < closestPointDistance))) then
            
                closestPoint = current
                closestPointDistance = distance
                
            end
            
        end
            
        // Now spawn appropriate resource tower there
        if(closestPoint ~= nil) then
        
            local towerClassName = ConditionalValue(self:GetIsAlienTeam(), Harvester.kMapName, Extractor.kMapName)
            success = closestPoint:SpawnResourceTowerForTeam(self, towerClassName)
        
        end
        
    else
        Print("PlayingTeam:SpawnResourceTower() - Couldn't spawn resource tower for team, no team location.")
    end    
    
    return success
    
end

// Spawn hive or command station at nearest empty tech point to specified team location.
// Does nothing if can't find any.
function PlayingTeam:SpawnCommandStructure(teamLocation)
    
    // Look for nearest empty tech point to use instead
    local nearestTechPoint = GetNearestTechPoint(teamLocation:GetOrigin(), self:GetTeamType(), true)
    
    if(nearestTechPoint ~= nil) then
    
        local commandStructure = nearestTechPoint:SpawnCommandStructure(self:GetTeamNumber())
        if(commandStructure ~= nil) then
        
            commandStructure:SetConstructionComplete()
            return true
            
        end
        
    end    

    return false
    
end

function PlayingTeam:GetIsAlienTeam()
    return false
end

function PlayingTeam:GetIsMarineTeam()
    return false    
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 * Pass nil origin/angles to have spawn entity chosen.
 */
function PlayingTeam:ReplaceRespawnPlayer(player, origin, angles)

    local newPlayer = player:Replace(self.respawnEntity, self:GetTeamNumber(), false)
    
    self:RespawnPlayer(newPlayer, origin, angles)
    
    newPlayer:ClearGameEffects()
    
    return (newPlayer ~= nil), newPlayer
    
end

// Call with origin and angles, or pass nil to have them determined from team location and spawn points.
function PlayingTeam:RespawnPlayer(player, origin, angles)

    local success = false
    
    if(origin ~= nil and angles ~= nil) then
        success = Team.RespawnPlayer(self, player, origin, angles)
    else
    
        local teamLocation = self:GetTeamLocation()
        if (teamLocation ~= nil) then

            local spawnPoints = {}
            for index, spawnPoint in ipairs(Server.playerSpawnList) do
            
                if (teamLocation:GetOrigin() - spawnPoint:GetOrigin()):GetLength() < teamLocation:GetSpawnRadius() then
                    table.insert(spawnPoints, spawnPoint)
                end
                
            end
            
            if(table.maxn(spawnPoints) == 0) then
            
                Print("PlayingTeam:RespawnPlayer: Found no %s for team %s, spawning at ReadyRoomSpawn", TeamLocation.kMapName, ToString(self:GetTeamNumber()))
                spawnPoints = Server.readyRoomSpawnList

            end
            
            if(table.maxn(spawnPoints) > 0) then
        
                // Randomly choose one of the spawn points that's unobstructed to spawn the player.                
                local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
                
                if (spawnPoint ~= nil) then
                    success = Team.RespawnPlayer(self, player, spawnPoint:GetOrigin(), spawnPoint:GetAngles())
                else                
                    Print("PlayingTeam:RespawnPlayer: Found no free spawn points found.\n")
                end
                
            else            
                Print("PlayingTeam:RespawnPlayer: No spawn points found.\n")
            end
        
        else
            Print("PlayingTeam:RespawnPlayer(): No team location.")
        end
        
    end

    player:OnIdle()
    
    return success

end

function PlayingTeam:TechAdded(entity)

    if(entity:isa("Structure")) then
        table.insertunique(self.structures, entity)
    end
    
    // If a resource tower, add it to a list
    if(entity:isa("ResourceTower")) then
        table.insertunique(self.towers, entity)
    end
   
    // Tell tech tree to recompute availability next think
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
end

function PlayingTeam:TechRemoved(entity)

    if(entity:isa("Structure")) then
        table.removevalue(self.structures, entity)
    end
    
    // If a resource tower, remove it to a list
    if(entity:isa("ResourceTower")) then
        table.removevalue(self.towers, entity)
    end
    
    // Tell tech tree to recompute availability next think
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
    
end

function PlayingTeam:TechBuilt(structure)

    // Tell tech tree to recompute availability next think
    if(self.techTree ~= nil) then
    
        self.techTree:SetTechChanged()
        
    end
    
end

function PlayingTeam:ComputeLOS()

    PROFILE("PlayingTeam:ComputeLOS")

    // Get all non-commander players on our team
    local teamBuilderName = ConditionalValue(self:GetIsAlienTeam(), "Drifter", "MAC")
    
    function IsFriendlyLOSGivingUnit(entity)
    
        if(entity:GetTeamNumber() == self:GetTeamNumber()) then
        
            // Scan entities are structures
            if( (entity:isa("Player") and not entity:GetIsCommander()) or entity:isa(teamBuilderName) or entity:isa("Structure") ) then
            
                return true
                
            end
            
        end
        
        return false
        
    end
    
    // Get list of entities that can see (players and AI builder units). Do it this
    // way to avoid unnecessarily iterating over all the entities in the world.
    local seeingUnits = {}
    local entities = {}
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    
    for index, entity in ipairs( GetGamerules():GetAllScriptActors() ) do
    
        if IsFriendlyLOSGivingUnit(entity) then
            table.insert(seeingUnits, entity)
        end
        
        // For each visible entity on other team
        if entity:GetTeamNumber() == enemyTeamNumber and entity:GetIsVisible() then
            table.insert(entities, entity)
        end
        
    end
    
    for entIndex, entity in ipairs(entities) do
    
        // Reset flag every tick
        entity.sighted = false
        
        // See if friendly buildings are near entity, with direct LOS to it (ala conventional RTS).
        // Check in 2D to detect hives above.
        for seeingIndex, seeingUnit in ipairs(seeingUnits) do

            local distance = seeingUnit:GetDistanceXZ(entity)
            if(distance < PlayingTeam.kUnitMinLOSDistance) then

                // TODO: Check to make sure view isn't blocked by the level or big visible entities?
                entity.sighted = true
                break
                
            // Only give LOS to units within max distance
            elseif( (distance < PlayingTeam.kUnitMaxLOSDistance) and not seeingUnit:isa("Structure") ) then

                if( seeingUnit:GetCanSeeEntity(entity) ) then
                
                    // For players and AI units, check if entity is in seeing unit's view cone
                    entity.sighted = true
                    break
                    
                end

            elseif seeingUnit:isa("Scan") and distance < Scan.kScanDistance then
            
                entity.sighted = true
                break
                
            end

        end
            
    end

end

function PlayingTeam:UpdateLOS(timePassed)

    // Skip LOS check when debugging for perf. reasons
    if(/*not GetIsDebugging() and*/ (self.timeSinceLastLOSUpdate > PlayingTeam.kLOSUpdateInterval)) then
    
        self:ComputeLOS()
        self.timeSinceLastLOSUpdate = 0
    
    else
 
        self.timeSinceLastLOSUpdate = self.timeSinceLastLOSUpdate + timePassed
        
    end
    
end

function PlayingTeam:Update(timePassed)

    PROFILE("PlayingTeam:Update")

    // Update structure research and energy
    for index, structure in ipairs(self.structures) do
    
        if(structure:GetIsBuilt()) then
        
            structure:UpdateResearch(timePassed)

            structure:UpdateEnergy(timePassed)
            
        end
        
    end
    
    self:UpdateHelp()
    
    // Update line of sight for other team
    self:UpdateLOS(timePassed)

    // Compute tech tree availability only so often because it's very slooow
    if self.techTree ~= nil and (self.timeOfLastTechTreeUpdate == nil or Shared.GetTime() > self.timeOfLastTechTreeUpdate + PlayingTeam.kTechTreeUpdateTime) then

        // Send tech tree base line to players that just switched teams or joined the game        
		// Also refresh and update existing players' tech trees.
        local players = self:GetPlayers()
        
        for index, player in ipairs(players) do
        
            if player:GetSendTechTreeBase() then
            
                if player:GetTechTree() ~= nil then            
                    player:GetTechTree():SendTechTreeBase(player)
                end
                
                player:ClearSendTechTreeBase()
                
            end
			
			// Send research, availability, etc. tech node updates to players   
            if player:GetTechTree() ~= nil then            
                player:GetTechTree():SendTechTreeUpdates({ player })
            end
            
        end
        
        self.timeOfLastTechTreeUpdate = Shared.GetTime()
        
    end
    
    self:UpdateGameEffects(timePassed)
    
end

function PlayingTeam:GetTechTree()
    return self.techTree
end

// Create death message string with following format:
//
// deathmsg killingPlayerIndex killerTeamNumber doerIconIndex targetPlayerIndex targetTeamNumber
//
// Note: Client indices are used here as entity Ids aren't always valid on the client
// due to relevance. If the killer or target is not a player, the entity techId is used.
function PlayingTeam:GetDeathMessage(killer, doerIconIndex, targetEntity)

    local killerIsPlayer = 0    
    local killerIndex = -1
    
    if killer then
        killerIsPlayer = ConditionalValue(killer:isa("Player"), 1, 0)
        if killerIsPlayer == 1 then
            killerIndex = killer:GetClientIndex()
        else
            if killer:GetOwner() and killer:GetOwner():isa("Player") then
                killerIsPlayer = 1
                killerIndex = killer:GetOwner():GetClientIndex()
            else
                killerIndex = killer:GetTechId()
            end
        end
    end
    
    local targetIsPlayer = ConditionalValue(targetEntity:isa("Player"), 1, 0)
    local targetIndex = -1
    if targetIsPlayer == 1 then
        targetIndex = targetEntity:GetClientIndex()
    else
        targetIndex = targetEntity:GetTechId()
    end
    
    local targetTeamNumber = targetEntity:GetTeamNumber()
    local killerTeamNumber = targetTeamNumber
    if killer then
        killerTeamNumber = killer:GetTeamNumber()
    end
    
    return string.format("deathmsg %d %d %d %d %d %d %d", killerIsPlayer, killerIndex, killerTeamNumber, doerIconIndex, targetIsPlayer, targetIndex, targetTeamNumber)

end

function PlayingTeam:OnKill(targetEntity, damage, killer, doer, point, direction)

    if not targetEntity or targetEntity:GetSendDeathMessage() then
    
        local index = 0
        
        if doer and doer:GetDeathIconIndex() then
            index = doer:GetDeathIconIndex()
        end
        
        self:SendCommand( self:GetDeathMessage(killer, index, targetEntity) )
        
    end
    
end

function PlayingTeam:TriggerSayingAction(player, sayingActionTechId)
end

function PlayingTeam:ProcessGeneralHelp(player)

    if((GetGamerules():GetGameState() == kGameState.NotStarted) and player:AddTooltipOnce("The game won't begin until both sides have players.")) then
        return true
    elseif(GetGamerules():GetGameStarted() and player:AddTooltipOnce("The game has begun!")) then
        return true
    elseif(player:isa("AlienCommander") and table.count(player:GetSelection()) > 1 and player:AddTooltipOnce("Press jump to toggle between sub-groups of selected units.")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("Press crouch + weapon key to create a hotgroup and a weapon key to select that group.")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("Press the arrow keys to scroll around.")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("You can leave Commander mode by clicking Logout in the upper right (or logout in console).")) then
        return true
    elseif(not player:isa("Commander") and GetGamerules():GetGameStarted() and player:AddTooltipOnce("Press your C key to bring up your sayings menu.")) then
        return true
    end
        
    return false
    
end

// Look for nearby entities that generate help messages
function PlayingTeam:ProcessEntityHelp(player)
    
    // Look for entities to give help about
    local entities = GetNearbyGameEntitiesInView(player, 4)
    
    for index, entity in ipairs(entities) do
    
        local enemy = GetEnemyTeamNumber(player:GetTeamNumber()) == entity:GetTeamNumber()
        
        if entity:isa("PowerPoint") and entity:ProcessEntityHelp(player) then
            return true
        elseif entity:isa("Structure") and not entity:GetIsBuilt() and player:isa("Marine") and player:AddTooltipOncePer("Help build this structure by pressing your use key.") then
            return true            
        elseif entity:isa("Door") then
        
            if entity:GetState() == Door.kState.Locked and player:AddTooltipOncePer("This door has been locked by the Commander and can be broken by infestation or an Onos.") then
                return true
            elseif player:AddTooltipOncePer("This door can be controlled by the Commander and welded shut.") then
                return true
            end
            
        elseif entity:isa("Armory") and entity:GetIsBuilt() and player:AddTooltipOncePer("Press your use key at this Armory to get healed, get ammo or buy new weapons (e key).") then 
            return true
            
        elseif entity:isa("Hive") then
        
            if enemy and player:AddTooltipOncePer("This is an enemy Hive, kill it!") then
                return true
            elseif not enemy and entity:GetIsOccupied() and player:AddTooltipOncePer(string.format("The commander is inside this Hive. Protect it!")) then
                return true
            elseif not enemy and not entity:GetIsOccupied() and player:AddTooltipOncePer("Press your use key on this Hive to become Commander.") then
                return true
            end
            
        elseif entity:isa("CommandStation") then

            local commander = entity:GetCommander()        
            if not enemy and commander and player:AddTooltipOncePer(string.format("%s is inside this Command Station.", commander:GetName())) then
                return true
            elseif not enemy and not entity:GetIsOccupied() and player:AddTooltipOncePer("This is the Command Station. Use the login screen to become a Commander.") then
                return true
            end
            
        elseif entity:isa("InfantryPortal") then
        
            if enemy and player:AddTooltipOncePer("This Infantry Portal spawns your enemy marines. Destroy it!") then
                return true       
            elseif not enemy and player:AddTooltipOncePer("This Infantry Portal is where you spawn. Guard it!") then
                return true       
            end
            
        elseif entity:isa("Extractor") then
            if enemy and player:AddTooltipOncePer("This Extractor generates resources for your enemy. Destroy it!") then
                return true
            elseif not enemy and player:AddTooltipOncePer("Extractors give 1 resource to each player and your team every " .. kResourceTowerResourceInterval .." seconds.") then
                return true
            end
        elseif entity:isa("Harvester") then
            if enemy and player:AddTooltipOncePer("This Harvester generates resources for your enemy. Destroy it!") then
                return true
            elseif not enemy and player:AddTooltipOncePer("Harvesters give 1 resource to every player and your team every " .. kResourceTowerResourceInterval .. " seconds.") then
                return true
            end
        elseif entity:isa("Egg") then
            if enemy and player:AddTooltipOncePer("Your enemies spawn from these eggs. Destroy them!") then
                return true
            elseif not enemy and player:AddTooltipOncePer("You and your teammates hatch out of these eggs.") then
                return true
            end
        end
        
    end
    
    return false
    
end

function PlayingTeam:UpdateHelp()

    if(self.timeOfLastHelpCheck == nil or (Shared.GetTime() > self.timeOfLastHelpCheck + PlayingTeam.kTooltipHelpInterval)) then
    
        function ProcessPlayerHelp(player)
        
            // Only do this before the game has started
            if((GetGamerules():GetGameState() == kGameState.NotStarted) and player:AddTooltipOnce("The game won't begin until both sides have players.")) then
                return true
            // Only process other help after game has started
            elseif(GetGamerules():GetGameStarted()) then
            
                if player:AddTooltipOnce("The game has begun!") then
                    return true
                else
        
                    if(not self:ProcessGeneralHelp(player)) then
                    
                        if not self:ProcessEntityHelp(player) then
                        
                            player:UpdateHelp()
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end

        self:ForEachPlayer(ProcessPlayerHelp)
    
        self.timeOfLastHelpCheck = Shared.GetTime()
        
    end 
    
end

// Update from alien team instead of in alien buildings think because we need to clear
// game effect flag too.
function PlayingTeam:UpdateGameEffects(timePassed)

    local time = Shared.GetTime()
    
    if not self.timeSinceLastGameEffectUpdate then
        self.timeSinceLastGameEffectUpdate = timePassed
    else
        self.timeSinceLastGameEffectUpdate = self.timeSinceLastGameEffectUpdate + timePassed
    end
    
    if self.timeSinceLastGameEffectUpdate >= PlayingTeam.kUpdateGameEffectsInterval then

        // Friendly entities that alien structures can affect
        local teamEntities = GetGamerules():GetEntities("LiveScriptActor", self:GetTeamNumber())
        local enemyPlayers = GetGamerules():GetPlayers( GetEnemyTeamNumber(self:GetTeamNumber()) )
            
        self:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)       
        
        self.timeSinceLastGameEffectUpdate = self.timeSinceLastGameEffectUpdate - PlayingTeam.kUpdateGameEffectsInterval        
        
    end    

end

function PlayingTeam:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)

    local catchFireEntities = {}
    
    for index, entity in ipairs(teamEntities) do

        if entity:GetGameEffectMask(kGameEffect.OnFire) then
        
            // Do damage over time
            entity:TakeDamage(kBurnDamagePerSecond * PlayingTeam.kUpdateGameEffectsInterval, Shared.GetEntity(entity.fireAttackerId), Shared.GetEntity(entity.fireDoerId))
            
            // See if we put ourselves out
            local stopFireChance = PlayingTeam.kUpdateGameEffectsInterval * kStopFireProbability
            
            if NetworkRandom() < stopFireChance then
            
                entity:SetGameEffectMask(kGameEffect.OnFire, false)

            end
            
        end
    
    end
    
    for index, catchFireEntity in ipairs(catchFireEntities) do
        catchFireEntity:SetGameEffectMask(kGameEffect.OnFire, true)
    end
    
end
