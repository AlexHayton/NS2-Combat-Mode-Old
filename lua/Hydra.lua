// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

// No deploy animation - it's built gradually through spawn and pose parameters
function Hydra:GetDeployAnimation()
    return ""
end
function Hydra:GetCanDoDamage()
    return true
end


Shared.LinkClassToMap("Hydra", Hydra.kMapName, {})