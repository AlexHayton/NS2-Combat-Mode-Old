// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineStructureEffects = 
{
    // When players or MACs build a structure
    construct =
    {
        marineConstruct =
        {
            {cinematic = "cinematics/marine/mac/build.cinematic", isalien = false},
            {sound = "sound/ns2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },

    construction_complete = 
    {
        marineStructureComplete =
        {
            {sound = "sound/ns2.fev/marine/structures/armory_idle", classname = "Armory", done = true},
            
            {sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor"},
            {animation = "active", classname = "Extractor", done = true},
        },
    },
    
    recycle =
    {
        recycleEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/recycle"},
            {cinematic = "cinematics/marine/structures/recycle.cinematic"},
        },        
    },
    
    animation_complete =
    {
        animCompleteEffects =
        {
            {animation = "open", classname = "CommandStation", from_animation = "deploy"},            
            {animation = "active", classname = "Extractor", from_animation = "deploy", blend_time = .3, force = true},            
            {animation = "active", classname = "Extractor", from_animation = "power_up", blend_time = .3, force = true},            
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "deploy"},
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "power_up"},
            {sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "deploy"},            
            {sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "power_up"},     
            
            {animation = "spin", classname = "InfantryPortal", from_animation = "spin_start", done = true},
        },
    },
    
    death =
    {
        marineStructureDeathCinematics =
        {        
            {cinematic = "cinematics/marine/armory/death.cinematic", classname = "Armory", done = true},
            {cinematic = "cinematics/marine/infantryportal/death.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/commandstation/death.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/roboticsfactory/death.cinematic", classname = "RoboticsFactory", done = true},
            {cinematic = "cinematics/marine/extractor/death.cinematic", classname = "Extractor", done = true},
            {cinematic = "cinematics/marine/observatory/death.cinematic", classname = "Observatory", done = true},
        },
        
        marineStructureDeathSounds =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_death", classname = "CommandStation", done = true},
            {sound = "sound/ns2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
        },
    },
    
    power_down =
    {
        powerDownEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/power_down"},
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor"},
            // Structure power down animations handled in code ("power_down")
        },
    },

    power_up =
    {
        powerUpEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/power_up"},
            // Structure power down animations handled in code ("power_down")
        },
    },    
    
    mac_construct =
    {
        macConstructEffects =
        {
            {animation = "construct", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/weld"},
            {cinematic = "cinematics/marine/mac/build.cinematic", attach_point = "fxnode_welder"},
        },
    },
    
    // TODO: "sound/ns2.fev/marine/structures/mac/weld_start" voiceover
    // TODO: "sound/ns2.fev/marine/structures/mac/welded" voiceover (complete)
    mac_weld = 
    {
        macWeldEffects =
        {
            {animation = "construct_weld", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/weld"},
            {cinematic = "cinematics/marine/mac/weld.cinematic", attach_point = "fxnode_welder"},
        },
    },
    
    mac_move_complete =
    {
        macMoveCompleteEffects = 
        {
            {animation = "fly_stop", blend_time = .2},
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
        },
    },
    
    mac_move =
    {
        macMoveEffects = 
        {
            {animation = "fly", blend_time = .2},
        },
    },
    
    mac_melee_attack =
    {
        macMeleeAttackEffects =
        {
            {animation = "attack", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/attack"},
        },
    },
    
    mac_set_order =
    {
        macSetOrderEffects =
        {
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
            {parented_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
            
            // Use parented so it follows MAC around
            {parented_cinematic = "cinematics/marine/mac/jet.cinematic", attach_point = "fxnode_jet1"},
            {parented_cinematic = "cinematics/marine/mac/jet.cinematic", attach_point = "fxnode_jet2"},
            
            // TODO: this should be attached to the siren
            {parented_cinematic = "cinematics/marine/mac/siren.cinematic", attach_point = "fxnode_light"},
        },
    },
    
    extractor_collect =
    {
        extractorCollectEffect =
        {
            {sound = "sound/ns2.fev/marine/structures/extractor_harvested"},
            //{cinematic = "cinematics/marine/extractor/collection_effect.cinematic"},
        },
    },
    
    armory_health = 
    {
        armoryHealth =
        {
            {sound = "sound/ns2.fev/marine/common/health"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },

    armory_ammo = 
    {
        armoryAmmo =
        {
            {sound = "sound/ns2.fev/marine/common/pickup_ammo"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },
    
    // Not hooked up
    armory_buy = 
    {
        armoryBuy =
        {
            {cinematic = "cinematics/marine/armory/buy_item_effect.cinematic"},
        },
    },
    
    armory_open = 
    {
        armoryOpen =
        {
            {sound = "sound/ns2.fev/marine/structures/armory_open"},
        },
    },
    
    armory_close = 
    {
        armoryClose =
        {
            {sound = "sound/ns2.fev/marine/structures/armory_close"},
        },
    },

    commmand_station_login = 
    {
        commandStationLogin =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_close"},
            {animation = "close"},
        },
    },

    commmand_station_logout = 
    {
        commandStationLogout =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_open"},
            {animation = "open"},
        },
    },
    
    commmand_station_closed = 
    {
    },
    
    commmand_station_opened = 
    {
    },
    
    infantry_portal_start_spin = 
    {
        ipStartSpinEffect =
        {
            {animation = "spin_start"},
            {sound = "sound/ns2.fev/marine/structures/infantry_portal_start_spin"},
        },
    },    

    infantry_portal_stop_spin = 
    {
        ipStartSpinEffect =
        {
            {animation = "spin_stop", from_animation = "spin", done = true},
            {animation = "spin_stop", from_animation = "spin_start", done = true},
        },
    },    
    
    infantry_portal_spawn = 
    {
        ipSpawnEffect =
        {
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
            {sound = "sound/ns2.fev/marine/structures/infantry_portal_player_spawn"},
        },
    },    
       
    distress_beacon = 
    {
        playerSpawnEffect =
        {
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
            {sound = "sound/ns2.fev/marine/structures/infantry_portal_player_spawn"},
        },
    },    
}

GetEffectManager():AddEffectData("MarineStructureEffects", kMarineStructureEffects)