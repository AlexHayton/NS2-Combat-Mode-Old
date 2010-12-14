// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hydra.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Structure droppable by Gorge that attacks enemy targets with clusters of shards. Can be built
// on walls.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Hydra' (Structure)

Hydra.kMapName = "hydra"

Hydra.kModelName = PrecacheAsset("models/alien/hydra/hydra.model")

Hydra.kAttackSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/attack")
Hydra.kDeploySound = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/deploy")
Hydra.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/idle")
Hydra.kDeathSound = PrecacheAsset("sound/ns2.fev/alien/structures/hydra/death")

Hydra.kSpikeFireEffect = PrecacheAsset("cinematics/alien/hydra/spike_fire.cinematic")
Hydra.kSpikeImpactEffect = PrecacheAsset("cinematics/alien/hydra/spike_impact.cinematic")

Hydra.kAnimIdleTable = {{1.5, "idle"}, {.1, "idle2"}}
Hydra.kAnimAttack = "attack"
Hydra.kAnimAlert = "alert"

Hydra.kRange = 17.78        // From NS1 (also "alert" range)
Hydra.kDamage = 20          // From NS1
Hydra.kAlertCheckInterval = 2

if Server then
    Script.Load("lua/Hydra_Server.lua")
    Script.Load("lua/HydraSpike.lua")
end

function Hydra:GetIsAlienStructure()
    return true
end

function Hydra:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function Hydra:GetDamageEffectOffset()
    return Vector(15, 16, 11)
end

function Hydra:GetIdleSound()
    return Hydra.kIdleSoundEffect
end

// No deploy animation - it's built gradually through spawn and pose parameters
function Hydra:GetDeployAnimation()
    return ""
end

function Hydra:GetIdleAnimation()

    // Play proper idle animation a short time from now
    local idleAnimName = ""
    
    if self:GetIsBuilt() then
        idleAnimName = chooseWeightedEntry( Hydra.kAnimIdleTable )
    end
    
    return idleAnimName
    
end

function Hydra:GetCanDoDamage()
    return true
end


Shared.LinkClassToMap("Hydra", Hydra.kMapName, {})