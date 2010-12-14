// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

    // If incoming weapon uses occupied weapon slot, drop current weapon before adding new one
    local newSlot = weapon:GetHUDSlot()
    local weaponInSlot = self:GetWeaponInHUDSlot(newSlot)
    
    if(weaponInSlot ~= nil) then
    
        self:Drop(weaponInSlot)
    
    end
    
    Player.AddWeapon(self, weapon)
    
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

// Drop current weapon
function Marine:Drop(weapon)

    if(weapon == nil) then
        weapon = self:GetActiveWeapon()
    end
    
    if( weapon ~= nil and weapon:isa("ClipWeapon") ) then
    
        // Remove from player's inventory
        self:RemoveWeapon(weapon)
        
        // Make sure we're ready to deploy new weapon so we switch to it properly
        self:ClearActivity()
        
        // Tell weapon not to be picked up again for a bit
        weapon:Dropped()
        
        // TODO: Include this after we get physics working again
        // Give forward velocity so we can see the result
        //local dropDirection = self:GetViewAngles():GetCoords().zAxis
        //weapon:SetImpulse(Vector(0, 0, 0), dropDirection*3)
        
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
