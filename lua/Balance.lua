// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Balance.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Auto-generated. Copy and paste from balance spreadsheet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/BalanceHealth.lua")
Script.Load("lua/BalanceMisc.lua")

// MARINE COSTS
kCommandStationCost = 20
kCommandFacilityUpgradeCost = 15
kCommandCenterUpgradeCost = 20

kExtractorCost = 15
kResourceUpgradeResearchCost = 5

kInfantryPortalCost = 20

kArmoryCost = 10
kAmmoPackCost = 1
kMedPackCost = 2

kAdvancedArmoryUpgradeCost = 15

kWeaponsModuleAddonCost = 20
kPrototypeLabCost = 40

kSentryCost = 20
kSentryTechCost = 5
kPowerPackCost = 15

kMACMineCost = 5
kTechMinesResearchCost = 10
kTechEMPResearchCost = 10
kTechMACSpeedResearchCost = 5

kShotgunCost = 25
kShotgunTechResearchCost = 15

kGrenadeLauncherCost = 30
kGrenadeLauncherTechResearchCost = 15
kNerveGasTechResearchCost = 15

kFlamethrowerCost = 30
kFlamethrowerTechResearchCost = 20

kRoboticsFactoryCost = 20
kARCCost = 25
kARCSplashTechResearchCost = 15
kARCArmorTechResearchCost = 15

kJetpackCost = 25
kJetpackTechResearchCost = 25
kJetpackFuelTechResearchCost = 15
kJetpackArmorTechResearchCost = 15

kExoskeletonCost = 15
kExoskeletonTechResearchCost = 20
kExoskeletonLockdownTechResearchCost = 20
kExoskeletonUpgradeTechResearchCost = 20

kMinigunCost = 30
kDualMinigunCost = 25
kDualMinigunTechResearchCost = 20

kWeapons1ResearchCost = 15
kWeapons2ResearchCost = 25
kWeapons3ResearchCost = 35
kArmor1ResearchCost = 15
kArmor2ResearchCost = 25
kArmor3ResearchCost = 35

kCatPackCost = 2
kCatPackTechResearchCost = 10

kRifleUpgradeTechResearchCost = 10

kObservatoryCost = 10
kPhaseTechResearchCost = 10



kHiveCost = 20
kHiveMassUpgradeCost = 20
kHiveColonyUpgradeCost = 20

kMetabolizeTechCost = 25

kHarvesterCost = 15

kDrifterFlareTechResearchCost = 20

kCragCost = 10
kMatureCragCost = 10

kShiftCost = 10
kMatureShiftCost = 10

kShadeCost = 10
kMatureShadeCost = 10

kWhipCost = 10
kMatureWhipCost = 10

kGorgeCost = 10
kLerkCost = 30
kFadeCost = 50
kOnosCost = 75
kHydraCost = 10

kLeapResearchCost = 5
kBloodThirstResearchCost = 5
kFeedResearchCost = 5
kCarapaceResearchCost = 5

kCorpulenceResearchCost = 5
kBacteriaResearchCost = 5

kAdrenalineResearchCost = 5
kPiercingResearchCost = 5

kFeintResearchCost = 5
kSapResearchCost = 5

kBoneShieldResearchCost = 5
kStompResearchCost = 5

kCarapaceCost = 2
kLeapCost = 2
kFeedCost = 2
kBloodThirstCost = 2
kCorpulenceCost = 2
kBacteriaCost = 2
kHydraAbilityCost = 2
kHarvesterAbilityCost = 2
kPiercingCost = 2
kAdrenalineCost = 2
kFeintCost = 2
kSapCost = 2
kStompCost = 2
kBoneShieldCost = 2

kMelee1ResearchCost = 15
kMelee2ResearchCost = 25
kMelee3ResearchCost = 35
kAlienArmor1ResearchCost = 15
kAlienArmor2ResearchCost = 25
kAlienArmor3ResearchCost = 35


kPlayingTeamInitialCarbon = 50

kPlayerInitialPlasma = 999

kResourceTowerResourceInterval = 12


// MARINE DAMAGE
kRifleDamage = 10
kRifleDamageType = kDamageType.Normal
kRifleFireDelay = 0.0555
kRifleClipSize = 50

kRifleMeleeDamage = 35
kRifleMeleeDamageType = kDamageType.Normal
kRifleMeleeFireDelay = 0.7


kPistolDamage = 20
kPistolDamageType = kDamageType.Heavy
kPistolFireDelay = 0.1
kPistolClipSize = 10

kPistolAltDamage = 30
kPistolAltFireDelay = 0.2



