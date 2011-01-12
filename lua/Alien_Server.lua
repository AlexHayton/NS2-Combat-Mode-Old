// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Alien:Evolve(techId)

    local handled = false
    local success = false
    
    // Morph into new class or buy upgrade
    local gestationClassName = LookupTechData(techId, kTechDataGestateName)
    
    // Change into new life form if different
    if(gestationClassName ~= nil) and (self:GetClassName() ~= gestationClassName) then

        // Check for room
        local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
        local newAlienExtents = LookupTechData(techId, kTechDataMaxExtents)
        local physicsMask = PhysicsMask.AllButPCsAndRagdolls
        local position = self:GetOrigin()
        
        if not self:GetIsOnGround() then
        
            // Pop up tooltip
            self:AddTooltipOncePer("You must be on the ground to evolve.", 3)
            
        elseif GetHasRoomForCapsule(eggExtents, position, physicsMask, self) and GetHasRoomForCapsule(newAlienExtents, position, physicsMask, self) then
        
            self:RemoveChildren()
            
            // Deduct cost here as player is immediately replaced and copied
            self:AddPlasma(-LookupTechData(techId, kTechDataCostKey))
            
            local newPlayer = self:Replace(Embryo.kMapName)
            
            // Clear angles, in case we were wall-walking or doing some crazy alien thing
            local angles = Angles(self:GetViewAngles())
            angles.roll = 0.0
            angles.pitch = 0.0
            newPlayer:SetAngles(angles)
            
            // Eliminate velocity so that we don't slide or jump as an egg
            newPlayer.velocity.x = 0
            newPlayer.velocity.y = 0
            newPlayer.velocity.z = 0
                    
            // We lose our purchased upgrades when we morph into something else
            newPlayer.upgrade1 = kTechId.None
            newPlayer.upgrade2 = kTechId.None
            newPlayer.upgrade3 = kTechId.None
            newPlayer.upgrade4 = kTechId.None
            
            newPlayer:SetGestationTechId(techId)
            
            success = true

        else
        
            // Pop up tooltip
            self:AddTooltipOncePer("You need more room to evolve.", 3)
            
        end        
        
        handled = true

    end
    
    return handled, success
    
end

// Availability and cost already checked
function Alien:AttemptToBuy(techId)

    // Morph into new class 
    local handled, success = self:Evolve(techId)
    
    if not handled then
        
        // Else try to buy tech (carapace, piercing, etc.). If we don't already have this tech node, buy it.
        if not self:GetHasUpgrade(techId) then
            
            success = self:GiveUpgrade(techId)
            
        else
            Print("%s:AttemptToBuy(%s) - Player already has tech.", self:GetClassName(), EnumToString(kTechId, techId))
        end
    
    end
        
    return success
    
end

function Alien:OnInit()

    Player.OnInit(self)
    
    self.abilityEnergy = Ability.kMaxEnergy

end

function Alien:MakeSpecialEdition()
    // Currently there's no alient special edition visual difference
end