// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MiniPustule.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A small version of the pustule created by the Gorge.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'MiniPustule' (Pustule)

MiniPustule.kModelName = PrecacheAsset("models/alien/small_pustule/small_pustule.model")

MiniPustule.kMapName = "minipustule"

MiniPustule.kImpulseLightRadius = 1

MiniPustule.kInfestRadius = kMiniPustuleRadius

MiniPustule.kExtents = Vector(0.1, 0.05, 0.1)

function MiniPustule:GetInfestationRadius()
    return MiniPustule.kInfestRadius
end

Shared.LinkClassToMap("MiniPustule", MiniPustule.kMapName, {})