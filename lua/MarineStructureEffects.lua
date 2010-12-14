// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineStructureEffects = 
{
    //////////////////////
    // Particle effects //
    //////////////////////
    death =
    {
        marineStructureDeathParticleEffect = {
            {cinematic = "cinematics/marine/structures/generic_death.cinematic", classname="Structure", isalienstructure = false}
        },
    },
}

GetEffectManager():AddEffectData("MarineStructureEffects", kMarineStructureEffects)

/*
Armory.lua:23: Armory.kResupplyEffect = "cinematics/marine/spawn_item.cinematic")
Armory.lua:24: Armory.kDeathEffect = PrecacheAsset("cinematics/marine/armory/death.cinematic")
Armory.lua:25: Armory.kBuyItemEffect = PrecacheAsset("cinematics/marine/armory/buy_item_effect.cinematic")
Armory.lua:14: Armory.kIdleSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_idle")
Armory.lua:15: Armory.kOpenSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_open")
Armory.lua:16: Armory.kCloseSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_close")
Armory.lua:19: Armory.kResupplySound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_resupply")
Armory.lua:20: Armory.kHealthSound = PrecacheAsset("sound/ns2.fev/marine/common/health")
Armory.lua:21: Armory.kAmmoSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

CommandStation.lua:23: CommandStation.kCommandScreenEffect = PrecacheAsset("cinematics/marine/commandstation/command_screen.cinematic")
CommandStation.lua:24: CommandStation.kDeathEffect = PrecacheAsset("cinematics/marine/commandstation/death.cinematic")
CommandStation.lua:17: CommandStation.kLoginSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_close")
CommandStation.lua:18: CommandStation.kLogoutSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_open")
CommandStation.lua:19: CommandStation.kActiveSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_active")
CommandStation.lua:20: CommandStation.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/command_station_under_attack")
CommandStation.lua:21: CommandStation.kReplicateSound = PrecacheAsset("sound/ns2.fev/alien/common/join_team")
CommandStation_Server.lua:9: CommandStation.kKilledSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_death")

InfantryPortal.lua:26: InfantryPortal.kDeathEffect = PrecacheAsset("cinematics/marine/infantryportal/death.cinematic")
InfantryPortal.lua:27: InfantryPortal.kSpinEffect = PrecacheAsset("cinematics/marine/infantryportal/spin.cinematic")
InfantryPortal.lua:28: InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")
InfantryPortal.lua:29: InfantryPortal.kSpawnEffect = PrecacheAsset("cinematics/marine/infantryportal/player_spawn.cinematic")
InfantryPortal.lua:20: InfantryPortal.kLoopSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_active")
InfantryPortal.lua:21: InfantryPortal.kSpawnPlayerSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_player_spawn")
InfantryPortal.lua:22: InfantryPortal.kStartSpinSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_start_spin")
InfantryPortal.lua:23: InfantryPortal.kSquadSpawnFailureSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn_fail")
InfantryPortal.lua:24: InfantryPortal.kSquadSpawnSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn")

Sentry.lua:30: Sentry.kFireEffect = PrecacheAsset("cinematics/marine/sentry/fire.cinematic")
Sentry.lua:31: Sentry.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/sentry/muzzle_smoke.cinematic")
Sentry.lua:33: Sentry.kFireShellEffect = PrecacheAsset("cinematics/marine/sentry/fire_shell.cinematic")
Sentry.lua:34: Sentry.kDeathEffect = PrecacheAsset("cinematics/marine/sentry/death.cinematic")
Sentry.lua:35: //Sentry.kTracerEffect = PrecacheAsset("cinematics/marine/tracer.cinematic")
Sentry.lua:37: Sentry.kRicochetEffect = "cinematics/materials/%s/ricochet.cinematic"
Sentry.lua:20: Sentry.kSpinUpSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentr_spin_up")
Sentry.lua:21: Sentry.kSpinDownSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_spin_down")
Sentry.lua:22: Sentry.kAttackSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_fire_loop")
Sentry.lua:24: Sentry.kSentryScanSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_scan")
Sentry.lua:25: Sentry.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceover/commander/sentry_taking_damage")
Sentry.lua:26: Sentry.kFiringAlertSound = PrecacheAsset("sound/ns2.fev/marine/voiceover/commander/sentry_firing")
Sentry.lua:27: Sentry.kRicochetMaterialSound = "sound/ns2.fev/materials/%s/ricochet"

Extractor.lua:18: Extractor.kActiveSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_active")
Extractor.lua:19: Extractor.kDeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_deploy")
Extractor.lua:20: Extractor.kKilledSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_death")
Extractor.lua:21: Extractor.kHarvestedSound = PrecacheAsset("sound/ns2.fev/marine/structures/extractor_harvested")
Extractor.lua:23: Extractor.kCollectionEffect = PrecacheAsset("cinematics/marine/extractor/collection_effect.cinematic")
Extractor.lua:24: Extractor.kDeathEffect = PrecacheAsset("cinematics/marine/extractor/death.cinematic")


Observatory.lua:19: Observatory.kDeathEffect = PrecacheAsset("cinematics/marine/observatory/death.cinematic")
Observatory.lua:20: Observatory.kGlowingLightEffect = PrecacheAsset("cinematics/marine/observatory/glowing_light_effect.cinematic")

RoboticsFactory.lua:16: RoboticsFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")
RoboticsFactory.lua:17: RoboticsFactory.kDeathEffect = PrecacheAsset("cinematics/marine/roboticsfactory/death.cinematic")

ARC.lua:20: ARC.kDeploySound = PrecacheAsset("sound/ns2.fev/marine/structure/arc/deploy")
ARC.lua:21: ARC.kFireSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/fire")
ARC.lua:22: ARC.kFlybySound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/flyby")
ARC.lua:23: ARC.kHitSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/hit")
ARC.lua:24: ARC.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/scan")
ARC.lua:25: ARC.kUndeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/undeploy")
ARC.lua:27: ARC.kScanEffect = PrecacheAsset("cinematics/marine/arc/scan.cinematic")
ARC.lua:28: ARC.kFireEffect = PrecacheAsset("cinematics/marine/arc/fire.cinematic")
ARC.lua:29: ARC.kFireShellEffect = PrecacheAsset("cinematics/marine/arc/fire_shell.cinematic")
ARC.lua:30: ARC.kExplosionEffect = PrecacheAsset("cinematics/marine/arc/explosion.cinematic")
ARC.lua:31: ARC.kDamagedEffect = PrecacheAsset("cinematics/marine/arc/damaged.cinematic")
ARC.lua:32: ARC.kDeathEffect = PrecacheAsset("cinematics/marine/arc/destroyed.cinematic")

*/