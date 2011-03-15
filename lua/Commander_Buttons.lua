// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Buttons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Commander_Hotkeys.lua")

// Maps tech buttons to keys in "grid" system
kGridHotkeys =
{
    Move.Q, Move.W, Move.E, Move.R,
    Move.A, Move.S, Move.D, Move.F,
    Move.Z, Move.X, Move.C, Move.V,
}

/**
 * Called by Flash when the user presses the "Logout" button.
 */
function CommanderUI_Logout()

    local commanderPlayer = Client.GetLocalPlayer()
    commanderPlayer:Logout()
        
end

function CommanderUI_MenuButtonWidth()
    return 80
end

function CommanderUI_MenuButtonHeight()
    return 80
end

/*
    Return linear array consisting of:    
    tooltipText (String)
    tooltipHotkey (String)
    tooltipCost (Number)
    tooltipRequires (String) - optional, specify "" or nil if not used
    tooltipEnables (String) - optional, specify "" or nil if not used
    tooltipInfo (String)
    tooltipType (Number) - 0 = carbon, 1 = plasma, 2 = energy
*/
function CommanderUI_MenuButtonTooltip(index)

    local player = Client.GetLocalPlayer()

    local techId = nil
    local tooltipText = nil
    local hotkey = nil
    local cost = nil
    local requiresText = nil
    local enablesText = nil
    local tooltipInfo = nil
    local resourceType = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        local techTree = GetTechTree()
        techId = player.menuTechButtons[index]        
        
        tooltipText = techTree:GetDescriptionText(techId)
        hotkey = kGridHotkeys[index]
        
        if hotkey ~= "" then
            hotkey = gHotkeyDescriptions[hotkey]
        end
        
        cost = LookupTechData(techId, kTechDataCostKey, 0)
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            resourceType = techNode:GetResourceType()
        end
        requiresText = techTree:GetRequiresText(techId)
        enablesText = techTree:GetEnablesText(techId)
        tooltipInfo = techTree:GetTooltipInfoText(techId)
        
    end
    
    return {tooltipText, hotkey, cost, requiresText, enablesText, tooltipInfo, resourceType}    
    
end

/** 
 * Returns the current status of the button. 
 * 0 = button or tech not found, or currently researching, don't display
 * 1 = available and ready, display as pressable
 * 2 = available but not currently, display in red
 * 3 = not available, display grayed out
 */
function CommanderUI_MenuButtonStatus(index)

    local player = Client.GetLocalPlayer()
    local buttonStatus = 0
    local techId = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        techId = player.menuTechButtons[index]
        
        if(techId ~= kTechId.None) then
        
            local techNode = GetTechTree():GetTechNode(techId)
            
            if(techNode ~= nil) then
            
                if techNode:GetResearching() then
                    // Don't display
                    buttonStatus = 0
                elseif not techNode:GetAvailable() then
                    // Greyed out
                    buttonStatus = 3
                // menuTechButtonsAllowed[] contains results of appropriate carbon, plasma or energy check
                elseif not player.menuTechButtonsAllowed[index] then
                    // Red
                    buttonStatus = 2
                else
                    // Available
                    buttonStatus = 1
                end

            else
                Print("CommanderUI_MenuButtonStatus(%s): Tech node for id %s not found (%s)", tostring(index), EnumToString(kTechId, techId), table.tostring(player.menuTechButtons))
            end
            
        end
        
    end    
    
    return buttonStatus

end

function CommanderUI_MenuButtonAction(index)

    local player = Client.GetLocalPlayer()
    
    if(index <= table.count(player.menuTechButtons)) then

        // Trigger button press (open menu, build tech, etc.)    
        player:SetCurrentTech(player.menuTechButtons[index])
        
    end
    
end

function CommanderUI_MenuButtonXOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
        local xOffset, yOffset = player:GetMaterialXYOffset(techId, player:isa("MarineCommander"))
        return xOffset
        
    end
    
    return -1
    
