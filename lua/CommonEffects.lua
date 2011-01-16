// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommonEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/*

// Common
Structure.lua:41: Structure.kMarineHitEffect = PrecacheAsset("cinematics/marine/structures/hit.cinematic")
Structure.lua:42: Structure.kMarineHitBigEffect = PrecacheAsset("cinematics/marine/structures/hit_big.cinematic")
Structure.lua:43: Structure.kMarineHurtEffect = PrecacheAsset("cinematics/marine/structures/hurt.cinematic")
Structure.lua:44: Structure.kMarineHurtSevereEffect = PrecacheAsset("cinematics/marine/structures/hurt_severe.cinematic")
Structure.lua:45: Structure.kMarineDeathEffect = PrecacheAsset("cinematics/marine/structures/generic_death.cinematic")
Structure.lua:46: Structure.kMarineSpawnBuildingEffect = PrecacheAsset("cinematics/marine/structures/spawn_building.cinematic")
Structure.lua:47: Structure.kMarineRecycleEffect = PrecacheAsset("cinematics/marine/structures/recycle.cinematic")
Structure.lua:50: Structure.kAlienSpawnSmallEffect = PrecacheAsset("cinematics/alien/structures/spawn_small.cinematic")
Structure.lua:51: Structure.kAlienSpawnLargeEffect = PrecacheAsset("cinematics/alien/structures/spawn_large.cinematic")
Structure.lua:52: Structure.kAlienHitEffect = PrecacheAsset("cinematics/alien/structures/hit.cinematic")
Structure.lua:53: Structure.kAlienHitBigEffect = PrecacheAsset("cinematics/alien/structures/hit_big.cinematic")
Structure.lua:54: Structure.kAlienDeathSmallEffect = PrecacheAsset("cinematics/alien/structures/death_small.cinematic")
Structure.lua:55: Structure.kAlienDeathLargeEffect = PrecacheAsset("cinematics/alien/structures/death_large.cinematic")
Structure.lua:56: Structure.kAlienBuildEffect = PrecacheAsset("cinematics/alien/structures/build.cinematic")
Structure.lua:57: Structure.kAlienCloakEffect = PrecacheAsset("cinematics/alien/structures/cloak.cinematic")
Structure.lua:58: Structure.kAlienBurnEffect = PrecacheAsset("cinematics/alien/structures/burn.cinematic")
Structure.lua:59: Structure.kAlienHurtEffect = PrecacheAsset("cinematics/alien/structures/hurt.cinematic")
Structure.lua:60: Structure.kAlienHurtSevereEffect = PrecacheAsset("cinematics/alien/structures/hurt_severe.cinematic")

PowerPoint.lua:35: PowerPoint.kTakeDamageSound = PrecacheAsset("sound/ns2.fev/marine/power_node/take_damage")
PowerPoint.lua:36: PowerPoint.kDamagedSound = PrecacheAsset("sound/ns2.fev/marine/power_node/damaged")
PowerPoint.lua:37: PowerPoint.kDestroyedSound = PrecacheAsset("sound/ns2.fev/marine/power_node/destroyed")
PowerPoint.lua:38: PowerPoint.kDestroyedPowerDownSound = PrecacheAsset("sound/ns2.fev/marine/power_node/destroyed_powerdown")
PowerPoint.lua:39: PowerPoint.kAuxPowerBackupSound = PrecacheAsset("sound/ns2.fev/marine/power_node/backup")

TechPoint.lua:18: TechPoint.kTechPointL1Effect = PrecacheAsset("cinematics/common/techpoint.cinematic")
TechPoint.lua:19: TechPoint.kTechPointL1LightEffect = PrecacheAsset("cinematics/common/techpoint_light.cinematic")
TechPoint.lua:21: TechPoint.kTechPointL2Effect = PrecacheAsset("cinematics/common/techpoint_lev2.cinematic")
TechPoint.lua:22: TechPoint.kTechPointL2LightEffect = PrecacheAsset("cinematics/common/techpoint_light_lev2.cinematic")
TechPoint.lua:24: TechPoint.kTechPointL3Effect = PrecacheAsset("cinematics/common/techpoint_lev3.cinematic")
TechPoint.lua:25: TechPoint.kTechPointL3LightEffect = PrecacheAsset("cinematics/common/techpoint_light_lev3.cinematic")

