// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gorge:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(SpitSpray.kMapName)
    self:GiveItem(InfestationAbility.kMapName)
    self:GiveItem(HydraAbility.kMapName)
    
    self:SetActiveWeapon(SpitSpray.kMapName)
    
end

// When we're in our Gorge armor shell, damage comes off of energy first
function Gorge:ComputeDamageOverride(damage, damageType)

    if(self.mode == kPlayerMode.GorgeArmor) then
    
        // Soak as much damage as we can in energy
        local energyNeeded = damage/Gorge.kDamageEnergyFactor
        local energyUsed = math.min(self.energy, energyNeeded)
        self.energy = self.energy - energyUsed
        
        damage = damage - energyUsed*Gorge.kDamageEnergyFactor
        
    end
    
    return damage, damageType
    
end

// Create hydra from menu
function Gorge:AttemptToBuy(techId)

    // Drop hydra
    if (techId == kTechId.Hydra) then    
    
        // Create hydra in front of us
        local playerViewPoint = self:GetOrigin() + self:GetViewOffset()
        local hydraEndPoint = playerViewPoint + self:GetViewAngles():GetCoords().zAxis * 2
        local trace = Shared.TraceRay(playerViewPoint, hydraEndPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        local hydraPosition = trace.endPoint
        
        local hydra = CreateEntity(LookupTechData(techId, kTechDataMapName), hydraPosition, self:GetTeamNumber())
        
        // Make sure there's room
        if(hydra:SpaceClearForEntity(hydraPosition)) then
        
            hydra:SetOwner(self)

            self:AddResources(-LookupTechData(techId, kTechDataCostKey))
                    
            self:TriggerEffects("gorge_create")
            
            self:SetActivityEnd(.6)

        else
        
            DestroyEntity(hydra)
            
        end
        
        return true
        
    else
    
        return Alien.AttemptToBuy(self, techId)
        
    end
    
end