end

function CommanderUI_MenuButtonYOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
        if(techId ~= kTechId.None) then
            local xOffset, yOffset = player:GetMaterialXYOffset(techId, player:isa("MarineCommander"))
            return yOffset
        end
    end
    
    return -1
    
end

function Commander:UpdateMenu(deltaTime)

    if(self.menuTechId == nil) then
        self.menuTechId = kTechId.None
    end

    local kMenuUpdateInterval = .3
    self.timeSinceUpdateMenu = self.timeSinceUpdateMenu + deltaTime
    
    if(self.timeSinceUpdateMenu > kMenuUpdateInterval) then
   
        self:UpdateSharedTechButtons()
        
        self:ComputeMenuTechAvailability()
        
        self.timeSinceUpdateMenu = self.timeSinceUpdateMenu - kMenuUpdateInterval
        
    end
    
end

// Look at current selection and our current menu (self.menuTechId) and build a list of tech
// buttons that represents valid orders for the Commander. Store in self.menuTechButtons.
function Commander:UpdateSharedTechButtons()

    self.menuTechButtons = {}
    
    if(table.count(self.selectedSubGroupEntities) > 0) then
    
        // Loop through all entities and get their tech buttons
        local selectedTechButtons = {}
        local maxTechButtons = 0
        for selectedEntityIndex, entity in ipairs(self.selectedSubGroupEntities) do
        
            if(entity ~= nil) then

                local techButtons = self:GetCurrentTechButtons(self.menuTechId, entity)
                
                if(techButtons ~= nil) then
                    table.insert(selectedTechButtons, techButtons)
                    maxTechButtons = math.max(maxTechButtons, table.count(techButtons))
                end
                
            end
        
        end
        
        // Now loop through tech button lists and use only the tech that doesn't conflict. These will generally be the same
        // tech id, but could also be a techid that not all selected units have, so long as the others don't specify a button
        // in the same position (ie, it is kTechId.None).
        local techButtonIndex = 1
        for techButtonIndex = 1, maxTechButtons do

            local buttonConflicts = false
            local buttonTechId = kTechId.None
            local highestButtonPriority = 0
            
            for index, techButtons in pairs(selectedTechButtons) do
            
                local currentButtonTechId = techButtons[techButtonIndex]
                
                // Lookup tech id priority. If not specified, treat as 0.
                local currentButtonPriority = LookupTechData(currentButtonTechId, kTechDataMenuPriority, 0)

                if(buttonTechId == kTechId.None) then
                
                    buttonTechId = currentButtonTechId
                    highestButtonPriority = currentButtonPriority
                    
                elseif((currentButtonTechId ~= buttonTechId) and (currentButtonTechId ~= kTechId.None)) then
                    
                    if(currentButtonPriority > highestButtonPriority) then
                        
                        highestButtonPriority = currentButtonPriority
                        buttonTechId = currentButtonTechId
                        buttonConflicts = false                            
                    
                    elseif(currentButtonPriority == highestButtonPriority) then
                    
                        buttonConflicts = true
                        
                    end
                    
                end
                
            end     
            
            if(not buttonConflicts) then
                table.insert(self.menuTechButtons, buttonTechId)
            end
            
        end
        
    end

end

function Commander:ComputeMenuTechAvailability()

    self.menuTechButtonsAllowed = {}
    
    local techTree = GetTechTree()

    for index, techId in ipairs(self.menuTechButtons) do
    
        local techNode = techTree:GetTechNode(techId)
        local menuTechButtonAllowed = false
        
        // Loop through all selected entities. If any of them allow this tech, then the button is enabled
        for index, entity in ipairs(self.selectedSubGroupEntities) do
        
            if(entity ~= nil and entity:GetTechAllowed(techId, techNode, self)) then
            
                menuTechButtonAllowed = true
                break
                
            end
            
        end       
        
        table.insert(self.menuTechButtonsAllowed, menuTechButtonAllowed)
    
    end
        
