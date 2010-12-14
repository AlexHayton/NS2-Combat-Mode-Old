// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
kAlienStructureEffects = 
{
    //////////////////////
    // Particle effects //
    //////////////////////
    death =
    {
        alienStructureDeathParticleEffect =
        {        
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Hive", isalien = true, stop = true},
            {cinematic = "cinematics/alien/egg/burst.cinematic", classname = "Egg", stop = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", isalien = true, stop = true},
            {cinematic = "cinematics/marine/structures/generic_death.cinematic", isalien = false, stop = true}
            
        },
    },
}

/*
Hive.lua:27: Hive.kHiveSpawnTechEffect = PrecacheAsset("cinematics/alien/hive/hive_spawn.cinematic")
Hive.lua:28: Hive.kDeployTechEffect = PrecacheAsset("cinematics/alien/hive/deploy_tech.cinematic")
Hive.lua:29: Hive.kIdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
Hive.lua:30: Hive.kL2IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev2.cinematic")
Hive.lua:31: Hive.kL3IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev3.cinematic")
Hive.lua:32: Hive.kGlowEffect = PrecacheAsset("cinematics/alien/hive/glow.cinematic")
Hive.lua:33: Hive.kSpecksEffect = PrecacheAsset("cinematics/alien/hive/specks.cinematic")
Hive.lua:34: Hive.kDeathEffect = PrecacheAsset("cinematics/alien/hive/death.cinematic")
Hive.lua:18: Hive.kActiveSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_idle")
Hive.lua:19: Hive.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_deploy")
Hive.lua:20: Hive.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound")
Hive.lua:22: Hive.kWoundAlienSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound_alien")
Hive.lua:23: Hive.kKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_death")
Hive.lua:24: Hive.kLoadSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_load")
Hive.lua:25: Hive.kExitSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_exit")
Hive.lua:36: Hive.kCompleteSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_complete")
Hive.lua:37: Hive.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_under_attack")
Hive.lua:38: Hive.kDyingSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_dying")

Hydra.lua:24: Hydra.kSpikeFireEffect = PrecacheAsset("cinematics/alien/hydra/spike_fire.cinematic")
Hydra.lua:25: Hydra.kSpikeImpactEffect = PrecacheAsset("cinematics/alien/hydra/spike_impact.cinematic")
Hydra.lua:19: Hydra.kAttackSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/attack")
Hydra.lua:20: Hydra.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/deploy")
Hydra.lua:21: Hydra.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/idle")
Hydra.lua:22: Hydra.kDeathSound = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/death")

Crag.lua:28: Crag.kHealEffect = PrecacheAsset("cinematics/alien/crag/heal.cinematic")
Crag.lua:29: Crag.kHealTargetEffect = PrecacheAsset("cinematics/alien/heal.cinematic")
Crag.lua:30: Crag.kHealBigTargetEffect = PrecacheAsset("cinematics/alien/heal_big.cinematic")
Crag.lua:31: Crag.kUmbraEffect = PrecacheAsset("cinematics/alien/crag/umbra.cinematic")
Crag.lua:32: Crag.kBabblerEffect = PrecacheAsset("cinematics/alien/crag/babbler.cinematic")
Crag.lua:24: Crag.kHealSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")
Crag.lua:25: Crag.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/crag/idle")
Crag.lua:26: Crag.kUmbraSound = PrecacheAsset("sound/ns2.fev/alien/structures/crag/umbra")

Shade.lua:35: Shade.kBlindEffect = PrecacheAsset("cinematics/alien/shade/blind.cinematic")
Shade.lua:36: Shade.kGlowEffect = PrecacheAsset("cinematics/alien/shade/glow.cinematic")
Shade.lua:37: Shade.kPhantasmEffect = PrecacheAsset("cinematics/alien/shade/phantasm.cinematic")
Shade.lua:33: Shade.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shade/idle")

Shift.lua:32: Shift.kEchoEffect = PrecacheAsset("cinematics/alien/shift/echo.cinematic")
Shift.lua:33: Shift.kEnergizeEffect = PrecacheAsset("cinematics/alien/shift/energize.cinematic")
Shift.lua:34: Shift.kEnergizeSmallTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_small.cinematic")
Shift.lua:35: Shift.kEnergizeLargeTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_large.cinematic")
Shift.lua:26: Shift.kEchoSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/echo")
Shift.lua:27: Shift.kEnergizeSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/energize")
Shift.lua:28: Shift.kEnergizeTargetSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/energize_target")
Shift.lua:29: Shift.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/idle")
Shift.lua:30: //Shift.kRecallSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/recall")

Whip.lua:28: Whip.kBombardFireEffect = PrecacheAsset("cinematics/alien/whip/bombard_fire.cinematic")
Whip.lua:29: Whip.kBombardEffect = PrecacheAsset("cinematics/alien/whip/bombard.cinematic")
Whip.lua:30: Whip.kBombardImpactEffect = PrecacheAsset("cinematics/alien/whip/bombard_impact.cinematic")
Whip.lua:31: Whip.kAcidStrikeFireEffect = PrecacheAsset("cinematics/alien/whip/acidstrike_fire.cinematic")
Whip.lua:32: Whip.kAcidStrikeEffect = PrecacheAsset("cinematics/alien/whip/acidstrike.cinematic")
Whip.lua:33: Whip.kAcidStrikeImpactEffect = PrecacheAsset("cinematics/alien/whip/acidstrike_impact.cinematic")
Whip.lua:34: Whip.kFuryEffect = PrecacheAsset("cinematics/alien/whip/fury.cinematic")
Whip.lua:24: Whip.kFurySound = PrecacheAsset("sound/ns2.fev/alien/structures/whip/fury")
Whip.lua:25: Whip.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/whip/idle")
Whip.lua:26: Whip.kStrikeSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/whip/attack")

Harvester.lua:22: Harvester.kGlowEffect = PrecacheAsset("cinematics/alien/harvester/glow.cinematic")
Harvester.lua:23: Harvester.kIdleEffect = PrecacheAsset("cinematics/alien/harvester/resource_idle.cinematic")
Harvester.lua:24: Harvester.kCollectEffect = PrecacheAsset("cinematics/alien/harvester/resource_collect.cinematic")
Harvester.lua:15: Harvester.kActiveSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_active")
Harvester.lua:16: Harvester.kHarvestedSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_harvested")
Harvester.lua:17: Harvester.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/deploy_small")
Harvester.lua:18: Harvester.kKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_death")
Harvester.lua:19: Harvester.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/structures/harvester_wound")
Harvester.lua:20: Harvester.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/harvester_under_attack")


Egg.lua:21: Egg.kBurstEffect = PrecacheAsset("cinematics/alien/egg/burst.cinematic")
Egg.lua:22: Egg.kMistEffect = PrecacheAsset("cinematics/alien/egg/mist.cinematic")
Egg.lua:23: Egg.kSpawnEffect = PrecacheAsset("cinematics/alien/egg/spawn.cinematic")
Egg.lua:24: Egg.kGlowEffect = PrecacheAsset("cinematics/alien/egg/glow.cinematic")
Egg.lua:26: Egg.kDeathSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/egg/death")
Egg.lua:27: Egg.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/egg/spawn")

*/