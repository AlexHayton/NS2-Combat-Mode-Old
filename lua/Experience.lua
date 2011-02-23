//
// lua\Experience.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
//
// Manages the experience ranks and generic functions for dealing with experience.
//
Script.Load("lua/Globals.lua")
Script.Load("lua/BalanceHealth.lua")

// Proper globals
kExperienceDamageModifier = 0.1
kExperienceAssistModifier = 0.5
kExperienceLevelUpSoundMarine = PrecacheAsset("sound/combat.fev/combat/combat/levelup_marine")
kExperienceLevelUpSoundAlien = PrecacheAsset("sound/combat.fev/combat/combat/levelup_alien")

// 'Local' globals
kMaxExperience = 10000.0
kRankExp = { 50.0, 150.0, 500.0, 1000.0, 1750.0, 3000.0, 5000.0, kMaxExperience, kMaxExperience + 1}
kMarineRanks = { "Private", "Private First Class", "Sergeant", "Lieutenant", "Commander", "General", "Master General", "Commander-in-Chief", "Superman" }
kAlienRanks = { "Worm", "Slug", "Parasite", "Crawler", "Hunter", "Prowler", "Beast", "Overlord", "Deity" }
kExperienceRadius = 10
kDamageModifiers = {	PowerPoint=1/(kStructuralDamageScalar*2), 
									InfantryPortal=1/kStructuralDamageScalar, 
									CommandStation=1/kStructuralDamageScalar }

// One more global									
kMaxRank = table.maxn(kRankExp)

function Experience_ComputeExperience(hitentity, damage)
    // Special rules for powerpoints etc.
    if (kDamageModifiers[hitentity:GetClassName()] ~= nil) then
        damage = damage * kDamageModifiers[hitentity:GetClassName()]
    end
    return damage * kExperienceDamageModifier
end

function Experience_GetNumSkillsAvailable(rank)
    return rank
end

function Experience_GetRank(experience)
    // Find an efficient way to look this up.
	for rank,exp in ipairs(kRankExp) do
		if (exp > experience) then
			return rank
		end
	end
end

function Experience_GetNextRankExp(rank)
    return kRankExp[rank]
end

function Experience_GetRankName(teamname, rank)
    // Marines - a better way to detect this?
	if (teamname == 0) then
		return "Spectator"
	end
	
    if (teamname == 1) then
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