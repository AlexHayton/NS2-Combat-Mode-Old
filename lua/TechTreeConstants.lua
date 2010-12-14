// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTreeConstants.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kTechId = enum({
    
    'None', 
    
    // General orders and actions ("Default" is right-click)
    'Default', 'Move', 'Attack', 'Build', 'Construct', 'Cancel', 'Recycle', 'Weld', 'Stop', 'SetRally', 'SetTarget',
    
    // Commander menus for selected units
    'RootMenu', 'BuildMenu', 'AdvancedMenu', 'AssistMenu', 'SquadMenu', 'MarkersMenu', 'UpgradesMenu',
    
    // Command station menus
    'CommandStationUpgradesMenu',
    
    // Armory menus
    'ArmoryUpgradesMenu', 'ArmoryEquipmentMenu',
    
    // Robotics factory menus
    'RoboticsFactoryARCUpgradesMenu', 'RoboticsFactoryMACUpgradesMenu',
    
    // Prototype lab menus
    'PrototypeLabUpgradesMenu',

    'ReadyRoomPlayer', 
    
    // Doors
    'Door', 'DoorOpen', 'DoorClose', 'DoorLock', 'DoorUnlock',

    // Misc
    'Target',
    
    /////////////
    // Marines //
    /////////////
    
    // Marine classes
    'Marine', 'Heavy', "MarineCommander",
    
    // Marine alerts (specified alert sound and text in techdata if any)
    'MarineAlertAcknowledge', 'MarineAlertNeedMedpack', 'MarineAlertNeedAmmo', 'MarineAlertNeedOrder', 'MarineAlertHostiles',
    
    'MarineAlertSentryFiring', 'MarineAlertSentryUnderAttack', 'MarineAlertCommandStationUnderAttack', 'MarineAlertStructureUnderAttack', 'MarineAlertExtractorUnderAttack', 'MarineAlertSoldierLost',
    
    'MarineAlertResearchComplete', 'MarineAlertUpgradeComplete', 'MarineAlertOrderComplete', 'MarineAlertWeldingBlocked', 'MarineAlertMACBlocked', 'MarineAlertNotEnoughResources', 'MarineAlertObjectiveCompleted', 'MarineAlertConstructionComplete',
    
    // Select squads
    'SelectRedSquad', 'SelectBlueSquad', 'SelectGreenSquad', 'SelectYellowSquad', 'SelectOrangeSquad',
    
    // Marine orders 
    'SquadMove', 'SquadAttack', 'SquadDefend', 'SquadSeekAndDestroy', 'SquadHarass', 'SquadRegroup', 
    
    // Marine tech 
    'CommandStation', 'CommandFacility', 'CommandCenter', 'MAC', 'Armory', 'InfantryPortal', 'Extractor', 'ExtractorUpgrade', 'SentryTech', 'Sentry', 'ARC', 'InfantryPortalTransponderTech', 'InfantryPortalTransponderUpgrade', 'InfantryPortalTransponder',
    'Scan', 'AmmoPack', 'MedPack', 'CatPack', 'CatPackTech', 'PowerPoint', 'AdvancedArmoryUpgrade', 'Observatory', 'ObservatoryEnergy', 'DistressBeacon', 'RoboticsFactory', 
    'WeaponsModule', 'PrototypeLab', 'AdvancedArmory', 'CommandFacilityUpgrade', 'CommandCenterUpgrade', 
    
    // Weapon tech
    'RifleUpgradeTech', 'ShotgunTech', 'GrenadeLauncherTech', 'FlamethrowerTech', 'NerveGasTech', 'FlamethrowerAltTech', 'DualMinigunTech',
    
    // Marine buys
    'RifleUpgrade', 'NerveGas', 'FlamethrowerAlt',
    
    // Research 
    'PhaseTech', 'MACWeldingTech', 'MACSpeedTech', 'MACMinesTech', 'MACEMPTech', 'ARCArmorTech', 'ARCSplashTech', 'JetpackTech', 'ExoskeletonTech',
    
    // MAC (build bot) abilities
    'MACMine', 'MACEMP',
    
    // Weapons 
    'Rifle', 'Pistol', 'Shotgun', 'Minigun', 'GrenadeLauncher', 'Flamethrower', 'Axe', 'Minigun',
    
    // Armor
    'Jetpack', 'JetpackFuelTech', 'JetpackArmorTech', 'Exoskeleton', 'ExoskeletonLockdownTech', 'ExoskeletonUpgradeTech',
    
    // Marine upgrades
    'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3',
    
    // Activations
    'ARCDeploy', 'ARCUndeploy',
    
    // Commander abilities
    'NanoDefense', 'ReplicateTech',
    
    // Special tech
    'TwoCommandStations', 'ThreeCommandStations',

    ////////////
    // Aliens //
    ////////////

    // Alien lifeforms 
    'Skulk', 'Gorge', 'Lerk', 'Fade', 'Onos', "AlienCommander",
    
    // Alien abilities (not all are needed, only ones with damage types)
    'Bite', 'Parasite', 'Spit', 'Spray', 'Spikes', 'SpikesAlt', 'Spores', 'HydraSpike', 'SwipeBlink', 'StabBlink', 'Gore',
    
    // Alien structures 
    'Hive', 'HiveMass', 'HiveColony', 'Harvester', 'HarvesterUpgrade', 'Drifter', 'Egg', 'Cocoon', 'Embryo', 'Hydra', 'HiveMassUpgrade', 'HiveColonyUpgrade',

    // Upgrade buildings and abilities (structure, upgraded structure, passive, triggered, targeted)
    'Crag', 'UpgradeCrag', 'MatureCrag', 'CragHeal', 'CragUmbra', 'CragBabblers',
    'Whip', 'UpgradeWhip', 'MatureWhip', 'WhipAcidStrike', 'WhipFury', 'WhipBombard',
    'Shift', 'UpgradeShift', 'MatureShift', 'ShiftRecall', 'ShiftEcho', 'ShiftEnergize', 
    'Shade', 'UpgradeShade', 'MatureShade', 'ShadeDisorient', 'ShadeCloak', 'ShadePhantasmMenu', 'ShadePhantasmFade', 'ShadePhantasmOnos', 'ShadePhantasmHive',
    
    // Alien abilities and upgrades - BabblerTech
    'BabblerTech', 'LobTech', 'EchoTech', 'PhantasmTech', 
    'LeapTech', 'BloodThirstTech', 'FeedTech', 'Melee1Tech', 'Melee2Tech', 'Melee3Tech', 'Armor1Tech', 'Armor2Tech', 'Armor3Tech',
    'AdrenalineTech', 'CorpulenceTech', 'BacteriaTech', 'FeintTech', 'SapTech', 'StompTech', 'BoneShieldTech', 'CarapaceTech', 'PiercingTech',
    
    // Alien buys
    'Leap', 'Feed', 'Carapace', 'BloodThirst', 'Bacteria', 'Corpulence', 'HydraAbility', 'HarvesterAbility', 'Piercing', 'Adrenaline', 'Feint', 'Sap', 'Gore', 'Stomp', 'BoneShield', 
    
    // Drifter tech/abilities
    'DrifterFlareTech', 'DrifterFlare', 'DrifterParasiteTech', 'DrifterParasite', 
    
    // Alien alerts
    'AlienAlertNeedHealing', 'AlienAlertStructureUnderAttack', 'AlienAlertHiveUnderAttack', 'AlienAlertHiveDying', 'AlienAlertHarvesterUnderAttack', 'AlienAlertGorgeBuiltHarvester',
    
    'AlienAlertNotEnoughResources', 'AlienAlertResearchComplete', 'AlienAlertUpgradeComplete', 'AlienAlertHiveComplete',
    
    // Hive markers    
    'ThreatMarker', 'LargeThreatMarker', 'NeedHealingMarker', 'WeakMarker', 'ExpandingMarker',
    
    // Special tech
    'TwoHives', 'ThreeHives',
    
    // Commander abilities
    'Grow', 'MetabolizeTech', 'Metabolize',

    // Maximum index
    'Max'
    
    })

// Increase techNode network precision if more needed
kTechIdMax  = kTechId.Max

// Tech types
kTechType = enum({ 'Invalid', 'Order', 'Research', 'Upgrade', 'Action', 'Buy', 'Build', 'Manufacture', 'Activation', 'Menu', 'EnergyBuild', 'Special' })

// Button indices
kRecycleButtonIndex         = 7
kMarineUpgradeButtonIndex   = 5
kAlienBackButtonIndex       = 8

