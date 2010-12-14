// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\EffectData.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Sound, effect and animation data to be used by the effect manager.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//
// All effect entries should be one of these basic types:
//
kCinematicType              = "cinematic"
kWeaponCinematicType        = "weapon_cinematic"        // Needs attach_point specified
kViewModelCinematicType     = "viewmodel_cinematic"     // Needs attach_point specified
kAnimationType              = "animation"               // Optional blend time, animation speed
kViewModelAnimationType     = "viewmodel_animation"     // Optional blend time, animation speed
kOverlayAnimationType       = "overlay_animation"       // Optional blend time, animation speed not supported
kSoundType                  = "sound"
kParentedSoundType          = "parented_sound"

// For cinematics and sounds, you can specify the asset names like this:
// Set to "cinematics/marine/rifle/shell.cinematic" or use a table like this to control probability:
// { {1, "cinematics/marine/rifle/shell.cinematic"}, {.5, "cinematics/marine/rifle/shell2.cinematic"} } // shell2 triggers 1/3 of the time
kEffectParamAttachPoint     = "attach_point"
kEffectParamBlendTIme       = "blend_time"
kEffectParamAnimationSpeed  = "speed"
kEffectParamForce           = "force"

// General effects. Chooses one effect from each block. Name of block is unused except for debugging/clarity.
// Filters:
kEffectClassName            = "classname"
kEffectDoerName             = "doername"
kEffectIsAlienStructure     = "isalienstructure"

kGeneralEffectData = 
{
    //////////////////////
    // Particle effects //
    //////////////////////
    // Always need effect name here. Will play only one effect from this block.
    // self:TriggerEffects("death", {kEffectIsAlienStructure = self:GetIsAlienStructure()})
    death =
    {
        alienStructureDeathParticleEffect =
        {        
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/alien/structures/death_large_by_flames_lev2.cinematic", classname = "HiveL2", doername = "Flamethrower"},
            {cinematic = "cinematics/alien/structures/death_large_by_flames.cinematic", classname = "Hive", doername = "Flamethrower", isalienstructure = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Hive", isalienstructure = true},
            {cinematic = "cinematics/alien/egg/burst.cinematic", classname = "Egg"},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", isalienstructure = true},
            {cinematic = "cinematics/marine/structures/generic_death.cinematic", isalienstructure = false}
            
        },
        
        marineStructureDeathParticleEffect = {
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/marine/structures/generic_death.cinematic", isalienstructure = false}
        },
        
        // Non structure death effects
        playerDeathParticleEffect = {
            // TODO: Substitute material properties?
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic", classname = "Grenade"},
            {cinematic = "cinematics/marine/mac/death.cinematic", classname = "MAC"}
        }
        
    }
}

// Composite effects. Play all effects in block. Must pass world coords.
kCompositeEffects =
{
    //////////////////////
    // Particle effects //
    //////////////////////
    spit_hit = 
    {
        // Always need effect name here. Will play only one effect from this block.
        spitHitEffects =
        {
            // Plays the first effect that evalutes to true
            {sound = "sound/ns2.fev/alien/gorge/spit_hit"},
            {cinematic = "cinematics/alien/gorge/spit_impact.cinematic"},
        }
    },
    
    spit_fire =
    {
        spitFireEffects = 
        {
            {cinematic = "sound/ns2.fev/alien/gorge/spit"},
            {cinematic = "cinematics/alien/gorge/spit.cinematic"},            
            {viewmodel_animation = "spit_attack"},
            {overlay_animation = "spit"}
        }
    },
    
    spray_fire = 
    {
        sprayFireEffects = 
        {
            //SpitSpray.kHealthSprayEffect = PrecacheAsset("cinematics/alien/gorge/healthspray.cinematic")
            //SpitSpray.kHealthSprayViewEffect = PrecacheAsset("cinematics/alien/gorge/healthspray_view.cinematic")
            //SpitSpray.kHealthSprayViewIdleEffect = PrecacheAsset("cinematics/alien/gorge/healthspray_view_idle.cinematic")
            //{cinematic = "cinematics/alien/gorge/spit.cinematic"},
            //"cinematics/alien/gorge/spit_fire.cinematic"

            {cinematic = "sound/ns2.fev/alien/gorge/heal_spray"},
            {viewmodel_animation = "spray_attack"},
            {overlay_animation = "healthspray"}        
        }
    },
    
    rifle_attack = 
    {
        rifleAttackEffects = 
        {
            // When view model attach point and player attach point specified, special-case as a weapon effect (emanates fromview model attach on client, weapon attach for all other players)
            {viewmodel_cinematic = "cinematics/marine/rifle/muzzle_flash.cinematic", viewmodelattach = "fxnode_riflemuzzle"},
            {weapon_cinematic = "cinematics/marine/rifle/muzzle_flash.cinematic", attachpoint = "RHand_Weapon"},
            
            // First-person and weapon shell casings
            {
                cinematic = { 
                    {1, "cinematics/marine/rifle/shell.cinematic"}, 
                    {1, "cinematics/marine/rifle/shell2.cinematic"},
                    {1, "cinematics/marine/rifle/shell3.cinematic"},
                    {1, "cinematics/marine/rifle/shell4.cinematic"},
                    {1, "cinematics/marine/rifle/shell5.cinematic"}
                    }, 
                    
                viewmodelattach = "fxnode_riflecasing", attachpoint = "RHand_Weapon"            
            }
            
        }
    },

    pistol_attack = 
    {
        pistolAttackEffects = 
        {
            // When view model attach point and player attach point specified, special-case as a weapon effect (emanates fromview model attach on client, weapon attach for all other players)
            {cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", viewmodelattach = "fxnode_pistolmuzzle", attachpoint = "RHand_Weapon"},
            
            // First-person and weapon shell casings
            { cinematic = "cinematics/marine/pistol/shell.cinematic", viewmodelattach = "fxnode_pistolcasing", attachpoint = "RHand_Weapon"},            
            
            // Sound effect
            { cinematic = "sound/ns2.fev/marine/pistol/fire"},
        }
    }

}