end

// Create arrays that convert between tech ids and the offsets within
// the button images used to display their buttons. Look in marine_buildmenu.psd 
// and alien_buildmenu.psd to understand these indices.
function Commander:InitTechTreeMaterialOffsets()

    // Init marine offsets
    self.kMarineTechIdToMaterialOffset = {}
    
    // First row
    self.kMarineTechIdToMaterialOffset[kTechId.CommandStation] = 0
    self.kMarineTechIdToMaterialOffset[kTechId.CommandStationUpgradesMenu] = 68
    
    self.kMarineTechIdToMaterialOffset[kTechId.Armory] = 1
    self.kMarineTechIdToMaterialOffset[kTechId.RifleUpgradeTech] = 66
    self.kMarineTechIdToMaterialOffset[kTechId.MAC] = 2
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing extractor
    self.kMarineTechIdToMaterialOffset[kTechId.Extractor] = 3
    self.kMarineTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
    self.kMarineTechIdToMaterialOffset[kTechId.InfantryPortalTransponderTech] = 4
    self.kMarineTechIdToMaterialOffset[kTechId.InfantryPortalTransponderUpgrade] = 4
    self.kMarineTechIdToMaterialOffset[kTechId.Sentry] = 5
    self.kMarineTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6
    self.kMarineTechIdToMaterialOffset[kTechId.Observatory] = 7
    self.kMarineTechIdToMaterialOffset[kTechId.WeaponsModule] = 8
    self.kMarineTechIdToMaterialOffset[kTechId.PrototypeLab] = 9
    self.kMarineTechIdToMaterialOffset[kTechId.PowerPoint] = 10    
    // TODO: Change this
    self.kMarineTechIdToMaterialOffset[kTechId.PowerPack] = 10
    
    // Second row - Non-player orders
    self.kMarineTechIdToMaterialOffset[kTechId.Recycle] = 12
    self.kMarineTechIdToMaterialOffset[kTechId.Move] = 13
    self.kMarineTechIdToMaterialOffset[kTechId.Stop] = 14
    self.kMarineTechIdToMaterialOffset[kTechId.RootMenu] = 15
    self.kMarineTechIdToMaterialOffset[kTechId.Cancel] = 16
    //self.kMarineTechIdToMaterialOffset[kTechId.] = 17 // MAC build
    
    self.kMarineTechIdToMaterialOffset[kTechId.Attack] = 18
    self.kMarineTechIdToMaterialOffset[kTechId.SetRally] = 19
    self.kMarineTechIdToMaterialOffset[kTechId.SetTarget] = 28
    self.kMarineTechIdToMaterialOffset[kTechId.SquadMenu] = 20
    self.kMarineTechIdToMaterialOffset[kTechId.Weld] = 21
    self.kMarineTechIdToMaterialOffset[kTechId.BuildMenu] = 22
    self.kMarineTechIdToMaterialOffset[kTechId.AdvancedMenu] = 23    
    
    // Third row - Player/squad orders
    self.kMarineTechIdToMaterialOffset[kTechId.SquadMove] = 24
    self.kMarineTechIdToMaterialOffset[kTechId.SquadAttack] = 25
    // nothing for 26
    self.kMarineTechIdToMaterialOffset[kTechId.SquadDefend] = 27
    self.kMarineTechIdToMaterialOffset[kTechId.SquadHarass] = 28
    // "converge" for 29
    // "alert" for 30
    self.kMarineTechIdToMaterialOffset[kTechId.SquadRegroup] = 31
    self.kMarineTechIdToMaterialOffset[kTechId.SquadSeekAndDestroy] = 32    
    self.kMarineTechIdToMaterialOffset[kTechId.AssistMenu] = 33
    
    // Fourth row - droppables, research
    self.kMarineTechIdToMaterialOffset[kTechId.AmmoPack] = 36
    self.kMarineTechIdToMaterialOffset[kTechId.MedPack] = 37
    self.kMarineTechIdToMaterialOffset[kTechId.CommandFacility] = 38
    self.kMarineTechIdToMaterialOffset[kTechId.CommandFacilityUpgrade] = 38
    self.kMarineTechIdToMaterialOffset[kTechId.CommandCenter] = 39
    self.kMarineTechIdToMaterialOffset[kTechId.CommandCenterUpgrade] = 39
    self.kMarineTechIdToMaterialOffset[kTechId.JetpackTech] = 40
    self.kMarineTechIdToMaterialOffset[kTechId.Jetpack] = 40
    self.kMarineTechIdToMaterialOffset[kTechId.Scan] = 41
    self.kMarineTechIdToMaterialOffset[kTechId.FlamethrowerTech] = 42
    self.kMarineTechIdToMaterialOffset[kTechId.FlamethrowerAltTech] = 42
    self.kMarineTechIdToMaterialOffset[kTechId.SentryTech] = 43
    self.kMarineTechIdToMaterialOffset[kTechId.ARC] = 44
    self.kMarineTechIdToMaterialOffset[kTechId.CatPack] = 45
    self.kMarineTechIdToMaterialOffset[kTechId.CatPackTech] = 45
    self.kMarineTechIdToMaterialOffset[kTechId.NerveGasTech] = 46
    self.kMarineTechIdToMaterialOffset[kTechId.DualMinigunTech] = 47
    
    // Fifth row 
    self.kMarineTechIdToMaterialOffset[kTechId.ShotgunTech] = 48
    self.kMarineTechIdToMaterialOffset[kTechId.Armor1] = 49
    self.kMarineTechIdToMaterialOffset[kTechId.Armor2] = 50
    self.kMarineTechIdToMaterialOffset[kTechId.Armor3] = 51
    self.kMarineTechIdToMaterialOffset[kTechId.NanoDefense] = 52
    
    // upgrades
    self.kMarineTechIdToMaterialOffset[kTechId.Weapons1] = 55
    self.kMarineTechIdToMaterialOffset[kTechId.Weapons2] = 56
    self.kMarineTechIdToMaterialOffset[kTechId.Weapons3] = 57
    self.kMarineTechIdToMaterialOffset[kTechId.CommandStationUpgradesMenu] = 58
    self.kMarineTechIdToMaterialOffset[kTechId.ArmoryEquipmentMenu] = 59
    self.kMarineTechIdToMaterialOffset[kTechId.ArmoryUpgradesMenu] = 59
    
    self.kMarineTechIdToMaterialOffset[kTechId.Marine] = 60
    self.kMarineTechIdToMaterialOffset[kTechId.Heavy] = 61
    self.kMarineTechIdToMaterialOffset[kTechId.MACEMPTech] = 62
    self.kMarineTechIdToMaterialOffset[kTechId.MACEMP] = 62
    self.kMarineTechIdToMaterialOffset[kTechId.DistressBeacon] = 63
    self.kMarineTechIdToMaterialOffset[kTechId.ExtractorUpgrade] = 64
    self.kMarineTechIdToMaterialOffset[kTechId.AdvancedArmory] = 65
    self.kMarineTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 65
    self.kMarineTechIdToMaterialOffset[kTechId.RifleUpgradeTech] = 66
    self.kMarineTechIdToMaterialOffset[kTechId.ARCSplashTech] = 67
    self.kMarineTechIdToMaterialOffset[kTechId.ARCArmorTech] = 68

    self.kMarineTechIdToMaterialOffset[kTechId.GrenadeLauncherTech] = 72
    self.kMarineTechIdToMaterialOffset[kTechId.JetpackFuelTech] = 73      
    self.kMarineTechIdToMaterialOffset[kTechId.JetpackArmorTech] = 74
    self.kMarineTechIdToMaterialOffset[kTechId.ExoskeletonTech] = 75
    self.kMarineTechIdToMaterialOffset[kTechId.Exoskeleton] = 76
    self.kMarineTechIdToMaterialOffset[kTechId.ExoskeletonLockdownTech] = 77
    self.kMarineTechIdToMaterialOffset[kTechId.ARCUndeploy] = 78
    self.kMarineTechIdToMaterialOffset[kTechId.ARCDeploy] = 79       
    
    self.kMarineTechIdToMaterialOffset[kTechId.MACMinesTech] = 80
    self.kMarineTechIdToMaterialOffset[kTechId.MACMine] = 81
    self.kMarineTechIdToMaterialOffset[kTechId.MACSpeedTech] = 82
        
    // Doors
    self.kMarineTechIdToMaterialOffset[kTechId.Door] = 84
    self.kMarineTechIdToMaterialOffset[kTechId.DoorOpen] = 85
    self.kMarineTechIdToMaterialOffset[kTechId.DoorClose] = 86
    self.kMarineTechIdToMaterialOffset[kTechId.DoorLock] = 87
    self.kMarineTechIdToMaterialOffset[kTechId.DoorUnlock] = 88
    // 89 = nozzle
    // 90 = tech point
    
    // Robotics factory menus
    self.kMarineTechIdToMaterialOffset[kTechId.RoboticsFactoryARCUpgradesMenu] = 91
    self.kMarineTechIdToMaterialOffset[kTechId.RoboticsFactoryMACUpgradesMenu] = 93
    self.kMarineTechIdToMaterialOffset[kTechId.PrototypeLab] = 93
    self.kMarineTechIdToMaterialOffset[kTechId.PrototypeLabUpgradesMenu] = 94        
    
    self.kMarineTechIdToMaterialOffset[kTechId.SelectRedSquad] = 96
    self.kMarineTechIdToMaterialOffset[kTechId.SelectBlueSquad] = 97
    self.kMarineTechIdToMaterialOffset[kTechId.SelectGreenSquad] = 98
    self.kMarineTechIdToMaterialOffset[kTechId.SelectYellowSquad] = 99
    self.kMarineTechIdToMaterialOffset[kTechId.SelectOrangeSquad] = 100

    // Init alien offsets
    self.kAlienTechIdToMaterialOffset = {}
    
    // Generic orders 
    self.kAlienTechIdToMaterialOffset[kTechId.Default] = 0
    self.kAlienTechIdToMaterialOffset[kTechId.Move] = 1
    self.kAlienTechIdToMaterialOffset[kTechId.Attack] = 2
    self.kAlienTechIdToMaterialOffset[kTechId.Build] = 3
    self.kAlienTechIdToMaterialOffset[kTechId.Construct] = 4
    self.kAlienTechIdToMaterialOffset[kTechId.Stop] = 5
    self.kAlienTechIdToMaterialOffset[kTechId.SetRally] = 6
    self.kAlienTechIdToMaterialOffset[kTechId.SetTarget] = 7
    
    // Menus
    self.kAlienTechIdToMaterialOffset[kTechId.BuildMenu] = 8
    self.kAlienTechIdToMaterialOffset[kTechId.RootMenu] = 9
    self.kAlienTechIdToMaterialOffset[kTechId.SquadMenu] = 10
    self.kAlienTechIdToMaterialOffset[kTechId.MarkersMenu] = 11
    self.kAlienTechIdToMaterialOffset[kTechId.UpgradesMenu] = 12
    self.kAlienTechIdToMaterialOffset[kTechId.Grow] = 23
    self.kAlienTechIdToMaterialOffset[kTechId.Infestation] = 23
    self.kAlienTechIdToMaterialOffset[kTechId.MetabolizeTech] = 14
    self.kAlienTechIdToMaterialOffset[kTechId.Metabolize] = 15
       
    // Lifeforms
    self.kAlienTechIdToMaterialOffset[kTechId.Skulk] = 16
    self.kAlienTechIdToMaterialOffset[kTechId.Gorge] = 17
    self.kAlienTechIdToMaterialOffset[kTechId.Lerk] = 18
    self.kAlienTechIdToMaterialOffset[kTechId.Fade] = 19
    self.kAlienTechIdToMaterialOffset[kTechId.Onos] = 20
    self.kAlienTechIdToMaterialOffset[kTechId.Cancel] = 21
    
    // Structures
    self.kAlienTechIdToMaterialOffset[kTechId.Hive] = 24
    self.kAlienTechIdToMaterialOffset[kTechId.HiveMass] = 25
    self.kAlienTechIdToMaterialOffset[kTechId.HiveColony] = 26    
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing harvester
    self.kAlienTechIdToMaterialOffset[kTechId.Harvester] = 27
    self.kAlienTechIdToMaterialOffset[kTechId.Drifter] = 28
    self.kAlienTechIdToMaterialOffset[kTechId.HarvesterUpgrade] = 12
    self.kAlienTechIdToMaterialOffset[kTechId.Egg] = 30
    self.kAlienTechIdToMaterialOffset[kTechId.Cocoon] = 31
    
    // Hive upgrades and markers
    //self.kAlienTechIdToMaterialOffset[kTechId.] = 32
    self.kAlienTechIdToMaterialOffset[kTechId.HiveMassUpgrade] = 33
    self.kAlienTechIdToMaterialOffset[kTechId.HiveColonyUpgrade] = 34
    self.kAlienTechIdToMaterialOffset[kTechId.ThreatMarker] = 35
    self.kAlienTechIdToMaterialOffset[kTechId.LargeThreatMarker] = 36
    self.kAlienTechIdToMaterialOffset[kTechId.NeedHealingMarker] = 37
    self.kAlienTechIdToMaterialOffset[kTechId.WeakMarker] = 38
    self.kAlienTechIdToMaterialOffset[kTechId.ExpandingMarker] = 39
   
    // Crag
    self.kAlienTechIdToMaterialOffset[kTechId.Crag] = 40
    self.kAlienTechIdToMaterialOffset[kTechId.UpgradeCrag] = 41
    self.kAlienTechIdToMaterialOffset[kTechId.MatureCrag] = 42
    self.kAlienTechIdToMaterialOffset[kTechId.CragHeal] = 43
    self.kAlienTechIdToMaterialOffset[kTechId.CragUmbra] = 44
    self.kAlienTechIdToMaterialOffset[kTechId.CragBabblers] = 45 
    self.kAlienTechIdToMaterialOffset[kTechId.BabblerTech] = 46
    
    // Whip
    self.kAlienTechIdToMaterialOffset[kTechId.Whip] = 48
    self.kAlienTechIdToMaterialOffset[kTechId.UpgradeWhip] = 49
    self.kAlienTechIdToMaterialOffset[kTechId.MatureWhip] = 50
    self.kAlienTechIdToMaterialOffset[kTechId.WhipAcidStrike] = 51
    self.kAlienTechIdToMaterialOffset[kTechId.WhipFury] = 52
    self.kAlienTechIdToMaterialOffset[kTechId.WhipBombard] = 53 
    self.kAlienTechIdToMaterialOffset[kTechId.LobTech] = 54

    // Shift
    self.kAlienTechIdToMaterialOffset[kTechId.Shift] = 56
    self.kAlienTechIdToMaterialOffset[kTechId.UpgradeShift] = 57
    self.kAlienTechIdToMaterialOffset[kTechId.MatureShift] = 58
    self.kAlienTechIdToMaterialOffset[kTechId.ShiftRecall] = 59
    self.kAlienTechIdToMaterialOffset[kTechId.ShiftEcho] = 60
    self.kAlienTechIdToMaterialOffset[kTechId.ShiftEnergize] = 61
    self.kAlienTechIdToMaterialOffset[kTechId.EchoTech] = 62
    
    // Shade
    self.kAlienTechIdToMaterialOffset[kTechId.Shade] = 64
    self.kAlienTechIdToMaterialOffset[kTechId.UpgradeShade] = 65
    self.kAlienTechIdToMaterialOffset[kTechId.MatureShade] = 66
    self.kAlienTechIdToMaterialOffset[kTechId.ShadeCloak] = 67
    self.kAlienTechIdToMaterialOffset[kTechId.ShadeDisorient] = 68
    self.kAlienTechIdToMaterialOffset[kTechId.ShadePhantasmMenu] = 69
    self.kAlienTechIdToMaterialOffset[kTechId.ShadePhantasmFade] = 69
    self.kAlienTechIdToMaterialOffset[kTechId.ShadePhantasmOnos] = 69
    self.kAlienTechIdToMaterialOffset[kTechId.ShadePhantasmHive] = 69
    self.kAlienTechIdToMaterialOffset[kTechId.PhantasmTech] = 70

    // Drifter
    self.kAlienTechIdToMaterialOffset[kTechId.DrifterFlareTech] = 72
    self.kAlienTechIdToMaterialOffset[kTechId.DrifterFlare] = 73
    self.kAlienTechIdToMaterialOffset[kTechId.DrifterParasiteTech] = 74
    self.kAlienTechIdToMaterialOffset[kTechId.DrifterParasite] = 75
    self.kAlienTechIdToMaterialOffset[kTechId.PiercingTech] = 76
    
    self.kAlienTechIdToMaterialOffset[kTechId.AlienArmor3Tech] = 77
    
    // Whip movement
    self.kAlienTechIdToMaterialOffset[kTechId.WhipUnroot] = 78
    self.kAlienTechIdToMaterialOffset[kTechId.WhipRoot] = 79
    
    // Upgrades #1
    self.kAlienTechIdToMaterialOffset[kTechId.AdrenalineTech] = 80
    self.kAlienTechIdToMaterialOffset[kTechId.CorpulenceTech] = 81
    self.kAlienTechIdToMaterialOffset[kTechId.BacteriaTech] = 82
    self.kAlienTechIdToMaterialOffset[kTechId.FeintTech] = 83
    self.kAlienTechIdToMaterialOffset[kTechId.SapTech] = 84
    self.kAlienTechIdToMaterialOffset[kTechId.StompTech] = 85
    self.kAlienTechIdToMaterialOffset[kTechId.BoneShieldTech] = 86
    self.kAlienTechIdToMaterialOffset[kTechId.CarapaceTech] = 87
    
    // Upgrades #2
    self.kAlienTechIdToMaterialOffset[kTechId.BloodThirstTech] = 89
    self.kAlienTechIdToMaterialOffset[kTechId.FeedTech] = 90
    self.kAlienTechIdToMaterialOffset[kTechId.Melee1Tech] = 91
    self.kAlienTechIdToMaterialOffset[kTechId.Melee2Tech] = 92
    self.kAlienTechIdToMaterialOffset[kTechId.Melee3Tech] = 93
    self.kAlienTechIdToMaterialOffset[kTechId.AlienArmor1Tech] = 94
    self.kAlienTechIdToMaterialOffset[kTechId.AlienArmor2Tech] = 95   
    
end

function Commander:GetMaterialXYOffset(techId, isaMarine)

    local index = nil
    
    local columns = 12
    if(isaMarine) then
        index = self.kMarineTechIdToMaterialOffset[techId]
    else
        index = self.kAlienTechIdToMaterialOffset[techId]
        columns = 8
    end

    if(index ~= nil) then
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function Commander:GetPixelCoordsForIcon(entityId)

    local ent = Shared.GetEntity(entityId)
    
    if (ent ~= nil and ent:isa("ScriptActor")) then
    
        local techId = ent:GetTechId()
        
        if (techId ~= kTechId.None) then
            
            local xOffset, yOffset = self:GetMaterialXYOffset(techId, self:isa("MarineCommander"))
            
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
