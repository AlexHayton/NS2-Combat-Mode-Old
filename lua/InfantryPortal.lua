// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfantryPortal.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'InfantryPortal' (Structure)

InfantryPortal.kMapName = "infantryportal"

InfantryPortal.kModelName = PrecacheAsset("models/marine/infantry_portal/infantry_portal.model")

InfantryPortal.kAnimSpinStart = "spin_start"
InfantryPortal.kAnimSpinStop = "spin_stop"
InfantryPortal.kAnimSpinContinuous = "spin"

InfantryPortal.kLoopSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_active")
InfantryPortal.kSpawnPlayerSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_player_spawn")
InfantryPortal.kStartSpinSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_start_spin")
InfantryPortal.kSquadSpawnFailureSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn_fail")
InfantryPortal.kSquadSpawnSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn")

InfantryPortal.kDeathEffect = PrecacheAsset("cinematics/marine/infantryportal/death.cinematic")
InfantryPortal.kSpinEffect = PrecacheAsset("cinematics/marine/infantryportal/spin.cinematic")
InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")
InfantryPortal.kSpawnEffect = PrecacheAsset("cinematics/marine/infantryportal/player_spawn.cinematic")

InfantryPortal.kTransponderUseTime = .5
InfantryPortal.kThinkInterval = 0.25
InfantryPortal.kSpawnTime = 8
InfantryPortal.kTransponderPointValue = 15
InfantryPortal.kLoginAttachPoint = "keypad"

function InfantryPortal:OnInit()

    Structure.OnInit(self)

    self:SetModel(InfantryPortal.kModelName)
    
    self.queuedPlayerId = nil
    
    // For both client and server
    self:SetNextThink(InfantryPortal.kThinkInterval)
    
end

function InfantryPortal:GetRequiresPower()
    return true
end

function InfantryPortal:GetUseAttachPoint()
    return InfantryPortal.kLoginAttachPoint
end

function InfantryPortal:GetDeathEffect()
    return InfantryPortal.kDeathEffect
end

function InfantryPortal:GetRecycleScalar()
    return kInfantryPortalRecycleScalar
end

function InfantryPortal:QueueWaitingPlayer()

    // Get team
    if(self.queuedPlayerId == nil) then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if(playerToSpawn ~= nil) then
        
            playerToSpawn = team:GetOldestQueuedPlayer()
            
            team:RemovePlayerFromRespawnQueue(playerToSpawn)        
            self.queuedPlayerId = playerToSpawn:GetId()

            self:StartSpinning()            
            
            playerToSpawn:AddTooltipOncePer(string.format("You are now respawning at an infantry portal")) 
            
        end
        
    end

end

function InfantryPortal:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        if(researchId == kTechId.InfantryPortalTransponderUpgrade) then
        
            success = self:Upgrade(kTechId.InfantryPortalTransponder)
            
        end
        
    end
    
end

function InfantryPortal:GetSpawnTime()
    return InfantryPortal.kSpawnTime
end

function InfantryPortal:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = {   kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
                                kTechId.None, kTechId.None, kTechId.Recycle, kTechId.None }

        // Don't display if upgraded already        
        if self:GetTechId() ~= kTechId.InfantryPortalTransponder then
            techButtons[kMarineUpgradeButtonIndex] = kTechId.InfantryPortalTransponderUpgrade
        end
        
        return techButtons
        
    end
    
    return nil
    
end

function InfantryPortal:OnReplace(newStructure)

    Structure.OnReplace(self, newStructure)
    
    newStructure.queuedPlayerId = self.queuedPlayerId
    
    newStructure:SetNextThink(InfantryPortal.kThinkInterval)

end

if(Server) then

function InfantryPortal:OnUse(player, elapsedTime, useAttachPoint)

    local success = false
    
    if(not Structure.OnUse(self, player, elapsedTime, useAttachPoint)) then
    
        if(self:GetIsBuilt() and self:GetTeamNumber() == player:GetTeamNumber()) then
        
            // Also functions as "transponder" which allows marines to spawn with their squad by using IP
            if self:GetTechId() == kTechId.InfantryPortalTransponder /*and useAttachPoint*/ then

                local currentTime = Shared.GetTime()
                
                if(self.timeOfLastUse == nil or currentTime > self.timeOfLastUse + InfantryPortal.kTransponderUseTime) then
            
                    if player:SpawnInSquad() then
                    
                        // Play squad spawn sound where you end up
                        Shared.PlayWorldSound(nil, InfantryPortal.kSquadSpawnSound, nil, self:GetOrigin())
                        
                        success = true
                        
                    end
                    
                    self.timeOfLastUse = currentTime
                    
                end
                
                // Play invalid sound
                if not success then
                    Shared.PlayWorldSound(nil, InfantryPortal.kSquadSpawnFailureSound, nil, self:GetOrigin())
                end
                
            end
        
        end
        
    end
    
    return success
    
end

end

function InfantryPortal:SpawnTimeElapsed()

    local elapsed = false
    
    if(self.queuedPlayerId ~= nil) then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        if(queuedPlayer == nil) then
            self.queuedPlayerId = nil
        else
            local enteredQueueTime = queuedPlayer:GetRespawnQueueEntryTime()
            local time = Shared.GetTime()
            
            if(enteredQueueTime ~= nil and (time - enteredQueueTime) >= self:GetSpawnTime()) then
            
                elapsed = true
                
            end
        end        
    end
    
    return elapsed