ResourcePoint.lua:14: ResourcePoint.kEffect = PrecacheAsset("cinematics/common/resnode.cinematic")


ScriptActor.lua:23: ScriptActor.kSparksEffect = PrecacheAsset("cinematics/sparks.cinematic")



MainMenu.lua:81:         MenuManager.SetMenuCinematic("cinematics/main_menu.cinematic")

DropPack.lua:13: DropPack.kPackDropEffect = PrecacheAsset("cinematics/marine/spawn_item.cinematic")

MAC.lua:38: MAC.kBuildEffect = PrecacheAsset("cinematics/marine/mac/build.cinematic")
MAC.lua:39: MAC.kWelderEffect = PrecacheAsset("cinematics/marine/mac/weld.cinematic")
MAC.lua:42: MAC.kJetEffect = PrecacheAsset("cinematics/marine/mac/jet.cinematic")
MAC.lua:45: MAC.kLightEffect = PrecacheAsset("cinematics/marine/mac/light.cinematic")
MAC.lua:48: MAC.kSirenEffect = PrecacheAsset("cinematics/marine/mac/siren.cinematic")
MAC.lua:49: MAC.kDeathEffect = PrecacheAsset("cinematics/marine/mac/death.cinematic")
MAC.lua:18: MAC.kAttackSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/attack")
MAC.lua:19: MAC.kBuildSound = PrecacheAsset("sound/ns2.fev/marine/structures/mac/build")
MAC.lua:20: MAC.kConfirmSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm")
MAC.lua:21: MAC.kConfirm2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm_2d")
MAC.lua:22: MAC.kStartConstructionSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing")
MAC.lua:23: MAC.kStartConstruction2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing_2d")
MAC.lua:24: MAC.kHelpingSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/help_build")
MAC.lua:25: MAC.kPassbyMACSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_mac")
MAC.lua:26: MAC.kPassbyDrifterSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_driffter")
MAC.lua:27: MAC.kDeathSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/death")
MAC.lua:28: MAC.kHoverSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/hover")
MAC.lua:29: MAC.kIdleSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/idle")
MAC.lua:30: MAC.kPainSound = PrecacheAsset("sound/ns2.fev/marine/structures/mac/pain")
MAC.lua:31: MAC.kThrustersSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/thrusters")
MAC.lua:32: MAC.kWeldSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/weld")
MAC.lua:33: MAC.kWeldStartSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/weld_start")
MAC.lua:34: MAC.kWeldedSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/welded")
MAC.lua:35: MAC.kUsedSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/use")




PowerPoint.lua:32: PowerPoint.kDamagedEffect = PrecacheAsset("cinematics/common/powerpoint_damaged.cinematic")
PowerPoint.lua:33: PowerPoint.kOfflineEffect = PrecacheAsset("cinematics/common/powerpoint_offline.cinematic")

Tracer_Client.lua:14: Tracer.kTracerEffect        = PrecacheAsset("cinematics/marine/tracer.cinematic")

Scan.lua:17: Scan.kScanEffect = PrecacheAsset("cinematics/marine/observatory/scan.cinematic")


