// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MarineTeam.lua")

class 'MarineTeamCombat' (MarineTeam)

function MarineTeamCombat:InitTechTree()

	PlayingTeam.InitTechTree(self)
	
	// Baseline 
	self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.None,                kTechId.None)
	self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.None,                kTechId.None)  
    self.techTree:AddEnergyBuildNode(kTechId.MAC,                 kTechId.None,                kTechId.None)
	self.techTree:AddResearchNode(kTechId.RifleUpgradeTech,       kTechId.Armory,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.RifleUpgrade, kTechId.RifleUpgradeTech, kTechId.None, kTechId.Rifle)
	self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)
	
	// Orders
	self.techTree:AddOrder(kTechId.SquadMove)
    self.techTree:AddOrder(kTechId.SquadAttack)
    self.techTree:AddOrder(kTechId.SquadDefend)
    self.techTree:AddOrder(kTechId.SquadSeekAndDestroy)
    self.techTree:AddOrder(kTechId.SquadHarass)
    self.techTree:AddOrder(kTechId.SquadRegroup)
    
    self.techTree:AddMenu(kTechId.ArmoryUpgradesMenu)
    self.techTree:AddMenu(kTechId.ArmoryEquipmentMenu)
	
	// Tier 1
    self.techTree:AddResearchNode(kTechId.Armor1,                 kTechId.None,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons1,             kTechId.None,               kTechId.None)
	self.techTree:AddResearchNode(kTechId.MedPackTech,             kTechId.None,               kTechId.None)
	self.techTree:AddEnergyBuildNode(kTechId.MedPack,                 kTechId.MedPackTech,                kTechId.None)
	self.techTree:AddEnergyBuildNode(kTechId.AmmoPack,                 kTechId.MedPackTech,                kTechId.None)
	self.techTree:AddResearchNode(kTechId.ShotgunTech,         kTechId.Weapons1,         kTechId.None)
	self.techTree:AddBuyNode(kTechId.Shotgun,                        kTechId.ShotgunTech,         kTechId.None)
	
	// Tier 2
	self.techTree:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1,            kTechId.None)
	self.techTree:AddResearchNode(kTechId.CatPackTech,             kTechId.MedPackTech,               kTechId.None)
	self.techTree:AddResearchNode(kTechId.ScanTech,             kTechId.MedPackTech,                 kTechId.None)
	self.techTree:AddResearchNode(kTechId.GrenadeLauncherTech,         kTechId.ShotgunTech,                 kTechId.None)
	self.techTree:AddBuyNode(kTechId.GrenadeLauncher,                    kTechId.GrenadeLauncherTech,       kTechId.None)
	self.techTree:AddResearchNode(kTechId.FlamethrowerTech,         kTechId.ShotgunTech,        			   kTechId.None)
	self.techTree:AddBuyNode(kTechId.Flamethrower,                       kTechId.FlamethrowerTech,                kTechId.None)
	
	// Tier 3
	self.techTree:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2,            kTechId.None)
	
	self.techTree:SetComplete()
	
end