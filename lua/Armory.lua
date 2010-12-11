// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
class 'Armory' (Structure)
Armory.kMapName = "armory"

Armory.kModelName = PrecacheAsset("models/marine/armory/armory.model")

Armory.kIdleSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_idle")
Armory.kOpenSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_open")
Armory.kCloseSound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_close")

// Looping sound while using the armory
Armory.kResupplySound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_resupply")
Armory.kHealthSound = PrecacheAsset("sound/ns2.fev/marine/common/health")
Armory.kAmmoSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

Armory.kResupplyEffect = PrecacheAsset("cinematics/marine/spawn_item.cinematic")
Armory.kDeathEffect = PrecacheAsset("cinematics/marine/armory/death.cinematic")
Armory.kBuyItemEffect = PrecacheAsset("cinematics/marine/armory/buy_item_effect.cinematic")

Armory.kArmoryBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Armory.kAttachPoint = "Root"

Armory.kAdvancedArmoryChildModel = PrecacheAsset("models/marine/advanced_armory/advanced_armory.model")
Armory.kWeaponsModuleChildModel = PrecacheAsset("models/marine/weapons_module/weapons_module.model")

Armory.kBuyMenuFlash = "ui/marine_buy.swf"
Armory.kBuyMenuTexture = "ui/marine_buymenu.dds"
Armory.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Armory.kThinkTime = .3
Armory.kHealAmount = 20
Armory.kResupplyInterval = .9

// Players can use menu and be supplied by armor inside this range
Armory.kResupplyUseRange = 2.5

if (Server) then
    Script.Load("lua/Armory_Server.lua")
else
    Script.Load("lua/Armory_Client.lua")
end
    
local networkVars =
    {
        // How far out the arms are for animation (0-1)
        loggedInEast     = "boolean",
        loggedInNorth    = "boolean",
        loggedInSouth    = "boolean",
        loggedInWest     = "boolean",
    }

function GetArmory(entity)

    local teamArmories = {}
    
    if Server then
        teamArmories = GetGamerules():GetEntities("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange)
    else
        teamArmories = GetEntitiesIsaInRadius("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange)
    end
    
    if table.count(teamArmories) > 0 then
    
        // TODO: Check facing to make sure player wants to use armory
        return teamArmories[1]
            
    end
    
    return nil

end

function Armory:OnInit()

    self:SetModel(Armory.kModelName)
    
    Structure.OnInit(self)
    
    // False if the player that's logged into a side is only nearby, true if
    // the pressed their key to open the menu to buy something. A player
    // must use the armory once "logged in" to be able to buy anything.
    
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0
    
    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0

    self.loginNorthAmount = 0
    self.loginEastAmount = 0
    self.loginSouthAmount = 0
    self.loginWestAmount = 0
    
    self.timeLastUpdate = Shared.GetTime()

    if Server then    
    
        self.loggedInArray = {false, false, false, false}
        
        // Use entityId as index, store time last resupplied
        self.resuppliedPlayers = {}

        self:SetNextThink(Armory.kThinkTime)
        
        self:SetAnimation(Structure.kAnimSpawn)
        
    end
    
end

function Armory:GetIdleAnimation()
    return "idle"
end

function Armory:GetRequiresPower()
    return true
end

function Armory:GetDeathEffect()
    return Armory.kDeathEffect
end

function Armory:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.ArmoryUpgradesMenu, kTechId.ArmoryEquipmentMenu, kTechId.None, kTechId.None,
                        kTechId.None, kTechId.None, kTechId.Recycle, kTechId.None }
    
        // Show button to upgraded to advanced armory
        if(self:GetTechId() == kTechId.Armory) then        
        
            techButtons[kMarineUpgradeButtonIndex] = kTechId.AdvancedArmoryUpgrade
            
        elseif self:GetTechId() == kTechId.AdvancedArmory then
        
            techButtons[kMarineUpgradeButtonIndex] = kTechId.WeaponsModule            
            
        end
        
    elseif(techId == kTechId.ArmoryUpgradesMenu) then
    
        techButtons = { kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3, kTechId.None,
                        kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.RootMenu }
                        
    elseif(techId == kTechId.ArmoryEquipmentMenu) then
    
        techButtons = { kTechId.ShotgunTech, kTechId.GrenadeLauncherTech, kTechId.FlamethrowerTech, kTechId.JetpackTech, 
                        kTechId.ExoskeletonTech, kTechId.None, kTechId.None, kTechId.RootMenu }

    end
    
    return techButtons
    
end

function Armory:UpdateArmoryAnim(extension, loggedIn, scanTime, timePassed)

    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)

    if extension == "n" then
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginNorthAmount)
    elseif extension == "s" then
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginSouthAmount)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginEastAmount)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginWestAmount)
    end
    
    local scannedName = "scan_" .. extension
    local scannedParamValue = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)
    self:SetPoseParam(scannedName, scannedParamValue)
    
end

function Armory:SetPoseParamForResearch(researchId, childModel, children)

    if self.researchingId == researchId then
    
        local children = GetChildEntities(self, "ScriptActor")
        
        // Get child model and set "spawn" progress according to research time
        for index, child in ipairs(children) do
        
            if child:GetModelName() == childModel then
            
                child:SetPoseParam("spawn", self.researchProgress)
                break
                
            end
            
        end
        
    end
    
end

function Armory:OnUpdate(deltaTime)

    if self:GetIsBuilt() then
    
        // Update animation for add-on modules as they're being built
        self:SetPoseParamForResearch(kTechId.AdvancedArmoryUpgrade, Armory.kAdvancedArmoryChildModel, children)
        self:SetPoseParamForResearch(kTechId.WeaponsModule, Armory.kWeaponsModuleChildModel, children)
        
        // Set pose parameters according to if we're logged in or not
        if self.timeLastUpdate ~= nil then
        
            local timePassed = Shared.GetTime() - self.timeLastUpdate
        
            self:UpdateArmoryAnim("e", self.loggedInEast, self.timeScannedEast, timePassed)
            self:UpdateArmoryAnim("n", self.loggedInNorth, self.timeScannedNorth, timePassed)
            self:UpdateArmoryAnim("w", self.loggedInWest, self.timeScannedWest, timePassed)
            self:UpdateArmoryAnim("s", self.loggedInSouth, self.timeScannedSouth, timePassed)
            
        end
        
    end
    
    Structure.OnUpdate(self, deltaTime)
    
end

Shared.LinkClassToMap("Armory", Armory.kMapName, networkVars)

class 'AdvancedArmory' (Armory)

AdvancedArmory.kMapName = "advancedarmory"

Shared.LinkClassToMap("AdvancedArmory", AdvancedArmory.kMapName, {})
