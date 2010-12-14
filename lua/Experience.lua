//
// lua\GUIScoreboard.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
//
// Manages the experience ranks and generic functions
//

gMaxExperience = 1000
gMarineRanks { "Private"=0, "Private First Class"=10, "Sergeant"=20, "Lieutenant"=40, "Commander"=80, "General"=150, "Master General"=300 }
gAlienRanks { "Worm"=0, "Slug"=10, "Parasite"=20, "Alien Rank 4"=40, "Alien Rank 5"=80, "Alien Rank 6"=150, "Alien Rank 7"=300 }

function Experience_GetNumSkillsAvailable(experience)

end

function Experience_GetRank(experience)

end

function Experience_GetMaxExperience()
    return gMaxExperience
end