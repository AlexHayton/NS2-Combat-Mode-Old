// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Cyst.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// A cyst controls and spreads infestation
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Cyst' (Structure)

PrepareClassForMixin(Cyst, InfestationMixin)

Cyst.kMaxEncodedPathLength = 30
Cyst.kMapName = "cyst"
Cyst.kModelName = PrecacheAsset("models/alien/pustule/pustule.model")
Cyst.kOffModelName = PrecacheAsset("models/alien/pustule/pustule_off.model")

Cyst.kEnergyCost = 25
Cyst.kPointValue = 5
// how fast the impulse moves
Cyst.kImpulseSpeed = 8

Cyst.kThinkInterval = 1 
Cyst.kImpulseColor = Color(1,1,0)
Cyst.kImpulseLightIntensity = 8
Cyst.kImpulseLightRadius = 1

Cyst.kExtents = Vector(0.2, 0.1, 0.2)

// range at which we can be a parent
Cyst.kCystParentRange = kCystParentRange

// size of infestation patch
Cyst.kInfestationRadius = kInfestationRadius

local networkVars = {
    // the track from our parent to us.determines the direction to follow. Each point is encoded by two bytes, the first
    // encoding the length in cm and the second the height difference, in cm. The value is an 8-bit value in cm offset by +128.
    // maximum length of a string is 30 bytes, so using 3 gives at most 45 points in the path. Could probably make do with just 30 points.
    parentId = "entityid",
    parentTrackStart = "vector",
    parentTrackEnd = "vector",
    parentTrack1 = string.format("string (%d)", Cyst.kMaxEncodedPathLength+1),
    parentTrack2 = string.format("string (%d)", Cyst.kMaxEncodedPathLength+1),
    parentTrack3 = string.format("string (%d)", Cyst.kMaxEncodedPathLength+1),
        
    // when the last impulse was started. The impulse is inactive if the starttime + pathtime < now
    impulseStartTime = "float",

    // id of our owned infestation
    infestationId = "entityid",  
    
    // if we are connected. Note: do NOT use on the server side when calculating reconnects/disconnects,
    // as the random order of entity update means that you can't trust it to reflect the actual connect/disconnects
    // used on the client side by the ui to determine connection status for potently cyst building locations
    connected = "boolean",
}

if Server then
    Script.Load("lua/Cyst_Server.lua")
end

function Cyst:OnInit()

    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
    
    self.parentId = Entity.invalidId
 
    if Server then
    
        // start out as disconnected; wait for impulse to arrive
        self.connected = false
        
        // mark us as not having received an impulse
        self.lastImpulseReceived = -1000
        
        self.lastImpulseSent = Shared.GetTime() 
        self.nextUpdate = Shared.GetTime()
        self.impulseActive = false
        self.children = { }
        self.infestationId = Entity.invalidId
        
        // initalize impulse setup
        self.impulseStartTime = 0
        
    elseif Client then    
    
        // create the impulse light
        self.light = Client.CreateRenderLight()
        
        self.light:SetType( RenderLight.Type_Point )
        self.light:SetCastsShadows( false )

        self.lightCoords = CopyCoords(self:GetCoords())
        self.light:SetCoords( self.lightCoords )
        self.light:SetRadius( Cyst.kImpulseLightRadius )
        self.light:SetIntensity( Cyst.kImpulseLightIntensity ) 
        self.light:SetColor( Cyst.kImpulseColor )
            
        self.light:SetIsVisible(true) 

    end
    
    self:SetUpdates(true)
    
end

function Cyst:GetIsAlienStructure()
    return true
end

function Cyst:GetInfestationRadius()
    return Cyst.kInfestationRadius
end

function Cyst:GetCystParentRange()
    return Cyst.kCystParentRange
end

function Cyst:GetInfestation()
    return Shared.GetEntity(self.infestationId)
end        

/**
 * Note: On the server side, used GetIsActuallyConnected()!
 */
function Cyst:GetIsConnected() 
    return self.connected
end

function Cyst:GetDescription()
    local prePendText = ConditionalValue(self:GetIsConnected(), "", "Unconnected ")
    return prePendText .. Structure.GetDescription(self)
end

function Cyst:OnDestroy()

    if (Client) then
    
        if (self.light ~= nil) then
            Client.DestroyRenderLight(self.light)
        end
        
    end
    
    Structure.OnDestroy(self)
    
end

function Cyst:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SpawnInfestation()
    
    if Server then
        self.lastUpdateTime = Shared.GetTime()
    end
end


function Cyst:GetIsAlienStructure()
    return true
end


function Cyst:GetDeployAnimation()
    return ""
end

function Cyst:GetCanDoDamage()
    return false
end

function Cyst:GetEngagementPoint()
   // Structure:GetEngagementPoint requires a target attachment point on the model, which Cyst doesn't have right now,
   // so override to get rid of the console spam
    return LiveScriptActor.GetEngagementPoint(self) 
end

function Cyst:OnOverrideSpawnInfestation(infestation)
    infestation.maxRadius = kInfestationRadius 
    infestation:SetRadiusPercent(.2)
end

