// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechNode.lua
//
// Represents one item in the tech tree. They also characterize the behavior when triggering that kind of action.
// Tech nodes are of the following types:
//
//   Order (Move, Default) - No cost, requires positional
//   Research (eg, research siege) - Costs team resources, queued from a structure, non-positional
//   Upgrade (eg, upgrade command station) - Like research but can be performed more than once
//   Action (eg, medpack, drifter flare) - Optionally costs energy, optional position, optionally must be researched
//   Buy (eg, create siege cannon from factory, player buy weapon) - Costs resources, position implied from buyer or originating structure (unless targeted). Requires target for commander.
//   Build (eg, build structure from drifter) - Costs team resources, requires position
//   EnergyBuild (add to manufacture queue, create unit when done) - Costs energy, takes time to complete, no position (MACs, Drifters). Only use for AI units that don't need a position.
//   Manufacture (add to manufacture queue, create unit when done) - Costs resources, takes time to complete, no position (ARCs)
//   Activation (eg, deploy/undeploy siege) - Optionally costs energy, optional position
//   Menu - No cost, no position
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/TechData.lua")

class 'TechNode'
TechNode.kMapName = "technode"

TechNode.kTechNodeVars =
{

    // Unique id
    techId              = string.format("integer (0 to %d)", kTechIdMax),
    
    // Type of tech
    techType            = "enum kTechType",
    
    // Tech nodes that are required to build or research (or kTechId.None)
    prereq1             = string.format("integer (0 to %d)", kTechIdMax),
    prereq2             = string.format("integer (0 to %d)", kTechIdMax),
    
    // This node is an upgrade, addition, evolution or add-on to another node
    // This includes an alien upgrade for a specific lifeform or an alternate
    // ammo upgrade for a weapon
    addOnTechId         = string.format("integer (0 to %d)", kTechIdMax),

    // Resource costs (team resources, individual resources or energy depending on type)
    cost                = "integer (0 to 125)",

    // If tech node can be built/researched/used. Requires prereqs to be met and for 
    // research, means that it hasn't already been researched and that it's not
    // in progress. Computed when structures are built or killed or when
    // global research starts or stops (TechTree:ComputeAvailability()).
    available           = "boolean",

    // Seconds to complete research or upgrade. Structure build time is kept in Structure.buildTime (Server).
    time                = "integer (0 to 360)",   
    
    // 0-1 research progress. This is non-authoritative and set/duplicated from Structure:SetResearchProgress()
    // so player buy menus can display progress.
    researchProgress    = "float",

    // True after being researched.
    researched          = "boolean",
    
    // True for research in progress (not upgrades)
    researching         = "boolean",
    
    // True if this is tech node represents a structure that is built or if the tech is satisfied (Hive, TwoCommandStations, etc.)
    hasTech             = "boolean",
    
    // If true, tech tree activity requires ghost, otherwise it will execute at target location's position (research, most actions)
    requiresTarget      = "boolean",
    
    // For some abilities, they look and feel like "build" actions but they cost energy
    energyBuild         = "boolean",

}

function TechNode:Initialize(techId, techType, prereq1, prereq2)

    if(techId == nil) then
        Print("TechNode:Initialize(%s, %s, %s, %s): techId is nil", tostring(techId), tostring(techType), tostring(prereq1), tostring(prereq2))
    end
    
    self.techId = techId
    
    self.techType = techType
    
    if prereq1 == nil then
        prereq1 = kTechId.None
    end
    
    if prereq2 == nil then
        prereq2 = kTechId.None
    end
    
    self.prereq1 = prereq1
    self.prereq2 = prereq2
    
    self.addOnTechId = kTechId.None
    
    self.cost = LookupTechData(self.techId, kTechDataCostKey, 0)
    
    self.available = false
    
    self.time = 0
    
    self.researchProgress = 0
    
    self.researched = false
    
    self.researching = false
    
    self.hasTech = false
    
    self.requiresTarget = false
    
    self.energyBuild = false
        
end

function TechNode:GetResearched()
    return self.researched
end

function TechNode:GetIsOrder()
    return self.techType == kTechType.Order
end

function TechNode:GetIsResearch()
    return self.techType == kTechType.Research
end

function TechNode:GetIsUpgrade()
    return self.techType == kTechType.Upgrade
end

// Returns: 0 = team resources, 1 = individual resources, 2 = energy (from CommanderUI_MenuButtonTooltip). Returns nil if none required.
function TechNode:GetResourceType()

    // TeamResources
    if self.techType == kTechType.Research or self.techType == kTechType.Upgrade or self.techType == kTechType.Build then
        return 0
    // Resources
    elseif self.techType == kTechType.Buy or self.techType == kTechType.Manufacture then
        return 1
    // Energy
    elseif self.techType == kTechType.Action or self.techType == kTechType.EnergyBuild or self.techType == kTechType.Activation then
        return 2
    end
    
    return nil
    
