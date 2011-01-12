// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GeneralEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kGeneralEffectData = 
{
    on_create =
    {
        onCreateEffects =
        {
            {parented_sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC", done = true},
        },
    },

    spawn =
    {
        generalSpawnEffects =
        {        
            {sound = "sound/ns2.fev/alien/skulk/spawn", classname = "Skulk", done = true},
            {sound = "sound/ns2.fev/alien/gorge/spawn", classname = "Gorge", done = true},
            {sound = "sound/ns2.fev/alien/lerk/spawn", classname = "Lerk", done = true},
            {sound = "sound/ns2.fev/alien/fade/spawn", classname = "Fade", done = true},
            {sound = "sound/ns2.fev/alien/onos/spawn", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/common/connect", classname = "Player", done = true},            

            {sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC", done = true},            
            {sound = "sound/ns2.fev/alien/drifter/spawn", classname = "Drifter", done = true},
            
            {sound = "sound/ns2.fev/alien/structures/generic_spawn_large", isalien = true, done = true},
            {sound = "sound/ns2.fev/marine/structures/generic_spawn", isalien = false, done = true},
            
        },
        
        spawnAnimations =
        {
            {animation = "idle", classname = "MAC", done = true},
            {animation = "idle", classname = "Drifter", done = true},            
            {animation = "", classname = "PowerPoint", done = true},            
            // Structure spawn animations handled in code ("spawn")
        },
    },
    
    // Structure deploy animations handled in code ("deploy")
    deploy =
    {
        deploySoundEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/hive_deploy", classname = "Hive", done = true},
            {sound = "sound/ns2.fev/marine/structures/command_station_open", classname = "CommandStation", done = true},
            {sound = "sound/ns2.fev/marine/structures/extractor_deploy", classname = "Extractor", done = true},
            {sound = "sound/ns2.fev/marine/structures/deploy_small", classname = "Harvester", done = true},
            {sound = "sound/ns2.fev/alien/structures/hydra/deploy", classname = "Hydra", done = true},
            {sound = "sound/ns2.fev/alien/structures/deploy_large", isalien = true, done = true},
            {sound = "sound/ns2.fev/marine/structures/generic_deploy", isalien = false, done = true},            
        },        
    },

    idle =
    {
        idleAnimations =
        {        
            {animation = {{.4, "idle_active"}, {.7, "idle_active2"}, {.7, "idle_active3"}}, classname = "Hive", occupied = true, done = true},
            {animation = {{1.4, "idle_inactive"}, {.3, "idle_inactive2"}, {.3, "idle_inactive3"}}, classname = "Hive", occupied = false, done = true},
            {animation = {{1.0, "idle"}, {.5, "idle2"}, {.05, "idle3"}, {.05, "idle4"}}, classname = "Drifter", done = true},
            
            {animation = {{.6, "idle2"}, {1, "idle3"}, {1, "idle4"}, {.1, "idle5"}, {.1, "idle6"}}, classname = "Fade", done = true},
            {animation = {{2.0, "idle2"}, {.1, "idle3"}}, classname = "Sentry", done = true},
            {animation = {{1.5, "idle"}, {.1, "idle2"}}, classname = "Hydra", done = true},
            {animation = {{1, "idle"}, {.4, "idle2"}, {.3, "idle3"}, {.2, "idle4"}}, classname = "Whip", done = true},
            {animation = {{1, "idle"}, {.1, "idle2"}}, classname = "MAC", done = true},
            
            // Don't idle
            {animation = nil, classname = "Door", done = true},
            {animation = nil, classname = "CommandStation", done = true},
            {animation = nil, classname = "Extractor", done = true},
            {animation = nil, classname = "Harvester", done = true},
            {animation = nil, classname = "PowerPoint", done = true},
            {animation = nil, classname = "InfantryPortal", done = true},

            // Don't put messages to log, too spammy
            {animation = "idle", classname = "Structure"},
        },
        
        idleSounds =
        {
            {sound = "sound/ns2.fev/alien/structures/hive_idle", classname = "Hive", done = true},
            {sound = "sound/ns2.fev/alien/structures/hydra/idle", classname = "Hydra", done = true},
            {sound = "sound/ns2.fev/alien/structures/crag/idle", classname = "Crag", done = true},
            {sound = "sound/ns2.fev/alien/structures/shade/idle", classname = "Shade", done = true},
            {sound = "sound/ns2.fev/alien/structures/shift/idle", classname = "Shift", done = true},
            {sound = "sound/ns2.fev/alien/structures/whip/idle", classname = "Whip", done = true},
            {sound = "sound/ns2.fev/marine/flamethrower/idle", classname = "Flamethrower", done = true},
        },
    },

    flinch =
    {
        generalFlinchCinematicEffects =
        {        
            {cinematic = "cinematics/alien/structures/hit_big.cinematic", classname = "Structure", isalien = true, flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/structures/hit.cinematic", classname = "Structure", isalien = true, done = true},
            {cinematic = "cinematics/marine/structures/hit_big.cinematic", classname = "Structure", isalien = false, flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hit.cinematic", classname = "Structure", isalien = false, done = true},
            
            {cinematic = "cinematics/alien/hit.cinematic", classname = "Alien", done = true},
            {cinematic = "cinematics/marine/hit.cinematic", classname = "Marine", done = true},            
        },
        
        generalFlinchAnimations =
        {
            // Special hive flinch animations
            {overlay_animation = "flinch_active_flames", classname = "Hive", built = true, damagetype = kDamageType.Flame, occupied = true, done = true},
            {overlay_animation = "flinch_inactive_flames", classname = "Hive", built = true, damagetype = kDamageType.Flame, occupied = false, done = true},
           
            {overlay_animation = "flinch_flames", damagetype = kDamageType.Flame, done = true},
            
            {overlay_animation = "flinch", done = true},
            
            // TODO: Add marine flinch animations ("rifle_flinch")            
        },
        
        generalFlinchSoundEffects =
        {        
            // Specific flinch sounds
            {sound = "sound/ns2.fev/alien/skulk/wound_serious", classname = "Skulk", flinch_severe = true, stop = true},           
            {sound = "sound/ns2.fev/alien/skulk/wound", classname = "Skulk", stop = true},           
            {sound = "sound/ns2.fev/alien/gorge/wound", classname = "Gorge", stop = true},           
            // The lerk wound sound is causing static and then FMOD to stop working completely
            //{sound = "sound/ns2.fev/alien/lerk/wound", classname = "Lerk", stop = true},           
            {sound = "sound/ns2.fev/alien/fade/wound", classname = "Fade", stop = true},           
            {sound = "sound/ns2.fev/alien/onos/wound", classname = "Onos", stop = true},           
            {sound = "sound/ns2.fev/alien/structures/harvester_wound", classname = "Harvester", stop = true},                       
            {sound = "sound/ns2.fev/alien/structures/hive_wound", classname = "Hive", stop = true},                       
            
            // TODO: Add common/near_death sound
        },
        
        aiUnitEffects =
        {        
            // MACs
            {sound = "sound/ns2.fev/marine/structures/mac/pain", classname = "MAC"},
            {animation = "flinch", classname = "MAC", done = true},
            
            // Drifters
            {sound = "sound/ns2.fev/alien/drifter/wound", classname = "Drifter"},
            {animation = "flinch_flames", classname = "Drifter", damagetype = kDamageType.Flame, done = true},
            {animation = "flinch", classname = "Drifter"},  
        },
    },
    
    animation_complete =
    {
        // Turn structures into ragdolls after death animation finishes
        ragdollEffects =
        {
            {ragdoll = "", from_animation = "death_closed", classname = "CommandStation", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death_opened", classname = "CommandStation", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death", classname = "MAC", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death", classname = "Drifter", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death_flames", classname = "Drifter", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death_spawn", classname = "Extractor", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death_deployed", classname = "Extractor", death_time = 3, done = true},
            {ragdoll = "", from_animation = "death", classname = "Structure", death_time = 3, done = true},
        },
    },
    
    construct =
    {
        constructEffects =
        {
            //{cinematic = "cinematics/alien/structures/build.cinematic", isalien = true},
            
            // Gorge
            {sound = "sound/ns2.fev/alien/gorge/build", classname = "Gorge", done = true},
            
            // Drifter construction effects        
            {sound = "sound/ns2.fev/alien/structures/generic_build", classname = "Drifter", done = true},
            
            // Marine/MAC construction effects
            {cinematic = "cinematics/sparks.cinematic", isalien = false},
            {sound = "sound/ns2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },
    
    death =
    {
        // Structure effects in other lua files
        // If death animation isn't played, and ragdoll isn't triggered, entity will be destroyed and removed immediately.
        // Otherwise, effects are responsible for setting ragdoll/death time.
        generalDeathCinematicEffects =
        {        
            // TODO: Substitute material properties?
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic", classname = "Grenade", done = true},
            {cinematic = "cinematics/marine/mac/death.cinematic", classname = "MAC", done = true},
            {cinematic = "cinematics/marine/arc/destroyed.cinematic", classname = "ARC", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Drifter"},
            
            {cinematic = "cinematics/marine/commandstation/death.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/infantryportal/death.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/extractor/death.cinematic", classname = "Extractor", done = true},
            {cinematic = "cinematics/marine/roboticsfactory/death.cinematic", classname = "RoboticsFactory", done = true},
            {cinematic = "cinematics/marine/observatory/death.cinematic", classname = "Observatory", done = true},
            
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Crag", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Shift", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Shade", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Whip", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/egg/burst.cinematic", classname = "Egg", done = true},
            
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Structure", isalien = true, done = true},
            {cinematic = "cinematics/marine/structures/generic_death.cinematic", isalien = false, classname = "Structure", done = true},            
        },
      
        // Play world sound instead of parented sound as entity is going away?
        deathSoundEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/bite_kill", doer = "BiteLeap"},
            
            {stop_sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC"},
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters", classname = "MAC"},
            {sound = "sound/ns2.fev/marine/structures/mac/death", classname = "MAC", done = true},
            
            {sound = "sound/ns2.fev/alien/drifter/death", classname = "Drifter", done = true},
            {sound = "sound/ns2.fev/alien/skulk/death", classname = "Skulk", done = true},
            {sound = "sound/ns2.fev/alien/gorge/death", classname = "Gorge", done = true},
            {sound = "sound/ns2.fev/alien/lerk/death", classname = "Lerk", done = true},
            {sound = "sound/ns2.fev/alien/fade/death", classname = "Fade", done = true},
            {sound = "sound/ns2.fev/alien/onos/death", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/marine/common/death", classname = "Marine", done = true},
            {sound = "sound/ns2.fev/marine/structures/", classname = "Extractor", done = true},
            {sound = "sound/ns2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
            {sound = "sound/ns2.fev/alien/structures/harvester_death", classname = "Harvester", done = true},
            {sound = "sound/ns2.fev/alien/structures/hydra/death", classname = "Hydra", done = true},
            {sound = "sound/ns2.fev/alien/structures/hive_death", classname = "Hive", done = true},
            {sound = "sound/ns2.fev/alien/structures/death_axe", classname = "Structure", isalien = true, doer = "Axe", done = true},            
            {sound = "sound/ns2.fev/alien/structures/egg/death", classname = "Egg", done = true},
            {sound = "sound/ns2.fev/alien/structures/death_grenade", classname = "Structure", isalien = true, doer = "Grenade", done = true},
            {sound = "sound/ns2.fev/alien/structures/death_small", classname = "Structure", isalien = true, done = true},
            {sound = "sound/ns2.fev/marine/structures/generic_death", classname = "Structure", isalien = false, done = true},
        },
        
        deathAnimations =
        {
            {animation = "death_closed", classname = "CommandStation", occupied = true, force = true, done = true},
            {animation = "death_opened", classname = "CommandStation", occupied = false, force = true, done = true},
            {animation = "death", classname = "MAC", force = true, done = true},
            {animation = "death_flames", classname = "Drifter", damagetype = kDamageType.Flame, force = true, done = true},
            {animation = "death", classname = "Drifter", force = true, done = true},            
            {animation = "", classname = "Egg", force = true, done = true},
            {animation = "death_spawn", classname = "Extractor", built = true, force = true, done = true},
            {animation = "death_deployed", classname = "Extractor", built = false, force = true, done = true},
            {ragdoll = "", classname = "Hive", death_time = 6, force = true, done = true},
            {animation = "death", classname = "Structure", force = true, done = true},
        },
    },
    
    commander_create =
    {
        commanderCreateSounds =
        {
            // Play world sounds at spawn point
            //{sound = "sound/ns2.fev/marine/commander/spawn", isalien = false},
            {sound = "sound/ns2.fev/marine/structures/generic_spawn", isalien = false, done = true},
            
            {sound = "sound/ns2.fev/alien/structures/generic_spawn_large", classname = "Hive", done = true},
            {sound = "sound/ns2.fev/alien/structures/generic_spawn", classname = "Hive", done = true},
            
        },
        
        commanderCreateCinematics =
        {            
            {cinematic = "cinematics/alien/structures/spawn_large.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/spawn_small.cinematic", isalien = true, done = true},            
            
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", isalien = false, done = true},            
        },
    },
    
    // Play private sound for commander for good feedback
    commander_create_local =
    {
        commanderCreateLocalEffects =
        {
            {private_sound = "sound/ns2.fev/alien/commander/spawn_2d", isalien = true},
            {private_sound = "sound/ns2.fev/marine/commander/spawn_2d", isalien = false},
        },
    },
    
    // Unit catches on fire. Called on server only.
    fire_start =
    {
        fireStartEffects =
        {
            {sound = "sound/ns2.fev/common/fire_large", classname = "Hive", done = true},
            {sound = "sound/ns2.fev/common/fire_large", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/common/fire_small"},
        },
    },
    
    fire_stop =
    {
        fireStopEffects =
        {
            {stop_sound = "sound/ns2.fev/common/fire_large", classname = "Hive", done = true},
            {stop_sound = "sound/ns2.fev/common/fire_large", classname = "Onos", done = true},
            {stop_sound = "sound/ns2.fev/common/fire_small"},
        },
    },
    
    regenerate =
    {
        regenerateEffects =
        {
            {sound = "sound/ns2.fev/alien/common/regeneration"},
        },
    },
}

GetEffectManager():AddEffectData("GeneralEffectData", kGeneralEffectData)