Structure.lua:22: Structure.kMarineBuildSound = PrecacheAsset("sound/ns2.fev/marine/structures/mac/build")
Structure.lua:23: Structure.kMarineKilledSound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_death")
Structure.lua:24: Structure.kMarineSpawnSound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_spawn")
Structure.lua:25: Structure.kMarineDeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_deploy")
Structure.lua:26: Structure.kMarineRecycleSound = PrecacheAsset("sound/ns2.fev/marine/structures/recycle")
Structure.lua:27: Structure.kPowerUpSound = PrecacheAsset("sound/ns2.fev/marine/structures/power_up")
Structure.lua:28: Structure.kPowerDownSound = PrecacheAsset("sound/ns2.fev/marine/structures/power_down")
Structure.lua:31: Structure.kAlienBuildSound = PrecacheAsset("sound/ns2.fev/alien/gorge/build")
Structure.lua:32: Structure.kAlienAutoBuildSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_build")
Structure.lua:33: Structure.kAlienKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_death_large")
Structure.lua:34: Structure.kAlienSpawnSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_spawn_large")
Structure.lua:35: Structure.kAlienKilledByAxeSound = PrecacheAsset("sound/ns2.fev/alien/structures/death_axe")
Structure.lua:36: Structure.kAlienKilledByGrenadeSound = PrecacheAsset("sound/ns2.fev/alien/structures/death_grenade")
Structure.lua:37: Structure.kAlienDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/deploy_large")
Structure.lua:38: Structure.kAlienUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/structure_under_attack")
Spectator.lua:17: Spectator.kDeadSound = PrecacheAsset("sound/ns2.fev/common/dead")


AmmoPack.lua:15: AmmoPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")
MedPack.lua:20: MedPack.kHealthSound = PrecacheAsset("sound/ns2.fev/marine/common/health")

Alien.lua:20: Alien.kNotEnoughResourcesSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/more")
Alien.lua:21: Alien.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")
Alien.lua:22: Alien.kHatchSound = PrecacheAsset("sound/ns2.fev/alien/common/hatch")
Alien.lua:23: Alien.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
Alien.lua:24: Alien.kSpendPlasmaSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")
Alien.lua:25: Alien.kMetabolizeSound = PrecacheAsset("sound/ns2.fev/alien/metabolize")

Door.lua:16: Door.kInoperableSound = PrecacheAsset("sound/ns2.fev/common/door_inoperable")
Door.lua:17: Door.kOpenSound = PrecacheAsset("sound/ns2.fev/common/door_open")
Door.lua:18: Door.kCloseSound = PrecacheAsset("sound/ns2.fev/common/door_close")
Door.lua:19: Door.kWeldedSound = PrecacheAsset("sound/ns2.fev/common/door_welded")
Door.lua:20: Door.kLockSound = PrecacheAsset("sound/ns2.fev/common/door_lock")
Door.lua:21: Door.kUnlockSound = PrecacheAsset("sound/ns2.fev/common/door_unlock")


Reverb.lua:42:         Client.CreateReverb("sound/ns2.fev/" .. reverbName, self:GetOrigin(), self.minRadius, self.maxRadius)



InterfaceSounds_Client.lua:17: buttonClickSound = "sound/ns2.fev/common/button_click"
InterfaceSounds_Client.lua:18: checkboxOnSound = "sound/ns2.fev/common/checkbox_on"
InterfaceSounds_Client.lua:19: checkboxOffSound = "sound/ns2.fev/common/checkbox_off"
InterfaceSounds_Client.lua:20: buttonEnterSound = "sound/ns2.fev/common/button_enter"
InterfaceSounds_Client.lua:21: arrowSound = "sound/ns2.fev/common/arrow"

Player.lua:30: Player.kClientConnectSoundName = PrecacheAsset("sound/ns2.fev/common/connect")
Player.lua:31: Player.kNotEnoughResourcesSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/more")
Player.lua:32: Player.kInvalidSound = PrecacheAsset("sound/ns2.fev/common/invalid")
Player.lua:33: Player.kTooltipSound = PrecacheAsset("sound/ns2.fev/common/tooltip")
Player.lua:34: Player.kChatSound = PrecacheAsset("sound/ns2.fev/common/chat")
Player.lua:36: Player.kFallMaterialSound = "sound/ns2.fev/materials/%s/fall"
Player.lua:37: Player.kLeftFootstepMaterialSound = "sound/ns2.fev/materials/%s/footstep_left"
Player.lua:38: Player.kRightFootstepMaterialSound = "sound/ns2.fev/materials/%s/footstep_right"
Player_Server.lua:720:     // Set near death mask so we can add sound/visual effects

