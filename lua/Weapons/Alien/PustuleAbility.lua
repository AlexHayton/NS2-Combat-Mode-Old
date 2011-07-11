// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\PustuleAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Gorge builds hydra.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'PustuleAbility' (DropStructureAbility)

PustuleAbility.kMapName = "pustule_ability"

function PustuleAbility:GetEnergyCost(player)
    return 40
end

function PustuleAbility:GetPrimaryAttackDelay()
    return 1.0
end

function PustuleAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function PustuleAbility:GetDropStructureId()
    return kTechId.MiniPustule
end

function PustuleAbility:GetSuffixName()
    return "minipustule"
end

function PustuleAbility:GetDropClassName()
    return "MiniPustule"
end

function PustuleAbility:GetDropMapName()
    return MiniPustule.kMapName
end

function PustuleAbility:GetHUDSlot()
    return 3
end

function PustuleAbility:CreateStructure(coords, player)
    // Create mini pustule
    return CreatePustule(player, coords.origin, coords.yAxis, true)
end


Shared.LinkClassToMap("PustuleAbility", PustuleAbility.kMapName, {} )