kAxeDamage = 30
kAxeDamageType = kDamageType.Structural
kAxeFireDelay = 0.6


kGrenadeLauncherDamage = 150
kGrenadeLauncherDamageType = kDamageType.Structural
kGrenadeLauncherFireDelay = 1
kGrenadeLauncherClipSize = 4
kGrenadeLauncherDamageRadius = 8
kGrenadeLifetime = 3

kShotgunMaxDamage = 20
kShotgunMinDamage = 14
kShotgunDamageType = kDamageType.Normal
kShotgunFireDelay = 0.9
kShotgunClipSize = 8
kShotgunBulletsPerShot = 10
kShotgunMinDamageRange = 20
kShotgunMaxDamageRange = 2
kShotgunSpreadDegrees = 20

kFlamethrowerDamage = 20
kFlamethrowerDamageType = kDamageType.Flame
kFlamethrowerFireDelay = 0.5
kFlamethrowerClipSize = 15

kBurnDamagePerSecond = 8

kMinigunDamage = 25
kMinigunDamageType = kDamageType.Normal
kMinigunFireDelay = 0.06
kMinigunClipSize = 250

kMACAttackDamage = 5
kMACAttackDamageType = kDamageType.Normal
kMACAttackFireDelay = 0.6


kSentryAttackDamage = 10
kSentryAttackDamageType = kDamageType.Light
kSentryAttackBaseROF = 0.08
kSentryAttackRandROF = 0.04
kSentryAttackBulletsPerSalvo = 1

kARCDamage = 300
kARCDamageType = kDamageType.StructuresOnly
kARCFireDelay = 3


kWeapons1DamageScalar = 1.1
kWeapons2DamageScalar = 1.2
kWeapons3DamageScalar = 1.3


// ALIEN DAMAGE
kBiteDamage = 75
kBiteDamageType = kDamageType.Normal
kBiteFireDelay = 0.45
kBiteEnergyCost = 3

kParasiteDamage = 10
kParasiteDamageType = kDamageType.Normal
kParasiteFireDelay = 0.5
kParasiteEnergyCost = 30

kSpitDamage = 25
kSpitDamageType = kDamageType.Normal
kSpitFireDelay = 0.5
kSpitEnergyCost = 7

kHealsprayDamage = 13
kHealsprayDamageType = kDamageType.Light
kHealsprayFireDelay = 0.8
kHealsprayEnergyCost = 20

kSpikeMaxDamage = 20
kSpikeMinDamage = 10
kSpikeDamageType = kDamageType.Normal
kSpikeFireDelay = 0.1
kSpikeEnergyCost = 1.5
kPiercingDamageScalar = 1.4

kSpikesAltDamage = 90
kSpikesAltDamageType = kDamageType.Normal
kSpikesAltFireDelay = 1
kSpikesAltEnergyCost = 30

kSporesDamagePerSecond = 14
kSporesDamageType = kDamageType.Normal
kSporesFireDelay = 0.8
kSporesEnergyCost = 20

kSwipeDamage = 80
kSwipeDamageType = kDamageType.Normal
kSwipeFireDelay = 0.5
kSwipeEnergyCost = 6

kStabDamage = 160
kStabDamageType = kDamageType.Puncture
kStabFireDelay = 1.5
kStabEnergyCost = 20
kBlinkEnergyCost = 25

kGoreDamage = 90
kGoreDamageType = kDamageType.Normal
kGoreFireDelay = 0.7
kGoreEnergyCost = 2

kChargeMaxDamage = 4
kChargeMinDamage = 1



kHydraSpikeDamage = 20
kHydraSpikeDamageType = kDamageType.Normal



kDrifterAttackDamage = 5
kDrifterAttackDamageType = kDamageType.Normal
kDrifterAttackFireDelay = 0.6


kMelee1DamageScalar = 1.1
kMelee2DamageScalar = 1.2
kMelee3DamageScalar = 1.3

// SPAWN TIMES
kMarineRespawnTime = 5
kAlienRespawnTime = 9

// BUILD/RESEARCH TIMES
kArmoryBuildTime = 15
kAdvancedArmoryResearchTime = 120
kWeaponsModuleAddonTime = 120
kPrototypeLabBuildTime = 20

kMACBuildTime = 5
kExtractorBuildTime = 15
kResourceUpgradeResearchTime = 30
kResourceUpgradeAmount = 0.3333

kInfantryPortalBuildTime = 10
kInfantryPortalTransponderTechResearchTime = 30
kInfantryPortalTransponderTechResearchCost = 10
kInfantryPortalTransponderUpgradeTime = 30
kInfantryPortalTransponderUpgradeCost = 10

