// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GeneralEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kGeneralEffectData = 
{
    death =
    {
        // Structure effects in other lua files
        generalDeathEffects = {
        
            // TODO: Substitute material properties?
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic", classname = "Grenade", stop = true},
            
            // MACs
            {sound = "sound/ns2.fev/marine/structures/mac/death", classname = "MAC"},
            {cinematic = "cinematics/marine/mac/death.cinematic", classname = "MAC", stop = true},
            
            // Drifters
            {sound = "sound/ns2.fev/alien/drifter/death", classname = "Drifter"},
            {cinematic = "cinematics/marine/drifter/death.cinematic", classname = "Drifter", stop = true}
            
        },      
    },

    flinch =
    {
        generalFlinchCinematicEffects = {
        
            {cinematic = "cinematics/alien/structures/hit_big.cinematic", classname = "Structure", isalien = true, flinch_severe = true, stop = true},
            {cinematic = "cinematics/alien/structures/hit.cinematic", classname = "Structure", isalien = true, stop = true},
            {cinematic = "cinematics/marine/structures/hit_big.cinematic", classname = "Structure", isalien = false, flinch_severe = true, stop = true},
            {cinematic = "cinematics/marine/structures/hit.cinematic", classname = "Structure", isalien = false, stop = true},
            
            {cinematic = "cinematics/alien/hit.cinematic", classname = "Alien", stop = true},
            {cinematic = "cinematics/marine/hit.cinematic", classname = "Marine", stop = true},
            
        },
        
        generalFlinchAnimations = {
        
            // TODO: Don't play flinch_active_flames when hive is occupied
            {overlay_animation = "flinch_active_flames", classname = "Hive", damagetype = kDamageType.Flame, stop = true},
            {overlay_animation = "flinch_flames", damagetype = kDamageType.Flame, stop = true},
            {overlay_animation = "flinch", stop = true},
            
            // TODO: Add marine flinch animations ("rifle_flinch")
            
        },
        
        generalFlinchSoundEffects = {
        
            // Specific flinch sounds
            {sound = "sound/ns2.fev/alien/skulk/wound_serious", classname = "Skulk", flinch_severe = true, stop = true},           
            {sound = "sound/ns2.fev/alien/skulk/wound", classname = "Skulk", stop = true},           
            {sound = "sound/ns2.fev/alien/gorge/wound", classname = "Gorge", stop = true},           
            {sound = "sound/ns2.fev/alien/lerk/wound", classname = "Lerk", stop = true},           
            {sound = "sound/ns2.fev/alien/fade/wound", classname = "Fade", stop = true},           
            {sound = "sound/ns2.fev/alien/onos/wound", classname = "Onos", stop = true},           
            {sound = "sound/ns2.fev/alien/structures/harvester_wound", classname = "Harvester", stop = true},                       
            {sound = "sound/ns2.fev/alien/structures/hive_wound", classname = "Hive", stop = true},                       
            
            // TODO: Add common/near_death sound
            
        },
        
        aiUnitEffects = {
        
            // MACs
            {sound = "sound/ns2.fev/marine/structures/mac/pain", classname = "MAC"},
            {animation = "flinch", classname = "MAC", stop = true},
            
            // Drifters
            {sound = "sound/ns2.fev/alien/drifter/wound", classname = "Drifter"},
            {animation = "flinch_flames", classname = "Drifter", damagetype = kDamageType.Flame, stop = true},
            {animation = "flinch", classname = "Drifter"},          
  
        },
    },
    
    spawn =
    {
        generalSpawnEffects = {
        
            // MACs
            {sound = "sound/ns2.fev/marine/structures/mac/hover", classname = "MAC"},
            {animation = "idle", classname = "MAC", stop = true},
            
            // Drifters
            {sound = "sound/ns2.fev/alien/drifter/spawn", classname = "Drifter"},
            {animation = "idle", classname = "Drifter", stop = true},
            
        },
    },
    
}

GetEffectManager():AddEffectData("GeneralEffectData", kGeneralEffectData)
