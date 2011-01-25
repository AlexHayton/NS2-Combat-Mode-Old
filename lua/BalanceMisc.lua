// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BalanceMisc.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Time spawning alien player must be in egg before hatching
kAlienSpawnTime = 2
kInitialMACs = 0
// Construct at a slower rate than players
kMACConstructEfficacy = .3
kStopFireProbability = .10       // 10% chance per second
kFlamethrowerAltTechResearchCost = 20
kDefaultFOV = 90
kDefaultStructureCost = 10
kStructureCircleRange = 4
kInfantryPortalUpgradeCost = 10
kInfantryPortalAttachRange = 10
// Allow marines to redeploy to other bases easier
kInfantryPortalRecycleScalar = .8
// Maximum distance from a command station that IPs can be built
kInfantryPortalBuildDistance = 8
// Minimum distance that initial IP spawns away from team location
kInfantryPortalMinSpawnDistance = 4
kWeaponStayTime = 30    // NS1
kInfestCost = 10
kRifleCost = 0
kPistolCost = 0
kAxeCost = 0
// % use per second
kJetpackUseFuelRate = .2
// % gain every second whether in use or not
kJetpackReplenishFuelRate = .15
kInitialDrifters = 3
kSkulkCost = 0
kBuildHydraDelay = .5
kLerkWeaponSwitchTime = .5
kMACSpeedAmount = .5
// How close should MACs/Drifters fly to operate on target
kCommandStationEngagementDistance = 4
kInfantryPortalEngagementDistance = 2
kArmoryEngagementDistance = 3
kExtractorEngagementDistance = 2
kObservatoryEngagementDistance = 1
kRoboticsFactorEngagementDistance = 5
kARCEngagementDistance = 2
kSentryEngagementDistance = 2
kPlayerEngagementDistance = 1
kHeavyEngagementDistance = 1.5
kOnosEngagementDistance = 2

// Marine buy costs
kFlamethrowerAltCost = 5

// Scanner sweep
kScanDuration = 10
kScanRadius = 20

// Distress Beacon (from NS1)
kDistressBeaconRange = 15
kDistressBeaconTime = 3

kEnergizeRange = 10
kEnergizeDuration = 6
kEnergizeEnergyIncrease = .2

// Rate of fire increase per level
kFuryROFIncrease = .15

kSprayDouseOnFireChance = .5

// Players and structures get energy back at this rate when on fire 
kOnFireEnergyRecuperationScalar = .2
