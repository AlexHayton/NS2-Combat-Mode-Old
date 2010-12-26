//
// lua\GUIScoreboard.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
//
// Manages the experience ranks and generic functions
//

kMaxExperience = 2000
kRankExp = { 0, 10, 20, 40, 80, 150, 300, kMaxExperience }
kMarineRanks = { "Private", "Private First Class", "Sergeant", "Lieutenant", "Commander", "General", "Master General" }
kAlienRanks = { "Worm", "Slug", "Parasite", "Crawler", "Hunter", "Beast", "Overlord" }
kExperienceRadius = 10
kDamageModifiers = { PowerPoint=0.1, InfantryPortal=0.2, CommandStation=0.2 }
kExperienceDamageModifier = 0.1
kExperienceAssistModifier = 0.5

kMaxRank = table.maxn(kRankExp) - 1

function Experience_ComputeExperience(hitentity, damage)
    // Special rules for powerpoints etc.
    if (kDamageModifiers[hitentity:GetClassName()] ~= nil) then
        damage = damage * kDamageModifiers[hitentity:GetClassName()]
    end
    return damage * kExperienceDamageModifier
end

function Experience_GetNumSkillsAvailable(rank)
    return rank + 1
end

function Experience_GetRank(experience)
    // Find an efficient way to look this up. Is there a sort function?
    for rank,exp in ipairs(kRankExp) do
        if (exp > experience) then
            return rank - 1
        end
    end
end

function Experience_GetNextRank(rank)
    return kRankExp[rank + 1]
end

function Experience_GetRankName(teamname, rank)
    // Marines - a better way to detect this?
    if (teamname == "Marines") then
        return kMarineRanks[rank]
    else
        return kAlienRanks[rank]
    end
end

function Experience_GetMaxExperience()
    return kMaxExperience
end


function Experience_GrantNearbyExperience(pointOwner, points)
    local friendlies = GetGamerules():GetEntities("Player", pointOwner:GetTeamNumber(), pointOwner:GetOrigin(), kExperienceRadius)
    
    for index, entity in ipairs(friendlies) do
    
        if (entity:GetOrigin() - pointOwner:GetOrigin()):GetLength() < kExperienceRadius then

            if not entity:isa("Commander") and not entity == pointOwner then

                // Make sure player can "see" nearby friend
                local trace = Shared.TraceRay(pointOwner:GetOrigin(), entity:GetOrigin(), PhysicsMask.Bullets)
                if trace.fraction == 1.0 or trace.entity == entity then
                
                    // Add the experience with reduction by a factor
                    entity:AddExperience(points * kExperienceAssistModifier)
                    
                end
                
            end
            
        end
        
    end
end