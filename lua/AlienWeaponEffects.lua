// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Debug with: {player_cinematic = "cinematics/locateorigin.cinematic"},

kAlienWeaponEffects =
{
    hit_effect =
    {
        // For hit effects, classname is the target
        generalHitEffects =
        {        
            {sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spike", done = true},
            
            {sound = "sound/ns2.fev/alien/gorge/spit_hit", doer = "Spit"},
            {cinematic = "cinematics/alien/gorge/spit_impact.cinematic", doer = "Spit", done = true},
            
            {sound = "sound/ns2.fev/alien/skulk/bite_hit_marine", doer = "BiteLeap", classname = "Marine", done = true},
            {sound = "sound/ns2.fev/alien/skulk/bite_hit_%s", doer = "BiteLeap", done = true},
        },
    },

    // Play ricochet sound for player locally for feedback (triggered if target > 5 meters away, play additional 30% volume sound)
    hit_effect_local =
    {
        hitEffectLocalEffects =
        {
            {private_sound = "sound/ns2.fev/alien/gorge/spit_hit", doer = "Spit", volume = .3, done = true},
            {private_sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spike", volume = .3, done = true},
        },
    },
    
    idle = 
    {
        // Use weapon names for view model 
        alienViewModelIdleAnims = 
        {
            // Skulk
            // "fxnode_bitesaliva"
            //{viewmodel_animation = {{1, "bite_idle"}, {.1, "bite_idle2"}, {.5, "bite_idle3"}, {.4, "bite_idle4"}}, classname = "BiteLeap", done = true},
            {viewmodel_animation = "bite_idle", classname = "BiteLeap", done = true},
            {viewmodel_animation = {{1, "bite_idle"}/*, {.1, "bite_idle2"}, {.5, "bite_idle3"}, {.4, "bite_idle4"}*/}, classname = "Parasite", done = true},
            
            // Gorge
            {viewmodel_animation = { {1, "idle"}, {.3, "idle2"}, {.05, "idle3"} }, classname = "SpitSpray", done = true},            
            {viewmodel_animation = { {1, "idle"}/*, {.3, "idle2"}, {.05, "idle3"}*/ }, classname = "HydraAbility", done = true},
            
            // Lerk
            {viewmodel_animation = {{1, "idle"}, {.1, "idle2"}, {.5, "idle3"} }, classname = "Spikes", done = true},
            {viewmodel_animation = {{1, "idle"}, {.1, "idle2"}, {.5, "idle3"} }, classname = "Spores", done = true},
            
            // Fade
            {viewmodel_animation = {{1, "swipe_idle"}, {.1, "swipe_idle2"}}, classname = "SwipeBlink", done = true},
            {viewmodel_animation = {{1, "stab_idle"}, {.1, "stab_idle2"}}, classname = "StabBlink", done = true},
            
            // Onos
            {viewmodel_animation = {{1, "gore_idle"}/*, {.1, "gore_idle2"}, {.5, "gore_idle3"}*/}, classname = "Gore", done = true},
            
        },
        
        alienViewModelCinematics =
        {
            {viewmodel_cinematic = "cinematics/alien/lerk/spore_view_idle.cinematic", classname = "Spores", attach_point = "fxnode_hole_left"},
            {viewmodel_cinematic = "cinematics/alien/lerk/spore_view_idle.cinematic", classname = "Spores", attach_point = "fxnode_hole_right"},
        },

    },
    
    draw = 
    {
        // Different draw animations for 
        alienDrawAnims = {
        
            {viewmodel_animation = "swipe_from_stab", classname = "SwipeBlink", speed = 2, from = "StabBlink", done = true},
            {viewmodel_animation = "stab_from_swipe", classname = "StabBlink", speed = 2, from = "SwipeBlink", done = true},
            
            {viewmodel_animation = "spore_draw", classname = "Spores", speed = 1, from = "Spikes", done = true},
            {viewmodel_animation = "spike_draw", classname = "Spikes", speed = 1, from = "Spores", done = true},
            
            // Aliens have no draw animations by default - will try to cover this with a "sploosh" from the egg.
            {viewmodel_animation = "", classname = "Ability"},
        },
    },
    
    bite_attack =
    {
        biteAttackEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/bite"},
            {viewmodel_animation = {{.03, "bite_attack1slow"}, {.03, "bite_attack2slow"}, {1, "bite_attack3slow"}, {1, "bite_attack4slow"}}},
            {overlay_animation = "bite"},
        },
    },
    
    // Leap
    bite_alt_attack =
    {
        biteAltAttackEffects = 
        {
            // TODO: Take volume or hasLeap 
            {sound = "sound/ns2.fev/alien/skulk/bite_alt"},
            {viewmodel_animation = "bite_leap"},
        },
    },   

    parasite_attack =
    {
        parasiteAttackEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/parasite"},
        },
    },   
    
    // When a target is parasited - played on target
    parasite_hit = 
    {
        parasiteHitEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/parasite_hit"},
        },
    },
    
    spitspray_attack =
    {
        spitFireEffects = 
        {
            {sound = "sound/ns2.fev/alien/gorge/spit"},
            {viewmodel_animation = "spit_attack", blend_time = .2, force = true},
            {overlay_animation = "spit"}
        },
    },

    // When healed by Gorge    
    sprayed =
    {
        sprayedEffects =
        {
            {sound = "sound/ns2.fev/alien/common/regeneration"},
        },
    },

    spitspray_alt_attack = 
    {
        sprayFireEffects = 
        {
            // Use player_cinematic because at world position, not attach_point
            {player_cinematic = "cinematics/alien/gorge/healthspray.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/gorge/healthspray_view.cinematic"},
            
            {sound = "sound/ns2.fev/alien/gorge/heal_spray"},            
            {viewmodel_animation = "spray_attack"},         
            {overlay_animation = "healthspray"}        
        },
    },
    
    // When creating a structure
    gorge_create =
    {
        gorgeCreateEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/spawn_small"},
        },
    },
    
    hydra_spawn =
    {
    },

    spikes_attack =
    {
        spikeAttackAnims = 
        {
            {overlay_animation = "spikes"},            
            {viewmodel_animation = "spikes_attack_l", left = true, done = true},
            {viewmodel_animation = "spikes_attack_r", left = false, done = true},
        },
        
        spikeAttackSounds = 
        {
            // Choose spike sound depending if we're zoomed and if we have piercing upgrade
            {sound = "sound/ns2.fev/alien/lerk/spikes", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_pierce", upgraded = true, done = true},
        },
    },
    
    spikes_alt_attack =
    {
        spikeZoomEffect = 
        {
            {overlay_animation = "spikes"},           
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoom", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = false, done = true},
        },
    },
    
    // Play snipe sound where it hits so players know what's going on (played at spot in world where spike hits - not for a target)
    spikes_snipe_miss =
    {
        spikesSnipeEffects =
        {
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = true, done = true},           
        },
    },
    
    // Played for unit that is hit with sniped lerk
    spikes_snipe_hit =
    {
        spikesSnipedEffects =
        {
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = true, done = true},           
        },
    },

    spores_attack =
    {
        sporesAttackEffects = 
        {
            {sound = "sound/ns2.fev/alien/lerk/spores_shoot"},
            {viewmodel_animation = "spores_attack"},
            {overlay_animation = "spores"},
            
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "?"},
            //{weapon_cinematic = "cinematics/alien/lerk/spores.cinematic", attach_point = "?"},
        },
    },
    
    spores =
    {
        sporesCreateEffects = 
        {
            {sound = "sound/ns2.fev/alien/lerk/spores_hit"},
            {cinematic = "cinematics/alien/lerk/spore_impact.cinematic"},
        },
    },
    
    swipe_attack = 
    {
        swipeAttackEffects =
        {
            {viewmodel_animation = {{1, "swipe_attack"}, {1, "swipe_attack2"}, {1, "swipe_attack3"}, {1, "swipe_attack4"}, {1, "swipe_attack5"}, {1, "swipe_attack6"}}, force = true},            
            {sound = "sound/ns2.fev/alien/fade/swipe"},
            {overlay_animation = { {1, "swipe"}, {1, "swipe2"}, {1, "swipe3"}, {1, "swipe4"}, {1, "swipe5"}, {1, "swipe6"} }, force = true},
        },
    },

    stab_attack = 
    {
        stabAttackEffects =
        {
            {viewmodel_animation = {{1, "stab_attack1"}}},
            {sound = "sound/ns2.fev/alien/fade/stab"},
            // TODO: SetAnimAndMode()
            {overlay_animation = { {1, "stab"}, {1, "stab2"}}},
        },
    },

    blink_out =
    {
        blinkOutEffects = {
        
            // Animated ghost that plays blinkin or blinkout is handled as a special case
            {viewmodel_cinematic = "cinematics/alien/fade/blink_view.cinematic", attach_point = ""},
            {cinematic = "cinematics/alien/fade/blink_out.cinematic"},
            
            // Play sound with randomized positional offset (in sound) at place we're leaving
            {sound = "sound/ns2.fev/alien/fade/blink"},
        },

    },

    blink_in =
    {
        blinkInEffects = {
        
            {cinematic = "cinematics/alien/fade/blink_in.cinematic"},
            
            // Play sound with randomized positional offset (in sound) at place we're leaving
            {sound = "sound/ns2.fev/alien/fade/blink"},
            
        },

    },    
    
    blink_ghost =
    {
        blinkGhostEffects = {        
            {sound = "sound/ns2.fev/alien/common/select"},            
        },

    }, 
}

