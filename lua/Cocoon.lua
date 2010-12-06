// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Cocoon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Intermediate that a Drifter turns into before eventually growing into a structure.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Cocoon' (Structure)

Cocoon.kMapName = "cocoon"

Cocoon.kModelName = PrecacheAsset("models/alien/cocoon/cocoon.model")

Cocoon.kAnimIdle = "idle"

Cocoon.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/death_large")

Cocoon.kHealth = 200
Cocoon.kArmor = 50

function Cocoon:GetIdleAnimation()
    return Cocoon.kAnimIdle
end

function Cocoon:OnInit()

    self:SetModel(Cocoon.kModelName)
    
    Structure.OnInit(self)
    
end

function Cocoon:GetIsAlienStructure()
    return true
end

function Cocoon:GetKilledSound(doer)
    if doer ~= nil then
        local doerClassName = doer:GetClassName()
        if doerClassName == "Axe" then 
            return Structure.kAlienKilledByAxeSound
        elseif doerClassName == "Grenade" then
            return Structure.kAlienKilledByGrenadeSound
        end
    end

    return Cocoon.kDieSoundName
    
end

function Cocoon:GetDamageEffectOffset()
    return Vector(0, 9, 10)
end

Shared.LinkClassToMap("Cocoon", Cocoon.kMapName, {})
