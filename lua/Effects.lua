// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Effects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Sound, effect and animation data to be used by the effect manager.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/EffectManager.lua")

// TODO: Add stop sound, cinematics

//
// All effect entries should be one of these basic types:
//
kCinematicType                      = "cinematic"
kWeaponCinematicType                = "weapon_cinematic"        // Needs attach_point specified
kViewModelCinematicType             = "viewmodel_cinematic"     // Needs attach_point specified
kAnimationType                      = "animation"               // Optional blend time, animation speed
kViewModelAnimationType             = "viewmodel_animation"     // Optional blend time, animation speed
kOverlayAnimationType               = "overlay_animation"       // Optional blend time, animation speed not supported
kSoundType                          = "sound"
kParentedSoundType                  = "parented_sound"

// For cinematics and sounds, you can specify the asset names like this:
// Set to "cinematics/marine/rifle/shell.cinematic" or use a table like this to control probability:
// { {1, "cinematics/marine/rifle/shell.cinematic"}, {.5, "cinematics/marine/rifle/shell2.cinematic"} } // shell2 triggers 1/3 of the time
kEffectParamAttachPoint             = "attach_point"
kEffectParamBlendTIme               = "blend_time"
kEffectParamAnimationSpeed          = "speed"
kEffectParamForce                   = "force"
kEffectParamStop                    = "stop"

// General effects. Chooses one effect from each block. Name of block is unused except for debugging/clarity. Filters:
kEffectFilterClassName              = "classname"
kEffectFilterDoerName               = "doername"
kEffectFilterDamageType             = "damagetype"
kEffectFilterIsAlien                = "isalien"
kEffectFilterFlinchSevere           = "flinch_severe"

// Load effect data, adding to effect manager
Script.Load("lua/GeneralEffects.lua")
Script.Load("lua/CommonEffects.lua")
Script.Load("lua/PlayerEffects.lua")
Script.Load("lua/MarineStructureEffects.lua")
Script.Load("lua/MarineWeaponEffects.lua")
Script.Load("lua/AlienStructureEffects.lua")
Script.Load("lua/AlienWeaponEffects.lua")

// Pre-cache effect assets
GetEffectManager():PrecacheEffects()