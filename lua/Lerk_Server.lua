// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
function Lerk:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(Spikes.kMapName)
    self:GiveItem(Spores.kMapName)

    self:SetActiveWeapon(Spikes.kMapName)
    
end

function Lerk:GetKilledSound(doer)
    return Lerk.kDieSoundName
end



