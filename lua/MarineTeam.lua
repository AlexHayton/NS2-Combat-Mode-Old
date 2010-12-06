// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Marine.lua")
Script.Load("lua/MarineTeamSquads.lua")
Script.Load("lua/PlayingTeam.lua")

class 'MarineTeam' (PlayingTeam)

MarineTeam.kSquadUpdateInterval = 1

function MarineTeam:GetTeamType()
    return kMarineTeamType
end

function MarineTeam:GetIsMarineTeam()
    return true 
end

function MarineTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Marine.kMapName
    
    self.timeSinceSquadUpdate = 0
    
end

// Returns ip
function MarineTeam:SpawnIP(nearOrigin)

    // Spawn a built infantry portal nearby 
    local success, origin = GetRandomSpaceForEntity(nearOrigin, kInfantryPortalAttachRange/2, kInfantryPortalAttachRange, 1, 3)    
    
    if success then
    
        local ip = CreateEntity(InfantryPortal.kMapName, origin, self:GetTeamNumber())
        
        SetRandomOrientation(ip)
        
        ip:SetConstructionComplete()
        
        return ip
    
    else
        Print("MarineTeam:SpawnIP(): GetRandomSpaceForEntity() return false.")    
    end
    
    return nil

end

function MarineTeam:SpawnInitialStructures(teamLocation)

    local nearestTechPoint = GetNearestTechPoint(teamLocation:GetOrigin(), self:GetTeamType(), true)
    
    //if nearestTechPoint ~= nil then
    //    self:SpawnIP(nearestTechPoint:GetOrigin())
    //end
    
    PlayingTeam.SpawnInitialStructures(self, teamLocation)
    
end

function MarineTeam:GetHasAbilityToRespawn()

    // Any active IPs on team? There could be a case where everyone has died and no active
    // IPs but builder bots are mid-construction so a marine team could theoretically keep
    // playing but ignoring that case for now
    local spawningStructures = GetGamerules():GetEntities("InfantryPortal", self:GetTeamNumber())
    
    for index, current in ipairs(spawningStructures) do

        if current:GetIsBuilt() and current:GetIsPowered() then
        
            return true
            
        end
        
    end        
    
    return false

end

function MarineTeam:UpdateSquads(timePassed)

    self.timeSinceSquadUpdate = self.timeSinceSquadUpdate + timePassed
    
    if(self.timeSinceSquadUpdate >= MarineTeam.kSquadUpdateInterval) then
    
        UpdateSquads(self:GetTeamNumber())
        self.timeSinceSquadUpdate = (self.timeSinceSquadUpdate - MarineTeam.kSquadUpdateInterval)
        
    end

end

// Called every so often by PlayingTeam() to figure assign players to squads.
function UpdateSquads(teamNumber)

    local playerList = GetGamerules():GetEntities(GetSquadClass(), teamNumber)
    
    if(table.maxn(playerList) == 0) then
        return
    end
    
    local squadList = GetSortedSquadList(playerList)    
    
    local assignedSquadIndices = {}
    
    // For each squad
    for index, squad in ipairs(squadList) do
    
        // If number of players in squad is 1, that's not enough for a squad so set their squad to 0
        local newSquadIndex = 0
        
        if(table.maxn(squad) >= kSquadMinimumEntityCount) then
        
            // Otherwise, reassign players in squad 
            newSquadIndex = GetBestSquadIndex(squad, assignedSquadIndices)
            
            if(newSquadIndex > 0) then
            
                if(not table.find(assignedSquadIndices, newSquadIndex)) then
                                
                    table.insertunique(assignedSquadIndices, newSquadIndex)
                    
                end
                
            end
            
        end
        
        AssignEntitiesToSquad(squad, newSquadIndex)
        
    end
    
end

function MarineTeam:Update(timePassed)

    PlayingTeam.Update(self, timePassed)

    self:UpdateSquads(timePassed)    
    
end

