// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechData.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A "database" of attributes for all units, abilities, structures, weapons, etc. in the game.
// Shared between client and server.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Commands
kBuildStructureCommand                  = "buildstructure"

// Set up structure data for easy use by Server.lua and model classes
// Store whatever data is necessary here and use LookupTechData to access
// Store any data that needs to used on both client and server here
// Lookup by key with LookupTechData()
kTechDataId                             = "id"
kTechDataDisplayName                    = "displayname"
kTechDataMapName                        = "mapname"
kTechDataModel                          = "model"
// Carbon, plasma or energy
kTechDataCostKey                        = "costkey"
kTechDataBuildTime                      = "buildtime"
// If an entity has this field, it's treated as a research node instead of a build node
kTechDataResearchTimeKey                = "researchTime"
kTechDataMaxHealth                      = "maxhealth"
kTechDataMaxArmor                       = "maxarmor"
kTechDataDamageType                     = "damagetype"
// Class that structure must be placed on top of (resource towers on resource points)
// If adding more attach classes, add them to GetIsAttachment()
kStructureAttachClass                   = "attachclass"
// Structure must be placed within kStructureAttachRange of this class, but it isn't actually attached
kStructureBuildNearClass                = "buildnearclass"
// If specified along with attach class, this entity can only be built within this range of an attach class (infantry portal near Command Station)
// If specified, you must also specify the tech id of the attach class.
kStructureAttachRange                   = "attachrange"
// If specified, draw a range indicator for the commander when selected.
kStructureVisualRange                   = "visualrange"
// The tech id of the attach class 
kStructureAttachId                      = "attachid"
// If specified, this tech is an alien class that can be gestated into
kTechDataGestateName                    = "gestateclass"
// If specified, how much time it takes to evolve into this class
kTechDataGestateTime                    = "gestatetime"
// If specified, object spawns this far off the ground
kTechDataSpawnHeightOffset              = "spawnheight"
// All player tech ids should have this, nothing else uses it
kTechDataMaxExtents                     = "maxextents"
// If specified, is amount of energy structure starts with
kTechDataInitialEnergy                  = "initialenergy"
// If specified, is max energy structure can have
kTechDataMaxEnergy                      = "maxenergy"
// Menu priority. If more than one techId is specified for the same spot in a menu, use the one with the higher priority.
// If a tech doesn't specify a priority, treat as 0. If all priorities are tied, show none of them. This is how Starcraft works (see siege behavior).
kTechDataMenuPriority                   = "menupriority"
// Indicates that the tech node is an upgrade of another tech node, so that the previous tech is still active (ie, if you upgrade a hive
// to an advanced hive, your team still has "hive" technology.
kTechDataUpgradeTech                    = "upgradetech"
// Set true if entity should be rotated before being placed
kTechDataSpecifyOrientation             = "specifyorientation"
// Point value for killing structure
kTechDataPointValue                     = "pointvalue"
// Set to false if not yet implemented, for displaying differently for not enabling
kTechDataImplemented                    = "implemented"
// Set to string that will be added to end of description indicating date it went in
kTechDataNew                            = "new"
// For setting grow parameter on alien structures
kTechDataGrows                          = "grows"
// Commander hotkey
kTechDataHotkey                         = "hotkey"
// Alert sound name
kTechDataAlertSound                     = "alertsound"
// Alert text for commander HUD
kTechDataAlertText                      = "alerttext"
// Alert type. These are the types in CommanderUI_GetDynamicMapBlips
kTechDataAlertType                      = "alerttype"
// Alert scope
kTechDataAlertTeam                      = "alertteam"
// Sound that plays for Comm and ordered players when given this order
kTechDataOrderSound                     = "ordersound"
// Usage notes, caveats, etc. for use in commander tooltip
kTechDataTooltipInfo                    = "tooltipinfo"
// Indicate tech id that we're replicating
// Engagement distance - how close can unit get to it before it can repair or build it
kTechDataEngagementDistance             = "engagementdist"

