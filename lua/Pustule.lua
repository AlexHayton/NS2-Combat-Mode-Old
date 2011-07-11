// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Pustule.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// An pustule controls and spreads infestation
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Pustule' (Structure)

PrepareClassForMixin(Pustule, InfestationMixin)

Pustule.kMaxEncodedPathLength = 30
Pustule.kMapName = "pustule"
Pustule.kModelName = PrecacheAsset("models/alien/pustule/pustule.model")

Pustule.kEnergyCost = 25
Pustule.kPointValue = 5
// how fast the impulse moves
Pustule.kImpulseSpeed = 4

Pustule.kThinkInterval = 1 
Pustule.kImpulseColor = Color(1,1,0)
Pustule.kImpulseLightIntensity = 8
Pustule.kImpulseLightRadius = 1

Pustule.kExtents = Vector(0.2, 0.1, 0.2)

Pustule.kPustuleRadius = kPustuleRadius

local networkVars = {
    // the track from our parent to us.determines the direction to follow. Each point is encoded by two bytes, the first
    // encoding the length in cm and the second the height difference, in cm. The value is an 8-bit value in cm offset by +128.
    // maximum length of a string is 30 bytes, so using 3 gives at most 45 points in the path. Could probably make do with just 30 points.
    parentTrackStart = "vector",
    parentTrackEnd = "vector",
    parentTrack1 = string.format("string (%d)", Pustule.kMaxEncodedPathLength+1),
    parentTrack2 = string.format("string (%d)", Pustule.kMaxEncodedPathLength+1),
    parentTrack3 = string.format("string (%d)", Pustule.kMaxEncodedPathLength+1),
        
    // when the last impulse was started. The impulse is inactive if the startime + pathtime < now
    impulseStartTime = "float",

    // id of our owned infestation
    infestationId = "entityid",  
}

if Server then
    Script.Load("lua/Pustule_Server.lua")
end

function Pustule:OnInit()
    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
 
    if Client then    
        // create the impulse light
        self.light = Client.CreateRenderLight()
        
        self.light:SetType( RenderLight.Type_Point )
        self.light:SetCastsShadows( false )

        self.lightCoords = CopyCoords(self:GetCoords())
        self.light:SetCoords( self.lightCoords )
        self.light:SetRadius( Pustule.kImpulseLightRadius )
        self.light:SetIntensity( Pustule.kImpulseLightIntensity ) 
        self.light:SetColor( Pustule.kImpulseColor )
            
        self.light:SetIsVisible(true) 

    end 
end

function Pustule:GetIsAlienStructure()
    return true
end

function Pustule:GetInfestationRadius()
    return Pustule.kPustuleRadius
end

function Pustule:GetInfestation()
    return Shared.GetEntity(self.infestationId)
end        

function Pustule:GetIsConnected() 
    local infestation = self:GetInfestation()
    return infestation and infestation.connectedToHive
end

function Pustule:OnDestroy()

    // Get all our connections, and have them reconnect
    local inf = self:GetInfestation()    
    if Server and inf then
    
        // Look for any pustules that had us a parent, and re-parent them if possible
        for index, pustule in ipairs(GetEntitiesForTeam("Pustule", self:GetTeamNumber())) do
            
            if pustule:GetId() ~= self:GetId() and pustule.parentId == self:GetId() then
            
                // TODO: Find and set new parent for pustule
                
            end
    
            /*local connections = Server.infestationMap:GetConnections(inf)
            for index, infestation do
            
                // Use radius from host entity 
                local radius = infestation:GetMaxRadius()
                
            end*/
        end
    end

    Structure.OnDestroy(self)
    
    if inf then
        inf.connectedToHive = false
    end
    if (Client) then
    
        if (self.light ~= nil) then
            Client.DestroyRenderLight(self.light)
        end
        
    end
end

function Pustule:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SpawnInfestation()
    
    if Server then
        local now = Shared.GetTime()
        self.lastUpdateTime = now
        self.nextDriveTime = now
    end
end


function Pustule:GetIsAlienStructure()
    return true
end


function Pustule:GetDeployAnimation()
    return ""
end

function Pustule:GetCanDoDamage()
    return false
end

function Pustule:GetEngagementPoint()
   // Structure:GetEngagementPoint requires a target attachment point on the model, which pustule doesn't have right now,
   // so override to get rid of the console spam
    return LiveScriptActor.GetEngagementPoint(self) 
end

function Pustule:OnOverrideSpawnInfestation(infestation)
    infestation.maxRadius = self:GetInfestationRadius()
    infestation:SetGrowthRateScalar(5)
end

function Pustule:OnUpdate(deltaTime)
    // Print("%s: OnUpdate", ToString(self))
    PROFILE("Pustule:OnUpdate")
    
    Structure.OnUpdate(self, deltaTime)
    
    local point = nil
    local now = Shared.GetTime()
    
    if self.tracker == nil then
        self.tracker = self:CreateTracker()
    else
        // if we have a tracker, check if we need to restart it
        if self.impulseStartTime ~= self.tracker.starTime then
            // if we need to restart it, make sure it has the correct track (may change if we change parent)
            if self.trackData ~= self.parentTrack1 .. self.parentTrack2 .. self.parentTrack3 then
                self.tracker = self:CreateTracker()
            end  
            self.tracker:Restart(self.impulseStartTime)
        end
    end
    // advance the tracker to the current time
    point = self.tracker:AdvanceTo(now)    
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

function Pustule:CreateTracker()
    self.trackData = self.parentTrack1 .. self.parentTrack2 .. self.parentTrack3
    local track = TrackYZ():InitFromYZEncoding(self.parentTrackStart, self.parentTrackEnd, self.trackData)
    return TrackerYZ():Init(self.impulseStartTime, Pustule.kImpulseSpeed, track)
end

function GetPustuleParent(origin, teamNumber)

    // find closest possible pustule parent. This is hives inside 26m and pustules inside 20m
    local pustuleParent = nil
    
    local ents = GetEntitiesWithinRange("Hive", origin, kHiveInfestRange)
    
    // Includes mini gorge pustules
    table.addtable(GetEntitiesWithinRange("Pustule", origin, kPustuleRadius), ents) 
    
    for i,ent in ipairs(ents) do
        // must be either a hive or an pustule with a connected infestation
        if ent:GetTeamNumber() == teamNumber and (ent:isa("Hive") or ent:GetIsConnected()) then
            local range = (origin - ent:GetOrigin()):GetLength() 
            if not pustuleParent or currentRange > range then
                pustuleParent = ent 
                currentRange = range
            end
        end
    end
    
    return pustuleParent

end

function CreatePustule(commander, targetPoint, normal, createMini) 
    // Find parent pustule or hive
    local pustuleParent = GetPustuleParent(targetPoint, commander:GetTeamNumber())
    if pustuleParent then
        local coords = pustuleParent:GetCoords()
        local track = TrackYZ():CreateBetween(coords.origin, coords.yAxis, targetPoint, normal)
        if track then
        
            local pustule = nil
            if commander.AttemptToBuild then                               
                pustule = CreateEntityForCommander(kTechId.Pustule, track.trackEnd, commander)
                success = true
            else
                pustule = CreateEntity(ConditionalValue(createMini, MiniPustule.kMapName, Pustule.kMapName), track.trackEnd, commander:GetTeamNumber())
                success = true
            end
            
            if pustule then
                pustule:InitWithTrack(pustuleParent, track)
                pustuleParent:AddChildPustule(pustule)
                return pustule
            end
        end      
    end
    
    return nil
end

Shared.LinkClassToMap("Pustule", Pustule.kMapName, networkVars)