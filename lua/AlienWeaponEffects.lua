// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Composite effects. Play ALL effects in block.
kAlienWeaponEffects =
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
        },
    },
    
    spit_fire =
    {
        spitFireEffects = 
        {
            {sound = "sound/ns2.fev/alien/gorge/spit"},
            {viewmodel_animation = "spit_attack"},
            {overlay_animation = "spit"}
        },
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

            {sound = "sound/ns2.fev/alien/gorge/heal_spray"},
            {viewmodel_animation = "spray_attack"},
            {overlay_animation = "healthspray"}        
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
Weapons\Alien\Spores.lua:22: Spores.kViewIdleEffect = PrecacheAsset("cinematics/alien/lerk/spore_view_idle.cinematic")
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
Weapons\Alien\Blink.lua:27: Blink.kBlinkOutEffect = PrecacheAsset("cinematics/alien/fade/blink_out.cinematic")
Weapons\Alien\Blink.lua:28: Blink.kBlinkViewEffect = PrecacheAsset("cinematics/alien/fade/blink_view.cinematic")
Weapons\Alien\Blink.lua:29: Blink.kBlinkPreviewEffect = PrecacheAsset("cinematics/alien/fade/blink_preview.cinematic")
Weapons\Alien\Blink.lua:23: Blink.kBlinkGhostSound = PrecacheAsset("sound/ns2.fev/alien/common/select")
Weapons\Alien\Blink.lua:24: Blink.kBlinkSound = PrecacheAsset("sound/ns2.fev/alien/fade/blink")
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
Weapons\Alien\BiteLeap.lua:19: BiteLeap.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_hit_marine")
Weapons\Alien\BiteLeap.lua:20: BiteLeap.kKillSound = PrecacheAsset("sound/ns2.fev/alien/skulk/bite_kill")
Weapons\Alien\BiteLeap.lua:22: BiteLeap.kHitMaterialSoundSpec = "sound/ns2.fev/alien/skulk/bite_hit_%s"

Weapons\Alien\Parasite.lua:17: Parasite.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/skulk/parasite")
Weapons\Alien\Parasite.lua:18: Parasite.kAttackHitSound = PrecacheAsset("sound/ns2.fev/alien/skulk/parasite_hit")

Weapons\Alien\SpitSpray.lua:22: SpitSpray.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")

Weapons\Alien\Gore.lua:17: Gore.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/gore")
Weapons\Alien\Gore.lua:18: Gore.kHitMaterialSoundSpec = "sound/ns2.fev/alien/onos/gore_hit_%s"

Weapons\Alien\Stomp.lua:17: Stomp.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/stomp")


*/