function BuildTechData()
    
    local techData = { 

        // Orders
        { [kTechDataId] = kTechId.Move,                  [kTechDataDisplayName] = "Move", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "Move to waypoint", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.Attack,                [kTechDataDisplayName] = "Attack", [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "Attack enemy unit or player", [kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName},
        { [kTechDataId] = kTechId.Build,                 [kTechDataDisplayName] = "Build", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "Build new team structure"},
        { [kTechDataId] = kTechId.Construct,             [kTechDataDisplayName] = "Construct", [kTechDataOrderSound] = MarineCommander.kBuildStructureSound},
        { [kTechDataId] = kTechId.Cancel,                [kTechDataDisplayName] = "Cancel", [kTechDataHotkey] = Move.ESC},
        { [kTechDataId] = kTechId.Recycle,               [kTechDataDisplayName] = "Recycle", [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] = string.format("Destroy structure to recover %d%% of cost (less when damaged)", Structure.kRecyclePaybackScalar * 100) },
        { [kTechDataId] = kTechId.Weld,                  [kTechDataDisplayName] = "Weld", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "Weld door shut or repair target"},
        { [kTechDataId] = kTechId.Stop,                  [kTechDataDisplayName] = "Stop", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Stop moving and cancel all orders"},
        { [kTechDataId] = kTechId.SetRally,              [kTechDataDisplayName] = "Set rally point", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "New helper units automatically move here"},
        { [kTechDataId] = kTechId.SetTarget,             [kTechDataDisplayName] = "Set target", [kTechDataHotkey] = Move.T, [kTechDataTooltipInfo] = "Set target direction"},
        
        // Ready room player is the default player, hence the Player.kMapName
        { [kTechDataId] = kTechId.ReadyRoomPlayer,        [kTechDataDisplayName] = "Ready room player", [kTechDataMapName] = Player.kMapName, [kTechDataModel] = Marine.kModelName },
        
        // Marine classes
        { [kTechDataId] = kTechId.Marine,              [kTechDataDisplayName] = "Marine", [kTechDataMapName] = Marine.kMapName, [kTechDataModel] = Marine.kModelName, [kTechDataMaxHealth] = Marine.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataPointValue] = kMarinePointValue},
        { [kTechDataId] = kTechId.Heavy,               [kTechDataDisplayName] = "Heavy", [kTechDataMapName] = Heavy.kMapName, [kTechDataModel] = Heavy.kModelName, [kTechDataMaxHealth] = Heavy.kHealth, [kTechDataEngagementDistance] = kHeavyEngagementDistance, [kTechDataPointValue] = kExosuitPointValue},
        { [kTechDataId] = kTechId.MarineCommander,     [kTechDataDisplayName] = "Marine Commander", [kTechDataMapName] = MarineCommander.kMapName, [kTechDataModel] = ""},

        // Squads
        { [kTechDataId] = kTechId.SelectRedSquad,              [kTechDataDisplayName] = "Red squad", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectBlueSquad,             [kTechDataDisplayName] = "Blue squad", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectGreenSquad,            [kTechDataDisplayName] = "Green squad", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectYellowSquad,           [kTechDataDisplayName] = "Yellow squad", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectOrangeSquad,           [kTechDataDisplayName] = "Orange squad", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        
        // Marine orders
        { [kTechDataId] = kTechId.SquadMove,               [kTechDataDisplayName] = "Move", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName, [kTechDataNew] = "new 10/6"},
        { [kTechDataId] = kTechId.SquadAttack,             [kTechDataDisplayName] = "Attack", [kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName, [kTechDataNew] = "new 10/6"},
        { [kTechDataId] = kTechId.SquadDefend,             [kTechDataDisplayName] = "Defend", [kTechDataOrderSound] = MarineCommander.kDefendTargetSound, [kTechDataNew] = "new 10/6"},
        { [kTechDataId] = kTechId.SquadSeekAndDestroy,     [kTechDataDisplayName] = "Seek and destroy", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.SquadHarass,             [kTechDataDisplayName] = "Harass", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.SquadRegroup,            [kTechDataDisplayName] = "Regroup", [kTechDataImplemented] = false},

        // Menus
        { [kTechDataId] = kTechId.RootMenu,              [kTechDataDisplayName] = "Back", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "Back to main menu"},
        { [kTechDataId] = kTechId.BuildMenu,             [kTechDataDisplayName] = "Build", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "Basic structures"},
        { [kTechDataId] = kTechId.AdvancedMenu,          [kTechDataDisplayName] = "Advanced", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "Advanced structures"},
        { [kTechDataId] = kTechId.AssistMenu,            [kTechDataDisplayName] = "Assist", [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "Assist players"},
        { [kTechDataId] = kTechId.SquadMenu,             [kTechDataDisplayName] = "Squad", [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "Squad orders"},
        { [kTechDataId] = kTechId.MarkersMenu,           [kTechDataDisplayName] = "Markers", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "Place pheromone markers"},
        { [kTechDataId] = kTechId.UpgradesMenu,          [kTechDataDisplayName] = "Upgrades", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "Team upgrades"},

        // Marine menus
        { [kTechDataId] = kTechId.CommandStationUpgradesMenu,           [kTechDataDisplayName] = "Command Station upgrades", [kTechDataHotkey] = Move.C, [kTechDataNew] = "new 10/6"},
        { [kTechDataId] = kTechId.ArmoryUpgradesMenu,                  [kTechDataDisplayName] = "Player upgrades", [kTechDataHotkey] = Move.U},
        { [kTechDataId] = kTechId.ArmoryEquipmentMenu,            [kTechDataDisplayName] = "Equipment upgrades", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.RoboticsFactoryARCUpgradesMenu,            [kTechDataDisplayName] = "ARC upgrades", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.RoboticsFactoryMACUpgradesMenu,            [kTechDataDisplayName] = "MAC upgrades", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.PrototypeLabUpgradesMenu,            [kTechDataDisplayName] = "Prototype lab upgrades", [kTechDataHotkey] = Move.P},
        
        // Misc.        
        { [kTechDataId] = kTechId.PowerPoint,            [kTechDataMapName] = PowerPoint.kMapName,            [kTechDataDisplayName] = "Power node",  [kTechDataCostKey] = 0,   [kTechDataMaxHealth] = PowerPoint.kHealth, [kTechDataMaxArmor] = PowerPoint.kArmor, [kTechDataBuildTime] = kPowerPointBuildTime, [kTechDataModel] = PowerPoint.kOnModelName, [kTechDataPointValue] = kPowerPointPointValue},        
        { [kTechDataId] = kTechId.Target,                [kTechDataMapName] = Target.kMapName,                [kTechDataDisplayName] = "Target", [kTechDataModel] = ""},
        { [kTechDataId] = kTechId.Door,                  [kTechDataDisplayName] = "Door", [kTechDataMapName] = Door.kMapName, [kTechDataModel] = Door.kModelName},
        { [kTechDataId] = kTechId.DoorOpen,              [kTechDataDisplayName] = "Open door", [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "Open door"},
        { [kTechDataId] = kTechId.DoorClose,             [kTechDataDisplayName] = "Close door", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "Close door"},
        { [kTechDataId] = kTechId.DoorLock,              [kTechDataDisplayName] = "Lock door", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "Locked doors can be destroyed by alien growth"},
        { [kTechDataId] = kTechId.DoorUnlock,            [kTechDataDisplayName] = "Unlock door", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "Unlock door"},
        
        // Commander abilities
        { [kTechDataId] = kTechId.NanoDefense,           [kTechDataDisplayName] = "Nano-grid defense", [kTechDataCostKey] = kCommandCenterNanoGridCost, [kTechDataImplemented] = false, [kTechDataTooltipInfo] = "Gradually reduces damage by 40% for target player or structure (lasts 15 seconds)"},        
        
        // Command station and its buildables
        { [kTechDataId] = kTechId.CommandStation,  [kTechDataMapName] = CommandStation.kLevel1MapName,     [kTechDataDisplayName] = "Command Station",     [kTechDataBuildTime] = kCommandStationBuildTime, [kTechDataCostKey] = kCommandStationCost, [kTechDataModel] = CommandStation.kModelName,             [kTechDataMaxHealth] = kCommandStationHealth, [kTechDataMaxArmor] = kCommandStationArmor,            [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 0, [kTechDataEngagementDistance] = kCommandStationEngagementDistance, [kTechDataInitialEnergy] = kCommandStationInitialEnergy,      [kTechDataMaxEnergy] = kCommandStationMaxEnergy, [kTechDataPointValue] = kCommandStationPointValue, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "Allows another player to become Commander and grants access to next tier"},
        { [kTechDataId] = kTechId.CommandFacilityUpgrade,  [kTechDataDisplayName] = "Upgrade to Command Facility",     [kTechDataCostKey] = kCommandFacilityUpgradeCost, [kTechDataResearchTimeKey] = kCommandFacilityUpgradeTime, [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] = "Gives access to second tier technology"},
        { [kTechDataId] = kTechId.CommandFacility,  [kTechDataMapName] = CommandStationL2.kMapName,     [kTechDataDisplayName] = "Command Facility",     [kTechDataModel] = CommandStation.kModelName,  [kTechDataUpgradeTech] = kTechId.CommandStation,      [kStructureAttachClass] = "TechPoint",      [kTechDataMaxHealth] = kCommandFacilityHealth, [kTechDataMaxArmor] = kCommandFacilityArmor, [kTechDataMaxEnergy] = kCommandFacilityMaxEnergy, [kTechDataEngagementDistance] = kCommandStationEngagementDistance, [kTechDataPointValue] = kCommandFacilityPointValue},
        { [kTechDataId] = kTechId.CommandCenterUpgrade,  [kTechDataDisplayName] = "Upgrade to Command Center",     [kTechDataCostKey] = kCommandCenterUpgradeCost,   [kTechDataResearchTimeKey] = kCommandCenterUpgradeTime, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "Gives access to third tier technology"},        
        { [kTechDataId] = kTechId.CommandCenter,  [kTechDataMapName] = CommandStationL3.kMapName,     [kTechDataDisplayName] = "Command Center",     [kTechDataModel] = CommandStation.kModelName,             [kTechDataMaxHealth] = kCommandCenterHealth,     [kTechDataEngagementDistance] = kCommandStationEngagementDistance,  [kTechDataMaxArmor] = kCommandCenterArmor,       [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 0, [kTechDataMaxEnergy] = kCommandCenterMaxEnergy, [kTechDataResearchTimeKey] = kCommandCenterUpgradeTime,    [kTechDataMaxEnergy] = kCommandStationMaxEnergy,      [kTechDataMaxEnergy] = kCommandStationMaxEnergy, [kTechDataUpgradeTech] = kTechId.CommandFacility, [kTechDataPointValue] = kCommandCenterPointValue },       
        { [kTechDataId] = kTechId.TwoCommandStations,  [kTechDataDisplayName] = "Two Command Stations" },        
        { [kTechDataId] = kTechId.ThreeCommandStations,  [kTechDataDisplayName] = "Three Command Stations" },        

        { [kTechDataId] = kTechId.MAC,                   [kTechDataMapName] = MAC.kMapName,                      [kTechDataDisplayName] = "MAC",  [kTechDataMaxHealth] = MAC.kHealth, [kTechDataMaxArmor] = MAC.kArmor, [kTechDataCostKey] = kMACCost,            [kTechDataResearchTimeKey] = kMACBuildTime, [kTechDataModel] = MAC.kModelName,            [kTechDataDamageType] = kMACAttackDamageType,      [kTechDataMenuPriority] = 1, [kTechDataPointValue] = kMACPointValue, [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "Flying robot that builds and repairs structures"},
        { [kTechDataId] = kTechId.AmmoPack,              [kTechDataMapName] = AmmoPack.kMapName,                 [kTechDataDisplayName] = "Ammo pack",           [kTechDataCostKey] = kAmmoPackCost,            [kTechDataModel] = AmmoPack.kModelName, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = string.format("%s of ammo for any weapon", Pluralize(AmmoPack.kNumClips, "clip")) },
        { [kTechDataId] = kTechId.MedPack,               [kTechDataMapName] = MedPack.kMapName,                  [kTechDataDisplayName] = "Med pack",            [kTechDataCostKey] = kMedPackCost,             [kTechDataModel] = MedPack.kModelName, [kTechDataHotkey] = Move.H, [kTechDataTooltipInfo] = string.format("Restores %d player health", MedPack.kHealth)},
        { [kTechDataId] = kTechId.CatPack,               [kTechDataMapName] = CatPack.kMapName,                  [kTechDataDisplayName] = "Catalyst pack", [kTechDataImplemented] = false,            [kTechDataCostKey] = kCatPackCost,             [kTechDataModel] = CatPack.kModelName, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "Increase marine movement and rate of fire"},
        { [kTechDataId] = kTechId.CatPackTech,           [kTechDataCostKey] = kCatPackTechResearchCost,          [kTechDataResearchTimeKey] = kCatPackTechResearchTime, [kTechDataDisplayName] = "Catalyst packs", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "Increase marine movement and rate of fire"},

        // Marine base structures
        { [kTechDataId] = kTechId.Extractor,             [kTechDataMapName] = Extractor.kMapName,                [kTechDataDisplayName] = "Extractor",           [kTechDataCostKey] = kExtractorCost,       [kTechDataBuildTime] = kExtractorBuildTime, [kTechDataEngagementDistance] = kExtractorEngagementDistance, [kTechDataModel] = Extractor.kModelName,            [kTechDataMaxHealth] = kExtractorHealth, [kTechDataMaxArmor] = kExtractorArmor, [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kExtractorPointValue, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = string.format("Gives 1 carbon to team and 1 plasma to each player every %d seconds", kResourceTowerResourceInterval) },
        { [kTechDataId] = kTechId.InfantryPortal,        [kTechDataMapName] = InfantryPortal.kMapName,           [kTechDataDisplayName] = "Infantry Portal",     [kTechDataCostKey] = kInfantryPortalCost,   [kTechDataPointValue] = kInfantryPortalPointValue,   [kTechDataBuildTime] = kInfantryPortalBuildTime, [kTechDataMaxHealth] = kInfantryPortalHealth, [kTechDataMaxArmor] = kInfantryPortalArmor, [kTechDataModel] = InfantryPortal.kModelName, [kStructureBuildNearClass] = "CommandStation", [kStructureAttachId] = kTechId.CommandStation, [kStructureAttachRange] = kInfantryPortalAttachRange, [kTechDataEngagementDistance] = kInfantryPortalEngagementDistance, [kTechDataHotkey] = Move.P, [kTechDataTooltipInfo] = string.format("Respawns a marine every %d seconds (build near Command Station)", InfantryPortal.kSpawnTime)},
        { [kTechDataId] = kTechId.InfantryPortalTransponder,        [kTechDataMapName] = InfantryPortal.kMapName,           [kTechDataDisplayName] = "Infantry Portal with Transponder",     [kTechDataPointValue] = InfantryPortal.kTransponderPointValue,   [kTechDataMaxHealth] = kInfantryPortalTransponderHealth, [kTechDataMaxArmor] = kInfantryPortalTransponderArmor, [kTechDataModel] = InfantryPortal.kModelName, [kStructureBuildNearClass] = "CommandStation", [kStructureAttachId] = kTechId.CommandStation, [kStructureAttachRange] = kInfantryPortalAttachRange, [kTechDataHotkey] = Move.P, [kTechDataTooltipInfo] = string.format("Respawns marines and allows them to squad spawn")},
        { [kTechDataId] = kTechId.Armory,                [kTechDataMapName] = Armory.kMapName,                   [kTechDataDisplayName] = "Armory",              [kTechDataCostKey] = kArmoryCost,              [kTechDataBuildTime] = kArmoryBuildTime, [kTechDataMaxHealth] = kArmoryHealth, [kTechDataMaxArmor] = kArmoryArmor, [kTechDataEngagementDistance] = kArmoryEngagementDistance, [kTechDataModel] = Armory.kModelName, [kTechDataPointValue] = kArmoryPointValue, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "Resupplies health and ammo, allows players to buy weapons"},
        { [kTechDataId] = kTechId.SentryTech,            [kTechDataDisplayName] = "Sentry tech",                 [kTechDataCostKey] = kSentryTechCost,           [kTechDataResearchTimeKey] = kSentryTechResearchTime, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Allows sentry turrets"},
        { [kTechDataId] = kTechId.Sentry,                [kTechDataMapName] = "sentry",                          [kTechDataDisplayName] = "Sentry turret",       [kTechDataCostKey] = kSentryCost,         [kTechDataPointValue] = kSentryPointValue, [kTechDataModel] = Sentry.kModelName,            [kTechDataBuildTime] = kSentryBuildTime, [kTechDataMaxHealth] = kSentryHealth,  [kTechDataMaxArmor] = kSentryArmor, [kTechDataDamageType] = kSentryAttackDamageType, [kTechDataSpecifyOrientation] = true, [kTechDataHotkey] = Move.S, [kStructureVisualRange] = Sentry.kRange, [kTechDataEngagementDistance] = kSentryEngagementDistance, [kTechDataTooltipInfo] = string.format("Attacks enemies in %d degree arc %s", Sentry.kFov, DamageTypeDesc(kDamageType.Light))},

        // MACs 
        { [kTechDataId] = kTechId.MACMine,          [kTechDataMapName] = "mac_mine",             [kTechDataDisplayName] = "Lay mine", [kTechDataImplemented] = false,        [kTechDataCostKey] = kMACMineCost,         [kTechDataHotkey] = Move.I, [kTechDataTooltipInfo] = "Plant proximity mine on ground"},
        { [kTechDataId] = kTechId.MACMinesTech,     [kTechDataCostKey] = kTechMinesResearchCost,             [kTechDataImplemented] = false, [kTechDataResearchTimeKey] = kTechMinesResearchTime, [kTechDataDisplayName] = "MAC mines", [kTechDataTooltipInfo] = "Allows MACs to drop mines" },
        { [kTechDataId] = kTechId.MACEMP,           [kTechDataDisplayName] = "EMP blast", [kTechDataHotkey] = Move.E, [kTechDataImplemented] = false, [kTechDataTooltipInfo] = "Draining energy of nearby alien structures" },        
        { [kTechDataId] = kTechId.MACEMPTech,       [kTechDataCostKey] = kTechEMPResearchCost,             [kTechDataResearchTimeKey] = kTechEMPResearchTime, [kTechDataDisplayName] = "EMP ability", [kTechDataImplemented] = false, [kTechDataTooltipInfo] = "Gives MACs ability to drain alien structures of energy" },
        { [kTechDataId] = kTechId.MACSpeedTech,     [kTechDataDisplayName] = "Increase MAC speed",  [kTechDataNew] = "New 10/6", [kTechDataCostKey] = kTechMACSpeedResearchCost,  [kTechDataResearchTimeKey] = kTechMACSpeedResearchTime, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = string.format("Increases MAC speed by %d%%", math.ceil(kMACSpeedAmount*100))},
        { [kTechDataId] = kTechId.AmmoPack,              [kTechDataMapName] = AmmoPack.kMapName,                 [kTechDataDisplayName] = "Ammo pack",           [kTechDataCostKey] = kAmmoPackCost,            [kTechDataModel] = AmmoPack.kModelName},        
        
        // Marine advanced structures
        { [kTechDataId] = kTechId.AdvancedArmory,        [kTechDataMapName] = AdvancedArmory.kMapName,                   [kTechDataDisplayName] = "Advanced Armory",     [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,  [kTechDataModel] = Armory.kModelName,                     [kTechDataMaxHealth] = kAdvancedArmoryHealth,   [kTechDataMaxArmor] = kAdvancedArmoryArmor,  [kTechDataEngagementDistance] = kArmoryEngagementDistance,  [kTechDataUpgradeTech] = kTechId.Armory, [kTechDataPointValue] = kAdvancedArmoryPointValue},
        { [kTechDataId] = kTechId.Observatory,           [kTechDataMapName] = Observatory.kMapName,    [kTechDataNew] = "New 10/14",  [kTechDataDisplayName] = "Observatory",  [kTechDataCostKey] = kObservatoryCost,       [kTechDataModel] = Observatory.kModelName,            [kTechDataBuildTime] = kObservatoryBuildTime, [kTechDataMaxHealth] = kObservatoryHealth,   [kTechDataEngagementDistance] = kObservatoryEngagementDistance, [kTechDataMaxArmor] = kObservatoryArmor,   [kTechDataInitialEnergy] = kObservatoryInitialEnergy,      [kTechDataMaxEnergy] = kObservatoryMaxEnergy, [kTechDataPointValue] = kObservatoryPointValue, [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "Gives marines information about nearby enemies"},
        { [kTechDataId] = kTechId.Scan,                  [kTechDataDisplayName] = "Scan",     [kTechDataNew] = "New 10/14", [kTechDataHotkey] = Move.S,   [kTechDataCostKey] = kObservatoryScanCost, [kTechDataTooltipInfo] = "Reveals cloaked units and gives line of sight to any area" },
        { [kTechDataId] = kTechId.DistressBeacon,        [kTechDataDisplayName] = "Distress beacon",    [kTechDataNew] = "New 10/14", [kTechDataHotkey] = Move.B, [kTechDataCostKey] = kObservatoryDistressBeaconCost, [kTechDataTooltipInfo] = "Quickly transports a squad back to observatory" },
        { [kTechDataId] = kTechId.RoboticsFactory,       [kTechDataDisplayName] = "Robotics Factory",         [kTechDataMapName] = RoboticsFactory.kMapName,          [kTechDataDisplayName] = "Robotics Factory", [kTechDataImplemented] = false,    [kTechDataCostKey] = kRoboticsFactoryCost,       [kTechDataModel] = RoboticsFactory.kModelName,    [kTechDataEngagementDistance] = kRoboticsFactorEngagementDistance,        [kTechDataBuildTime] = kRoboticsFactoryBuildTime, [kTechDataMaxHealth] = kRoboticsFactoryHealth,    [kTechDataMaxArmor] = kRoboticsFactoryArmor, [kTechDataPointValue] = kRoboticsFactoryPointValue, [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] = "Allows production of mobile siege cannons"},        
        { [kTechDataId] = kTechId.ARC,                  [kTechDataMapName] = ARC.kMapName,                     [kTechDataDisplayName] = "ARC", [kTechDataImplemented] = false,        [kTechDataCostKey] = kARCCost,       [kTechDataDamageType] = kARCDamageType,  [kTechDataBuildTime] = kARCBuildTime, [kTechDataMaxHealth] = kARCHealth, [kTechDataEngagementDistance] = kARCEngagementDistance, [kTechDataMaxArmor] = kARCArmor, [kTechDataModel] = ARC.kModelName,            [kTechDataMaxHealth] = kARCHealth, [kTechDataPointValue] = kARCPointValue, [kTechDataHotkey] = Move.T},
        { [kTechDataId] = kTechId.ARCSplashTech,        [kTechDataCostKey] = kARCSplashTechResearchCost,             [kTechDataResearchTimeKey] = kARCSplashTechResearchTime, [kTechDataDisplayName] = "Increases ARC splash radius by 30%", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ARCArmorTech,         [kTechDataCostKey] = kARCArmorTechResearchCost,             [kTechDataResearchTimeKey] = kARCArmorTechResearchTime, [kTechDataDisplayName] = "Increases ARC armor", [kTechDataImplemented] = false },
        
        // Upgrades
        { [kTechDataId] = kTechId.ExtractorUpgrade,       [kTechDataCostKey] = kResourceUpgradeResearchCost,          [kTechDataResearchTimeKey] = kResourceUpgradeResearchTime, [kTechDataDisplayName] = string.format("Upgrade plasma production by %d%%", math.floor(kResourceUpgradeAmount*100)), [kTechDataHotkey] = Move.U, [kTechDataNew] = "New 10/16" },
        { [kTechDataId] = kTechId.InfantryPortalTransponderTech, [kTechDataCostKey] = kInfantryPortalTransponderTechResearchCost,            [kTechDataResearchTimeKey] = kInfantryPortalTransponderTechResearchTime, [kTechDataDisplayName] = "Transponder technology", [kTechDataTooltipInfo] = "Allows squad spawning from infantry portals", [kTechDataHotkey] = Move.T },
        { [kTechDataId] = kTechId.InfantryPortalTransponderUpgrade, [kTechDataCostKey] = kInfantryPortalTransponderUpgradeCost,            [kTechDataResearchTimeKey] = kInfantryPortalTransponderUpgradeTime, [kTechDataDisplayName] = "Add transponder", [kTechDataTooltipInfo] = "Allows marines to spawn with their squad", [kTechDataHotkey] = Move.T },
        { [kTechDataId] = kTechId.PhaseTech,             [kTechDataCostKey] = kPhaseTechResearchCost,                [kTechDataResearchTimeKey] = kPhaseTechResearchTime },
        
        // Note: The model name should not be specified for the armory upgrades due to how the parent/child relationship works
        // and how a model is loaded in ScriptActor:OnInit()
        { [kTechDataId] = kTechId.AdvancedArmoryUpgrade, [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,            [kTechDataResearchTimeKey] = kAdvancedArmoryResearchTime,  [kTechDataHotkey] = Move.U, [kTechDataDisplayName] = "Upgrade to Advanced Armory", [kTechDataTooltipInfo] = "Gives access to weapon and prototype modules" },
        { [kTechDataId] = kTechId.WeaponsModule,         [kTechDataCostKey] = kWeaponsModuleAddonCost,               [kTechDataResearchTimeKey] = kWeaponsModuleAddonTime,      [kTechDataDisplayName] = "Armory with Weapons module", [kTechDataMaxHealth] = kAdvancedArmoryHealth, [kTechDataUpgradeTech] = kTechId.AdvancedArmory, [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "Allows access to advanced weaponry"},
        { [kTechDataId] = kTechId.PrototypeLab,          [kTechDataCostKey] = kPrototypeLabCost,                     [kTechDataResearchTimeKey] = kPrototypeLabBuildTime,       [kTechDataDisplayName] = "Prototype lab", [kTechDataModel] = PrototypeLab.kModelName, [kTechDataMaxHealth] = kPrototypeLabHealth, [kTechDataPointValue] = kPrototypeLabPointValue, [kTechDataImplemented] = false, [kTechDataHotkey] = Move.P, [kTechDataTooltipInfo] = "Allows access advanced TSA prototype tech"},
       
        // Weapons
        { [kTechDataId] = kTechId.Rifle,                 [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "Rifle",         [kTechDataModel] = Rifle.kModelName, [kTechDataDamageType] = kRifleDamageType, [kTechDataCostKey] = kRifleCost,                                     },
        { [kTechDataId] = kTechId.Pistol,                [kTechDataMapName] = Pistol.kMapName,                   [kTechDataDisplayName] = "Pistol",         [kTechDataModel] = Pistol.kModelName, [kTechDataDamageType] = kPistolDamageType, [kTechDataCostKey] = kPistolCost,                                     },
        { [kTechDataId] = kTechId.Axe,                   [kTechDataMapName] = Axe.kMapName,                      [kTechDataDisplayName] = "Switch ax",         [kTechDataModel] = Axe.kModelName, [kTechDataDamageType] = kAxeDamageType, [kTechDataCostKey] = kAxeCost,                                     },
        { [kTechDataId] = kTechId.RifleUpgrade,          [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "Rifle upgrade", [kTechDataImplemented] = false, [kTechDataCostKey] = kRifleUpgradeCost,                       },
        { [kTechDataId] = kTechId.Shotgun,               [kTechDataMapName] = Shotgun.kMapName,                  [kTechDataDisplayName] = "Shotgun",             [kTechDataModel] = Shotgun.kModelName, [kTechDataDamageType] = kShotgunDamageType, [kTechDataCostKey] = kShotgunCost},
        
        { [kTechDataId] = kTechId.FlamethrowerTech,      [kTechDataCostKey] = kFlamethrowerTechResearchCost,     [kTechDataResearchTimeKey] = kFlamethrowerTechResearchTime, [kTechDataDisplayName] = "Research flamethrowers", [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] = "Allows flamethrowers to be purchased at Armories" },
        { [kTechDataId] = kTechId.FlamethrowerAltTech,   [kTechDataCostKey] = kFlamethrowerAltTechResearchCost,  [kTechDataResearchTimeKey] = kFlamethrowerAltTechResearchTime, [kTechDataDisplayName] = "Research flamethrower alt attack", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "Gives alt-attack to flamethrowers" },
        { [kTechDataId] = kTechId.Flamethrower,          [kTechDataMapName] = Flamethrower.kMapName,             [kTechDataDisplayName] = "Flamethrower", [kTechDataModel] = Flamethrower.kModelName,  [kTechDataDamageType] = kFlamethrowerDamageType, [kTechDataCostKey] = kFlamethrowerCost           },
        { [kTechDataId] = kTechId.DualMinigunTech,       [kTechDataCostKey] = kDualMinigunTechResearchCost,      [kTechDataResearchTimeKey] = kDualMinigunTechResearchTime, [kTechDataDisplayName] = "Research dual miniguns", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "Allows heavies to buy two Miniguns" },
        { [kTechDataId] = kTechId.Minigun,               [kTechDataMapName] = Minigun.kMapName,                  [kTechDataDisplayName] = "Minigun", [kTechDataImplemented] = false,        [kTechDataDamageType] = kMinigunDamageType,         [kTechDataCostKey] = kMinigunCost, [kTechDataModel] = Minigun.kModelName},
        { [kTechDataId] = kTechId.GrenadeLauncher,       [kTechDataMapName] = GrenadeLauncher.kMapName,          [kTechDataDisplayName] = "Grenade launcher",     [kTechDataModel] = GrenadeLauncher.kModelName,   [kTechDataDamageType] = kGrenadeLauncherDamageType,    [kTechDataCostKey] = kGrenadeLauncherCost},
        { [kTechDataId] = kTechId.NerveGasTech,          [kTechDataCostKey] = kNerveGasTechResearchCost,             [kTechDataResearchTimeKey] = kNerveGasTechResearchTime, [kTechDataDisplayName] = "Research nerve gas", [kTechDataImplemented] = false },
        
        // Marine upgrades
        { [kTechDataId] = kTechId.NerveGas,              [kTechDataDisplayName] = "Nerve gas",  [kTechDataCostKey] = kNerveGasCost, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Allows nerve gas grenades for grenade launcher" },        
        { [kTechDataId] = kTechId.FlamethrowerAlt,       [kTechDataDisplayName] = "Flamethrower alt",  [kTechDataCostKey] = kFlamethrowerAltCost },        
        
        // Armor and upgrades
        { [kTechDataId] = kTechId.Jetpack,               [kTechDataMapName] = "jetpack",                   [kTechDataDisplayName] = "Jetpack", [kTechDataModel] = Jetpack.kModelName, [kTechDataCostKey] = kJetpackCost },
        { [kTechDataId] = kTechId.JetpackTech,           [kTechDataCostKey] = kJetpackTechResearchCost,               [kTechDataResearchTimeKey] = kJetpackTechResearchTime,     [kTechDataDisplayName] = "Jetpack tech" },
        { [kTechDataId] = kTechId.JetpackFuelTech,       [kTechDataCostKey] = kJetpackFuelTechResearchCost,           [kTechDataResearchTimeKey] = kJetpackFuelTechResearchTime,     [kTechDataDisplayName] = "Jetpack fuel tech", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] = "Improves jetpack maneuverability and flight time" },
        { [kTechDataId] = kTechId.JetpackArmorTech,       [kTechDataCostKey] = kJetpackArmorTechResearchCost,         [kTechDataResearchTimeKey] = kJetpackArmorTechResearchTime,     [kTechDataDisplayName] = "Jetpack armor tech", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Grants extra armor to jetpacks" },

        
        { [kTechDataId] = kTechId.Exoskeleton,           [kTechDataMapName] = "Exoskeleton", [kTechDataImplemented] = false,               [kTechDataCostKey] = kExoskeletonCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "Allows Exoskeletons (heavies) to be purchased" },
        { [kTechDataId] = kTechId.ExoskeletonTech,          [kTechDataDisplayName] = "Research exoskeletons", [kTechDataImplemented] = false, [kTechDataCostKey] = kExoskeletonTechResearchCost,  [kTechDataResearchTimeKey] = kExoskeletonTechResearchTime},
        { [kTechDataId] = kTechId.ExoskeletonLockdownTech,  [kTechDataCostKey] = kExoskeletonLockdownTechResearchCost,               [kTechDataResearchTimeKey] = kExoskeletonLockdownTechResearchTime,     [kTechDataDisplayName] = "Exoskeleton lockdown tech", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "Exoskeletons can lock down for extra accuracy and damage" },
        { [kTechDataId] = kTechId.ExoskeletonUpgradeTech,  [kTechDataCostKey] = kExoskeletonUpgradeTechResearchCost,               [kTechDataResearchTimeKey] = kExoskeletonUpgradeTechResearchTime,     [kTechDataDisplayName] = "Exoskeleton upgrade tech", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.Armor1,                [kTechDataCostKey] = kArmor1ResearchCost,                   [kTechDataResearchTimeKey] = kArmor1ResearchTime,     [kTechDataDisplayName] = "Armor #1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = string.format("Gives marines %d extra armor", 1*Marine.kArmorPerUpgradeLevel) },
        { [kTechDataId] = kTechId.Armor2,                [kTechDataCostKey] = kArmor2ResearchCost,                   [kTechDataResearchTimeKey] = kArmor2ResearchTime,     [kTechDataDisplayName] = "Armor #2", [kTechDataHotkey] = Move.X, [kTechDataTooltipInfo] = string.format("Gives marines %d extra armor", 2*Marine.kArmorPerUpgradeLevel) },
        { [kTechDataId] = kTechId.Armor3,                [kTechDataCostKey] = kArmor3ResearchCost,                   [kTechDataResearchTimeKey] = kArmor3ResearchTime,     [kTechDataDisplayName] = "Armor #3", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = string.format("Gives marines %d extra armor", 3*Marine.kArmorPerUpgradeLevel) },

        // Weapons research
        { [kTechDataId] = kTechId.Weapons1,              [kTechDataCostKey] = kWeapons1ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons1ResearchTime,     [kTechDataDisplayName] = "Weapons #1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = string.format("Marine weapons do %d%% extra damage", math.ceil((kWeapons1DamageScalar - 1)*100)) },
        { [kTechDataId] = kTechId.Weapons2,              [kTechDataCostKey] = kWeapons2ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons2ResearchTime,     [kTechDataDisplayName] = "Weapons #2", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = string.format("Marine weapons do %d%% extra damage", math.ceil((kWeapons2DamageScalar - 1)*100)) },
        { [kTechDataId] = kTechId.Weapons3,              [kTechDataCostKey] = kWeapons3ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons3ResearchTime,     [kTechDataDisplayName] = "Weapons #3", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = string.format("Marine weapons do %d%% extra damage", math.ceil((kWeapons3DamageScalar - 1)*100)) },
        { [kTechDataId] = kTechId.RifleUpgradeTech,      [kTechDataCostKey] = kRifleUpgradeTechResearchCost,         [kTechDataResearchTimeKey] = kRifleUpgradeTechResearchTime, [kTechDataDisplayName] = "Undecided rifle upgrade", [kTechDataHotkey] = Move.U, [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ShotgunTech,           [kTechDataCostKey] = kShotgunTechResearchCost,              [kTechDataResearchTimeKey] = kShotgunTechResearchTime, [kTechDataDisplayName] = "Research shotguns", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Allows shotguns to be purchased at Armories" },
        { [kTechDataId] = kTechId.DualMinigunTech,       [kTechDataCostKey] = kDualMinigunTechResearchCost,              [kTechDataResearchTimeKey] = kDualMinigunTechResearchTime, [kTechDataDisplayName] = "Research dual miniguns", [kTechDataImplemented] = false,         }, 
        { [kTechDataId] = kTechId.GrenadeLauncherTech,   [kTechDataCostKey] = kGrenadeLauncherTechResearchCost,      [kTechDataResearchTimeKey] = kGrenadeLauncherTechResearchTime, [kTechDataDisplayName] = "Research grenade launcher", [kTechDataHotkey] = Move.G, [kTechDataTooltipInfo] = "Allows grenade launchers to be purchased at Armories"   },
        
        // ARC abilities
        { [kTechDataId] = kTechId.ARCDeploy,            [kTechDataCostKey] = 0,                                         [kTechDataResearchTimeKey] = kARCDeployTime,                     [kTechDataMenuPriority] = 1, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "Put ARC into firing mode"},
        { [kTechDataId] = kTechId.ARCUndeploy,          [kTechDataCostKey] = 0,                                         [kTechDataResearchTimeKey] = kARCUndeployTime,                     [kTechDataMenuPriority] = 2, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "Put ARC into movement mode"},

        // Alien abilities for damage types
        { [kTechDataId] = kTechId.Bite,                  [kTechDataMapName] = BiteLeap.kMapName,        [kTechDataDamageType] = kBiteDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "Bite"},
        { [kTechDataId] = kTechId.Parasite,              [kTechDataMapName] = Parasite.kMapName,        [kTechDataDamageType] = kParasiteDamageType,    [kTechDataModel] = "", [kTechDataDisplayName] = "Parasite"},
        { [kTechDataId] = kTechId.Spit,                  [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kSpitDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "Spit"},
        { [kTechDataId] = kTechId.Spray,                 [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kHealsprayDamageType,   [kTechDataModel] = "", [kTechDataDisplayName] = "Spray"},
        { [kTechDataId] = kTechId.Spikes,                [kTechDataMapName] = Spikes.kMapName,          [kTechDataDamageType] = kSpikeDamageType,       [kTechDataModel] = "", [kTechDataDisplayName] = "Spikes"},
        { [kTechDataId] = kTechId.SpikesAlt,             [kTechDataMapName] = Spikes.kMapName,          [kTechDataDamageType] = kSpikesAltDamageType,   [kTechDataModel] = "", [kTechDataDisplayName] = "Spikes Alt"},
        { [kTechDataId] = kTechId.Spores,                [kTechDataMapName] = Spores.kMapName,          [kTechDataDamageType] = kSporesDamageType,      [kTechDataModel] = "", [kTechDataDisplayName] = "Spores"},
        { [kTechDataId] = kTechId.HydraSpike,            [kTechDataMapName] = HydraSpike.kMapName,      [kTechDataDamageType] = kHydraSpikeDamageType,  [kTechDataModel] = "", [kTechDataDisplayName] = "Hydra Spike"},
        { [kTechDataId] = kTechId.SwipeBlink,            [kTechDataMapName] = SwipeBlink.kMapName,      [kTechDataDamageType] = kSwipeDamageType,       [kTechDataModel] = "", [kTechDataDisplayName] = "Swipe Blink"},
        { [kTechDataId] = kTechId.StabBlink,             [kTechDataMapName] = StabBlink.kMapName,       [kTechDataDamageType] = kStabDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "Stab Blink"},
        { [kTechDataId] = kTechId.Gore,                  [kTechDataMapName] = Gore.kMapName,            [kTechDataDamageType] = kGoreDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "Gore"},
        
        // Alien structures (spawn hive at 110 units off ground = 2.794 meters)
        { [kTechDataId] = kTechId.Hive,                [kTechDataMapName] = Hive.kLevel1MapName,                   [kTechDataDisplayName] = "Hive", [kTechDataCostKey] = kHiveCost,                     [kTechDataBuildTime] = kHiveBuildTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,                [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,              [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "Allows another player to become Commander and grants access to next tier"},
        { [kTechDataId] = kTechId.HiveMassUpgrade,     [kTechDataDisplayName] = "Upgrade to Hive Mass", [kTechDataCostKey] = kHiveMassCost,               [kTechDataBuildTime] = kHiveBuildTime, [kTechDataResearchTimeKey] = kHiveMassUpgradeTime, [kTechDataModel] = Hive.kModelName,                  [kTechDataHotkey] = Move.U, [kTechDataMaxHealth] = kHiveMassHealth,                    [kStructureAttachClass] = "TechPoint",         [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataUpgradeTech] = kTechId.Hive, [kTechDataDisplayName] = "Gives access to Tier 2 research"},
        { [kTechDataId] = kTechId.HiveMass,            [kTechDataMapName] = HiveL2.kMapName,                   [kTechDataDisplayName] = "Hive Mass",  [kTechDataModel] = Hive.kModelName, [kTechDataMaxHealth] = kHiveMassHealth,   [kTechDataMaxArmor] = kHiveMassArmor,  [kTechDataMaxEnergy] = kHiveMassMaxEnergy, [kTechDataSpawnHeightOffset] = 2.494, [kTechDataUpgradeTech] = kTechId.Hive, [kTechDataPointValue] = kHiveMassPointValue},
        { [kTechDataId] = kTechId.HiveColonyUpgrade,   [kTechDataDisplayName] = "Upgrade to Hive Colony", [kTechDataCostKey] = kHiveColonyUpgradeCost,  [kTechDataResearchTimeKey] = kHiveColonyUpgradeTime, [kTechDataModel] = Hive.kModelName,                  [kTechDataMaxHealth] = kHiveColonyHealth,                    [kStructureAttachClass] = "TechPoint",  [kTechDataUpgradeTech] = kTechId.HiveMass},
        { [kTechDataId] = kTechId.HiveColony,          [kTechDataMapName] = HiveL3.kMapName,                   [kTechDataDisplayName] = "Hive Colony", [kTechDataModel] = Hive.kModelName, [kTechDataMaxHealth] = kHiveColonyHealth, [kTechDataMaxArmor] = kHiveColonyArmor, [kTechDataMaxEnergy] = kHiveColonyMaxEnergy, [kTechDataSpawnHeightOffset] = 2.494, [kTechDataUpgradeTech] = kTechId.HiveMass, [kTechDataPointValue] = kHiveColonyPointValue},
        { [kTechDataId] = kTechId.TwoHives,            [kTechDataDisplayName] = "Two Hives" },        
        { [kTechDataId] = kTechId.ThreeHives,          [kTechDataDisplayName] = "Three Hives" },        
        
        // Drifter and tech
        { [kTechDataId] = kTechId.Drifter,               [kTechDataMapName] = Drifter.kMapName,                      [kTechDataDisplayName] = "Drifter",       [kTechDataCostKey] = kDrifterCost,              [kTechDataResearchTimeKey] = kDrifterBuildTime,     [kTechDataHotkey] = Move.D, [kTechDataMaxHealth] = Drifter.kHealth, [kTechDataMaxArmor] = kDrifterArmor, [kTechDataMaxArmor] = Drifter.kArmor, [kTechDataModel] = Drifter.kModelName, [kTechDataDamageType] = kDrifterAttackDamageType, [kTechDataPointValue] = kDrifterPointValue, [kTechDataTooltipInfo] = "Flying creature that morphs into structures"},   
        { [kTechDataId] = kTechId.DrifterFlareTech,      [kTechDataDisplayName] = "Research drifter flare",          [kTechDataCostKey] = kDrifterFlareTechResearchCost,                                           [kTechDataResearchTimeKey] = kDrifterFlareTechResearchTime},
        { [kTechDataId] = kTechId.DrifterFlare,          [kTechDataDisplayName] = "Flare", [kTechDataHotkey] = Move.F,                         [kTechDataCostKey] = 0, [kTechDataTooltipInfo] = "Detonate in burst of light, blinding enemies"},
        { [kTechDataId] = kTechId.DrifterParasiteTech,   [kTechDataDisplayName] = "Parasite research", [kTechDataHotkey] = Move.A, [kTechDataImplemented] = false,                               [kTechDataCostKey] = 10, [kTechDataTooltipInfo] = "Grants parasite abilities to Drifters"},        
        { [kTechDataId] = kTechId.DrifterParasite,       [kTechDataDisplayName] = "Parasite", [kTechDataHotkey] = Move.P, [kTechDataImplemented] = false,                               [kTechDataCostKey] = 0, [kTechDataTooltipInfo] = "Shoot parasite into target, giving line of sight"},        
        
        // Alien buildables
        { [kTechDataId] = kTechId.Egg,                   [kTechDataMapName] = Egg.kMapName,                         [kTechDataDisplayName] = "Egg",       [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataBuildTime] = 1, [kTechDataCostKey] = 1, [kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents) }, 
        { [kTechDataId] = kTechId.Cocoon,                [kTechDataMapName] = Cocoon.kMapName,                         [kTechDataDisplayName] = "Cocoon", [kTechDataImplemented] = false,       [kTechDataMaxHealth] = Cocoon.kHealth, [kTechDataMaxArmor] = Cocoon.kArmor, [kTechDataModel] = Cocoon.kModelName, [kTechDataBuildTime] = 1, [kTechDataCostKey] = 1}, 
        { [kTechDataId] = kTechId.Harvester,             [kTechDataMapName] = Harvester.kMapName,                    [kTechDataDisplayName] = "Harvester",  [kTechDataCostKey] = kHarvesterCost,            [kTechDataBuildTime] = kHarvesterBuildTime, [kTechDataHotkey] = Move.H, [kTechDataMaxHealth] = kHarvesterHealth, [kTechDataMaxArmor] = kHarvesterArmor, [kTechDataModel] = Harvester.kModelName,           [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kHarvesterPointValue, [kTechDataTooltipInfo] = string.format("Gives 1 carbon to team and 1 plasma to each player every %d seconds", kResourceTowerResourceInterval) },
        { [kTechDataId] = kTechId.HarvesterUpgrade,      [kTechDataCostKey] = kResourceUpgradeResearchCost,          [kTechDataResearchTimeKey] = kResourceUpgradeResearchTime, [kTechDataDisplayName] = string.format("Upgrade plasma production by %d%%", math.floor(kResourceUpgradeAmount*100)), [kTechDataHotkey] = Move.U },

        // Upgrade structures and research
        { [kTechDataId] = kTechId.Crag,                  [kTechDataMapName] = Crag.kMapName,                         [kTechDataDisplayName] = "Crag",  [kTechDataCostKey] = kCragCost,     [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kCragBuildTime, [kTechDataModel] = Crag.kModelName,           [kTechDataMaxHealth] = kCragHealth, [kTechDataMaxArmor] = kCragArmor,   [kTechDataInitialEnergy] = kCragInitialEnergy,      [kTechDataMaxEnergy] = kCragMaxEnergy, [kTechDataPointValue] = kCragPointValue, [kStructureVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "Heals friendly units and allows defensive upgrades (automatic)", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeCrag,           [kTechDataMapName] = Crag.kMapName,                         [kTechDataDisplayName] = "Upgrade to Mature Crag",  [kTechDataCostKey] = kMatureCragCost, [kTechDataBuildTime] = kMatureCragBuildTime, [kTechDataHotkey] = Move.U, [kTechDataModel] = Crag.kModelName,  [kTechDataMaxHealth] = kMatureCragHealth, [kTechDataMaxArmor] = kMatureCragArmor,[kTechDataTooltipInfo] = "Increase Crag health and gain Babbler ability", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureCrag,            [kTechDataMapName] = MatureCrag.kMapName,                   [kTechDataDisplayName] = "Mature Crag",  [kTechDataModel] = Crag.kModelName,   [kTechDataCostKey] = kMatureCragCost, [kTechDataBuildTime] = kMatureCragBuildTime,     [kTechDataMaxHealth] = kMatureCragHealth,    [kTechDataInitialEnergy] = kCragInitialEnergy,      [kTechDataMaxEnergy] = kMatureCragMaxEnergy, [kTechDataPointValue] = kMatureCragPointValue, [kTechDataTooltipInfo] = "Defensive healing structure with babbler capabilities", [kTechDataGrows] = true},
        
         
        { [kTechDataId] = kTechId.Whip,                  [kTechDataMapName] = Whip.kMapName,                         [kTechDataDisplayName] = "Whip",  [kTechDataCostKey] = kWhipCost,    [kTechDataHotkey] = Move.W,        [kTechDataBuildTime] = kWhipBuildTime, [kTechDataModel] = Whip.kModelName,           [kTechDataMaxHealth] = kWhipHealth, [kTechDataMaxArmor] = kWhipArmor,   [kTechDataDamageType] = kDamageType.Light, [kTechDataInitialEnergy] = kWhipInitialEnergy,      [kTechDataMaxEnergy] = kWhipMaxEnergy, [kStructureVisualRange] = Whip.kRange, [kTechDataPointValue] = kWhipPointValue, [kTechDataTooltipInfo] = "Attacks nearby enemies and allows offensive upgrades", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeWhip,           [kTechDataMapName] = Whip.kMapName,                         [kTechDataDisplayName] = "Upgrade to Mature Whip",  [kTechDataCostKey] = kMatureWhipCost, [kTechDataBuildTime] = kMatureWhipBuildTime, [kTechDataHotkey] = Move.U, [kTechDataModel] = Whip.kModelName, [kTechDataTooltipInfo] = "Increase Whip health and gain Bombard ability", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureWhip,            [kTechDataMapName] = MatureWhip.kMapName,                   [kTechDataDisplayName] = "Mature Whip",  [kTechDataModel] = Whip.kModelName, [kTechDataCostKey] = kMatureWhipCost, [kTechDataBuildTime] = kMatureWhipBuildTime,       [kTechDataMaxHealth] = kMatureWhipHealth,  [kTechDataMaxArmor] = kMatureWhipArmor,  [kTechDataInitialEnergy] = kMatureWhipInitialEnergy,      [kTechDataMaxEnergy] = kMatureWhipMaxEnergy, [kTechDataPointValue] = kMatureWhipPointValue, [kStructureVisualRange] = Whip.kRange, [kTechDataTooltipInfo] = "Offensive structure with Bombard ability", [kTechDataGrows] = true },
        
        { [kTechDataId] = kTechId.Shift,                 [kTechDataMapName] = Shift.kMapName,                        [kTechDataDisplayName] = "Shift", [kTechDataImplemented] = false,   [kTechDataCostKey] = kShiftCost,    [kTechDataHotkey] = Move.S,        [kTechDataBuildTime] = kShiftBuildTime, [kTechDataModel] = Shift.kModelName,           [kTechDataMaxHealth] = kShiftHealth,  [kTechDataMaxArmor] = kShiftArmor,  [kTechDataInitialEnergy] = kShiftInitialEnergy,      [kTechDataMaxEnergy] = kShiftMaxEnergy, [kTechDataPointValue] = kShiftPointValue, [kStructureVisualRange] = kEnergizeRange, [kTechDataTooltipInfo] = "Speeds energy recovery for units and shift units around map", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.UpgradeShift,          [kTechDataMapName] = Shift.kMapName,                        [kTechDataDisplayName] = "Upgrade to Mature Shift", [kTechDataImplemented] = false, [kTechDataCostKey] = kMatureShiftCost, [kTechDataBuildTime] = kMatureShiftBuildTime, [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "Increase Shift health and gain Echo ability", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureShift,           [kTechDataMapName] = MatureShift.kMapName,                  [kTechDataDisplayName] = "Mature Shift", [kTechDataImplemented] = false, [kTechDataCostKey] = kMatureShiftCost, [kTechDataModel] = Shift.kModelName,     [kTechDataBuildTime] = kMatureShiftBuildTime,      [kTechDataMaxHealth] = kMatureShiftHealth, [kTechDataMaxArmor] = kMatureShiftArmor,   [kTechDataMaxEnergy] = kMatureShiftMaxEnergy,      [kTechDataMaxEnergy] = kMatureShiftMaxEnergy, [kTechDataPointValue] = kMatureShiftPointValue, [kTechDataTooltipInfo] = "Shift with Echo ability", [kTechDataGrows] = true },
        
        { [kTechDataId] = kTechId.Shade,                 [kTechDataMapName] = Shade.kMapName,                        [kTechDataDisplayName] = "Shade",  [kTechDataCostKey] = kShadeCost,           [kTechDataImplemented] = false, [kTechDataBuildTime] = kShadeBuildTime, [kTechDataHotkey] = Move.D, [kTechDataModel] = Shade.kModelName,           [kTechDataMaxHealth] = kShadeHealth, [kTechDataMaxArmor] = kShadeArmor,   [kTechDataInitialEnergy] = kShadeInitialEnergy,      [kTechDataMaxEnergy] = kShadeMaxEnergy, [kTechDataPointValue] = kShadePointValue, [kStructureVisualRange] = Shade.kCloakRadius, [kTechDataMaxExtents] = Vector(1, 1.3, .4), [kTechDataTooltipInfo] = "Cloaks nearby units and allows deception upgrades", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.UpgradeShade,          [kTechDataMapName] = Shade.kMapName,                        [kTechDataDisplayName] = "Upgrade to Mature Shade",  [kTechDataCostKey] = kMatureShadeCost, [kTechDataImplemented] = false, [kTechDataBuildTime] = kMatureShadeBuildTime, [kTechDataModel] = Shade.kModelName, [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "Increase Shade health and grant Phantasm ability", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.MatureShade,           [kTechDataMapName] = MatureShade.kMapName,                  [kTechDataDisplayName] = "Mature Shade",  [kTechDataModel] = Shade.kModelName,  [kTechDataCostKey] = kMatureShadeCost, [kTechDataImplemented] = false,   [kTechDataBuildTime] = kMatureShadeBuildTime,      [kTechDataMaxHealth] = kMatureShadeHealth,  [kTechDataMaxArmor] = kMatureShadeArmor,  [kTechDataInitialEnergy] = kMatureShadeInitialEnergy,      [kTechDataMaxEnergy] = kMatureShadeMaxEnergy, [kTechDataPointValue] = kMatureShadePointValue, [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "Shade with Phantasm ability", [kTechDataGrows] = true },
        
        { [kTechDataId] = kTechId.Hydra,                 [kTechDataMapName] = Hydra.kMapName,                        [kTechDataDisplayName] = "Hydra",           [kTechDataCostKey] = kHydraCost,       [kTechDataBuildTime] = kHydraBuildTime, [kTechDataMaxHealth] = kHydraHealth, [kTechDataMaxArmor] = kHydraArmor, [kTechDataModel] = Hydra.kModelName, [kStructureVisualRange] = Hydra.kRange, [kTechDataPointValue] = kHydraPointValue, [kTechDataGrows] = true},
        
        // Alien structure abilities and their energy costs
        { [kTechDataId] = kTechId.CragHeal,              [kTechDataDisplayName] = "Heal",    [kTechDataHotkey] = Move.H,                       [kTechDataCostKey] = kCragHealCost, [kTechDataTooltipInfo] = string.format("Heals players and structures (%d per %s, max %d targets)", Crag.kHealAmount, Pluralize(Crag.kHealInterval, "second"), Crag.kMaxTargets) },
        { [kTechDataId] = kTechId.CragUmbra,             [kTechDataDisplayName] = "Umbra",    [kTechDataHotkey] = Move.M,                      [kTechDataCostKey] = kCragUmbraCost, [kStructureVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = string.format("Creates protective cloud for units inside (blocks 1 out of %d bullets)", Crag.kUmbraBulletChance)},
        { [kTechDataId] = kTechId.CragBabblers,          [kTechDataDisplayName] = "Babblers",   [kTechDataHotkey] = Move.B,                    [kTechDataCostKey] = kCragBabblersCost },

        { [kTechDataId] = kTechId.WhipFury,              [kTechDataDisplayName] = "Fury",       [kTechDataHotkey] = Move.F,                   [kTechDataCostKey] = kWhipFuryCost },
        { [kTechDataId] = kTechId.WhipBombard,           [kTechDataDisplayName] = "Lob",         [kTechDataHotkey] = Move.L,                       [kTechDataCostKey] = kWhipBombardCost },

        { [kTechDataId] = kTechId.ShiftEcho,             [kTechDataDisplayName] = "Echo",        [kTechDataHotkey] = Move.E,                    [kTechDataCostKey] = kShiftEchoCost, [kTechDataTooltipInfo] = "Reposition structure elsewhere"},
        { [kTechDataId] = kTechId.ShiftRecall,           [kTechDataDisplayName] = "Recall",      [kTechDataTooltipInfo] = "Aliens can use the shift to teleport to the nearest hive"},
        { [kTechDataId] = kTechId.ShiftEnergize,         [kTechDataDisplayName] = "Energize",    [kTechDataCostKey] = kShiftEnergizeCost},

        { [kTechDataId] = kTechId.ShadeDisorient,         [kTechDataDisplayName] = "Disorient",      [kTechDataHotkey] = Move.D,  [kTechDataTooltipInfo] = "Enemy players and commander can't see or hear well in range (Passive)" },        
        { [kTechDataId] = kTechId.ShadeCloak,             [kTechDataDisplayName] = "Cloak",      [kTechDataHotkey] = Move.C,                    [kTechDataCostKey] = kShadeCloakCost },        
        { [kTechDataId] = kTechId.ShadePhantasmMenu,      [kTechDataDisplayName] = "Phantasm",     [kTechDataHotkey] = Move.P },
        //{ [kTechDataId] = kTechId.ShadePhantasmFade,      [kTechDataDisplayName] = "Phantasm Fade",  [kTechDataModel] = Fade.kModelName,  [kTechDataMapName] = FadePhantasm.kMapName,  [kTechDataHotkey] = Move.F,                  [kTechDataCostKey] = kShadePhantasmFadeEnergyCost },
        { [kTechDataId] = kTechId.ShadePhantasmOnos,      [kTechDataDisplayName] = "Phantasm Onos",  [kTechDataModel] = Onos.kModelName,  [kTechDataMapName] = OnosPhantasm.kMapName,  [kTechDataHotkey] = Move.O,                  [kTechDataCostKey] = kShadePhantasmOnosEnergyCost },
        //{ [kTechDataId] = kTechId.ShadePhantasmHive,      [kTechDataDisplayName] = "Phantasm Hive",  [kTechDataModel] = Hive.kModelName,  [kTechDataMapName] = HivePhantasm.kMapName,  [kTechDataHotkey] = Move.H,                  [kTechDataCostKey] = kShadePhantasmHiveEnergyCost,  [kStructureAttachClass] = "TechPoint", },

        // Alien lifeforms
        { [kTechDataId] = kTechId.Skulk,                 [kTechDataMapName] = Skulk.kMapName, [kTechDataGestateName] = Skulk.kMapName,                      [kTechDataGestateTime] = kSkulkGestateTime, [kTechDataDisplayName] = "Skulk",           [kTechDataModel] = Skulk.kModelName, [kTechDataCostKey] = kSkulkCost, [kTechDataMaxHealth] = Skulk.kHealth, [kTechDataMaxArmor] = Skulk.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents), [kTechDataPointValue] = kSkulkPointValue},
        { [kTechDataId] = kTechId.Gorge,                 [kTechDataMapName] = Gorge.kMapName, [kTechDataGestateName] = Gorge.kMapName,                      [kTechDataGestateTime] = kGorgeGestateTime, [kTechDataDisplayName] = "Gorge",           [kTechDataModel] = Gorge.kModelName,[kTechDataCostKey] = kGorgeCost, [kTechDataMaxHealth] = Gorge.kHealth, [kTechDataMaxArmor] = Gorge.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Gorge.kXZExtents, Gorge.kYExtents, Gorge.kXZExtents), [kTechDataPointValue] = kGorgePointValue},
        { [kTechDataId] = kTechId.Lerk,                  [kTechDataMapName] = Lerk.kMapName, [kTechDataGestateName] = Lerk.kMapName,                       [kTechDataGestateTime] = kLerkGestateTime, [kTechDataDisplayName] = "Lerk",            [kTechDataModel] = Lerk.kModelName,[kTechDataCostKey] = kLerkCost, [kTechDataMaxHealth] = Lerk.kHealth, [kTechDataMaxArmor] = Lerk.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Lerk.XZExtents, Lerk.YExtents, Lerk.XZExtents), [kTechDataPointValue] = kLerkPointValue},
        { [kTechDataId] = kTechId.Fade,                  [kTechDataMapName] = Fade.kMapName, [kTechDataGestateName] = Fade.kMapName,                       [kTechDataGestateTime] = kFadeGestateTime, [kTechDataDisplayName] = "Fade",            [kTechDataModel] = Fade.kModelName,[kTechDataCostKey] = kFadeCost, [kTechDataMaxHealth] = Fade.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxArmor] = Fade.kArmor, [kTechDataMaxExtents] = Vector(Fade.XZExtents, Fade.YExtents, Fade.XZExtents), [kTechDataPointValue] = kFadePointValue},        
        { [kTechDataId] = kTechId.Onos,                  [kTechDataMapName] = Onos.kMapName, [kTechDataGestateName] = Onos.kMapName,                       [kTechDataGestateTime] = kOnosGestateTime, [kTechDataDisplayName] = "Onos", [kTechDataImplemented] = false,            [kTechDataModel] = Onos.kModelName,[kTechDataCostKey] = kOnosCost, [kTechDataMaxHealth] = Onos.kHealth, [kTechDataEngagementDistance] = kOnosEngagementDistance, [kTechDataMaxArmor] = Onos.kArmor, [kTechDataMaxExtents] = Vector(Onos.XExtents, Onos.YExtents, Onos.ZExtents), [kTechDataPointValue] = kOnosPointValue},
        { [kTechDataId] = kTechId.Embryo,                [kTechDataMapName] = Embryo.kMapName, [kTechDataGestateName] = Embryo.kMapName,                     [kTechDataDisplayName] = "Embryo", [kTechDataModel] = Embryo.kModelName, [kTechDataMaxExtents] = Vector(Embryo.kXExtents, Embryo.kYExtents, Embryo.kZExtents)},
        { [kTechDataId] = kTechId.AlienCommander,        [kTechDataMapName] = AlienCommander.kMapName, [kTechDataDisplayName] = "Alien Commander", [kTechDataModel] = ""},
        
        // General alien upgrades
        { [kTechDataId] = kTechId.Melee1Tech,                  [kTechDataDisplayName] = "Melee #1", [kTechDataHotkey] = Move.M },        
        { [kTechDataId] = kTechId.Melee2Tech,                  [kTechDataDisplayName] = "Melee #2", [kTechDataHotkey] = Move.M },        
        { [kTechDataId] = kTechId.Melee3Tech,                  [kTechDataDisplayName] = "Melee #3", [kTechDataHotkey] = Move.M },        
        { [kTechDataId] = kTechId.Armor1Tech,                  [kTechDataDisplayName] = "Armor #1", [kTechDataHotkey] = Move.A },        
        { [kTechDataId] = kTechId.Armor2Tech,                  [kTechDataDisplayName] = "Armor #2", [kTechDataHotkey] = Move.A },        
        { [kTechDataId] = kTechId.Armor3Tech,                  [kTechDataDisplayName] = "Armor #3", [kTechDataHotkey] = Move.A },

        // Lifeform research
        { [kTechDataId] = kTechId.BloodThirstTech,              [kTechDataDisplayName] = "Bloodthirst", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBloodThirstResearchCost, [kTechDataResearchTimeKey] = kBloodThirstResearchTime },        
        { [kTechDataId] = kTechId.LeapTech,                     [kTechDataDisplayName] = "Running leap", [kTechDataCostKey] = kLeapResearchCost, [kTechDataResearchTimeKey] = kLeapResearchTime },                
        { [kTechDataId] = kTechId.FeedTech,                     [kTechDataDisplayName] = "Feed", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeedResearchCost, [kTechDataResearchTimeKey] = kFeedResearchTime },                
        { [kTechDataId] = kTechId.CarapaceTech,                 [kTechDataDisplayName] = "Carapace", [kTechDataImplemented] = false,  [kTechDataCostKey] = kCarapaceResearchCost, [kTechDataResearchTimeKey] = kCarapaceResearchTime },                
        
        { [kTechDataId] = kTechId.CorpulenceTech,               [kTechDataDisplayName] = "Corpulence", [kTechDataImplemented] = false,  [kTechDataCostKey] = kCorpulenceResearchCost, [kTechDataResearchTimeKey] = kCorpulenceResearchTime },        
        { [kTechDataId] = kTechId.BacteriaTech,                 [kTechDataDisplayName] = "Bacteria", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBacteriaResearchCost, [kTechDataResearchTimeKey] = kBacteriaResearchTime },                

        { [kTechDataId] = kTechId.AdrenalineTech,                 [kTechDataDisplayName] = "Adrenaline", [kTechDataImplemented] = false,  [kTechDataCostKey] = kAdrenalineResearchCost, [kTechDataResearchTimeKey] = kAdrenalineResearchTime },                
        { [kTechDataId] = kTechId.PiercingTech,                 [kTechDataDisplayName] = "Piercing", [kTechDataImplemented] = false,  [kTechDataCostKey] = kPiercingResearchCost, [kTechDataResearchTimeKey] = kPiercingResearchTime },        
        
        { [kTechDataId] = kTechId.FeintTech,                 [kTechDataDisplayName] = "Feint", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeintResearchCost, [kTechDataResearchTimeKey] = kFeintResearchTime },                
        { [kTechDataId] = kTechId.SapTech,                 [kTechDataDisplayName] = "Sap", [kTechDataImplemented] = false,  [kTechDataCostKey] = kSapResearchCost, [kTechDataResearchTimeKey] = kSapResearchTime },                
        
        { [kTechDataId] = kTechId.BoneShieldTech,                 [kTechDataDisplayName] = "BoneShield", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBoneShieldResearchCost, [kTechDataResearchTimeKey] = kBoneShieldResearchTime },                
        { [kTechDataId] = kTechId.StompTech,                 [kTechDataDisplayName] = "Stomp", [kTechDataImplemented] = false,  [kTechDataCostKey] = kStompResearchCost, [kTechDataResearchTimeKey] = kStompResearchTime },                
        
        // Lifeform purchases
        { [kTechDataId] = kTechId.Carapace,                  [kTechDataDisplayName] = "Carapace",  [kTechDataCostKey] = kCarapaceCost },        
        { [kTechDataId] = kTechId.Leap,                  [kTechDataDisplayName] = "Running leap", [kTechDataCostKey] = kLeapCost },        
        { [kTechDataId] = kTechId.Feed,                  [kTechDataDisplayName] = "Feed", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeedCost },        
        { [kTechDataId] = kTechId.BloodThirst,                  [kTechDataDisplayName] = "Bloodthirst", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBloodThirstCost },        
        { [kTechDataId] = kTechId.Corpulence,                  [kTechDataDisplayName] = "Corpulence", [kTechDataImplemented] = false,  [kTechDataCostKey] = kCorpulenceCost },        
        { [kTechDataId] = kTechId.Bacteria,                  [kTechDataDisplayName] = "Bacteria", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBacteriaCost },        
        { [kTechDataId] = kTechId.HydraAbility,                  [kTechDataDisplayName] = "Build Hydra",  [kTechDataCostKey] = kHydraAbilityCost /* cost for purchasing ability */ },        
        { [kTechDataId] = kTechId.HarvesterAbility,                  [kTechDataDisplayName] = "Build Harvester",  [kTechDataCostKey] = kHarvesterAbilityCost /* cost for purchasing ability */ },        
        { [kTechDataId] = kTechId.Piercing,                  [kTechDataDisplayName] = "Piercing ", [kTechDataTooltipInfo] = string.format("Increases spike damage by %d%%", math.floor((kPiercingDamageScalar - 1)*100)), [kTechDataCostKey] = kPiercingCost },        
        { [kTechDataId] = kTechId.Adrenaline,                  [kTechDataDisplayName] = "Adrenaline", [kTechDataImplemented] = false,  [kTechDataCostKey] = kAdrenalineCost },        
        { [kTechDataId] = kTechId.Feint,                  [kTechDataDisplayName] = "Feint", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeintCost },        
        { [kTechDataId] = kTechId.Sap,                  [kTechDataDisplayName] = "Sap", [kTechDataImplemented] = false,  [kTechDataCostKey] = kSapCost },        
        { [kTechDataId] = kTechId.Gore,                  [kTechDataDisplayName] = "Gore", [kTechDataDamageType] = kDamageType.Door, [kTechDataModel] = Onos.kViewModelName },        
        { [kTechDataId] = kTechId.Stomp,                  [kTechDataDisplayName] = "Stomp", [kTechDataImplemented] = false,  [kTechDataCostKey] = kStompCost },        
        { [kTechDataId] = kTechId.BoneShield,                  [kTechDataDisplayName] = "Bone shield", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBoneShieldCost },        
        
        // Alien markers
        { [kTechDataId] = kTechId.ThreatMarker,                  [kTechDataDisplayName] = "Mark threat", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.LargeThreatMarker,             [kTechDataDisplayName] = "Mark large threat", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.NeedHealingMarker,             [kTechDataDisplayName] = "Need healing here", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.WeakMarker,                    [kTechDataDisplayName] = "Weak here", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.ExpandingMarker,               [kTechDataDisplayName] = "Expanding here", [kTechDataImplemented] = false},
        
        // Commander abilities
        { [kTechDataId] = kTechId.Grow,             [kTechDataDisplayName] = "Grow infestation", [kTechDataCostKey] = kHiveGrowCost, [kTechDataImplemented] = false, [kTechDataTooltipInfo] = "Extend infestation towards point"},        
        { [kTechDataId] = kTechId.MetabolizeTech,   [kTechDataDisplayName] = "Research Metabolize", [kTechDataCostKey] = kMetabolizeTechCost, [kTechDataImplemented] = false, [kTechDataResearchTimeKey] = kMetabolizeTechResearchTime, [kTechDataTooltipInfo] = "Temporarily boosts player movement speed or research speed"},
        { [kTechDataId] = kTechId.Metabolize,       [kTechDataDisplayName] = "Metabolize", [kTechDataCostKey] = kHiveMetabolizeCost, [kTechDataTooltipInfo] = "Temporarily boosts gestation or research speed" },     
        
        // Alerts
        { [kTechDataId] = kTechId.MarineAlertSentryFiring,                      [kTechDataAlertSound] = MarineCommander.kSentryFiringSoundName,             [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Sentry firing"},
        { [kTechDataId] = kTechId.MarineAlertSentryUnderAttack,                 [kTechDataAlertSound] = MarineCommander.kSentryTakingDamageSoundName,       [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Sentry taking damage"},
        { [kTechDataId] = kTechId.MarineAlertSoldierLost,                       [kTechDataAlertSound] = MarineCommander.kSoldierLostSoundName,              [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Soldier lost"},
        { [kTechDataId] = kTechId.MarineAlertNeedAmmo,                          [kTechDataAlertSound] = MarineCommander.kSoldierNeedsAmmoSoundName,         [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "Soldier needs ammo"},
        { [kTechDataId] = kTechId.MarineAlertNeedMedpack,                       [kTechDataAlertSound] = MarineCommander.kSoldierNeedsHealthSoundName,       [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "Soldier needs medpack"},
        { [kTechDataId] = kTechId.MarineAlertNeedOrder,                         [kTechDataAlertSound] = MarineCommander.kSoldierNeedsOrderSoundName,        [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "Soldier needs order"},
        { [kTechDataId] = kTechId.MarineAlertUpgradeComplete,                   [kTechDataAlertSound] = MarineCommander.kUpgradeCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Upgrade complete"},
        { [kTechDataId] = kTechId.MarineAlertResearchComplete,                  [kTechDataAlertSound] = MarineCommander.kResearchCompleteSoundName,         [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Research complete"},
        { [kTechDataId] = kTechId.MarineAlertNotEnoughResources,                [kTechDataAlertSound] = Player.kNotEnoughResourcesSound,                    [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Not enough resources"},
        { [kTechDataId] = kTechId.MarineAlertOrderComplete,                     [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,        [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Objective complete"},        
        { [kTechDataId] = kTechId.MarineAlertStructureUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Structure under attack"},
        { [kTechDataId] = kTechId.MarineAlertExtractorUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Extractor under attack"},    
        { [kTechDataId] = kTechId.MarineAlertConstructionComplete,              [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,        [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Construction complete"},        
        { [kTechDataId] = kTechId.MarineAlertCommandStationUnderAttack,         [kTechDataAlertSound] = CommandStation.kUnderAttackSound,                   [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Command Station under attack",  [kTechDataAlertTeam] = true},        
                
        { [kTechDataId] = kTechId.AlienAlertHiveUnderAttack,                    [kTechDataAlertSound] = Hive.kUnderAttackSound,                             [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Hive under attack",       [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.AlienAlertHiveDying,                          [kTechDataAlertSound] = Hive.kDyingSound,                                   [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "Hive is dying",      [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.AlienAlertHiveComplete,                       [kTechDataAlertSound] = Hive.kCompleteSound,                                [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Hive construction complete",      [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.AlienAlertUpgradeComplete,                    [kTechDataAlertSound] = AlienCommander.kUpgradeCompleteSoundName,           [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Upgrade complete"},
        { [kTechDataId] = kTechId.AlienAlertResearchComplete,                   [kTechDataAlertSound] = AlienCommander.kResearchCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Research complete"},
        { [kTechDataId] = kTechId.AlienAlertGorgeBuiltHarvester,                [kTechDataAlertType] = kAlertType.Info,                                     [kTechDataAlertText] = "Gorge building Harvester"},
        { [kTechDataId] = kTechId.AlienAlertNotEnoughResources,                 [kTechDataAlertSound] = Alien.kNotEnoughResourcesSound,                     [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "Not enough resources"},

    }

    return techData

end

kTechData = nil

function LookupTechId(fieldData, fieldName)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if fieldName == nil or fieldName == "" then
    
        Print("LookupTechId(%s, %s) called improperly.", tostring(fieldData), tostring(fieldName))
        return kTechId.None
        
    end

    for index,record in ipairs(kTechData) do 
    
        local currentField = record[fieldName]
        
        if(fieldData == currentField) then
        
            return record[kTechDataId]
            
        end

    end
    
    //Print("LookupTechId(%s, %s) returned kTechId.None", fieldData, fieldName)
    
    return kTechId.None

end

// Table of fieldName tables. Each fieldName table is indexed by techId and returns data.
local cachedTechData = {}

function ClearCachedTechData()
    cachedTechData = {}
end

// Returns true or false. If true, return output in "data"
function GetCachedTechData(techId, fieldName)
    
    local entry = cachedTechData[fieldName]
    
    if entry ~= nil then
    
        return entry[techId]
        
    end
        
    return nil
    
end

function SetCachedTechData(techId, fieldName, data)

    local inserted = false
    
    local entry = cachedTechData[fieldName]
    
    if entry == nil then
    
        cachedTechData[fieldName] = {}
        entry = cachedTechData[fieldName]
        
    end
    
    if entry[techId] == nil then
    
        entry[techId] = data
        inserted = true
        
    end
    
    return inserted
    
end

// Call with techId and fieldname (returns nil if field not found). Pass optional
// third parameter to use as default if not found.
function LookupTechData(techId, fieldName, default)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if techId == nil or techId == 0 or fieldName == nil or fieldName == "" then
    
        Print("LookupTechData(%s, %s, %s) called improperly.", EnumToString(kTechId, techId), tostring(fieldName), tostring(default))
        return kTechId.None
        
    end

    local data = GetCachedTechData(techId, fieldName)
    
    if data == nil then
    
        for index,record in ipairs(kTechData) do 
        
            local currentid = record[kTechDataId]

            if(techId == currentid and record[fieldName] ~= nil) then
            
                data = record[fieldName]
                
                break
                
            end
            
        end        
        
        if data == nil then
            data = default
        end
        
        if not SetCachedTechData(techId, fieldName, data) then
            //Print("Didn't insert anything when calling SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        else
            //Print("Inserted new field with SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        end
    
    end
    
    return data

end

// Returns true if specified class name is used to attach objects to
function GetIsAttachment(className)
    return (className == "TechPoint") or (className == "ResourcePoint")
end