end

function InfantryPortal:SpinUpTimeElapsed()

    local elapsed = false
    
    if(self.timeSpinUpStarted ~= nil) then
    
        elapsed = (Shared.GetTime() > self.timeSpinUpStarted + self:GetAnimationLength(InfantryPortal.kAnimSpinStart))
        
    end
    
    return elapsed
    
end

// Spawn player on top of IP. Returns true if it was able to, false if way was blocked.
function InfantryPortal:SpawnPlayer()

    if(self.queuedPlayerId ~= nil) then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        local team = queuedPlayer:GetTeam()
    
        // Spawn player on top of IP
        local spawnOrigin = Vector(self:GetOrigin())
        
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, self:GetAngles())
        if(success) then
        
            self.queuedPlayerId = nil
            
            spawnOrigin.y = spawnOrigin.y + player:GetExtents().y
            player:SetOrigin(spawnOrigin)       
            
            // Play sound and remove player from queue
            self:PlaySound(InfantryPortal.kSpawnPlayerSound)
            
            Shared.CreateEffect(nil, InfantryPortal.kSpawnEffect, self)
            
            return true
            
        end
            
    end
    
    return false

end

function InfantryPortal:OnReset()

    Structure.OnReset(self)
    
    Shared.StopEffect(nil, InfantryPortal.kSpawnEffect, self)

end

if Server then
function InfantryPortal:OnEntityChange(entityId, newEntityId)
    
    if(self.queuedPlayerId == entityId) then
    
        // Player left or was replaced, either way 
        // they're not in the queue anymore
        self.queuedPlayerId = nil
        
    end
    
end
end

function InfantryPortal:OnKill(damage, attacker, doer, point, direction)
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)

    // Don't spawn player
    self.queuedPlayerId = nil
    
end

function InfantryPortal:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:PlaySound(InfantryPortal.kLoopSound)
    
end

function InfantryPortal:OnThink()

    Structure.OnThink(self)
    
    // If built and active 
    if Server then
    
        if self:GetIsBuilt() and self:GetIsActive() then
        
            // If no player in queue
            if(self.queuedPlayerId == nil) then
            
                // Grab available player from team and put in queue
                self:QueueWaitingPlayer()
               
            // else if time has elapsed to spawn player
            elseif(self:SpawnTimeElapsed()) then
            
                self:SpawnPlayer()
                self:SetAnimation(InfantryPortal.kAnimSpinStop)
                self.timeSpinUpStarted = nil
                
            elseif(self:SpinUpTimeElapsed()) then
            
                self:SetAnimation(InfantryPortal.kAnimSpinContinuous)
                self.timeSpinUpStarted = nil
                
            end

            // Stop spinning if player left server, switched teams, etc.            
            if self.queuedPlayerId == nil then
            
                self:StopSpinning()
                
            end
            
        end
        
    // Start or stop the spinning effect on the client
    else
            
        local anim = self:GetAnimation()
        local spinning = (anim == InfantryPortal.kAnimSpinContinuous or anim == InfantryPortal.kAnimSpinStart)
        
        if spinning and (self.spinEffectInstance == nil) then
        
            self.spinEffectInstance = Client.CreateCinematic(RenderScene.Zone_Default)
            self.spinEffectInstance:SetCinematic(InfantryPortal.kSpinEffect)
            self.spinEffectInstance:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.spinEffectInstance:SetCoords(self:GetCoords())

        elseif not spinning and self.spinEffectInstance then
        
            Client.DestroyCinematic(self.spinEffectInstance)
            self.spinEffectInstance = nil
            
        end
        
    end
    
    self:SetNextThink(InfantryPortal.kThinkInterval)

end

function InfantryPortal:StopSpinning()

    local anim = self:GetAnimation()
    
    if (anim == InfantryPortal.kAnimSpinContinuous or anim == InfantryPortal.kAnimSpinStart) then
    
        self:SetAnimation(InfantryPortal.kAnimSpinStop)
        self.timeSpinUpStarted = nil
        
    end

end

function InfantryPortal:StartSpinning()

    self:SetAnimation(InfantryPortal.kAnimSpinStart)
    self:PlaySound(InfantryPortal.kStartSpinSound)
    
    self.timeSpinUpStarted = Shared.GetTime()

end

function InfantryPortal:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    if not self.powered then
    
        self:StopSpinning()
        
    elseif (self.queuedPlayerId ~= nil) then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        
        if queuedPlayer then
        
            queuedPlayer:SetRespawnQueueEntryTime(Shared.GetTime())
            
            self:StartSpinning()
            
        end
        
    end
    
end

if Client then
function InfantryPortal:OnDestroy()

    if self.spinEffectInstance then
        
        Client.DestroyCinematic(self.spinEffectInstance)
        self.spinEffectInstance = nil
        
    end
    
    Structure.OnDestroy(self)
    
end
end

Shared.LinkClassToMap("InfantryPortal", InfantryPortal.kMapName)