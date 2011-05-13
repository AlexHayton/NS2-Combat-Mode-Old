// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhaseGate.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'PhaseGate' (Structure)

PhaseGate.kMapName = "phasegate"

PhaseGate.kThinkInterval = 0.25
PhaseGate.kModelName = PrecacheAsset("models/marine/phase_gate/phase_gate.model")

// Can only teleport a player every so often
PhaseGate.kDepartureRate = .5

function PhaseGate:OnInit()

    Structure.OnInit(self)

    self:SetModel(PhaseGate.kModelName)
    
    if Server then
    self:SetNextThink(PhaseGate.kThinkInterval)
    self.timeOfLastPhase = nil
    end
    
end

function PhaseGate:GetTechButtons(techId)

    return { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.None, kTechId.None, kTechId.Recycle, kTechId.None }
    
end

// Temporarily don't use "target" attach point
function PhaseGate:GetEngagementPoint()
    return LiveScriptActor.GetEngagementPoint(self)
end

if Server then

function PhaseGate:OnThink()

    Structure.OnThink(self)
    
    // If built and active 
    if self:GetIsBuilt() and self:GetIsActive() and (self.timeOfLastPhase == nil or (Shared.GetTime() > (self.timeOfLastPhase + PhaseGate.kDepartureRate))) then
    
        local players = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1)
        
        for index, player in ipairs(players) do
        
            if player.GetCanPhase and player:GetCanPhase() then
            
                local destinationPhaseGate = self:GetDestinationGate()
                
                if destinationPhaseGate then 
                
                    local destOrigin = destinationPhaseGate:GetOrigin() + Vector(0, player:GetExtents().y, 0)
                    
                    // Check if destination is clear
                    if player:SpaceClearForEntity(destOrigin) then
                    
                        player:TriggerEffects("phase_gate_player_enter")
                
                        SpawnPlayerAtPoint(player, destOrigin, destinationPhaseGate:GetAngles())
                    
                        player:TriggerEffects("phase_gate_player_exit")
                        
                        self.timeOfLastPhase = Shared.GetTime()
                        
                        player:SetTimeOfLastPhase(self.timeOfLastPhase)
                        
                        break    
    
                    end
                    
                end
                
            end
            
        end
            
    end
    
    self:SetNextThink(PhaseGate.kThinkInterval)
    
end

// Returns next phase gate in round-robin order. Returns nil if there are no other built/active phase gates 
function PhaseGate:GetDestinationGate()

    // Find next phase gate to teleport to
    local phaseGates = {}    
    for index, phaseGate in ipairs( GetEntitiesForTeam("PhaseGate", self:GetTeamNumber()) ) do
        if phaseGate:GetIsAlive() and phaseGate:GetIsBuilt() and phaseGate:GetIsActive() then
            table.insert(phaseGates, phaseGate)
        end
    end    
    
    if table.count(phaseGates) < 2 then
        return nil
    end
    
    // Find our index and add 1
    local index = table.find(phaseGates, self)
    ASSERT(index ~= nil)
    
    local nextIndex = ConditionalValue(index == table.count(phaseGates), 1, index + 1)
    ASSERT(nextIndex >= 1)
    ASSERT(nextIndex <= table.count(phaseGates))
    return phaseGates[nextIndex]
    
end
        
end

Shared.LinkClassToMap("PhaseGate", PhaseGate.kMapName)