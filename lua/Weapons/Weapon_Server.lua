// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Weapon:OnTouch(player)

    if( (self.dropTime == nil) or (Shared.GetTime() > self.dropTime + 1) ) then

        player:ClearActivity()    
        player:AddWeapon(self)
        self.dropTime = nil
        
    end
    
end

function Weapon:CreateWeaponEffect(player, playerAttachPointName, entityAttachPointName, cinematicName)

    Shared.CreateAttachedEffect(player, cinematicName, self, Coords.GetIdentity(), entityAttachPointName, false)
    
end

// Only on client
function Weapon:CreateViewModelEffect(effectName)
end