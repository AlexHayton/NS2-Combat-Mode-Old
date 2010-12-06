// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'Door' (LiveScriptActor)

Door.kMapName = "door"

Door.kModelName = PrecacheAsset("models/misc/door/door.model")
Door.kInoperableSound = PrecacheAsset("sound/ns2.fev/common/door_inoperable")
Door.kOpenSound = PrecacheAsset("sound/ns2.fev/common/door_open")
Door.kCloseSound = PrecacheAsset("sound/ns2.fev/common/door_close")
Door.kWeldedSound = PrecacheAsset("sound/ns2.fev/common/door_welded")
Door.kLockSound = PrecacheAsset("sound/ns2.fev/common/door_lock")
Door.kUnlockSound = PrecacheAsset("sound/ns2.fev/common/door_unlock")

// Open means it's opening, close means it's closing
Door.kState = enum( {'Opened', 'Open', 'Closed', 'Close', 'Welded', 'Lock', 'Locked', 'Unlock', 'Unlocked', 'LockDestroyed'} )
Door.kStateAnim = {'opened', 'open', 'closed', 'close', 'welded', 'lock', 'locked', 'unlock', 'unlocked', ''}
Door.kStateSound = {'', Door.kOpenSound, '', Door.kCloseSound, Door.kWeldedSound, Door.kLockSound, '', Door.kUnlockSound, '', ''}

Door.kDefaultWeldTime = 15
Door.kDefaultHealth = 500
Door.kWeldPointValue = 3
Door.kThinkTime = .3

if (Server) then
    Script.Load("lua/Door_Server.lua")
end

local networkVars   = {

    // Saved health we restore to on reset
    weldHealth      = "integer (0 to 2000)",

    // Amount door has been welded so far
    time            = "float",
    
    // Saved weld time we restore to on reset
    weldTime        = "float",
    
    // So door doesn't act on its own accord too soon after Commander affects it
    timeLastCommanderAction = "float",
    
    // Stores current state (kState )
    state           = string.format("integer (1 to %d)", Door.kState.LockDestroyed)

}

function Door:OnInit()

    LiveScriptActor.OnInit(self)
    
    if (Server) then
    
        self:SetModel(Door.kModelName)  
      
        self:SetIsVisible(true)
        
        self:SetPhysicsType(Actor.PhysicsType.Kinematic)
        
        self:SetPhysicsGroup(PhysicsGroup.CommanderUnitGroup)
        
        self:SetNextThink(Door.kThinkTime)
        
    end
    
    // In case door isn't placed in map
    if (self.weldHealth == nil) then
    
        self.weldHealth = Door.kDefaultHealth
        
    end
    
    self.health = self.weldHealth
    
    if (self.weldTime == nil) then
    
        self.weldTime = Door.kDefaultWeldTime
        
    end
    
    self.time = 0
    
    self.timeLastCommanderAction = 0
    
    self.alive = true
    
    self:SetState(Door.kState.Closed)   

end

function Door:GetTechId()
    return kTechId.Door
end

// Only hackable by marine commander
function Door:PerformActivation(techId, position, commander)

    local success = nil
    local state = self:GetState()

    // Set success to false if action specifically not allowed
    if techId == kTechId.DoorOpen then
    
        if (state == Door.kState.Closed) then
    
            self:SetState(Door.kState.Open, commander)
            success = true
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorClose then
    
        if state == Door.kState.Opened then
        
            self:SetState(Door.kState.Close, commander)
            success = true
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorLock then
    
        if state == Door.kState.Closed then
        
            self:SetState(Door.kState.Lock, commander)
            success = true
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorUnlock then
    
        if state == Door.kState.Locked then
        
            self:SetState(Door.kState.Unlock, commander)
            success = true
            
        else
            success = false            
        end
        
    end
    
    if success == false then
        self:PlaySound(Door.kInoperableSound)
    else
        self.timeLastCommanderAction = Shared.GetTime()
    end
    
    return success

end

function Door:GetDescription()

    local doorName = LookupTechData(self:GetTechId(), kTechDataDisplayName, "<no description>")
    local doorDescription = doorName
    
    local state = self:GetState()
    
    if state == Door.kState.Locked then
        doorDescription = string.format("Locked %s", doorName)
    elseif state == Door.kState.LockDestroyed then
        doorDescription = string.format("Destroyed %s", doorName)
    end
    
    return doorDescription
    
end

function Door:GetTechAllowed(techId, techNode, player)

    local state = self:GetState()
    
    if techId == kTechId.DoorOpen then
        return state == Door.kState.Closed
    elseif techId == kTechId.DoorClose then
        return state == Door.kState.Opened
    elseif techId == kTechId.DoorLock then
        return (state ~= Door.kState.Locked) and (state ~= Door.kState.LockDestroyed)
    elseif techId == kTechId.DoorUnlock then
        return state == Door.kState.Locked
    end

    return true

end

function Door:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then   
    
        return  {   kTechId.DoorOpen, kTechId.DoorClose, kTechId.None, kTechId.None,
                    kTechId.DoorLock, kTechId.DoorUnlock, kTechId.None, kTechId.None }
                    
    end
    
    return nil
    
end

// Set door state and play animation. If commander parameter plassed, 
// play door sound for that player as well.
function Door:SetState(state, commander)

    if(self.state ~= state) then
    
        self.state = state
        
        self:SetAnimation(Door.kStateAnim[ self.state ])
        
        if Server then
        
            local sound = Door.kStateSound[ self.state ]
            if sound ~= "" then
            
                self:PlaySound(sound)
                
                if commander ~= nil then
                    Server.PlayPrivateSound(commander, sound, nil, 1.0, commander:GetOrigin())
                end
                
            end
            
        end
        
    end
    
end

function Door:GetState()
    return self.state
end

function Door:GetWeldTime()
    return self.weldTime
end

function Door:GetMaxHealth()
    return self.weldHealth
end

// If door is ready to be welded by buildbot right now, and in the future
function Door:GetCanBeWelded(entity)

    local canBeWeldedNow = (self.state == Door.kState.Closed)
    local canBeWeldedFuture = (self.state ~= Door.kState.Welded)
    
    return canBeWeldedNow, canBeWeldedFuture
    
end

// If we've been destroyed or not (only after we've been welded and smashed)
function Door:GetIsAlive()
    return self.alive
end

function Door:GetCanBeUsed(player)
    return true
end

function Door:OnUse(player, elapsedTime, useAttachPoint)

    local state = self:GetState()
    if state == Door.kState.Welded or state == Door.kState.Locked then
        self:PlaySound(Door.kInoperableSound)
    end
    
end

Shared.LinkClassToMap("Door", Door.kMapName, networkVars)
