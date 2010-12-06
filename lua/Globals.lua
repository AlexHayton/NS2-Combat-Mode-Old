// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Globals.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")

// Team types - corresponds with teamNumber in editor_setup.xml
kNeutralTeamType = 0
kMarineTeamType = 1
kAlienTeamType = 2
kRandomTeamType = 3

// Team colors 
kMarineTeamColor = 0x4DB1FF
kAlienTeamColor = 0xFFCA3A
kNeutralTeamColor = 0xEEEEEE
kChatPrefixTextColor = 0xFFFFFF
kChatTextColor = 0xDDDDDD
kChatTypeTextColor = 0xDD4444
kFriendlyNeutralColor = 0xFFFFFF
kEnemyColor = 0xFF0000

// Team numbers and indices
kTeamInvalid = -1
kTeamReadyRoom = 0
kTeam1Index = 1
kTeam2Index = 2
kSpectatorIndex = 3

// Marines vs. Aliens
kTeam1Type = kMarineTeamType
kTeam2Type = kAlienTeamType

// Used for playing team and scoreboard
kTeam1Name = "Frontiersmen"
kTeam2Name = "Kharaa"
kSpectatorTeamName = "Ready room"
kDefaultPlayerName = "NsPlayer"

kDefaultWaypointGroup = "GroundWaypoints"
kAirWaypointsGroup = "AirWaypoints"

kMaxResources = 999

// Max number of entities allowed in radius. Don't allow creating any more entities if this number is rearched.
// Don't include players in count.
kMaxEntitiesInRadius = 25
kMaxEntityRadius = 25

// Max player name
kMaxNameLength = 20
kMaxScore = 9999
kMaxKills = 254
kMaxDeaths = 254
kMaxPing = 999

// Surface list. Add more materials here to precache ricochets, bashes, footsteps, etc
// Used with PrecacheMultipleAssets
kSurfaceList = {"door", "electronic", "metal", "organic", "rock", "thin_metal" }

kMainMenuFlash = "ui/main_menu.swf"

kMaxAlienAbilities = 4

// Weapon slots (marine only). Alien weapons use just regular numbers.
kPrimaryWeaponSlot = 1
kSecondaryWeaponSlot = 2
kTertiaryWeaponSlot = 3

// How long to display weapon picker after selecting weapons
kDisplayWeaponTime = 1.5

// If player bought Special Edition
kSpecialEditionProductId = 4930

// Allow players to fire before animation finishes, feels too sluggish otherwise (marine weapons)
kMarineDrawSpeedScalar = 1.25
kSkulkBiteSpeedScalar = 1.25

// Damage types 
// 
// In NS2 - Keep simple and mostly in regard to armor and non-armor. Can't see armor, but players
// and structures spawn with an intuitive amount of armor.
// http://www.unknownworlds.com/ns2/news/2010/6/damage_types_in_ns2
// 
// Normal - Regular damage (Rifle, Bite, Spit, Railgun, Flamethrower)
// Light - Reduced vs. armor (Sentries, Hydras, Whip attack?)
// Heavy - Extra damage vs. armor (Swipe, Pistol, Shotgun)
// Puncture - Extra vs. players (Minigun, Spikes)
// Structural - Double against structures (Gore, Axe, GL)
// Gas - Breathing targets only (Spores, Nerve Gas GL)
// Biological - Living targets only (Parasite, Flamethrower, Healing spray)
// StructuresOnly - Doesn't damage players or AI units (ARC, Bombard, Sap)
// Falling - Ignores armor for humans, no damage for some creatures or exoskeleton
// Door - Like Normal but also does damage to Doors. Nothing else damages Doors.
// Flame - Like normal but catches target on fire and plays special flinch animation
kDamageType = enum( {'Normal', 'Light', 'Heavy', 'Puncture', 'Structural', 'Gas', 'Biological', 'StructuresOnly', 'Falling', 'Door', 'Flame'} )

// Describe damage types for tooltips
kDamageTypeDesc = {
    "",
    "Light damage: reduced vs. armor",
    "Heavy damage: extra vs. armor",
    "Puncture damage: extra vs. players",
    "Structural damage: Double vs. structures",
    "Gas damage: affects breathing targets only",
    "Biological damage: Living targets only",
    "Structures only: Doesn't damage players or AI units",
    "Falling damage: Ignores armor for humans, no damage for aliens",
    "Door: Can also affect Doors",
}

// Death message indices 
kDeathMessageIcon = enum( {'None', 'Rifle', 'RifleButt', 'Pistol', 'Axe', 'Shotgun', 'Flamethrower', 'ARC', 'Grenade', 'Sentry', 'MAC', 'Bite', 'HydraSpike', 'Spit', 'Spikes', 'SpikesAlt', 'SporeCloud', 'SwipeBlink', 'Drifter', 'Whip'} )

