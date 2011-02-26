// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienTeamCombat.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/AlienTeam.lua")

class 'AlienTeamCombat' (AlienTeam)

function AlienTeamCombat:InitTechTree()

	PlayingTeam.InitTechTree(self)
	
	// Baseline 
	self.techTree:AddBuildNode(kTechId.Hive,                      kTechId.None,                kTechId.None)
	self.techTree:AddBuyNode(kTechId.Skulk,                     kTechId.None,                kTechId.None)
	
	// Add special alien menus
    self.techTree:AddMenu(kTechId.MarkersMenu)
    self.techTree:AddMenu(kTechId.UpgradesMenu)
    self.techTree:AddMenu(kTechId.ShadePhantasmMenu)
    
    // Add markers (orders)
    self.techTree:AddOrder(kTechId.ThreatMarker)
    self.techTree:AddOrder(kTechId.LargeThreatMarker)
    self.techTree:AddOrder(kTechId.NeedHealingMarker)
    self.techTree:AddOrder(kTechId.WeakMarker)
    self.techTree:AddOrder(kTechId.ExpandingMarker)
	
	// Tier 1
    self.techTree:AddResearchNode(kTechId.Melee1Tech,              kTechId.None,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor1Tech,         kTechId.None,                kTechId.None)
	//self.techTree:AddResearchNode(kTechId.Whip1Tech, kTechId.None, kTechId.None)
	//self.techTree:AddResearchNode(kTechId.Crag1Tech, kTechId.None, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Leap, kTechId.Melee1Tech, kTechId.None, kTechId.Skulk)
    self.techTree:AddBuyNode(kTechId.BloodThirst, kTechId.AlienArmor1Tech, kTechId.None, kTechId.Skulk)
	self.techTree:AddResearchNode(kTechId.GorgeTech,        kTechId.AlienArmor1Tech,          kTechId.None)
	self.techTree:AddBuyNode(kTechId.Gorge,       kTechId.GorgeTech,                kTechId.None)
	
	// Tier 2
	self.techTree:AddResearchNode(kTechId.Melee2Tech,             kTechId.Melee1Tech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor2Tech,        kTechId.AlienArmor1Tech,          kTechId.None)
	//self.techTree:AddResearchNode(kTechId.Whip2Tech, kTechId.Whip1Tech, kTechId.None)
	//self.techTree:AddResearchNode(kTechId.Crag2Tech, kTechId.Crag1Tech, kTechId.None)
	self.techTree:AddResearchNode(kTechId.FadeTech,        kTechId.LerkTech,          kTechId.None)
    self.techTree:AddBuyNode(kTechId.Fade,                      kTechId.FadeTech,          kTechId.None)
	self.techTree:AddBuyNode(kTechId.HydraAbility, kTechId.Melee1Tech, kTechId.None, kTechId.Gorge)
    self.techTree:AddBuildNode(kTechId.Hydra,                     kTechId.HydraAbility,           kTechId.None)
	self.techTree:AddResearchNode(kTechId.LerkTech,         kTechId.Melee2Tech,                kTechId.None)
	self.techTree:AddBuyNode(kTechId.Lerk,                      kTechId.LerkTech,              kTechId.None)
	
	// Tier 3
    self.techTree:AddResearchNode(kTechId.Melee3Tech,             kTechId.Melee2Tech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor3Tech,        kTechId.AlienArmor2Tech,          kTechId.None)
	self.techTree:AddResearchNode(kTechId.OnosTech,        kTechId.FadeTech,          kTechId.None)
	self.techTree:AddBuyNode(kTechId.Onos,                      kTechId.OnosTech,          kTechId.None)
	
	self.techTree:SetComplete()
	
end