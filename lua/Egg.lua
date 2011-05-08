// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Egg.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Thing that aliens spawn out of.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/Onos.lua")
Script.Load("lua/InfestationMixin.lua")

class 'Egg' (Structure)
PrepareClassForMixin(Egg, InfestationMixin)

Egg.kMapName = "egg"

Egg.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Egg.kMistEffect = PrecacheAsset("cinematics/alien/egg/mist.cinematic")
Egg.kSpawnEffect = PrecacheAsset("cinematics/alien/egg/spawn.cinematic")
Egg.kGlowEffect = PrecacheAsset("cinematics/alien/egg/glow.cinematic")

Egg.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/egg/spawn")

Egg.kXExtents = 1
Egg.kYExtents = 1
Egg.kZExtents = 1

Egg.kHealth = kEggHealth
Egg.kArmor = kEggArmor

Egg.kThinkInterval = .5

function Egg:OnCreate()
    Structure.OnCreate(self)
    
    self:SetModel(Egg.kModelName)
    
end

function Egg:OnInit()
    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
    
    self.queuedPlayerId = nil
    
    if Server then
    
        self:SetNextThink(Egg.kThinkInterval)
    
        self:PlaySound(Egg.kSpawnSoundName)
        
        Shared.CreateEffect(nil, Egg.kMistEffect, nil, self:GetCoords())
        
    end
    
end

function Egg:GetBaseArmor()
    return Egg.kArmor
end

function Egg:GetArmorFullyUpgradedAmount()
    return 0
end

function Egg:GetIsAlienStructure()
    return true
end

function Egg:QueueWaitingPlayer()

    // Get team
    local success = false
    
    if(self.queuedPlayerId == nil and (self:GetId() ~= Entity.invalidId)) then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if(playerToSpawn ~= nil) then
            
            team:RemovePlayerFromRespawnQueue(playerToSpawn)        
            
            self.queuedPlayerId = playerToSpawn:GetId()
            self.timeQueuedPlayer = Shared.GetTime()
            
            if playerToSpawn:isa("AlienSpectator") then
            
                playerToSpawn:SetEggId(self:GetId())
                success = true    
                
            else
                Print("Egg:QueueWaitingPlayer(): queuing %s instead of AlienSpectator", playerToSpawn:GetClassName())
            end
            
        end
        
    end
    
    return success

end

function Egg:OnKill(damage, attacker, doer, point, direction)

    // If we were spawning a player, put them back in the respawn queue
    if self.queuedPlayerId ~= nil then
    
        local player = Shared.GetEntity(self.queuedPlayerId) 
        self:GetTeam():PutPlayerInRespawnQueue(player, Shared.GetTime())
        
    end

    self:TriggerEffects("egg_death")        
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)
    
end

// Grab player out of respawn queue unless player passed in (for test framework)
function Egg:SpawnPlayer(player)

    if(self.queuedPlayerId ~= nil or player) then
    
        local queuedPlayer = player
        if not player then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        // Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        
        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles())
        if(success) then
        
            self.queuedPlayerId = nil
            
            self:TriggerEffects("egg_death")
            
            DestroyEntity(self) 
            
            return true
            
        end
            
    end
    
    return false

end

function Egg:GetQueuedPlayerId()
    return self.queuedPlayerId
end

function Egg:GetTimeQueuedPlayer()
    return self.timeQueuedPlayer
end

if Server then
function Egg:OnThink()

    if self:GetIsAlive() then
    
        Structure.OnThink(self)

        // If no player in queue
        if(self.queuedPlayerId == nil) then
            
            // Grab available player from team and put in queue
            self:QueueWaitingPlayer()

        else
        
            local startTime = self:GetTimeQueuedPlayer()
            if startTime ~= nil and (Shared.GetTime() > (startTime + kAlienSpawnTime)) then
            
                local player = Shared.GetEntity(self.queuedPlayerId)
                if player ~= nil then
                    player:AddTooltipOncePer(string.format("Press your attack key to hatch!"), 8)   
                else
                    self.queuedPlayerId = nil
                end
            end
        end
        
    end
    
    self:SetNextThink(Egg.kThinkInterval)
    
end

function Egg:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SpawnInfestation()
end
end

Shared.LinkClassToMap("Egg", Egg.kMapName, {})
