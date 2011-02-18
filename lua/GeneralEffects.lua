// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

    // Called for structures, infestation, MACs and Drifters
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

            // Causing problems right now - playing too much
            //{sound = "sound/ns2.fev/alien/commander/DI_drop_3D", classname = "Infestation"},
            {sound = "sound/ns2.fev/alien/infestation/build", classname = "Infestation", done = true},

            {sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC", done = true},            
            {sound = "sound/ns2.fev/alien/drifter/spawn", classname = "Drifter", done = true},
            
            {sound = "sound/ns2.fev/alien/structures/spawn_small", isalien = true, done = true},
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
            {sound = "sound/ns2.fev/alien/structures/deploy_small", classname = "Hydra", done = true},
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
        //add sounds for generic hits
        //spit hit all
            {sound = "sound/ns2.fev/alien/gorge/spit_hit", doer = "Spit"},
            {cinematic = "cinematics/alien/gorge/spit_impact.cinematic", doer = "Spit", done = true},
        //spikes hit structure
            {cinematic = "cinematics/alien/lerk/spike_impact.cinematic", doer = "Spike", classname = "Structure"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spike", classname = "Structure"},
            {cinematic = "cinematics/alien/lerk/snipe_impact.cinematic", doer = "Spikes", classname = "Structure"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spikes", classname = "Structure"},
            {cinematic = "cinematics/alien/hydra/spike_impact.cinematic", doer = "HydraSpike", classname = "Structure"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "HydraSpike", classname = "Structure"},
         //generic buildings        
            {cinematic = "cinematics/alien/structures/hit_big.cinematic", classname = "Structure", isalien = true, flinch_severe = true},
            {sound = "sound/ns2.fev/materials/organic/bash",  classname = "Structure", isalien = true, flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/structures/hit.cinematic", classname = "Structure", isalien = true},
            {sound = "sound/ns2.fev/materials/organic/bash",  classname = "Structure", isalien = true, done = true},
            {cinematic = "cinematics/marine/structures/hit_big.cinematic", classname = "Structure", isalien = false, flinch_severe = true},
            {sound = "sound/ns2.fev/materials/metal/bash",  classname = "Structure", isalien = false, flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hit.cinematic", classname = "Structure", isalien = false},
            {sound = "sound/ns2.fev/materials/metal/bash",  classname = "Structure", isalien = false, done = true},
       //rifle alt hit TODO      
       //bullet hit alien  
            {cinematic = "cinematics/alien/bullet_hit.cinematic", doer = "ClipWeapon", classname = "Alien"},
            {sound = "sound/ns2.fev/materials/organic/ricochet", doer = "ClipWeapon", classname = "Alien", done = true},  
        //axe hit alien
            {sound = "sound/ns2.fev/materials/organic/metal_scrape", doer = "Axe", classname = "Alien"},
            {cinematic = "cinematics/alien/axe_hit.cinematic", doer = "Axe", classname = "Alien", done = true},
        //bite hit marine
            {sound = "sound/ns2.fev/alien/skulk/bite_hit_marine", doer = "BiteLeap", classname = "Marine"},
            {cinematic = "cinematics/marine/bite_hit.cinematic", doer = "BiteLeap", classname = "Marine", done = true},   
        //stab hit marine
            {cinematic = "cinematics/marine/slash_hit.cinematic", doer = "StabBlink", classname = "Marine"},
            {sound = "sound/ns2.fev/alien/fade/stab_marine", doer = "StabBlink", classname = "Marine", done = true},
        //swipe hit marine
            {cinematic = "cinematics/marine/slash_hit.cinematic", doer = "SwipeBlink", classname = "Marine"},
            {sound = "sound/ns2.fev/alien/fade/swipe_hit_marine", doer = "SwipeBlink", classname = "Marine", done = true},
        //spike hit marine
            {cinematic = "cinematics/marine/spike_hit.cinematic", doer = "Spike", classname = "Marine"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spike", classname = "Marine", done = true}, 
        //snipe hit marine
            {cinematic = "cinematics/marine/spike_hit.cinematic", doer = "Spikes", classname = "Marine"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spikes", classname = "Marine", done = true},
            {sound = "sound/ns2.fev/marine/common/spore_wound", doer = "SporeCloud", classname = "Marine", done = true},
        //hdyra hit marine
            {cinematic = "cinematics/marine/spike_hit.cinematic", doer = "HydraSpike", classname = "Marine"},
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "HydraSpike", classname = "Marine", done = true},
        //generic
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
            {sound = "sound/ns2.fev/marine/common/spore_wound", classname = "Marine", doer = "SporeCloud", stop = true},
            {sound = "sound/ns2.fev/marine/common/wound_serious", classname = "Marine", flinch_severe = true, stop = true},
            {sound = "sound/ns2.fev/marine/common/wound", classname = "Marine", stop = true},
                       
            
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
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Drifter", done = true},
        },
      
        // Play world sound instead of parented sound as entity is going away?
        deathSoundEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/bite_kill", doer = "BiteLeap"},
            
            {stop_sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC"},
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters", classname = "MAC"},
            
            {stop_sound = "sound/ns2.fev/alien/infestation/build", classname = "Infestation", done = true},
            
            {sound = "sound/ns2.fev/marine/structures/mac/death", classname = "MAC", done = true},
            {sound = "sound/ns2.fev/alien/drifter/death", classname = "Drifter", done = true},
            {sound = "sound/ns2.fev/alien/skulk/death", classname = "Skulk", done = true},
            {sound = "sound/ns2.fev/alien/gorge/death", classname = "Gorge", done = true},
            {sound = "sound/ns2.fev/alien/lerk/death", classname = "Lerk", done = true},
            {sound = "sound/ns2.fev/alien/fade/death", classname = "Fade", done = true},
            {sound = "sound/ns2.fev/alien/onos/death", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/marine/common/death", classname = "Marine", done = true},
            {sound = "sound/ns2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
            
            // Note: PowerPoints are in game script
            
            {sound = "sound/ns2.fev/marine/power_node/destroyed_powerdown", classname = "PowerPack"},
            {sound = "sound/ns2.fev/marine/power_node/destroyed", classname = "PowerPack", done = true},
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
            {sound = "sound/ns2.fev/alien/structures/spawn_small", done = true},
        },
        
        commanderCreateCinematics =
        {            
            {cinematic = "cinematics/alien/structures/spawn_large.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/spawn_small.cinematic", isalien = true, done = true},            
            
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "Structure", isalien = false, done = true},
            {cinematic = "cinematics/marine/spawn_item.cinematic", isalien = false, done = true},            
        },
    },
    
    // Play private sound for commander for good feedback
    commander_create_local =
    {
        commanderCreateLocalEffects =
        {
            {private_sound = "sound/ns2.fev/alien/commander/spawn_2", isalien = true},
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
    
    infestation_grown =
    {
        infestationEffects = 
        {
            {stop_sound = "sound/ns2.fev/alien/infestation/build", classname = "Infestation", done = true},
        },
    },
            
}

GetEffectManager():AddEffectData("GeneralEffectData", kGeneralEffectData)