kRifleUpgradeTechResearchTime = 20
kShotgunTechResearchTime = 40
kDualMinigunTechResearchTime = 20
kGrenadeLauncherTechResearchTime = 20

kCommandStationBuildTime = 15
kCommandFacilityUpgradeTime = 120
kCommandCenterUpgradeTime = 180

kPowerPointBuildTime = 15
kPowerPackBuildTime = 13

kRoboticsFactoryBuildTime = 50
kARCBuildTime = 20
kARCSplashTechResearchTime = 30
kARCArmorTechResearchTime = 30

kSentryTechResearchTime = 15
kSentryBuildTime = 10

kTechMinesResearchTime = 20
kTechEMPResearchTime = 20
kTechMACSpeedResearchTime = 15

kJetpackTechResearchTime = 90
kJetpackFuelTechResearchTime = 60
kJetpackArmorTechResearchTime = 60
kExoskeletonTechResearchTime = 90
kExoskeletonLockdownTechResearchTime = 60
kExoskeletonUpgradeTechResearchTime = 60

kFlamethrowerTechResearchTime = 60
kFlamethrowerAltTechResearchTime = 60

kNerveGasTechResearchTime = 60

kDualMinigunTechResearchTime = 60
kCatPackTechResearchTime = 15

kObservatoryBuildTime = 15

kWeapons1ResearchTime = 60
kWeapons2ResearchTime = 90
kWeapons3ResearchTime = 120
kArmor1ResearchTime = 60
kArmor2ResearchTime = 90
kArmor3ResearchTime = 120


kHiveBuildTime = 30
kHiveMassUpgradeTime = 120
kHiveColonyUpgradeTime = 180

kDrifterBuildTime = 4
kHarvesterBuildTime = 20

kDrifterFlareTechResearchTime = 25

kCragBuildTime = 20
kMatureCragResearchTime = 30

kWhipBuildTime = 20
kMatureWhipResearchTime = 30

kShiftBuildTime = 20
kMatureShiftResearchTime = 30

kShadeBuildTime = 20
kMatureShadeResearchTime = 30

kHydraBuildTime = 12

kSkulkGestateTime = 3
kGorgeGestateTime = 10
kLerkGestateTime = 15
kFadeGestateTime = 25
kOnosGestateTime = 35

kEvolutionGestateTime = 3
kMetabolizeTechResearchTime = 15
kMetabolizeTime = 10
kMetabolizeResearchScalar = 0.2
kFuryTime = 6

kLeapResearchTime = 10
kBloodThirstResearchTime = 10
kFeedResearchTime = 10
kCarapaceResearchTime = 10

kCorpulenceResearchTime = 10
kBacteriaResearchTime = 10

kAdrenalineResearchTime = 15
kPiercingResearchTime = 15

kFeintResearchTime = 15
kSapResearchTime = 15

kBoneShieldResearchTime = 20
kStompResearchTime = 20





// ENERGY COSTS
kCommandStationInitialEnergy = 50  kCommandStationMaxEnergy = 200
kCommandFacilityMaxEnergy = 250
kCommandCenterMaxEnergy = 300
kCommandCenterNanoGridCost = 50  

kMACCost = 50  

kHiveInitialEnergy = 100  kHiveMaxEnergy = 200
kHiveMassMaxEnergy = 250
kHiveColonyMaxEnergy = 300
kGrowCost = 25
kMetabolizeCost = 25  

kObservatoryInitialEnergy = 25  kObservatoryMaxEnergy = 100
kObservatoryScanCost = 20  
kObservatoryDistressBeaconCost = 25  

kDrifterCost = 30  

kCragInitialEnergy = 25  kCragMaxEnergy = 100
kCragHealCost = 0  
kCragUmbraCost = 30  
kCragBabblersCost = 75  
kMatureCragMaxEnergy = 150

kWhipInitialEnergy = 25  kWhipMaxEnergy = 100
kWhipFuryInitialEnergy = 50  kWhipFuryCost = 50  
kWhipBombardInitialEnergy = 25  
kMatureWhipMaxEnergy = 150

kShiftInitialEnergy = 25  kShiftMaxEnergy = 100
kShiftEchoCost = 75  
kShiftEnergizeCost = 25  
kMatureShiftMaxEnergy = 150

kShadeInitialEnergy = 25  kShadeMaxEnergy = 100
kShadeCloakCost = 25  
kShadePhantasmFadeCost = 25  
kShadePhantasmOnosCost = 50  
kShadePhantasmCost = 75  
kMatureShadeMaxEnergy = 150

kEnergyUpdateRate = 0.5











