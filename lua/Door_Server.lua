// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Door:OnReset()
    
    self:OnInit()
    
    // Restore original origin, angles, etc. as it could have been rag-dolled
    self:SetOrigin(self.savedOrigin)
    self:SetAngles(self.savedAngles)
    
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)

    self:SetState(Door.kState.Closed)    
    
    self.timeToRagdoll = nil
    self.timeToDestroy = nil
    
end

function Door:OnLoad()

    self.weldTime = GetAndCheckValue(self.weldTime, 1, 1000, "weldTime", Door.kDefaultWeldTime, true)
    self.weldHealth = GetAndCheckValue(self.weldHealth, 1, 2000, "weldHealth", Door.kDefaultHealth, true)
    
    // Save origin, angles, etc. so we can restore on reset
    self.savedOrigin = Vector(self:GetOrigin())
    self.savedAngles = Angles(self:GetAngles())
    
end

function Door:OnWeld(entity, elapsedTime)

    local performedWelding = false
    
    if (self.state == Door.kState.Opened) then
        
        self:SetState(Door.kState.Close)
        
    elseif (self.state == Door.kState.Close) then
    
        // Do nothing yet
        
    elseif (self.state == Door.kState.Closed) then

        // Add weld time by using door
        self.time = self.time + elapsedTime
        
        // Check total weld time to that specified in entity property
        if(self.time >= self.weldTime) then
        
            self:SetState(Door.kState.Welded)
            
            entity:AddScoreForOwner(Door.kWeldPointValue)
        
        end
        
        performedWelding = true
    
    elseif(self.state ~= Door.kState.Welded) then
    
        // Make sure there is nothing obstructing door
        local blockingEnts = GetGamerules():GetEntities("Entity", -1, self:GetOrigin(), 1)
        
        // ...but we can't block ourselves
        table.removevalue(blockingEnts, self) 
        
        if(table.count(blockingEnts) == 0) then
            
            self:SetState(Door.kState.Close)
            
        else
        
            entity:GetTeam():TriggerAlert(kTechId.MarineAlertWeldingBlocked, self)
            
        end
            
    end
    
    return performedWelding
    
end

function Door:ComputeDamageOverride(damage, damageType)

    if damageType ~= kDamageType.Door then
        damage = 0
    end
    
    return damage, damageType

end

function Door:OnTakeDamage(damage, doer, point)

    //Print("Door taking %s damage (alive: %s)", ToString(damage), ToString(self:GetIsAlive()))
    
    LiveScriptActor.OnTakeDamage(self, damage, doer, point)
    
    // Locked doors become unlocked when damaged
    if self:GetIsAlive() and (self:GetState() == Door.kState.Locked) then
        self:SetState(Door.kState.Unlock)
    end
    
end

function Door:OnThink()

    LiveScriptActor.OnThink(self)
    
    // If any players are around, have door open if possible, otherwise close it
    local state = self:GetState()
    
    if self:GetIsAlive() and (state == Door.kState.Opened or state == Door.kState.Closed) then
    
        if (self.timeLastCommanderAction == 0) or (Shared.GetTime() > self.timeLastCommanderAction + 4) then
        
            local players = GetGamerules():GetAllPlayers()
            
            local desiredOpenState = false
            for index, player in ipairs(players) do
            
                local dist = (player:GetOrigin() - self:GetOrigin()):GetLength()
                if player:GetIsAlive() and player:GetIsVisible() and (dist < 4) then
                
                    desiredOpenState = true
                    break
                    
                end
                
            end
            
            if desiredOpenState and (self:GetState() == Door.kState.Closed) then
                self:SetState(Door.kState.Open)
            elseif not desiredOpenState and (self:GetState() == Door.kState.Opened) then
                self:SetState(Door.kState.Close)
            end
            
        end
        
    end
    
    self:SetNextThink(Door.kThinkTime)
    
end

function Door:OnAnimationComplete(animationName)

    // Opening => Open
    if (animationName == Door.kStateAnim[Door.kState.Open]) then
    
        self:SetState(Door.kState.Opened)
        
    // Closing => Closed
    elseif (animationName == Door.kStateAnim[Door.kState.Close]) then    
    
        self:SetState(Door.kState.Closed) 

    // Lock => Locked
    elseif (animationName == Door.kStateAnim[Door.kState.Lock]) then    
    
        self:SetState(Door.kState.Locked) 

    // Unlock => Unlocked
    elseif (animationName == Door.kStateAnim[Door.kState.Unlock]) then    
    
        self:SetState(Door.kState.Closed) 
        
    end
    
    LiveScriptActor.OnAnimationComplete(self, animationName)
    
end
