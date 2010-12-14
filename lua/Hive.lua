// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/CommandStructure.lua")

class 'Hive' (CommandStructure)

Hive.kMapName        = "hive"

Hive.kLevel1MapName  = "hivel1"
Hive.kModelName = PrecacheAsset("models/alien/hive/hive.model")

Hive.kActiveSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_idle")
Hive.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_deploy")
Hive.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound")
// Play special sound for players on team to make it sound more dramatic or horrible
Hive.kWoundAlienSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound_alien")
Hive.kKilledSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_death")
Hive.kLoadSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_load")
Hive.kExitSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_exit")

Hive.kHiveSpawnTechEffect = PrecacheAsset("cinematics/alien/hive/hive_spawn.cinematic")
Hive.kDeployTechEffect = PrecacheAsset("cinematics/alien/hive/deploy_tech.cinematic")
Hive.kIdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
Hive.kL2IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev2.cinematic")
Hive.kL3IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev3.cinematic")
Hive.kGlowEffect = PrecacheAsset("cinematics/alien/hive/glow.cinematic")
Hive.kSpecksEffect = PrecacheAsset("cinematics/alien/hive/specks.cinematic")
Hive.kDeathEffect = PrecacheAsset("cinematics/alien/hive/death.cinematic")

Hive.kCompleteSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_complete")
Hive.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_under_attack")
Hive.kDyingSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_dying")
// Play 'hive is dying' sound when health gets to 40% or less
Hive.kHiveDyingThreshold = .4

Hive.kHealRadius = 12.7     // From NS1
Hive.kHealthPercentage = .08
Hive.kHealthUpdateTime = 1

// Hive
Hive.kAnimScaredActive = "scared_active"
Hive.kAnimScaredInactive = "scared_inactive"

// Played when hive is created but not yet built
Hive.kAnimFlinchSpawnSmall = "flinch_spawn"
Hive.kAnimFlinchSpawnBig = "flinch_spawn_big"

// Played when hive has been built but doesn't have a commander (after it's been deployed)
Hive.kAnimFlinchInactiveSmall = "flinch_inactive"
Hive.kAnimFlinchInactiveBig = "flinch_inactive_big"

// Played when hive is occupied by commander
Hive.kAnimFlinchActiveSmall = "flinch_active"
Hive.kAnimFlinchActiveBig = "flinch_active_big"

Hive.kAnimIdleActiveTable = {{.4, "idle_active"}, {.7, "idle_active2"}, {.7, "idle_active3"}}
Hive.kAnimIdleInactiveTable = {{1.4, "idle_inactive"}, {.3, "idle_inactive2"}, {.3, "idle_inactive3"}}

// A little bigger than we might expect because the hive origin isn't on the ground
Hive.kEggMinSpawnRadius = 3
Hive.kEggMaxSpawnRadius = 10
Hive.kHiveNumEggs = 3
Hive.kMassNumEggs = 5
Hive.kColonyNumEggs = 7
Hive.kBaseEggSpawnTime = 6
Hive.kMaxEggDropDistance = 15


if Server then
    Script.Load("lua/Hive_Server.lua")
else
    Script.Load("lua/Hive_Client.lua")
end

function Hive:GetPlaceBuildingEffect()
    return Structure.kAlienSpawnLargeEffect
end

function Hive:GetOpenAnimation()
    return Structure.kAnimDeploy
end

function Hive:GetIdleSound()
    return Hive.kActiveSound
end

function Hive:GetCloseAnimation()
    return "load"
end

function Hive:GetIsAlienStructure()
    return true
end

function Hive:GetDeathEffect()
    return Hive.kDeathEffect
end

function Hive:GetIdleAnimation()

    // Play proper idle animation a short time from now
    local idleAnimName = ""
    
    if(self:GetIsOccupied()) then
        idleAnimName = chooseWeightedEntry( Hive.kAnimIdleActiveTable )
    else
        idleAnimName = chooseWeightedEntry( Hive.kAnimIdleInactiveTable )
    end

    return idleAnimName
    
end

function Hive:OnTouch(player)

    if(GetEnemyTeamNumber(self:GetTeamNumber()) == player:GetTeamNumber()) then    
        self:SetAnimationWithBlending(ConditionalValue(self:GetIsOccupied(), Hive.kAnimScaredActive, Hive.kAnimScaredInactive))
    end
    
end

function Hive:GetDamageEffectOffset()
    return Vector(-34, 45, -45)
end

function Hive:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.Drifter, kTechId.MarkersMenu, kTechId.UpgradesMenu, kTechId.SetRally, kTechId.Metabolize }
        
        // Allow hive to be upgraded but you'll never upgrade to Level1 so don't show it
        local upgradeIndex = table.maxn(techButtons) + 1

        if(self:GetTechId() == kTechId.Hive) then
            techButtons[upgradeIndex] = self:GetLevelTechId(2)
        elseif(self:GetTechId() == kTechId.HiveMass) then
            techButtons[upgradeIndex] = self:GetLevelTechId(3)
        end        
       
    elseif(techId == kTechId.MarkersMenu) then 
        techButtons = {kTechId.RootMenu, kTechId.ThreatMarker, kTechId.LargeThreatMarker, kTechId.NeedHealingMarker, kTechId.WeakMarker, kTechId.ExpandingMarker}
    elseif(techId == kTechId.UpgradesMenu) then 
        techButtons = {kTechId.RootMenu, kTechId.DrifterFlareTech, kTechId.MetabolizeTech, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None}
    end
    
    return techButtons
    
end

function Hive:TriggerMetabolize(position)

    // Find nearest friendly entity within range and boost it's evolve/research speed
    local target = GetTriggerEntity(position, self:GetTeamNumber())
    
    if target then
    
        local effectName = ConditionalValue(target:isa("Hive") or target:isa("Onos"), kMetabolizeLargeEffect, kMetabolizeSmallEffect)
        
        Shared.CreateEffect(nil, effectName, target)
        
        target:PlaySound(Alien.kMetabolizeSound)
        
        target:AddStackableGameEffect(kMetabolizeGameEffect, kMetabolizeTime, self)
        
    end
    
end

function Hive:PerformActivation(techId, position, commander)

    local success = false
    
    if techId == kTechId.Metabolize then
    
        self:TriggerMetabolize(position)
        success = true

    else        
        success = CommandStructure.PerformActivation(self, techId, position, commander)
    end
    
    return success
    
end

function Hive:GetOnFireSound()
    return LiveScriptActor.kOnFireLargeSound
end

Shared.LinkClassToMap("Hive",    Hive.kLevel1MapName, {})

// Create new classes here so L2 and L3 hives can be created for test cases without
// create a basic hive and then upgrading it
class 'HiveL2' (Hive)

HiveL2.kMapName = "hivel2"
Shared.LinkClassToMap("HiveL2",    HiveL2.kMapName, {})

class 'HiveL3' (HiveL2)

HiveL3.kMapName = "hivel3"
Shared.LinkClassToMap("HiveL3",    HiveL3.kMapName, {})