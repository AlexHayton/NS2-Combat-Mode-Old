// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
// Composite effects. Play ALL effects in block.
kMarineWeaponEffects =
{
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

GetEffectManager():AddEffectData("MarineWeaponEffects", kMarineWeaponEffects)

/*
Weapons\Marine\Axe.lua:18: Axe.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/axe/attack")
Weapons\Marine\Axe.lua:19: Axe.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/axe/draw")
Weapons\Marine\Axe.lua:20: Axe.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
Weapons\Marine\Axe.lua:21: Axe.kMetalScrapeMaterialSound = "sound/ns2.fev/materials/%s/metal_scrape"
Weapons\Marine\ClipWeapon.lua:40: ClipWeapon.kRicochetMaterialSound = "sound/ns2.fev/materials/%s/ricochet"
Weapons\Marine\ClipWeapon.lua:408: // Play ricochet sound/effect every %d bullets
Weapons\Marine\Flamethrower.lua:21: Flamethrower.kAttackStartSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_start")
Weapons\Marine\Flamethrower.lua:22: Flamethrower.kAttackLoopSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_loop")
Weapons\Marine\Flamethrower.lua:23: Flamethrower.kAttackEndSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_end")
Weapons\Marine\Flamethrower.lua:24: Flamethrower.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/draw")
Weapons\Marine\Flamethrower.lua:25: Flamethrower.kIdleSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/idle")

Weapons\Marine\Minigun.lua:18: //Minigun.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/fire")
Weapons\Marine\Minigun.lua:19: Minigun.kSpinUpSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin_up")
Weapons\Marine\Minigun.lua:20: Minigun.kSpinDownSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin_down")
Weapons\Marine\Minigun.lua:21: Minigun.kSpinSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin")
Weapons\Marine\Pistol.lua:18: Pistol.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/fire")
Weapons\Marine\Pistol.lua:19: Pistol.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/draw")
Weapons\Marine\Pistol.lua:20: Pistol.kReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/reload")
Weapons\Marine\Pistol.lua:21: Pistol.kAltFireSoundName = PrecacheAsset("sound/ns2.fev/marine/pistol/press_button")
Weapons\Marine\Rifle.lua:18: Rifle.drawSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/draw")
Weapons\Marine\Rifle.lua:19: Rifle.reloadSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/reload")
Weapons\Marine\Rifle.lua:22: Rifle.fireSingleSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single")
Weapons\Marine\Rifle.lua:23: Rifle.fireSingle2SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single_2")
Weapons\Marine\Rifle.lua:24: Rifle.fireSingle3SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_single_3")
Weapons\Marine\Rifle.lua:26: Rifle.fireSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_14_sec_loop")
Weapons\Marine\Rifle.lua:27: Rifle.fire2SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_loop_2")
Weapons\Marine\Rifle.lua:28: Rifle.fire3SoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_loop_3")
Weapons\Marine\Rifle.lua:30: Rifle.fireEndSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_14_sec_end")
Weapons\Marine\Rifle.lua:32: Rifle.meleeSwingSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_swing")
Weapons\Marine\Rifle.lua:33: Rifle.meleeHitHardSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_hit_hard")
Weapons\Marine\Rifle.lua:34: Rifle.meleeHitLivingSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/alt_hit_living")
Weapons\Marine\Shotgun.lua:31: Shotgun.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/fire")
Weapons\Marine\Shotgun.lua:32: Shotgun.kFireLastSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/fire_last")
Weapons\Marine\Shotgun.lua:33: Shotgun.kSecondaryFireSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/alt-fire")
Weapons\Marine\Shotgun.lua:34: Shotgun.kDeploySoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/deploy")
Weapons\Marine\Shotgun.lua:35: Shotgun.kStartReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/start_reload")
Weapons\Marine\Shotgun.lua:36: Shotgun.kLoadShellSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/load_shell")
Weapons\Marine\Shotgun.lua:37: Shotgun.kEndReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/shotgun/end_reload")
Weapons\Marine\Shotgun.lua:28: Shotgun.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/shotgun/muzzle_flash.cinematic")
Weapons\Marine\Shotgun.lua:29: Shotgun.kShellEffect = PrecacheAsset("cinematics/marine/shotgun/shell.cinematic")


Weapons\Marine\Axe.lua:22: Axe.kHitEffect = "cinematics/materials/%s/axe.cinematic"
Weapons\Marine\ClipWeapon.lua:39: ClipWeapon.kRicochetEffect = "cinematics/materials/%s/ricochet.cinematic"

Weapons\Marine\Flamethrower.lua:27: Flamethrower.kBurnBigCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_big.cinematic")
Weapons\Marine\Flamethrower.lua:28: Flamethrower.kBurnHugeCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_huge.cinematic")
Weapons\Marine\Flamethrower.lua:29: Flamethrower.kBurnMedCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_med.cinematic")
Weapons\Marine\Flamethrower.lua:30: Flamethrower.kBurnSmallCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_small.cinematic")
Weapons\Marine\Flamethrower.lua:31: Flamethrower.kBurn1PCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_1p.cinematic")
Weapons\Marine\Flamethrower.lua:32: Flamethrower.kFlameCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame.cinematic")
Weapons\Marine\Flamethrower.lua:33: Flamethrower.kFlameFirstPersonCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_1p.cinematic")
Weapons\Marine\Flamethrower.lua:34: Flamethrower.kFlameoutCinematic = PrecacheAsset("cinematics/marine/flamethrower/flameout.cinematic")
Weapons\Marine\Flamethrower.lua:35: Flamethrower.kImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/impact.cinematic")
Weapons\Marine\Flamethrower.lua:36: Flamethrower.kPilotCinematic = PrecacheAsset("cinematics/marine/flamethrower/pilot.cinematic")
Weapons\Marine\Flamethrower.lua:37: Flamethrower.kScorchedCinematic = PrecacheAsset("cinematics/marine/flamethrower/scorched.cinematic")

Weapons\Marine\GrenadeLauncher.lua:18: GrenadeLauncher.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/fire_grenade")
Weapons\Marine\GrenadeLauncher.lua:19: GrenadeLauncher.kReloadSoundName = PrecacheAsset("sound/ns2.fev/marine/rifle/reload_grenade")
Weapons\Marine\GrenadeLauncher.lua:20: GrenadeLauncher.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/gl/muzzle_flash.cinematic")
Weapons\Marine\GrenadeLauncher.lua:21: GrenadeLauncher.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/gl/barrel_smoke.cinematic")
Weapons\Marine\GrenadeLauncher.lua:22: GrenadeLauncher.kShellEffect = PrecacheAsset("cinematics/marine/gl/shell.cinematic")

Weapons\Marine\Grenade.lua:17: Grenade.kExplosionEffect    = "cinematics/materials/%s/grenade_explosion.cinematic"
Weapons\Marine\Grenade.lua:15: Grenade.kExplosionSound     = PrecacheAsset("sound/ns2.fev/marine/common/explode")
Weapons\Marine\Grenade.lua:16: Grenade.kGrenadeBounceSound = PrecacheAsset("sound/ns2.fev/marine/rifle/grenade_bounce")

Weapons\Marine\Pistol.lua:23: Pistol.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/pistol/muzzle_flash.cinematic")
Weapons\Marine\Pistol.lua:24: Pistol.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/pistol/barrel_smoke.cinematic")
Weapons\Marine\Pistol.lua:25: Pistol.kShellEffect = PrecacheAsset("cinematics/marine/pistol/shell.cinematic")

Weapons\Marine\Rifle.lua:36: Rifle.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
Weapons\Marine\Rifle.lua:37: Rifle.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/rifle/barrel_smoke.cinematic")
Weapons\Marine\Rifle.lua:39: Rifle.kShellEffect = PrecacheAsset("cinematics/marine/rifle/shell.cinematic")
Weapons\Marine\Rifle.lua:40: Rifle.kShell2Effect = PrecacheAsset("cinematics/marine/rifle/shell2.cinematic")
Weapons\Marine\Rifle.lua:41: Rifle.kShell3Effect = PrecacheAsset("cinematics/marine/rifle/shell3.cinematic")
Weapons\Marine\Rifle.lua:42: Rifle.kShell4Effect = PrecacheAsset("cinematics/marine/rifle/shell4.cinematic")
Weapons\Marine\Rifle.lua:43: Rifle.kShell5Effect = PrecacheAsset("cinematics/marine/rifle/shell5.cinematic")
Weapons\Marine\Rifle.lua:46: Rifle.kBashEffect = "cinematics/materials/%s/bash.cinematic"
*/