// "false" means play all effects in each block
GetEffectManager():AddEffectData("AlienWeaponEffects", kAlienWeaponEffects)

/*
Weapons\Alien\Spikes.lua:24: Spikes.kFireEffect = PrecacheAsset("cinematics/alien/lerk/spike_fire.cinematic")
Weapons\Alien\Spikes.lua:25: Spikes.kEffect = PrecacheAsset("cinematics/alien/lerk/spike.cinematic")
Weapons\Alien\Spikes.lua:26: Spikes.kImpactEffect = PrecacheAsset("cinematics/alien/lerk/spike_impact.cinematic")
Weapons\Alien\Spikes.lua:27: Spikes.kFireViewEffect = PrecacheAsset("cinematics/alien/lerk/spike_view_fire.cinematic")
Weapons\Alien\Spikes.lua:18: Spikes.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes")
Weapons\Alien\Spikes.lua:19: Spikes.kAttackPierceSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_pierce")
Weapons\Alien\Spikes.lua:20: Spikes.kAttackZoomedSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoomed")
Weapons\Alien\Spikes.lua:21: Spikes.kAttackZoomedPierceSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoomed_pierce")
Weapons\Alien\Spikes.lua:22: Spikes.kZoomToggleSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spikes_zoom")

Weapons\Alien\Spike.lua:15: Spike.kHitSound           = PrecacheAsset("sound/ns2.fev/alien/common/spikes_ricochet")

Weapons\Alien\Spores.lua:20: Spores.kEffect = PrecacheAsset("cinematics/alien/lerk/spores.cinematic")
Weapons\Alien\Spores.lua:21: Spores.kImpactEffect = PrecacheAsset("cinematics/alien/lerk/spore_impact.cinematic")
Weapons\Alien\Spores.lua:23: Spores.kViewFireEffect = PrecacheAsset("cinematics/alien/lerk/spore_view_fire.cinematic")
Weapons\Alien\Spores.lua:16: Spores.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spores_shoot")
Weapons\Alien\Spores.lua:17: Spores.kHitSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spores_hit")

Weapons\Alien\SpitSpray.lua:23: SpitSpray.kHealthSprayEffect = PrecacheAsset("cinematics/alien/gorge/healthspray.cinematic")

Weapons\Alien\Gore.lua:20: Gore.kDoorHitEffect = PrecacheAsset("cinematics/alien/onos/door_hit.cinematic")

Weapons\Alien\HydraAbility.lua:18: HydraAbility.kCreateEffect = PrecacheAsset("cinematics/alien/gorge/create.cinematic")
Weapons\Alien\HydraAbility.lua:19: HydraAbility.kCreateViewEffect = PrecacheAsset("cinematics/alien/gorge/create_view.cinematic")
Weapons\Alien\HydraAbility.lua:14: HydraAbility.kCreateStartSound = PrecacheAsset("sound/ns2.fev/alien/gorge/create_structure_start")

Weapons\Alien\Spit.lua:16: Spit.kSpitEffect         = PrecacheAsset("cinematics/alien/gorge/spit.cinematic")
Weapons\Alien\Spit.lua:17: Spit.kSpitHitEffect      = PrecacheAsset("cinematics/alien/gorge/spit_impact.cinematic")

HydraSpike.lua:16: HydraSpike.kImpactEffect       = PrecacheAsset("cinematics/alien/lerk/spike_impact.cinematic")

Weapons\Alien\Blink.lua:26: Blink.kBlinkInEffect = PrecacheAsset("cinematics/alien/fade/blink_in.cinematic")
Weapons\Alien\Blink.lua:28: Blink.kBlinkViewEffect = PrecacheAsset("cinematics/alien/fade/blink_view.cinematic")
Weapons\Alien\Blink.lua:29: Blink.kBlinkPreviewEffect = PrecacheAsset("cinematics/alien/fade/blink_preview.cinematic")
Weapons\Alien\StabBlink.lua:18: StabBlink.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/fade/stab")
Weapons\Alien\StabBlink.lua:19: StabBlink.kStabSound = PrecacheAsset("sound/ns2.fev/alien/fade/impale")
Weapons\Alien\StabBlink.lua:20: StabBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/stab_marine")
Weapons\Alien\StabBlink.lua:21: StabBlink.kImpaleSound = PrecacheAsset("sound/ns2.fev/alien/fade/impale")
Weapons\Alien\StabBlink.lua:22: StabBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"

Weapons\Alien\SwipeBlink.lua:20: SwipeBlink.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/fade/swipe")
Weapons\Alien\SwipeBlink.lua:21: SwipeBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/swipe_hit_marine")
Weapons\Alien\SwipeBlink.lua:22: SwipeBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"

Weapons\Alien\BiteLeap.lua:17: BiteLeap.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite")
Weapons\Alien\BiteLeap.lua:18: BiteLeap.kLeapSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_alt")
Weapons\Alien\BiteLeap.lua:20: BiteLeap.kKillSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_kill")

Weapons\Alien\SpitSpray.lua:22: SpitSpray.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")

Weapons\Alien\Gore.lua:17: Gore.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/gore")
Weapons\Alien\Gore.lua:18: Gore.kHitMaterialSoundSpec = "sound/ns2.fev/alien/onos/gore_hit_%s"

Weapons\Alien\Stomp.lua:17: Stomp.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/stomp")


*/