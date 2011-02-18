// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SporeCloud.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'SporeCloud' (ScriptActor)

// Spores didn't stack in NS1 so consider that
SporeCloud.kMapName = "sporecloud"

// Damage per think interval (from NS1)
SporeCloud.kDamage = 7
SporeCloud.kThinkInterval = .5  // From NS1
SporeCloud.kDamageRadius = 5.7  // From NS1
SporeCloud.kLifetime = 6.0      // From NS1

// Keep table of entities that have been hurt by spores to make
// spores non-stackable. List of {entityId, time} pairs.
gHurtBySpores = {}

function GetEntityRecentlyHurt(entityId, time)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId and pair[2] > time then
            return true
        end
    end
    
    return false
    
end

function SetEntityRecentlyHurt(entityId)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId then
            table.remove(gHurtBySpores, index)
        end
    end
    
    table.insert(gHurtBySpores, {entityId, Shared.GetTime()})
    
end

function SporeCloud:GetDeathIconIndex()
    return kDeathMessageIcon.SporeCloud
end

function SporeCloud:OnThink()

    ScriptActor.OnThink(self)

    // Expire after a time
    local time = Shared.GetTime()
    local enemies = GetGamerules():GetPlayers( GetEnemyTeamNumber(self:GetTeamNumber()) )
    
    for index, entity in ipairs(enemies) do
    
        if (entity:GetOrigin() - self:GetOrigin()):GetLength() < SporeCloud.kDamageRadius then

            if not entity:isa("Commander") and not GetEntityRecentlyHurt(entity:GetId(), (time - SporeCloud.kThinkInterval)) then

                // Make sure spores can "see" target        
                local trace = Shared.TraceRay(self:GetOrigin(), entity:GetOrigin(), PhysicsMask.Bullets)
                if trace.fraction == 1.0 or trace.entity == entity then
                
                    entity:TakeDamage(SporeCloud.kDamage, self:GetOwner(), self)
                    
                    // Spores can't hurt this entity for SporeCloud.kThinkInterval
                    SetEntityRecentlyHurt(entity:GetId())
                    
                end
                
            end
            
        end
        
    end
    
    if Shared.GetTime() > (self.createTime + SporeCloud.kLifetime) then
        DestroyEntity(self)        
    else
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
end

function SporeCloud:OnInit()

    self:SetUpdates(true)

    if Server then
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
    self.createTime = Shared.GetTime()
    
end

Shared.LinkClassToMap("SporeCloud", SporeCloud.kMapName, {} )
