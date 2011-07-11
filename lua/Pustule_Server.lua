//=============================================================================
//
// lua\Pustule_Server.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se)

// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//============================================================================

Pustule.kThinkTime = 1

// How long we can be without a confirmation impulse before we start shrinking
Pustule.kMaxTimeWithoutImpulse = 30

// minimum time between impulses (used to kill unnecessary crosslink impulses)
Pustule.kMinTimeBetweenImpulses = 1 // 15

// size of infestation when not "in supply"
Pustule.kMinInfestationSize = 0.3
// size of infestation when "in supply"
Pustule.kNormalInfestationSize = kInfestationRadius

//
// Create track from dropped points
//
function Pustule:InitWithDrop(parent, dropPoints)
    return self:InitWithTrack(parent, TrackYZ():InitFromDropData(parent:GetOrigin(), self:GetOrigin(), dropPoints))
end

//
// Track already created
//
function Pustule:InitWithTrack(parent, track)
    self:SetParent(parent, track)

    // start out as disconnected; wait for impulse to arrive
    self.lastImpulseReceived = Shared.GetTime() + Pustule.kMaxTimeWithoutImpulse - 1
    
    self.lastImpulseSent = Shared.GetTime() 
    self.nextUpdate = Shared.GetTime()
    self.impulseActive = false
    self.children = { }
    self.infestationId = Entity.invalidId
    
    // initalize impulse setup
    self.impulseStartTime = 0
    return self
end

function Pustule:SetParent(parent, track)
    self.parentId = parent:GetId()
    self.track = track
    self.parentTrackStart = track.trackStart
    self.parentTrackEnd = track.trackEnd
    local pl = Pustule.kMaxEncodedPathLength
    local path = track:EncodeYZ()
    self.parentTrack1 = string.sub(path,1,pl)
    self.parentTrack2 = string.sub(path,1 + pl, 2*pl)
    self.parentTrack3 = string.sub(path,1 + 2*pl, 3*pl)
end


function Pustule:Update(point, deltaTime)
    
    if not self.constructionComplete or not self:GetIsAlive() then
        return 
    end
    
    local now = Shared.GetTime()
   
    if now > self.nextUpdate then
        local infestation = self:GetInfestation()
        if infestation == nil then
            // this will rebuild the infestation
            self.infestationId = Entity.invalidId
        end
        // if we haven't received an impulse for too long seconds, we start shrinking
        if now - self.lastImpulseReceived > Pustule.kMaxTimeWithoutImpulse then
            // the infestation will handle its own shrinking.
            if infestation and infestation.connectedToHive then
                //Log("%s: disconnected", self)
                infestation.connectedToHive = false
            end
        else
           // .. and grow again
            if infestation then
                if not infestation.connectedToHive then
                    //Log("%s: reconnected", self)
                    infestation.connectedToHive = true
                end
            else
                //Log("%s: recreating infest ", self)
                self:UpdateInfestation()
                self:GetInfestation().connectedToHive = true
            end
        end
        
        if self.impulseActive and point == nil then
            self.lastImpulseReceived = now
            self.impulseActive = false
        end
        
        // if we have received an impulse but hasn't sent one out yet, send one
        if self.lastImpulseReceived - self.lastImpulseSent > Pustule.kMinTimeBetweenImpulses then
            self:FireImpulses(now)
            self.lastImpulseSent = now
        end
        // avoid clumping; don't use now when calculating next think time (large kThinkTime)
        self.nextUpdate = self.nextUpdate + Pustule.kThinkTime
    end
    
end

function Pustule:GetIsCrosslinkPossible(peer)
    // check if we can link to the given peer
    // first, make sure that we can be the source of the crosslink
    if not self:GetIsConnected() then
        return false
    end
    // then make sure that we are not the parent (directly or indirectly) of the peer
    local p = peer
    while p and p ~= self do
        p = p.parent
    end
    return p == nil
end

function Pustule:CreateCrosslink(peer, track)
    //Log("%s: Activate crosslink from to %s", self, peer)
    // right, make the peer our child and tell it to make us its parent via the given track
    self:AddChildPustule(peer)
    peer:ChangeParent(self, track)
end


function Pustule:ChangeParent(newParent, track)
    local oldParent = Shared.GetEntity(self.parentId)
    //Log("%s:Changing parent from %s to %s", self, oldParent, newParent)
    local oldTrack = self.track
    self.children[""..newParent:GetId()] = nil
    self:SetParent(newParent, track)

    if oldParent then
        oldTrack:Reverse()
        self:AddChildPustule(oldParent)
        oldParent:ChangeParent(self, oldTrack)
    end 
end

function Pustule:FireImpulses(now)
    local removals = {}
    for key,id in pairs(self.children) do
        local child = Shared.GetEntity(id)
        if child == nil then
            removals[key] = true
        else
            // we ask the children to trigger the impulse to themselves
            child:TriggerImpulse(now)
        end
    end
    for key,_ in pairs(removals) do
        self.children[key] = nil
    end
end

/**
 * Trigger an impulse to us along the track. 
 */
function Pustule:TriggerImpulse(now)
    if self.impulseActive then
        //Log("already driving impulse")
    else
        self.impulseStartTime = now
        self.impulseActive = true   
    end
end

function Pustule:AddChildPustule(child)
    // children can die; tragic; so only keep the id around
    self.children["" .. child:GetId()] = child:GetId()
end

function Pustule:OverrideTechTreeAction(techNode, position, orientation, commander, trace)
    if techNode.techId == kTechId.Crosslink then
        // the trace must have hit another pustule inside range
        Log("te %s/%s", trace.entity, trace.entity and trace.entity:isa("Pustule"))
        if trace.entity and trace.entity:isa("Pustule") then
            Log("ok-1");
            if self:GetIsCrosslinkPossible(trace.entity) then
                local sCoords = self:GetCoords()
                local tCoords = trace.entity:GetCoords()
                local track = TrackYZ():CreateBetween(sCoords.origin, sCoords.yAxis, tCoords.origin, tCoords.yAxis)
                Log("tr")
                if track then
                    self:CreateCrosslink(trace.entity, track)
                end
            end       
        end
    end
end