function MarineTeam:InitTechTree()
   
   PlayingTeam.InitTechTree(self)
    
    // Marine tier 1
    self.techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.ExtractorUpgrade,        kTechId.Extractor,           kTechId.None)
    self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.None,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.SentryTech,             kTechId.None,                kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.Sentry,              kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.None,                kTechId.None)  
    self.techTree:AddEnergyBuildNode(kTechId.MAC,                 kTechId.None,                kTechId.None)
    
    self.techTree:AddTargetedBuyNode(kTechId.MedPack,             kTechId.Armory,              kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.AmmoPack,            kTechId.None,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.CatPackTech,            kTechId.Armory,              kTechId.None)
    self.techTree:AddTargetedBuyNode(kTechId.CatPack,             kTechId.Armory,              kTechId.CatPackTech)
    self.techTree:AddBuyNode(kTechId.Axe,                         kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Rifle,                       kTechId.None,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.MACWeldingTech,           kTechId.Armory,              kTechId.None)
    
    // Squad tech nodes
    self.techTree:AddOrder(kTechId.SelectRedSquad)
    self.techTree:AddOrder(kTechId.SelectBlueSquad)
    self.techTree:AddOrder(kTechId.SelectGreenSquad)
    self.techTree:AddOrder(kTechId.SelectYellowSquad)
    self.techTree:AddOrder(kTechId.SelectOrangeSquad)
    
    self.techTree:AddOrder(kTechId.SquadMove)
    self.techTree:AddOrder(kTechId.SquadAttack)
    self.techTree:AddOrder(kTechId.SquadDefend)
    self.techTree:AddOrder(kTechId.SquadSeekAndDestroy)
    self.techTree:AddOrder(kTechId.SquadHarass)
    self.techTree:AddOrder(kTechId.SquadRegroup)
    
    // Commander abilities
    self.techTree:AddTargetedActivation(kTechId.NanoDefense,       kTechId.None,                kTechId.None)
    
    self.techTree:AddMenu(kTechId.CommandStationUpgradesMenu)
    
    // Armory upgrades
    self.techTree:AddResearchNode(kTechId.RifleUpgradeTech,       kTechId.Armory,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.RifleUpgrade, kTechId.RifleUpgradeTech, kTechId.None, kTechId.Rifle)
    
    self.techTree:AddMenu(kTechId.ArmoryUpgradesMenu)
    self.techTree:AddMenu(kTechId.ArmoryEquipmentMenu)
    
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,  kTechId.CommandFacility,        kTechId.InfantryPortal)
    
    self.techTree:AddResearchNode(kTechId.Armor1,                 kTechId.Armory,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons1,               kTechId.Armory,               kTechId.None)
    
    // Marine tier 2
    self.techTree:AddSpecial(kTechId.TwoCommandStations)
    self.techTree:AddBuildNode(kTechId.CommandFacility,      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.CommandFacilityUpgrade,  kTechId.TwoCommandStations,              kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmory,               kTechId.CommandFacility,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.CommandFacility,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.InfantryPortalTransponderTech,    kTechId.CommandFacility,        kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor2,                 kTechId.Armor1,              kTechId.CommandFacility)
    self.techTree:AddResearchNode(kTechId.Weapons2,               kTechId.Weapons1,            kTechId.CommandFacility)

    self.techTree:AddBuildNode(kTechId.Observatory,               kTechId.CommandFacility,       kTechId.None)      
    self.techTree:AddTargetedActivation(kTechId.Scan,             kTechId.None,                 kTechId.None)
    self.techTree:AddActivation(kTechId.DistressBeacon)
    
    self.techTree:AddUpgradeNode(kTechId.InfantryPortalTransponderUpgrade,  kTechId.InfantryPortalTransponderTech,  kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.WeaponsModule,          kTechId.AdvancedArmory,              kTechId.None)        
    
    // Build bot upgrades
    self.techTree:AddBuildNode(kTechId.MACMine,                kTechId.MACMinesTech,              kTechId.None)        
    self.techTree:AddResearchNode(kTechId.MACMinesTech,        kTechId.CommandFacility,           kTechId.None)        
    self.techTree:AddBuildNode(kTechId.MACEMP,                 kTechId.MACEMPTech,                kTechId.None)        
    self.techTree:AddResearchNode(kTechId.MACEMPTech,          kTechId.CommandFacility,           kTechId.None)        
    self.techTree:AddResearchNode(kTechId.MACSpeedTech,           kTechId.InfantryPortal,            kTechId.None)        
    
    // Door actions
    self.techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    self.techTree:AddActivation(kTechId.DoorOpen)
    self.techTree:AddActivation(kTechId.DoorClose)
    self.techTree:AddActivation(kTechId.DoorLock)
    self.techTree:AddActivation(kTechId.DoorUnlock)
    
    // Weapon-specific
    self.techTree:AddResearchNode(kTechId.ShotgunTech,           kTechId.Armory,              kTechId.None)
    self.techTree:AddBuyNode(kTechId.Shotgun,                    kTechId.ShotgunTech,         kTechId.Armory)
    
    self.techTree:AddResearchNode(kTechId.GrenadeLauncherTech,           kTechId.AdvancedArmory,                   kTechId.None)
    self.techTree:AddBuyNode(kTechId.GrenadeLauncher,                    kTechId.GrenadeLauncherTech,             kTechId.None)
    
    self.techTree:AddResearchNode(kTechId.NerveGasTech,                  kTechId.GrenadeLauncher,                            kTechId.None)
    self.techTree:AddBuyNode(kTechId.NerveGas, kTechId.NerveGasTech, kTechId.None, kTechId.GrenadeLauncher)
    
    self.techTree:AddResearchNode(kTechId.FlamethrowerTech,              kTechId.WeaponsModule,                   kTechId.None)
    self.techTree:AddBuyNode(kTechId.Flamethrower,                       kTechId.FlamethrowerTech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.FlamethrowerAltTech,           kTechId.FlamethrowerTech,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.FlamethrowerAlt,                    kTechId.FlamethrowerAltTech,                kTechId.None, kTechId.Flamethrower)
    
    // ARCs
    self.techTree:AddBuildNode(kTechId.RoboticsFactory,             kTechId.CommandFacility,              kTechId.None)      
    self.techTree:AddManufactureNode(kTechId.ARC,                          kTechId.RoboticsFactory,                kTechId.None)        
    self.techTree:AddActivation(kTechId.ARCDeploy)
    self.techTree:AddActivation(kTechId.ARCUndeploy)
    
    // Robotics factory menus
    self.techTree:AddMenu(kTechId.RoboticsFactoryARCUpgradesMenu)
    self.techTree:AddMenu(kTechId.RoboticsFactoryMACUpgradesMenu)
    
    // Marine tier 3
    self.techTree:AddSpecial(kTechId.ThreeCommandStations)
    self.techTree:AddBuildNode(kTechId.CommandCenter,      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.CommandCenterUpgrade,   kTechId.ThreeCommandStations,              kTechId.Armory)
    self.techTree:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.CommandCenter)        
    self.techTree:AddResearchNode(kTechId.ARCSplashTech,           kTechId.RoboticsFactory,         kTechId.CommandCenter)
    self.techTree:AddResearchNode(kTechId.ARCArmorTech,           kTechId.RoboticsFactory,          kTechId.CommandCenter)
    
    self.techTree:AddMenu(kTechId.PrototypeLabUpgradesMenu)

    // Armory upgrades
    self.techTree:AddResearchNode(kTechId.Armor3,                 kTechId.Armor2,              kTechId.CommandCenter)
    self.techTree:AddResearchNode(kTechId.Weapons3,               kTechId.Weapons2,            kTechId.CommandCenter)

    // Jetpack
    self.techTree:AddResearchNode(kTechId.JetpackTech,           kTechId.PrototypeLab, kTechId.CommandCenter)
    // TODO: Make jetpacks depend on ThreeCommandStations
    self.techTree:AddBuyNode(kTechId.Jetpack,                    kTechId.JetpackTech, kTechId.PrototypeLab)
    self.techTree:AddResearchNode(kTechId.JetpackFuelTech,       kTechId.JetpackTech, kTechId.CommandCenter)
    self.techTree:AddResearchNode(kTechId.JetpackArmorTech,      kTechId.JetpackTech, kTechId.CommandCenter)
    
    // Exoskeleton
    self.techTree:AddResearchNode(kTechId.ExoskeletonTech,       kTechId.PrototypeLab, kTechId.CommandCenter)
    // TODO: Make exoskeletons depend on ThreeCommandStations
    self.techTree:AddBuyNode(kTechId.Exoskeleton,                kTechId.ExoskeletonTech, kTechId.PrototypeLab)
    self.techTree:AddResearchNode(kTechId.DualMinigunTech,       kTechId.ExoskeletonTech, kTechId.PrototypeLab)
    
    self.techTree:AddResearchNode(kTechId.ExoskeletonLockdownTech,   kTechId.ExoskeletonTech, kTechId.CommandCenter)
    self.techTree:AddResearchNode(kTechId.ExoskeletonUpgradeTech,    kTechId.ExoskeletonTech, kTechId.CommandCenter)   
    
    self.techTree:SetComplete()

end