function Cyst:OnUpdate(deltaTime)

    PROFILE("Cyst:OnUpdate")
    
    Structure.OnUpdate(self, deltaTime)
    
    local point = nil
    local now = Shared.GetTime()
    
    if self.tracker == nil then
        self.tracker = self:CreateTracker()
    else
        // if we have a tracker, check if we need to restart it
        if self.impulseStartTime ~= self.tracker.startTime then
            // if we need to restart it, make sure it has the correct track (may change if we change parent)
            if self.trackData ~= self.parentTrack1 .. self.parentTrack2 .. self.parentTrack3 then
                self.tracker = self:CreateTracker()
            end  
            self.tracker:Restart(self.impulseStartTime)
        end
        
        // advance the tracker to the current time
        point = self.tracker:AdvanceTo(now)    
    end
    
    if Server then
        self:Update(point, deltaTime)
    else
        self.light:SetIsVisible(point ~= nil)
        if point then
            self.lightCoords.origin = point
            self.light:SetCoords(self.lightCoords)
        end
    end      

end

function Cyst:CreateTracker()
    
    PROFILE("Cyst:CreateTracker")
    if self.parentId ~= nil and self.parentId ~= Entity.invalidId then
        self.trackData = self.parentTrack1 .. self.parentTrack2 .. self.parentTrack3
        local track = TrackYZ():InitFromYZEncoding(self.parentTrackStart, self.parentTrackEnd, self.trackData)
        return TrackerYZ():Init(self.impulseStartTime, Cyst.kImpulseSpeed, track)
    end
    return nil
end


function Cyst:GetCystParent()
    local parent = nil
    if self.parentId and self.parentId ~= Entity.invalidId then
        parent = Shared.GetEntity(self.parentId)
    end
    return parent
end


// asking for a cystparent from the same location actually happens a fair amount,
// the cache will decrease the cpu required a lot
local cystParentCache = {}
// cache is valid for this much time
local cystParentCacheTimeout = 1
// use cache if less than this from last use
local cystParentCacheRadius = 0.1

/**
 * Returns a parent and the track from that parent, or nil if none found.
 */
function GetCystParentFromPoint(origin, normal)

    PROFILE("GetCystParentFromPoint")

    local now = Shared.GetTime()
    
    // implement a cache to help with cpu load. Only use on the Client side.
    if Client and cystParentCache.origin and (cystParentCache.origin - origin):GetLength() < cystParentCacheRadius then
        // The parent may not exist anymore on the Client.
        local parent = Shared.GetEntity(cystParentCache.parentId)
        if parent and (now - cystParentCache.timestamp < cystParentCacheTimeout) then
            return parent, cystParentCache.track
        end
    end

    local ents = GetSortedListOfPotentialParents(origin)
    
    for i,ent in ipairs(ents) do
        // must be either a built hive or an cyst with a connected infestation
        if ((ent:isa("Hive") and ent:GetIsBuilt()) or (ent.GetIsConnected and ent:GetIsConnected())) then
            local range = (origin - ent:GetOrigin()):GetLength() 
            if range < ent:GetCystParentRange() then
                // check if we have a track from the entity to origin
                local track = TrackYZ():CreateBetween(ent:GetOrigin(), ent:GetCoords().yAxis, origin, normal )
                if track then
                    cystParentCache.timestamp = now
                    cystParentCache.origin = origin
                    cystParentCache.parentId = ent:GetId() 
                    cystParentCache.track = track
                    return ent, track
                end
            end
        end
    end
    
    return nil, nil
end

/**
 * Return true if a connected cyst parent is availble at the given origin normal. 
 */
function GetCystParentAvailable(techId, origin, normal, commander)
    local parent, track = GetCystParentFromPoint(origin, normal)
    return parent ~= nil
end

/**
 * Returns a ghost-guide table for gui-use. 
 */
function GetCystGhostGuides(commander)
    local parent, track = commander:GetCystParentFromCursor()
    local result = {}
    if parent then
        result[parent] = parent:GetCystParentRange()
    end
    return result    
end

function GetIsPositionConnected(origin,normal)
    local parent, track = GetCystParentFromPoint(origin, normal)
    return parent ~= nil    
end

function GetSortedListOfPotentialParents(origin)
    
    function sortByDistance(ent1, ent2)
        return (ent1:GetOrigin() - origin):GetLength() < (ent2:GetOrigin() - origin):GetLength()
    end
    
    // first, check for hives
    local hives = GetEntitiesWithinRange("Hive", origin, kHiveCystParentRange)
    table.sort(hives, sortByDistance)
    
    // add in the cysts. We get all cysts here, but mini-cysts have a shorter parenting range (bug, should be filtered out)
    local cysts = GetEntitiesWithinRange("Cyst", origin, kCystParentRange)
    table.sort(cysts, sortByDistance)
    
    local parents = {}
    table.copy(hives, parents)
    table.copy(cysts, parents, true)
    
    return parents
    
end

function Cyst:GetCystModelName(connected)
    return ConditionalValue(connected, Cyst.kModelName, Cyst.kOffModelName)
end

Shared.LinkClassToMap("Cyst", Cyst.kMapName, networkVars)