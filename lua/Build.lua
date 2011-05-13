// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Build.lua
//
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)
//
// A request for an entity to build something.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Build' (Entity)

Build.kMapName = "build"

Build.networkVars =
{    
    buildType           = "enum kTechType",
    buildTechId         = "integer",
    buildLocation       = "vector",
    buildOrientation    = "float",
    buildProgress       = "float"
}

function Build:OnCreate()
    self.buildType = Build.kBuildType
    self.buildTechId = -1
    self.buildLocation = Vector(0, 0, 0)
    self.buildOrientation = 0 
    self.buildProgress = 0

    self.buildPlayer = Entity.invalidId 
end

function Build:Initialize(buildType, buildTechId, position, orientation)

    self.buildType = buildType
    self.buildTechId = buildTechId
    
    if orientation then
        self.buildOrientation = orientation
    end
    
    if position then
        self.buildLocation = position    
    end
    
end

function Build:GetBuildType()
    return self.buildType
end

function Build:SetBuildType(buildType)
    self.buildType = buildType
end

function Build:GetTechId()
    return self.buildTechId
end

function Build:GetLocation()

    local location = self.buildLocation        
    return location
    
end

function Build:SetLocation(position)
    if self.buildLocation == nil then
        self.buildLocation = Vector()
    end
    self.buildLocation = position
end

function Build:GetOrientation()
    return self.buildOrientation
end

function Build:GetBuildTime()
    local owner = Shared.GetEntity(self.buildPlayer)
    local buildNode = owner:GetTeam():GetTechTree():GetTechNode(self.buildTechId)
    
    if (buildNode ~= nil) then
        return buildNode.time
    end
    
    return 0
end

function Build:_SetBuildProgress(progress)
    progress = math.max(math.min(progress, 1), 0)
    
    if(progress ~= self.buildProgress) then
    
        self.buildProgress = progress
        
        local owner = Shared.GetEntity(self.buildPlayer)
        
        local buildNode = owner:GetTeam():GetTechTree():GetTechNode(self.buildTechId)
        if buildNode ~= nil then
        
            buildNode:SetResearchProgress(self.buildProgress)
            
            owner:GetTeam():GetTechTree():SetTechNodeChanged(buildNode)            
        end
        
    end
end

function Build:GetIsComplete ()
    return (self.buildProgress == 1)
end

function Build:UpdateProgress ()
  local timePassed = Shared.GetTime() - self.timeBuildStarted
        
  // Adjust for metabolize effects
  // $AS FIXME: I do not like this here REMOVE!!!!
  if self:GetTeam():GetTeamType() == kAlienTeamType then
    timePassed = GetAlienEvolveResearchTime(timePassed, self)
  end
        
  local researchTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, self.researchTime)
  self:_SetBuildProgress( timePassed / researchTime )
end

function CreateBuild(buildType, buildTechId, position, orientation)

    local newBuild = CreateEntity(Build.kMapName)
       
    newBuild:Initialize(buildType, buildTechId, position, tonumber(orientation))
    
    return newBuild
    
end

Shared.LinkClassToMap( "Build", Build.kMapName, Build.networkVars )