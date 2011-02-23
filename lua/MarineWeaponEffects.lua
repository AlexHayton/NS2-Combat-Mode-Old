// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineWeaponEffects =
{
    hit_effect =
    {
        // For hit effects, classname is the target
        generalHitEffects =
        {
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "ClipWeapon"},
            {player_cinematic = "cinematics/materials/%s/scrape.cinematic", doer = "Axe"},
           //rifle alt is below
           //grenade is below
           //add flamethrower searing hit effect/sound
        },
        generalHitSounds = 
        {
            {sound = "sound/ns2.fev/materials/%s/ricochet", doer = "ClipWeapon", done = true},
            {sound = "sound/ns2.fev/materials/%s/metal_scrape", doer = "Axe", surface = "metal", done = true},
        },
    },
    
    // Play ricochet sound for player locally for feedback (triggered if target > 5 meters away, play additional 30% volume sound)
    hit_effect_local =
    {
        hitEffectLocalEffects =
        {
            {private_sound = "sound/ns2.fev/materials/%s/ricochet", doer = "ClipWeapon", volume = .3},
        },
    },
    
    draw =
    {
        marineWeaponDrawSounds =
        {
            {sound = "sound/ns2.fev/marine/rifle/deploy_grenade", classname = "GrenadeLauncher", done = true},
            {sound = "sound/ns2.fev/marine/rifle/draw", classname = "Rifle", done = true},
            {sound = "sound/ns2.fev/marine/pistol/draw", classname = "Pistol", done = true},
            {sound = "sound/ns2.fev/marine/axe/draw", classname = "Axe", done = true},
            {sound = "sound/ns2.fev/marine/flamethrower/draw", classname = "Flamethrower", done = true},
            {sound = "sound/ns2.fev/marine/shotgun/deploy", classname = "Shotgun", done = true},
        },
        
        marineWeaponDrawAnimations =
        {
            {viewmodel_animation = "draw_grenade", classname = "GrenadeLauncher", done = true},
            {viewmodel_animation = "draw", classname = "Rifle", done = true},
            {viewmodel_animation = {{1, "draw"}, {1, "draw2"}}, classname = "Shotgun", done = true},
            {viewmodel_animation = "draw", classname = "ClipWeapon", done = true},
            {viewmodel_animation = "draw", classname = "Axe", done = true},
        },

    },
    
    idle = 
    {
        marineViewModelIdleAnims = 
        {
            {viewmodel_animation = {{.5, "idle"}, {.5, "idle2"}, {.5, "idle3"}, {.03, "idle4"}, {.15, "idle5"}}, classname = "Axe", done = true},
            {viewmodel_animation = {{.7, "idle"}, {.7, "idle2"}}, classname = "Pistol", empty = false, done = true},
            // TODO: Put in fidgets when standing still
            // {.05, "idle3"}, {.02, "idle4"}
            {viewmodel_animation = {{.7, "idle"}}, classname = "Pistol", empty = true, done = true},
            {viewmodel_animation = {{1.0, "idle"}, {.5, "idle3"}, {.05, "idle4"}, {.05, "idle5"}}, classname = "Rifle", done = true},
            {viewmodel_animation = {{1.2, "idle"}, {.03, "idle2"}/*, {.05, "idle3"}*/}, classname = "Shotgun", done = true},
            {viewmodel_animation = {{1.0, "idle"}, {.05, "idle2"}, {.04, "idle3"}, {.4, "idle4"}, {.04, "idle5"}}, classname = "Flamethrower", done = true},
        }
    },

    reload = 
    {
        // MUST set an animation here or else reload will happen instantly. Reload takes as long as the animation specified.
        // Adjust animation speed to change animation speed and reload time ("speed")
        gunReloadEffects =
        {
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_14_sec_loop", variant = 1},
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_loop_2", variant = 2},
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_loop_3", variant = 3},

            {viewmodel_animation = "reload", classname = "Rifle"},
            {sound = "sound/ns2.fev/marine/rifle/reload", classname = "Rifle"},
            {overlay_animation = "rifle_reload", classname = "Rifle", done = true},
            
            {viewmodel_animation = "reload", classname = "Pistol", speed = 1},
            {sound = "sound/ns2.fev/marine/pistol/reload", classname = "Pistol"},
            {overlay_animation = "pistol_reload", classname = "Pistol", done = true},
            
            // Default
            {viewmodel_animation = "reload"},
        },
    },
    
    clipweapon_empty =
    {
        emptyEffects = 
        {
            {viewmodel_animation = "attack_empty", classname = "Shotgun", force = true},
            {viewmodel_animation = "attack_empty", classname = "Rifle"},
            {viewmodel_animation = "attack_empty", classname = "Flamethrower", force = true},
            {viewmodel_animation = "attack_grenade_empty", classname = "GrenadeLauncher", force = true},
        },
        emptySounds =
        {
            {sound = "sound/ns2.fev/marine/shotgun/fire_empty", classname = "Shotgun", done = true},
            {sound = "sound/ns2.fev/marine/common/empty", classname = "Rifle", done = true},
            {sound = "sound/ns2.fev/marine/common/empty", classname = "Flamethrower", done = true},
            {sound = "sound/ns2.fev/marine/common/empty", classname = "GrenadeLauncher", done = true},
            {sound = "sound/ns2.fev/marine/common/empty", classname = "Pistol", done = true},  
        },
        
    },
    
    // The grenade launcher uses this for primary fire also
    rifle_attack =
    {
        rifleAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/rifle/muzzle_flash.cinematic", attach_point = "fxnode_riflemuzzle"},
            {weapon_cinematic = "cinematics/marine/rifle/muzzle_flash.cinematic", attach_point = "fxnode_riflemuzzle"},

            {viewmodel_cinematic = "cinematics/marine/rifle/barrel_smoke.cinematic", attach_point = "fxnode_riflemuzzle"},
            {weapon_cinematic = "cinematics/marine/rifle/barrel_smoke.cinematic", attach_point = "fxnode_riflemuzzle"},
            
            // First-person and weapon shell casings
            {
                viewmodel_cinematic = 
                    { 
                    {1, "cinematics/marine/rifle/shell.cinematic"}, 
                    {1, "cinematics/marine/rifle/shell2.cinematic"},
                    {1, "cinematics/marine/rifle/shell3.cinematic"},
                    {1, "cinematics/marine/rifle/shell4.cinematic"},
                    {1, "cinematics/marine/rifle/shell5.cinematic"},
                    }, 
                    
                attach_point = "fxnode_riflecasing"            
            },
            
            // Play two sounds simultaneously, depending on rifle variant given to player (for variety)
            {sound = "sound/ns2.fev/marine/rifle/fire_single", variant = 1},
            {looping_sound = "sound/ns2.fev/marine/rifle/fire_14_sec_loop", variant = 1},
            
            {sound = "sound/ns2.fev/marine/rifle/fire_single_2", variant = 2},
            {looping_sound = "sound/ns2.fev/marine/rifle/fire_loop_2", variant = 2},
            
            {sound = "sound/ns2.fev/marine/rifle/fire_single_3", variant = 3},
            {looping_sound = "sound/ns2.fev/marine/rifle/fire_loop_3", variant = 3},
            {viewmodel_animation = "attack"},
            {overlay_animation = "rifle_fire", force = true},
            
        }
    },
    
    rifle_attack_end =
    {    
        rifleAttackEndEffects =
        {
            {overlay_animation = ""},
            {sound = "sound/ns2.fev/marine/rifle/end"},
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_14_sec_loop", variant = 1, done = true},
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_loop_2", variant = 2, done = true},
            {stop_sound = "sound/ns2.fev/marine/rifle/fire_loop_3", variant = 3, done = true},            
        },
    },
    
    rifle_alt_attack = 
    {
        rifleAltAttackEffects = 
        {
            {sound = "sound/ns2.fev/marine/rifle/alt_swing"},
            {viewmodel_animation = "attack_secondary", force = true},
            {overlay_animation = "rifle_alt"},
        },
    },
    
    // Bash hit something (classname is nil or target)
    rifle_alt_attack_hit = 
    {
        rifleAltAttackHitSoundEffects = 
        {   
            {cinematic = "cinematics/materials/%s/bash.cinematic"},
            {sound = "sound/ns2.fev/materials/%s/bash", done = true},
        },
        
    },
    
    pistol_attack = 
    {
        pistolAttackEffects = 
        {
            // When view model attach point and player attach point specified, special-case as a weapon effect (emanates fromview model attach on client, weapon attach for all other players)
            {viewmodel_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            {weapon_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            
            // First-person and weapon shell casings
            {viewmodel_cinematic = "cinematics/marine/pistol/shell.cinematic", attach_point = "fxnode_pistolcasing"},            
            {weapon_cinematic = "cinematics/marine/pistol/shell.cinematic", attach_point = "fxnode_pistolcasing"},            
            
            // Sound effect
            {sound = "sound/ns2.fev/marine/pistol/fire"},
            
            {overlay_animation = "pistol_fire", force = true},
            
            // Play different view model anims
            {viewmodel_animation = {{.5, "attack"}/*, {.5, "attack2"}*/}, alt_mode = false, force = true},
            {viewmodel_animation = {/*{.5, "attack"},*/ {.5, "attack2"}}, alt_mode = true, force = true},
            
        },
    },
    
    pistol_alt_attack = 
    {
        pistolAltAttackEffects = 
        {
            {viewmodel_animation = "press_button"},
            {sound = "sound/ns2.fev/marine/pistol/press_button"},
        },
    },
    
    axe_attack = 
    {
        axeAttackEffects = 
        {
            {viewmodel_animation = { {.5, "attack4"}}, force = true },
            {sound = "sound/ns2.fev/marine/axe/attack"},
            {overlay_animation = "axe_fire", force = true},            
        },
    },

    shotgun_attack = 
    {
        shotgunAttackEffects = 
        {
            {sound = "sound/ns2.fev/marine/shotgun/fire", empty = false},
            {viewmodel_animation = "attack", empty = false, force = true},
            
            {viewmodel_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},
            {weapon_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle", empty = false},
            
            {viewmodel_cinematic = "cinematics/marine/shotgun/shell.cinematic", attach_point = "fxnode_shotguncasing", empty = false},            
            {weapon_cinematic = "cinematics/marine/shotgun/shell.cinematic", attach_point = "fxnode_shotguncasing", empty = false},            

        },

        //shotgunAttackEmptyEffects = 
        //{
            //{sound = "sound/ns2.fev/marine/shotgun/fire_last", empty = true},
            //{viewmodel_animation = "attack_last", empty = true, force = true},
        //},
    },   
    
    // Special shotgun reload effects
    shotgun_reload_start =
    {
        shotgunReloadStartEffects =
        {
            {viewmodel_animation = "reload_start", force = true},
            {sound = "sound/ns2.fev/marine/shotgun/start_reload"},
            {overlay_animation = "shotgun_reload_start", force = true},
        },
    },    

    shotgun_reload_shell =
    {
        shotgunReloadShellEffects =
        {
            {viewmodel_animation = "reload_insert", force = true},
            {sound = "sound/ns2.fev/marine/shotgun/load_shell"},
            {overlay_animation = "shotgun_reload_insert", force = true},
        },
    },    

    shotgun_reload_end =
    {
        shotgunReloadEndEffects =
        {
            {viewmodel_animation = {{1, "reload_end"}, {1, "reload_end2"}}, force = true},
            {sound = "sound/ns2.fev/marine/shotgun/end_reload"},
            {overlay_animation = "shotgun_reload_end", force = true},
        },
    },    
    
    grenadelauncher_alt_attack =
    {
        glAttackEffects =
        {
            {viewmodel_animation = "attack_grenade", empty = false, force = true},
            {overlay_animation = "grenadelauncher_attack_grenade", force = true},
            {sound = "sound/ns2.fev/marine/rifle/fire_grenade", done = true},
            
            // First-person and weapon shell casings
            //{viewmodel_cinematic = "cinematics/marine/gl/shell.cinematic", attach_point = "fxnode_riflecasing"},            
            //{weapon_cinematic = "cinematics/marine/gl/shell.cinematic", attach_point = "fxnode_riflecasing", done = true},
            {viewmodel_animation = "attack_grenade_empty", empty = true, force = true},
            {sound = "sound/ns2.fev/marine/common/empty", empty = true, done = true},    
        },
    },
    
    flamethrower_attack = 
    {
        flamethrowerAttackCinematics = 
        {
            // If we're out of ammo, play 'flame out' effect
            {viewmodel_cinematic = "cinematics/marine/flamethrower/flameout.cinematic", attach_point = "fxnode_flamethrowermuzzle", empty = true},
            {weapon_cinematic = "cinematics/marine/flamethrower/flameout.cinematic", attach_point = "fxnode_flamethrowermuzzle", empty = true, done = true},
        
            // Otherwise play either first-person or third-person flames
            {viewmodel_cinematic = "cinematics/marine/flamethrower/flame_1p.cinematic", attach_point = "fxnode_flamethrowermuzzle"},
            {weapon_cinematic = "cinematics/marine/flamethrower/flame.cinematic", attach_point = "fxnode_flamethrowermuzzle"},
            {overlay_animation = "flamethrower_attack"},
        },
        
        flamethrowerAttackEffects = 
        {
            // Sound effect
            {looping_sound = "sound/ns2.fev/marine/flamethrower/attack_loop"},
            {looping_sound = "sound/ns2.fev/marine/flamethrower/attack_start"},
            {viewmodel_animation = {{.5, "attack"}, {.5, "attack2"}}, force = true},
        },
    },
    
    flamethrower_attack_end = 
    {
        flamethrowerAttackEndCinematics = 
        {
            {stop_sound = "sound/ns2.fev/marine/flamethrower/attack_loop"},
            {stop_sound = "sound/ns2.fev/marine/flamethrower/attack_start"},
            {sound = "sound/ns2.fev/marine/flamethrower/attack_end"},
        },
    },

    // TODO: Do we need cinematics/marine/gl/muzzle_flash.cinematic" and "cinematics/marine/gl/barrel_smoke.cinematic"?    
    grenadelauncher_reload =
    {
        glReloadEffects = 
        {
            {viewmodel_animation = "reload_grenade", force = true},
            {overlay_animation = "grenadelauncher_reload_grenade", force = true},
            {sound = "sound/ns2.fev/marine/rifle/reload_grenade"},
        },    
    },
    
    grenade_bounce =
    {
        grenadeBounceEffects =
        {
            {sound = "sound/ns2.fev/marine/rifle/grenade_bounce"},
        },
    },
    
    grenade_explode =
    {
        grenadeExplodeEffects =
        {
            // Any asset name with a %s will use the "surface" parameter as the name
            {sound = "sound/ns2.fev/marine/common/explode"},
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic"},
        },
    },
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kMarineWeaponEffects)
