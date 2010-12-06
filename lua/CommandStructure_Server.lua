// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kCommandStructureThinkInterval = .25

function CommandStructure:OnKill(damage, attacker, doer, point, direction)

    self:Logout()
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)

end

// Children should override this
function CommandStructure:GetTeamType()
    return kNeutralTeamType
end

function CommandStructure:GetIsValidForRecycle()
    return not self.occupied
end

function CommandStructure:OnInit()

    Structure.OnInit(self)
    
    self.commander = nil
    
    self.occupied = false
    
    // Attach self to nearest tech point
    local position = Vector(self:GetOrigin())
    
    local nearestTechPoint = GetNearestTechPoint(position, self:GetTeamType(), true)
    if(nearestTechPoint ~= nil) then
    
        nearestTechPoint:SetAttached(self)
        
        // Allow entities to be positioned off ground (eg, hive hovers over tech point)
        position = Vector(nearestTechPoint:GetOrigin())
    
    end
    
    local spawnHeightOffset = LookupTechData(self:GetTechId(), kTechDataSpawnHeightOffset)
    if(spawnHeightOffset ~= nil) then
        position.y = position.y + spawnHeightOffset
    end
    
    self:SetOrigin(position)
    
    self:SetNextThink(kCommandStructureThinkInterval)
    
end

function CommandStructure:GetCommanderClassName()
    return Commander.kMapName   
end

function CommandStructure:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        if(structure and (structure:GetId() == self:GetId()) and (researchId == self.level1TechId or researchId == self.level2TechId or researchId == self.level3TechId)) then

            // Also changes current health and maxHealth    
            success = self:Upgrade(researchId)
            
        end
        
    end
    
    return success    
end

function CommandStructure:GetLoginTime()
    return ConditionalValue(Shared.GetDevMode(), 0, self:GetAnimationLength(self:GetCloseAnimation()))
end

function CommandStructure:GetIsPlayerValidForCommander(player)
    return true
end

function CommandStructure:UpdateCommanderLogin(force)

    if (self.occupied and self.commander == nil and (Shared.GetTime() > (self.timeStartedLogin + self:GetLoginTime())) or force) then
    
        // Don't turn player into commander until short time later
        local player = Shared.GetEntity(self.playerStartedLogin)
        
        if (self:GetIsPlayerValidForCommander(player) and self:GetIsActive()) or force then
        
            self:LoginPlayer(player)
            
        // Player was killed, became invalid or left the server somehow
        else
        
            self.occupied = false
            self.timeStartedLogin = nil
            self.commander = nil
                        
            self:PlaySound(self:GetLogoutSound())
            self:SetAnimation(self:GetOpenAnimation())
            
        end
        
    end
    
end

function CommandStructure:LoginPlayer(player)

    local commanderStartOrigin = Vector(player:GetOrigin())
            
    // Create Commander player
    local commanderPlayer = player:Replace( self:GetCommanderClassName(), player:GetTeamNumber(), true)
    
    // Set all child entities and view model invisible
    function SetInvisible(weapon) 
        weapon:SetIsVisible(false)
    end
    commanderPlayer:ForEachChild(SetInvisible)
    
    if (commanderPlayer:GetViewModelEntity()) then
        commanderPlayer:GetViewModelEntity():SetModel("")
    end
    
    // Make this structure the first hotgroup if we don't have any yet
    if(commanderPlayer:GetNumHotkeyGroups() == 0) then
                    
        commanderPlayer:SetSelection( {self:GetId()} )
        commanderPlayer:CreateHotkeyGroup(1)
        
    end
    
    commanderPlayer:SetCommandStructure(self)
    
    // Save origin so we can restore it on logout
    commanderPlayer.lastGroundOrigin = Vector(commanderStartOrigin)
    
    self.commander = commanderPlayer
    
    // Must reset offset angles once player becomes commander
    commanderPlayer:SetOffsetAngles(Angles(0, 0, 0))
    
    return commanderPlayer

end

function CommandStructure:GetCommander()
    return self.commander
end

function CommandStructure:OnThink()

    Structure.OnThink(self)

    self:UpdateCommanderLogin()

    self:SetNextThink(kCommandStructureThinkInterval)
    
end

function CommandStructure:GetOpenAnimation()
    return "open"
end

function CommandStructure:GetCloseAnimation()
    return "close"
end

// Put player into Commander mode
function CommandStructure:OnUse(player, elapsedTime, useAttachPoint)

    local teamNum = self:GetTeamNumber()
    
    if( (teamNum == 0) or (teamNum == player:GetTeamNumber()) ) then
    
        if(not Structure.OnUse(self, player, elapsedTime, useAttachPoint)) then
        
            // Must use attach point if specified (Command Station)
            if (not self.occupied) and (useAttachPoint or (self:GetUseAttachPoint() == "")) then

                self.timeStartedLogin = Shared.GetTime()
                
                self.playerStartedLogin = player:GetId()
                
                self.occupied = true
                
                self:PlaySound(self:GetLoginSound())
                
                self:SetAnimation(self:GetCloseAnimation())
                
                return true
                
            end
            
        end

    end
    
    return false
    
end

function CommandStructure:OnAnimationComplete(animName)
    self:GetCloseAnimation()
end

function CommandStructure:OnEntityChange(oldEntityId, newEntityId)

    Structure.OnEntityChange(self, oldEntityId, newEntityId)

    if self.commander and self.commander:GetId() == oldEntityId then
    
        self.commander = nil
        
        self.occupied = false
        
        self:PlaySound(self:GetLogoutSound())
        
        self:SetAnimation(self:GetOpenAnimation())

    end
    
end

// Returns new player 
function CommandStructure:Logout()

    // Change commander back to player
    if(self.commander ~= nil) then
    
        local previousWeaponMapName = self.commander.previousWeaponMapName
        local previousOrigin = self.commander.lastGroundOrigin
        local previousAngles = self.commander.previousAngles
        local previousHealth = self.commander.previousHealth
        local previousArmor = self.commander.previousArmor
        
        local player = self.commander:Replace(self.commander.previousMapName, self.commander:GetTeamNumber(), true)    

        // Switch to weapon player was using before becoming Commander
        player:InitViewModel()
        player:SetActiveWeapon(previousWeaponMapName)
        player:SetOrigin(previousOrigin)
        player:SetAngles(previousAngles)
        player:SetHealth(previousHealth)
        player:SetArmor(previousArmor)
        player.frozen = false

        self.commander = nil
        
        self.occupied = false
        
        self:PlaySound(self:GetLogoutSound())
        self:SetAnimation(self:GetOpenAnimation())
        
        return player
        
    end
    
    return nil
    
end

function CommandStructure:OverrideOrder(order)

    // Convert default to set rally point
    if(order:GetType() == kTechId.Default) then
    
        order:SetType(kTechId.SetRally)
        
    end

end
