// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Weapon:OnInit()

    ScriptActor.OnInit(self)

    self:SetWeaponWorldState(true)    
    
end

function Weapon:Dropped(prevOwner)

    self.prevOwnerId = prevOwner:GetId()
    
    self:SetWeaponWorldState(true)
    
    // So we can see the result
    self:AddImpulse(prevOwner:GetEyePos(), prevOwner:GetViewAngles():GetCoords().zAxis * 3)
    
end

// Set to true for being a world weapon, false for when it's carried by a player
function Weapon:SetWeaponWorldState(state)

    if state ~= self.weaponWorldState then
    
        if state then
        
            self:SetPhysicsType(Actor.PhysicsType.DynamicServer)
    
            // So it doesn't affect player movement and so collide callback is called
            self:SetPhysicsGroup(PhysicsGroup.ProjectileGroup)
            self:SetIsVisible(true)
            
            self:UpdatePhysicsModel()
            
            self.dropTime = Shared.GetTime()
            
            self:SetNextThink(kWeaponStayTime)
            
        else
        
            self:SetPhysicsType(Actor.PhysicsType.None)
            self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
            
            self:UpdatePhysicsModel()
            
            self.dropTime = nil
            
        end

        self.hitGround = false

        self.weaponWorldState = state
        
    end
    
end

// Should only be called when dropped
function Weapon:OnCollision(targetHit)

    // Don't hit owner - shooter
    if not targetHit then
    
        // Play weapon drop sound
        if not self.hitGround then
            Shared.PlayWorldSound(nil, Weapon.kDropSound, nil, self:GetOrigin())
        end
        
        self.hitGround = true
   
    elseif targetHit.GetTeamNumber and targetHit:GetTeamNumber() == self:GetTeamNumber() then
    
        // Don't allow dropper to pick it up until it hits the ground            
        if (targetHit:GetId() ~= self.prevOwnerId) or self.hitGround then
        
            if targetHit.AddWeapon and targetHit:AddWeapon(self) then

                self:SetWeaponWorldState(false)
                
                targetHit:ClearActivity()
                
                targetHit:SetActiveWeapon(self:GetMapName())
                
            end
            
        end
        
    end    
    
end

function Weapon:OnThink()
    if self.weaponWorldState then
        DestroyEntity(self)
    end
end

function Weapon:CreateWeaponEffect(player, playerAttachPointName, entityAttachPointName, cinematicName)
    Shared.CreateAttachedEffect(player, cinematicName, self, Coords.GetIdentity(), entityAttachPointName, false)    
end

// Only on client
function Weapon:CreateViewModelEffect(effectName)
end