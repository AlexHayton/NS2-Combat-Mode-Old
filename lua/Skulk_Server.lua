// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Skulk:InitWeapons()

    Alien.InitWeapons(self)
    
    self:GiveItem(BiteLeap.kMapName)
    self:GiveItem(Parasite.kMapName)
    
    self:SetActiveWeapon(BiteLeap.kMapName)
    
end

function Skulk:GetKilledSound(doer)
    return Skulk.kDieSoundName
end

// Handle carapace
function Skulk:GetHealthPerArmor(damageType)

    if ( self:GetHasUpgrade(kTechId.Carapace) ) then
    
        return kCarapaceHealthPerArmor
    
    end
    
    return Alien.GetHealthPerArmor(self, damageType)
    
end