end

function TechNode:GetIsAction()
    return self.techType == kTechType.Action
end

function TechNode:GetIsBuy()
    return self.techType == kTechType.Buy
end

function TechNode:GetAddOnTechId()
    return self.addOnTechId
end

function TechNode:GetIsBuild()
    return self.techType == kTechType.Build
end

function TechNode:GetIsActivation()
    return self.techType == kTechType.Activation
end

function TechNode:GetIsMenu()
    return self.techType == kTechType.Menu
end

function TechNode:GetRequiresTarget()
    return self.requiresTarget
end

function TechNode:GetIsEnergyBuild()
    return self.energyBuild
end

function TechNode:GetTechId()
    return self.techId
end

function TechNode:GetPrereq1()
    return self.prereq1
end

function TechNode:GetPrereq2()
    return self.prereq2
end

function TechNode:GetCost()
    return self.cost
end

// Nodes that have been researched and will never be allowed again this game
function TechNode:GetIsForeverUnavailable()

    return (self.techType == kTechType.Research) and self.researched

end

function TechNode:SetResearchProgress(progress)
    self.researchProgress = progress
end

function TechNode:GetAvailable()
    return self.available
end

function TechNode:GetCanResearch()

    return ((self.techType == kTechType.Research) and not self.researched and not self.researching) or (self.techType == kTechType.Upgrade) or (self.techType == kTechType.EnergyBuild)
    
end

function TechNode:GetResearching()
    return self.researching
end

function TechNode:SetResearching()

    if(self:GetCanResearch()) then
    
        self.researching = true
        
    end

end

// Make sure to call TechTree:ComputeAvailability() after making a change here.
function TechNode:SetResearched(state)

    if(self.techType == kTechType.Research) then
        self.researched = state
        self.researchProgress = 1
    end    
    
end

if Client then

    // Build tech node from data sent in base update
    function TechNode:InitializeFromNetwork(networkVars)

        self.techId             = networkVars.techId
        self.techType           = networkVars.techType
        self.prereq1            = networkVars.prereq1
        self.prereq2            = networkVars.prereq2
        self.addOnTechId        = networkVars.addOnTechId
        self.cost               = networkVars.cost
        self.available          = networkVars.available
        self.time               = networkVars.time
        self.researchProgress   = networkVars.researchProgress
        self.researched         = networkVars.researched
        self.researching        = networkVars.researching
        self.hasTech            = networkVars.hasTech
        self.requiresTarget     = networkVars.requiresTarget
        self.energyBuild        = networkVars.energyBuild
        
    end

    // Update values from kTechNodeUpdateMessage
    function TechNode:UpdateFromNetwork(networkVars)

        self.available          = networkVars.available
        self.researchProgress   = networkVars.researchProgress
        self.researched         = networkVars.researched
        self.researching        = networkVars.researching
        self.hasTech            = networkVars.hasTech
        
    end

end

if Server then

    function BuildTechNodeBaseMessage(techNode)

        local t = {}
        
        t.techId             = techNode.techId
        t.techType           = techNode.techType
        t.prereq1            = techNode.prereq1
        t.prereq2            = techNode.prereq2
        t.addOnTechId        = techNode.addOnTechId
        t.cost               = techNode.cost
        t.available          = techNode.available
        t.time               = techNode.time
        t.researchProgress   = techNode.researchProgress
        t.researched         = techNode.researched
        t.researching        = techNode.researching
        t.requiresTarget     = techNode.requiresTarget
        t.energyBuild        = techNode.energyBuild
        
        return t
        
    end

end

function TechNode:CopyDataFrom(techNode)

	self.techId             = techNode.techId
	self.techType           = techNode.techType
	self.prereq1            = techNode.prereq1
	self.prereq2            = techNode.prereq2
	self.addOnTechId        = techNode.addOnTechId
	self.cost               = techNode.cost
	self.available          = techNode.available
	self.time               = techNode.time
	self.researchProgress   = techNode.researchProgress
	self.researched         = techNode.researched
	self.researching        = techNode.researching
	self.hasTech            = techNode.hasTech
	self.requiresTarget     = techNode.requiresTarget
	self.energyBuild        = techNode.energyBuild
        
end

// TODO: Make this reliable
Shared.RegisterNetworkMessage( "TechNodeBase", TechNode.kTechNodeVars )


