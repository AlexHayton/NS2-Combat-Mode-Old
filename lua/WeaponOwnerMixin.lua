// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeaponOwnerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

WeaponOwnerMixin = { }

function WeaponOwnerMixin:UpdateWeapons(input)

    // Get list once a frame
    if not Shared.GetIsRunningPrediction() then
    
        self:ComputeHUDOrderedWeaponList()

        // Call ProcessMove on all our weapons so they can update properly
        for index, weapon in ipairs(self.hudOrderedWeaponList) do
            weapon:OnProcessMove(self, input)
        end
        
    end
        
end

// Get list of weapons in order displayed on HUD
function WeaponOwnerMixin:ComputeHUDOrderedWeaponList()

    local childEntities = GetChildEntities(self, "Weapon")
        
    // Sort weapons
    function sort(weapon1, weapon2)
        return weapon2:GetHUDSlot() > weapon1:GetHUDSlot()
    end
    
    table.sort(childEntities, sort)
        
    self.hudOrderedWeaponList = childEntities
    
end   

function WeaponOwnerMixin:GetHUDOrderedWeaponList()

    if self.hudOrderedWeaponList == nil then
        self:ComputeHUDOrderedWeaponList()
    end
    
    return self.hudOrderedWeaponList
    
end

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function WeaponOwnerMixin:SetActiveWeapon(weaponMapName)

    local weaponList = self:GetHUDOrderedWeaponList()
    
    for index, weapon in ipairs(weaponList) do
    
        local mapName = weapon:GetMapName()

        if (mapName == weaponMapName) then
        
            local newWeapon = weapon
            local activeWeapon = self:GetActiveWeapon()
            
            if (activeWeapon == nil or activeWeapon:GetMapName() ~= weaponMapName) then
            
                local previousWeaponName = ""
                
                if activeWeapon then
                
                    activeWeapon:OnHolster(self)
                    activeWeapon:SetIsVisible(false)
                    previousWeaponName = activeWeapon:GetMapName()
                    
                end

                // Set active first so proper anim plays
                self.activeWeaponIndex = index
                
                newWeapon:SetIsVisible(true)
                
                // Always allow player to draw weapon
                self:ClearActivity()
                
                newWeapon:OnDraw(self, previousWeaponName)

                return true
                
            end
            
        end
        
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon ~= nil and activeWeapon:GetMapName() == weaponMapName then
        return true
    end
    
    Print("%s:SetActiveWeapon(%s) failed", self:GetClassName(), weaponMapName)
    
    return false

end

function WeaponOwnerMixin:GetActiveWeapon()

    local activeWeapon = nil
    
    if(self.activeWeaponIndex ~= 0) then
    
        self:ComputeHUDOrderedWeaponList()
        local weapons = self:GetHUDOrderedWeaponList()
        
        if self.activeWeaponIndex <= table.count(weapons) then
            activeWeapon = weapons[self.activeWeaponIndex]
        end
        
    end
    
    return activeWeapon
    
end

// SwitchWeapon or choose option from sayings menu if open
// weaponindex starts at 1
function WeaponOwnerMixin:SwitchWeapon(weaponIndex)

    local success = false
    
    if( not self:GetIsCommander()) then
        
        local weaponList = self:GetHUDOrderedWeaponList()
        
        if(weaponIndex >= 1 and weaponIndex <= table.maxn(weaponList)) then

            success = self:SetActiveWeapon(weaponList[weaponIndex]:GetMapName())
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()
            
        end
        
    end
    
    return success
    
end

// Checks to see if self already has a weapon with the passed in map name.
function WeaponOwnerMixin:GetHasWeapon(weaponMapName)

    local weapons = self:GetHUDOrderedWeaponList()
    for index, weapon in ipairs(weapons) do
        if weapon:GetMapName() == weaponMapName then
            return true
        end
    end
    
    return false

end