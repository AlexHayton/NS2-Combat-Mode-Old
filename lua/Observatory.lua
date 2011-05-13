// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Observatory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Observatory' (Structure)

Observatory.kMapName = "observatory"

Observatory.kModelName = PrecacheAsset("models/marine/observatory/observatory.model")

Observatory.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/observatory_scan")
Observatory.kDistressBeaconSound = PrecacheAsset("sound/ns2.fev/marine/common/distress_beacon")

Observatory.kGlowingLightEffect = PrecacheAsset("cinematics/marine/observatory/glowing_light_effect.cinematic")
Observatory.kDistressBeaconTime = kDistressBeaconTime
Observatory.kDistressBeaconRange = kDistressBeaconRange

function Observatory:OnInit()

    self:SetModel(Observatory.kModelName)
    
    Structure.OnInit(self)
    
end

function Observatory:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = {   kTechId.Scan, kTechId.PhaseTech, kTechId.DistressBeacon, kTechId.None, 
                                kTechId.InfantryPortalTransponderTech, kTechId.None, kTechId.Recycle, kTechId.None }
        
        return techButtons
        
    end
    
    return nil
    
end

function Observatory:GetRequiresPower()
    return true
end

function Observatory:TriggerScan(position)

    // Create scan entity in world at this position
    CreateEntity(Scan.kMapName, position, self:GetTeamNumber())
    
    Shared.PlayWorldSound(nil, Observatory.kScanSound, nil, position)
    
end

function Observatory:TriggerDistressBeacon()

    local success = false
    
    if not self.distressBeaconTime then
    
        self:PlaySound(Observatory.kDistressBeaconSound)
        
        // Beam all faraway players back in a few seconds!
        self.distressBeaconTime = Shared.GetTime() + Observatory.kDistressBeaconTime
        
        success = true
    
    end
    
    return success
    
end

function Observatory:PerformDistressBeacon()

    self:StopSound(Observatory.kDistressBeaconSound)

    // For all players on team that are alive, aren't commanding and are kind of far away, beam them back to this Observatory
    local players = self:GetTeam():GetPlayers()
        
    for index, player in ipairs(players) do
    
        if player:GetIsAlive() and not player:isa("Commander") then
        
            if (player:GetOrigin() - self:GetOrigin()):GetLength() > Observatory.kDistressBeaconRange then
            
                self:RespawnPlayer(player)
                
            end
            
        end
        
    end
    
end

function Observatory:RespawnPlayer(player)

    // Get spawn point
    local success, spawnPoint = GetRandomSpaceForEntity(self:GetModelOrigin(), 3, Observatory.kDistressBeaconRange * .8, 3, 2)
    
    if success then
    
        // Reset player state
        player:SetOrigin(spawnPoint)       
        player:TriggerEffects("distress_beacon")            
        
    else
        Print("Observatory:RespawnPlayer(): Couldn't find space to respawn player.")
    end
    
end

function Observatory:OnUpdate(deltaTime)

    Structure.OnUpdate(self, deltaTime)

    if self.distressBeaconTime then
    
        if Shared.GetTime() >= self.distressBeaconTime then
        
            self:PerformDistressBeacon()
            self.distressBeaconTime = nil
            
        end
        
    end
    
end

function Observatory:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if self:GetIsBuilt() and self:GetIsActive() then
    
        if techId == kTechId.Scan then
        
            self:TriggerScan(position)
            success = true

        elseif techId == kTechId.DistressBeacon then
        
            success = self:TriggerDistressBeacon()
            
        else        
            success = LiveScriptActor.PerformActivation(self, techId, position, normal, commander)
        end
    
    end
    
    return success
    
end

function Observatory:OnKill(damage, killer, doer, point, direction)

    self:StopSound(Observatory.kDistressBeaconSound)
    
    Structure.OnKill(self, damage, killer, doer, point, direction)
    
end

Shared.LinkClassToMap("Observatory", Observatory.kMapName, {})