// 0 = tech/resource point (empty white square)
// 1 = structure (filled in square, smaller than tech point)
// 2 = player (filled in circle, little smaller than structure)
// 3 = door (small filled in white square)
kMinimapBlipType = enum( {'AttachPoint', 'Structure', 'Player', 'Door'} )

// Friendly IDs
// 0 = friendly
// 1 = enemy
// 2 = neutral
kMinimapBlipTeam = enum( {'Friendly', 'Enemy', 'Neutral'} )

// How often to send minimap blips - and when to expire them
kMinimapBlipLifetime = 1.5

// Bit mask table for non-stackable game effects.
// Always keep "Max" as last element.
kGameEffect = CreateBitMask( {"InUmbra", "Fury", "Cloaked", "Parasite", "NearDeath", "Disorient", "OnFire", "Max"} )
kGameEffectMax = bit.rshift(kGameEffect.Max, 1)

// Stackable game effects (more than one can be active, server-side only)
kFuryGameEffect = "fury"
kMetabolizeGameEffect = "metabolize"
kEnergizeGameEffect = "energize"
kMaxStackLevel = 10

kMaxEntityStringLength = 32
kMaxAnimationStringLength = 32

// Player modes. When outside the default player mode, input isn't processed from the player
kPlayerMode = enum( {'Default', 'Taunt', 'Knockback', 'StandUp', 'GorgeStructure', 'GorgeStartArmor', 'GorgeArmor', 'GorgeEndArmor', 'GorgeStartSlide', 'GorgeSliding', 'GorgeEndSlide', 'GorgeDeath', 'FadeBlinkIn', 'FadeStab', 'OnosStartJump'} )

// Team alert types
kAlertType = enum( {'Attack', 'Info', 'Request'} )

// DSP enums
kDSPType = enum( {'NearDeath', 'ShadeDisorientFlange', 'ShadeDisorientLoPass'} )

// Dynamic light modes for power grid
kLightMode = enum( {'Normal', 'NoPower', 'LowPower', 'Damaged'} )

// Don't allow commander to build structures this close to attach points or other structures
kBlockAttachStructuresRadius = 3

// Marquee while active, to ensure we get mouse release event even if on top of other component
kHighestPriorityZ = 3

// How often to send kills, deaths, nick name changes, etc. for scoreboard
kScoreboardUpdateInterval = 1

// How often to send ping updates
kUpdatePingsInterval = 1.25

// How often blips sent to alien players
kHiveSightUpdateInterval = 2.0

// Only send friendly blips down within this range 
kHiveSightMaxRange = 50
kHiveSightMinRange = 3
kHiveSightDamageTime = 8

// Hive sight constants
kBlipType = enum( {'Undefined', 'Friendly', 'FriendlyUnderAttack', 'Sighted', 'TechPointStructure'} )

kFeedbackURL = "http://www.unknownworlds.com/game_scripts/ns2/feedback.php"

// Use for marine HUD, alien HUD, Commander UI. These are created and destroyed with
// the player.
kClassFlashIndex = 1
// Used for menu on top of class (marine or alien buy menus or out of game menu) 
kMenuFlashIndex = 2

// Fade to black time (then to spectator mode)
kFadeToBlackTime = 3

// Constant to prevent z-fighting 
kZFightingConstant = 0.1

// Any geometry or props with this name won't be drawn or affect commanders
kCommanderInvisibleGroupName    = "CommanderInvisible"

kCollisionGeometryGroupName     = "CollisionGeometry"
kNonCollisionGeometryGroupName  = "NonCollisionGeometry"

// libswf's default for the flash "undefined" value
kLibSwfUndefined = 2147483648

// Max players allowed in game
kMaxPlayers = 32

kMaxIdleWorkers = 127

// Max distance to propagate entities with
kMaxRelevancyDistance = 40

kEpsilon = 0.0001

// Options keys
kNicknameOptionsKey = "nickname"
kVisualDetailOptionsKey = "visualDetail"
kSoundVolumeOptionsKey = "soundVolume"
kMusicVolumeOptionsKey = "musicVolume"
kFullscreenOptionsKey = "graphics/display/fullscreen"
kDisplayQualityOptionsKey = "graphics/display/quality"
kInvertedMouseOptionsKey = "graphics/display/invertedmouse"

kGraphicsXResolutionOptionsKey = "graphics/display/x-resolution"
kGraphicsYResolutionOptionsKey = "graphics/display/y-resolution"

kMouseSensitivityScalar         = 50


