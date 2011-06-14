// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\BuildingMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

BuildingMixin = { }
BuildingMixin.type = "Builds"

// Snap structures within this range to attach points.
BuildingMixin.kStructureSnapRadius = 4

function BuildingMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "BuildingMixin expects the class to have network fields")
    
    local addNetworkFields =
    {        
        buildPosition       = "vector",
        buildTechId         = "enum kTechId"
        buildType           = "enum kTechType"
        timeBuildStarted    = "float" 
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function BuildingMixin:__initmixin()    
        
    self.buildPosition = Vector(0, 0, 0)
    
    self.buildType = kTechId.None
    
    self.buildTechId = kTechId.None
    
    self.timeBuildStarted = 0
        
    self.builds = { }
    
end

function BuildingMixin:GetHasBuild()
    return self:GetCurrentBuild() ~= nil
end

function BuildingMixin:GetNumBuilds()
    return table.count(self.builds)
end

function BuildingMixin:_OverrideBuild(build)
    if self.OnOverrideBuild then
        self:OnOverrideBuild(build)
    end    
end

function BuildingMixin:CreateBuild(buildType, builderId, builderOrigin, orientation, clearExisting, insertFirst, buildPlayerId)
   
    ASSERT(type(buildType) == "number")
    ASSERT(type(builderId) == "number")
    ASSERT(type(buildPlayerId) == "number")        
    
    local build = CreateBuild(buildType, builderId, builderOrigin, orientation, buildPlayerId)
    
    self:_OverrideBuild(build)
    
    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end
    
    self:_SetBuild(build, clearExisting, insertFirst)
    
    return build:GetType()

end



function BuildingMixin:ClearBuilds()

    if table.count(self.builds) > 0 then
    
        self:_DestroyBuilds()
        self:_BuildChanged()
        
    end
    
end

function BuildingMixin:_DestroyBuilds()
        
    local first = true
        
    for index, buildEntId in ipairs(self.builds) do
    
        local buildEntId = Shared.GetEntity(buildEntId)
        ASSERT(buildEntId ~= nil)
        
        if first then
        
            if self.OnDestroyCurrentBuild and buildEntId ~= nil then
                self:OnDestroyCurrentBuild(buildEntId)
            end
            first = false
            
        end
        
        DestroyEntity(buildEntId)            
        
    end
    
    table.clear(self.builds)

end

function BuildingMixin:_SetBuild(build, clearExisting, insertFirst)

    if clearExisting then
        self:ClearBuilds()
    end
        
    if(insertFirst) then
        table.insert(self.builds, 1, build:GetId())
    else    
        table.insert(self.builds, build:GetId())
    end        
            
    self:_BuildChanged()    
end

function BuildingMixin:GetCurrentBuild()

    local currentBuild = nil
    
    if(self.builds and table.maxn(self.builds) > 0) then
        local buildId = self.builds[1] 
        currentBuild = Shared.GetEntity(buildId)
        ASSERT(currentBuild ~= nil)
    end

    return currentBuild
    
end

function BuildingMixin:ClearCurrentBuild()

    local currentBuild = self:GetCurrentBuild()
    if currentBuild then
    
        DestroyEntity(currentOrder)
        
        table.remove(self.builds, 1)
        
    end
    
    self:_BuildChanged()
    
end

function BuildingMixin:OnOverrideResearchComplete()
    local currentBuild = self:GetCurrentBuild()
    
    if self:GetTeam().OnResearchComplete then
        self:GetTeam():OnResearchComplete(self, currentBuild:GetTechId())
    end
end

function BuildingMixin:OnOverrideUpgradeComplete()
    local currentBuild = self:GetCurrentBuild()
    
    // Right now I think upgrades use the same path as research
    if self:GetTeam().OnResearchComplete then
        self:GetTeam():OnResearchComplete(self, currentBuild:GetTechId())
    end
end

function BuildingMixin:OnOverrideManufactureComplete()
    local currentBuild = self:GetCurrentBuild()       
    
    local mapName = LookupTechData(currentBuild:GetTechId(), kTechDataMapName)
    local buildEntity = CreateEntity(mapName, currentBuild:GetLocation(), structure:GetTeamNumber())
                 
    local owner = Shared.GetEntity(self.buildPlayerId)
    buildEntity:SetOwner(owner)
    
    if self:GetTeam().OnManufactureComplete then
        self:GetTeam():OnManufactureComplete(self, currentBuild:GetTechId(), buildEntity:GetId())
    end
end

function BuildingMixin:OnOverrideEnergyBuildComplete()
    local currentBuild = self:GetCurrentBuild()
        
    local mapName = LookupTechData(currentBuild:GetTechId(), kTechDataMapName)
    local buildEntity = CreateEntity(mapName, currentBuild:GetLocation(), structure:GetTeamNumber())            
    
    local owner = Shared.GetEntity(self.buildPlayerId)
    energyBuildEntity:SetOwner(owner)
    
    if self:GetTeam().OnEnergyBuildComplete then
        self:GetTeam():OnEnergyBuildComplete(self, currentBuild:GetTechId(), buildEntity:GetId())
    end
end

function BuildingMixin:OnOverrideBuildComplete()
    local currentBuild = self:GetCurrentBuild()             
    
    if self:GetTeam().OnBuildComplete then
        self:GetTeam():OnBuildComplete(self, currentBuild:GetTechId(), currentBuild:GetBuildEntity())
    end
end

function BuildingMixin:CompletedCurrentBuild()

    local currentBuild = self:GetCurrentBuild()
    if currentBuild then
        local buildType = currentBuld:GetType()
        if (buildType == kTechType.Research) then
            self:OnOverrideResearchComplete()
        elseif (buildType == kTechType.Upgrade) then
            self:OnOverrideUpgradeComplete()
        elseif (buildType == kTechType.Manufacture) then
            self:OnOverrideManufactureComplete()
        elseif (buildType == kTechType.Build) then
            self:OnOverrideBuildComplete()
        elseif (buildType == kTechType.EnergyBuild) then
            self:OnOverrideEnergyBuildComplete()   
        end
        
        DestroyEntity(currentBuild)
        
        table.remove(self.builds, 1)
        
    end
    
    self:_BuildChanged()
    
end

function BuildingMixin:_BuildChanged()
    
    if self:GetHasBuild() then    
        local build = self:GetCurrentBuild()
        local buildLocation = build:GetLocation()
        self.buildPosition = Vector(buildLocation)
        self.buildType = build:GetType()        
    end
    
    if self.OnBuildChanged then
        self:OnBuildChanged()
    end
    
end

function BuildingMixin:UpdateBuilds () 
    if (self._overrideBuildUpdate)
        self._overrideBuildUpdate()
    end
    
    self:_UpdateBuild()
end

function BuildingMixin:_UpdateBuild()
    local currentBuild = self:GetCurrentBuild()
    
    if (self:GetIsBuilt() and (currentBuild ~= nil)) then           
      currentBuild:UpdateProgress()
      
      if (currentBuild:GetIsComplete()) then
        self:CompletedCurrentBuild()
      end
    end
end