Drifter.lua:19: Drifter.kAttackSoundName   = PrecacheAsset("sound/ns2.fev/alien/drifter/attack")
Drifter.lua:20: Drifter.kDieSoundName      = PrecacheAsset("sound/ns2.fev/alien/drifter/death")
Drifter.lua:21: Drifter.kDriftSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/drift")
Drifter.lua:22: Drifter.kFlareSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/flare")
Drifter.lua:23: Drifter.kOrderedSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered")
Drifter.lua:24: Drifter.kOrdered2DSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered_2d")
Drifter.lua:25: Drifter.kSpawnSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/spawn")
Drifter.lua:26: Drifter.kWoundSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/wound")


Observatory.lua:16: Observatory.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/observatory_scan")
Observatory.lua:17: Observatory.kDistressBeaconSound = PrecacheAsset("sound/ns2.fev/marine/common/distress_beacon")
CatPack.lua:15: CatPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")
Sayings.lua:13: marineRequestSayingsSounds = {"sound/ns2.fev/marine/voiceovers/ack", "sound/ns2.fev/marine/voiceovers/medpack", "sound/ns2.fev/marine/voiceovers/ammo", "sound/ns2.fev/marine/voiceovers/need_orders" }
Sayings.lua:17: marineGroupSayingsSounds = {"sound/ns2.fev/marine/voiceovers/follow_me", "sound/ns2.fev/marine/voiceovers/lets_move", "sound/ns2.fev/marine/voiceovers/covering", "sound/ns2.fev/marine/voiceovers/hostiles", "sound/ns2.fev/marine/voiceovers/taunt"}
Sayings.lua:21: alienGroupSayingsSounds = {"sound/ns2.fev/alien/voiceovers/need_healing", "sound/ns2.fev/alien/voiceovers/follow_me", "sound/ns2.fev/alien/voiceovers/chuckle"}

LiveScriptActor.lua:29: LiveScriptActor.kOnFireSmallSound = PrecacheAsset("sound/ns2.fev/common/fire_small")
LiveScriptActor.lua:30: LiveScriptActor.kOnFireLargeSound = PrecacheAsset("sound/ns2.fev/common/fire_large")
LiveScriptActor.lua:31: LiveScriptActor.kAlienRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")

Cocoon.lua:20: Cocoon.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/death_large")
AlienSpectator.lua:18: AlienSpectator.kOpenSound = PrecacheAsset("sound/ns2.fev/alien/common/select")

Jetpack.lua:16: Jetpack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_jetpack")
HydraSpike.lua:15: HydraSpike.kHitSound           = PrecacheAsset("sound/ns2.fev/alien/common/spikes_ricochet")
Embryo.lua:15: Embryo.kGestateSound = PrecacheAsset("sound/ns2.fev/alien/common/gestate")

Weapons\Alien\HarvesterAbility.lua:14: HarvesterAbility.kCreateStartSound = PrecacheAsset("sound/ns2.fev/alien/gorge/create_structure_start")

NS2Gamerules.lua:27: NS2Gamerules.kMarineStartSound   = PrecacheAsset("sound/ns2.fev/marine/voiceovers/game_start")
NS2Gamerules.lua:28: NS2Gamerules.kAlienStartSound    = PrecacheAsset("sound/ns2.fev/alien/voiceovers/game_start")
NS2Gamerules.lua:29: NS2Gamerules.kVictorySound       = PrecacheAsset("sound/ns2.fev/common/victory")
NS2Gamerules.lua:30: NS2Gamerules.kDefeatSound        = PrecacheAsset("sound/ns2.fev/common/loss")
NS2Gamerules.lua:31: NS2Gamerules.kCountdownSound     = PrecacheAsset("sound/ns2.fev/common/countdown")
*/
