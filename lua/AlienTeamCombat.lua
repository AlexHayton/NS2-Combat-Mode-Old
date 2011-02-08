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
    self.techTree:AddBuyNode(kTechId.Gorge,                     kTechId.None,                kTechId.None)
	self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.None,                kTechId.None)
	self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.None,                kTechId.None)  
	self.techTree:AddResearchNode(kTechId.RifleUpgradeTech,       kTechId.Armory,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.RifleUpgrade, kTechId.RifleUpgradeTech, kTechId.None, kTechId.Rifle)
	self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)
    
    self.techTree:AddMenu(kTechId.ArmoryUpgradesMenu)
    self.techTree:AddMenu(kTechId.ArmoryEquipmentMenu)
	
	// Tier 1
    self.techTree:AddResearchNode(kTechId.Melee1Tech,              kTechId.None,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor1Tech,         kTechId.None,                kTechId.None)
	self.techTree:AddBuyNode(kTechId.Lerk,                      kTechId.AlienArmor1Tech,              kTechId.None)
	
	// Tier 2
	self.techTree:AddResearchNode(kTechId.Melee2Tech,             kTechId.Melee1Tech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor2Tech,        kTechId.AlienArmor1Tech,          kTechId.None)
    self.techTree:AddBuyNode(kTechId.Fade,                      kTechId.AlienArmor2Tech,          kTechId.Lerk)
	
	// Tier 3
    self.techTree:AddResearchNode(kTechId.Melee3Tech,             kTechId.Melee2Tech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor3Tech,        kTechId.AlienArmor2Tech,          kTechId.None)
	
	self.techTree:SetComplete()
	
end