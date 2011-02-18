// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Marine:InitWeapons()

    Player.InitWeapons(self)
    
    self:GiveItem(Rifle.kMapName)
    self:GiveItem(Pistol.kMapName)
    self:GiveItem(Axe.kMapName)
    
    self:SetActiveWeapon(Rifle.kMapName)

end

function Marine:MakeSpecialEdition()
    self:SetModel(Marine.kSpecialModelName)
end

function Marine:AddWeapon(weapon)

    local success = false
    
    if self:GetCanNewActivityStart() then
    
        // If incoming weapon uses occupied weapon slot, only pick it up if it costs more than our current weapon (ie, it's better)
        // In that case, drop current weapon before adding new one
        local newSlot = weapon:GetHUDSlot()
        local weaponInSlot = self:GetWeaponInHUDSlot(newSlot)
        
        if not weaponInSlot or (weapon:GetCost() > weaponInSlot:GetCost()) then
        
            if weaponInSlot then
                self:Drop(weaponInSlot)
            end
            
            success = Player.AddWeapon(self, weapon)
            
        end
        
    end
    
    return success
    
end

function Marine:OverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to unbuilt friendly structures should be construct orders
    if(order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Construct)
        
    elseif order:GetType() == kTechId.Default and GetOrderTargetIsDefendTarget(order, self:GetTeamNumber()) then
    
        order:SetType(kTechId.SquadDefend)

    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
    
        order:SetType(kTechId.Attack)

    elseif order:GetType() == kTechId.Default then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.SquadMove)
        
    else
    
        Player.OverrideOrder(self, order)
        
    end
    
end

function Marine:AttemptToBuy(techId)

    local armory = GetArmory(self)
    
    if armory then
    
        local mapName = LookupTechData(techId, kTechDataMapName)
        
        if mapName and self:GiveItem(mapName) then
        
            // Make sure we're ready to deploy new weapon so we switch to it properly
            self:ClearActivity()
                
            self:SetActiveWeapon(mapName)
                        
            Shared.PlayPrivateSound(self, Marine.kSpendPlasmaSoundName, nil, 1.0, self:GetOrigin())
            
            if techId == kTechId.Jetpack then
                Shared.PlayWorldSound(nil, Marine.kJetpackPickupSound, nil, self:GetOrigin())
            else
                Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, self:GetOrigin())
            end
            
            //armory:PlayArmoryScan()
            
            return true
            
        end
        
    end
    
    return false
    
end

function Marine:OnKill(damage, attacker, doer, point, direction)

    // Will become "drop" soon
    self:KillWeapons()
    
    Player.OnKill(self, damage, attacker, doer, point, direction)
    self:PlaySound(Marine.kDieSoundName)
    
    // Don't play alert if we suicide
    if player ~= self then
        self:GetTeam():TriggerAlert(kTechId.MarineAlertSoldierLost, self)
    end
    
    // Remember squad we were in on death so we can beam back to them
    self.lastSquad = self:GetSquad()
    
end

// Will become DropWeapons soon
function Marine:KillWeapons()

    local weapons = self:GetHUDOrderedWeaponList()
    
    for index = 1, table.count(weapons) do
    
        local weapon = weapons[index]
        if weapon then
            //self:Drop(weapon)
            DestroyEntity(weapon)
        end
        
    end
    
end

function Marine:Drop(weapon)

    local activeWeapon = self:GetActiveWeapon()
    
    if not weapon then
        weapon = activeWeapon
    end

    if weapon == activeWeapon then
        self:SelectNextWeapon()
    end
    
    if( weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() ) then
    
        // Remove from player's inventory
        self:RemoveWeapon(weapon)
        
        // Make sure we're ready to deploy new weapon so we switch to it properly
        self:ClearActivity()
        
        local weaponSpawnPoint = self:GetAttachPointOrigin(Weapon.kHumanAttachPoint)
        weapon:SetOrigin(weaponSpawnPoint)
        
        // Tell weapon not to be picked up again for a bit
        weapon:Dropped(self)
        
    end

end

function Marine:OnResearchComplete(structure, researchId)

    local success = Player.OnResearchComplete(self, structure, researchId)
    
    // For armor upgrades, give us more armor immediately (preserving percentage)
    if success then
    
        if(researchId == kTechId.Armor1 or researchId == kTechId.Armor2 or researchId == kTechId.Armor3) then
        
            local armorPercent = self.armor/self.maxArmor
            self.maxArmor = self:GetArmorAmount()
            self.armor = self.maxArmor * armorPercent
            
        end    
        
    end
    
    return success  
end

function Marine:SetSquad(squad)
    
    if(squad ~= self.squad) then
    
        self.squad = squad

    end
    
end

function Marine:SpawnInSquad(squad)

    local success = false
    
    if squad == nil then
        squad = self.lastSquad
    end
    
    if(squad ~= nil and squad > 0) then
    
        local spawnOrigin, spawnAngles, spawnViewAngles = GetSpawnInSquad(self, squad)
        
        if(spawnOrigin ~= nil and spawnAngles ~= nil and spawnViewAngles ~= nil) then
        
            // Set new coordinates
            self:SetOrigin(spawnOrigin)
            self:SetAngles(spawnAngles)
            self:SetViewAngles(spawnViewAngles)
            
            // Play squad spawn sound where you end up
            Shared.PlayWorldSound(nil, Marine.kSquadSpawnSound, nil, spawnOrigin)
            
            success = true
            
        end
        
    end
    
    return success

end

function Marine:ApplyCatPack()
    
    // Play catpack sound for everyone here
    Shared.PlayWorldSound(nil, Marine.kCatalystSound, nil, self:GetOrigin())
    
    self.timeOfLastCatPack = Shared.GetTime()
    
end

