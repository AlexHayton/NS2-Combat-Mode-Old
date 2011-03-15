// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'Infestation' (LiveScriptActor)

Infestation.kMapName = "infestation"

Infestation.kEnergyCost = kGrowCost
Infestation.kInitialHealth = 50
Infestation.kMaxHealth = 500
Infestation.kGrowRate = .75
Infestation.kVerticalSize = 1.0

Infestation.kInitialRadius = .05

if Server then
    Script.Load("lua/Infestation_Server.lua")
end

local networkVars = 
{
    // 0 to kMaxRadius
    radius                  = "interpolated float",
    maxRadius               = "float",
    connected               = "boolean",
    fullyGrown              = "boolean",
}

function Infestation:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    self.health = Infestation.kInitialHealth
    self.maxHealth = Infestation.kMaxHealth
    self.maxRadius = kInfestationRadius
    
    // Set to true if it sustains other infestation (hive)
    self.generatorState = false
    
    self.connectedToHive = true
    
    // False when created, turns true once it has reached full radius
    // Doesn't need to be connected to hive until it has reached full radius
    self.fullyGrown = false
    
    // ids of other infestation nodes we're connected to
    self.connections = {}
    
    // Start visible
    self.radius = Infestation.kInitialRadius
    
    if (Client) then
        self.decal = Client.CreateRenderDecal()
        self.decal:SetMaterial("materials/infestation/infestation_decal.material")
    end
    
    self:SetPhysicsGroup(PhysicsGroup.InfestationGroup)
    
    self:SetUpdates(true)
    
end

function Infestation:OnDestroy()

    if Client then
        Client.DestroyRenderDecal( self.decal )
        self.decal = nil
    end

end

function Infestation:OnInit()

    LiveScriptActor.OnInit(self)
    
    self:SetAnimation("scale")

    if Server then    
        self:TriggerEffects("spawn")
    end
    
end

function Infestation:GetGeneratorState()
    return self.generatorState
end

function Infestation:ClearConnections()
    self.connections = {}
end

function Infestation:GetConnections()
    return self.connections
end

function Infestation:GetConnectedToHive()
    return self.connectedToHive
end

function Infestation:SetConnections(connections)
    table.copy(connections, self.connections)
end

function Infestation:GetRadius()
    return self.radius
end

function Infestation:SetMaxRadius(radius)
    self.maxRadius = radius
end

function Infestation:GetMaxRadius()
    return self.maxRadius
end

// Takes 0 to 1
function Infestation:SetRadiusPercent(percent)
    self.radius = Clamp(percent, 0, 1)*self:GetMaxRadius()
end

function Infestation:GetTechId()
    return kTechId.Infestation
end

function Infestation:GetIsSelectable()
    return false
end

function Infestation:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)
    
    // Update radius based on lifetime and health
    if Server then
        self:UpdateInfestation(deltaTime)
    end
    
    self:SetPoseParam("scale", self.radius * 2)

end

function Infestation:GetIsPointOnInfestation(point)

    local onInfestation = false
    
    // Check radius
    local radius = point:GetDistanceTo(self:GetOrigin())
    if radius <= self.radius then
    
        // Check dot product
        local toPoint = point - self:GetOrigin()
        local verticalProjection = math.abs( self:GetCoords().yAxis:DotProduct( toPoint ) )
        
        onInfestation = (verticalProjection < Infestation.kVerticalSize)
        
    end
    
    return onInfestation
   
end

if Client then

function Infestation:UpdateRenderModel()

    LiveScriptActor.UpdateRenderModel(self)
    
    if self.decal then
        self.decal:SetCoords( self:GetCoords() )
        self.decal:SetExtents( Vector(self.radius, Infestation.kVerticalSize, self.radius) )
    end
    
    //DebugLine(self:GetOrigin(), self:GetOrigin() + self:GetCoords().xAxis * self.radius, .1, 1, 0, 0, 1)
    //DebugLine(self:GetOrigin(), self:GetOrigin() + self:GetCoords().yAxis, .1, 0, 1, 0, 1)    
    //DebugLine(self:GetOrigin(), self:GetOrigin() + self:GetCoords().zAxis * self.radius, .1, 0, 0, 1, 1)
    
end

end

Shared.LinkClassToMap("Infestation", Infestation.kMapName, networkVars )