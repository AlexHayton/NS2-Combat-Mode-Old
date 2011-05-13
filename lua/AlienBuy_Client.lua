//=============================================================================
//
// lua/AlienBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
Script.Load("lua/InterfaceSounds_Client.lua")
Script.Load("lua/AlienUpgrades_Client.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/Gorge.lua")
Script.Load("lua/Lerk.lua")
Script.Load("lua/Fade.lua")
Script.Load("lua/Onos.lua")

// Indices passed in from flash
local indexToAlienTechIdTable = {kTechId.Fade, kTechId.Gorge, kTechId.Lerk, kTechId.Onos, kTechId.Skulk}

function IndexToAlienTechId(index)

    if index >= 1 and index <= table.count(indexToAlienTechIdTable) then
        return indexToAlienTechIdTable[index]
    else    
        Print("IndexToAlienTechId(%d) - invalid id passed", index)
        return kTechId.None
    end
    
end

function AlienTechIdToIndex(techId)
    for index, alienTechId in ipairs(indexToAlienTechIdTable) do
        if techId == alienTechId then
            return index
        end
    end
    
    ASSERT(false, "AlienTechIdToIndex(" .. ToString(techId) .. ") - invalid tech id passed")
    return 0
    
end

/**
 * Return 1-d array of name, hp, ap, and cost for this class index
 */
function AlienBuy_GetClassStats(idx)

    if idx == nil then
        Print("AlienBuy_GetClassStats(nil) called")
    end
    
    // name, hp, ap, cost
    local techId = IndexToAlienTechId(idx)
    
    if techId == kTechId.Fade then
        return {"Fade", Fade.kHealth, Fade.kArmor, kFadeCost}
    elseif techId == kTechId.Gorge then
        return {"Gorge", Gorge.kHealth, Gorge.kArmor, kGorgeCost}
    elseif techId == kTechId.Lerk then
        return {"Lerk", Lerk.kHealth, Lerk.kArmor, kLerkCost}
    elseif techId == kTechId.Onos then
        return {"Onos", Onos.kHealth, Onos.kArmor, kOnosCost}
    else
        return {"Skulk", Skulk.kHealth, Skulk.kArmor, kSkulkCost}
    end   
    
end

// iconx, icony, name, research, cost
function GetUnpurchasedUpgradeInfoArray(techIdTable)

    local t = {}
    
    for index, techId in ipairs(techIdTable) do
    
        local success, iconX, iconY = GetAlienUpgradeIconXY(techId)
        
        if success then
        
            table.insert(t, iconX)
            table.insert(t, iconY)
            
            table.insert(t, LookupTechData(techId, kTechDataDisplayName))
            
            table.insert(t, GetTechTree():GetResearchProgressForBuyNode(techId))
            
            table.insert(t, LookupTechData(techId, kTechDataCostKey, 0))
            
        end
        
    end
    
    return t
    
end

function GetUnpurchasedTechIds(techId)

    // Get list of potential upgrades for lifeform. These are tech nodes with
    // "addOnTechId" set to this tech id.
    local addOnUpgrades = {}
    
    local player = Client.GetLocalPlayer()
    local techTree = GetTechTree()
    
    if techTree ~= nil then
    
        addOnUpgrades = techTree:GetAddOnsForTechId(techId)
        
        // If we've already purchased it, remove it. Iterate through a different
        // table as we'll be changing it as we go.
        local addOnCopy = {}
        table.copy(addOnUpgrades, addOnCopy)

        for key, value in pairs(addOnCopy) do
        
            local hasTech = player:GetHasUpgrade(value)
            
            if hasTech then
            
                table.removevalue(addOnUpgrades, value)
                
            end
            
        end
        
    end
    
    return addOnUpgrades
    
end

/**
 * Return 1-d array of all unpurchased upgrades for this class index
 * Format is x icon offset, y icon offset, name, 
 * research pct [0.0 - 1.0], and cost
 */
function AlienBuy_GetUnpurchasedUpgrades(idx)
    if idx == nil then
        Print("AlienBuy_GetUnpurchasedUpgrades(nil) called")
        return {}
    end
    
    return GetUnpurchasedUpgradeInfoArray(GetUnpurchasedTechIds(IndexToAlienTechId(idx)))   
end

function GetPurchasedUpgradeInfoArray(techIdTable)
    local t = {}
    
    for index, id in ipairs(techIdTable) do
    
        local success, iconX, iconY = GetAlienUpgradeIconXY(id)
        
        if success then
        
            table.insert(t, iconX)
            table.insert(t, iconY)
            table.insert(t, LookupTechData(id, kTechDataDisplayName))
            
        else
        
            Print("GetPurchasedUpgradeInfoArray():GetAlienUpgradeIconXY(%s): Couldn't find upgrade icon.", ToString(id))
            
        end
    end
    
    return t
end

/**
 * Return 1-d array of all purchased upgrades for this class index
 * Format is x icon offset, y icon offset, and name
 */
function AlienBuy_GetPurchasedUpgrades(idx)

    // If this is us
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
    if AlienTechIdToIndex(techId) == idx then
        return GetPurchasedUpgradeInfoArray(player:GetUpgrades())
    end
    
    // Any alien that we haven't evolved to shows no purchased upgrades on the menu (TODO: handle global upgrades)
    return {}
    
end

function PurchaseTech(purchaseId)

    local player = Client.GetLocalPlayer()
    local techNode = GetTechTree():GetTechNode(purchaseId)
    
    if techNode ~= nil then
    
        if techNode:GetAvailable() then
        
            if techNode:GetCost() <= player:GetResources() then
            
                Client.ConsoleCommand("buy " .. tostring(purchaseId))
                
                Shared.PlayPrivateSound(player, Alien.kSpendResourcesSoundName, player, 1.0, Vector(0, 0, 0))
                
            else
            
                Shared.PlayPrivateSound(player, player:GetNotEnoughResourcesSound(), player, 1.0, Vector(0, 0, 0))
            
            end
            
        end
        
    else
    
        Print("PurchaseTech(): Couldn't find tech node %d", purchaseId)
        
    end
    
    Shared.PlayPrivateSound(player, buttonClickSound, player, 1.0, Vector(0, 0, 0))

end

/**
 * Indicated the selected index for the selected alien has been purchased.
 */
function AlienBuy_PurchaseUpgrade(idx, upgradeIndex)
    local unpurchasedIds = GetUnpurchasedTechIds(IndexToAlienTechId(idx))
    local purchaseId = unpurchasedIds[upgradeIndex]
    PurchaseTech(purchaseId)    
end

function GetAlienTechNode(idx, isAlienIndex)

    local techNode = nil
    
    local techId = idx
    
    if isAlienIndex then
        techId = IndexToAlienTechId(idx)
    end
    
    local techTree = GetTechTree()
    
    if techTree ~= nil then
        techNode = techTree:GetTechNode(techId)
    end
    
    return techNode
    
end

/**
 * Return true if alien type is researched, false otherwise
 */
function AlienBuy_IsAlienResearched(alienType)
    local techNode = GetAlienTechNode(alienType, true)
    return (techNode ~= nil) and techNode:GetAvailable()    
end

/**
 * Return cost for the base alien type
 */
function AlienBuy_GetAlienCost(alienType)

    local cost = nil
    
    local techNode = GetAlienTechNode(alienType, true)
    if techNode ~= nil then
        cost = techNode:GetCost()
    end
    
    if cost == nil then
        cost = 0
    end
    
    return cost
    
end

/**
 * Return current alien type
 */
function AlienBuy_GetCurrentAlien()
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
    local index = AlienTechIdToIndex(techId)
    
    ASSERT(index >= 1 and index <= table.count(indexToAlienTechIdTable), "AlienBuy_GetCurrentAlien(" .. ToString(techId) .. "): returning invalid index " .. ToString(index) .. " for " .. SafeClassName(player))
    
    return index
    
end

/**
 * Buy alien type
 */
function AlienBuy_BuyAlien(alienType)
    PurchaseTech(IndexToAlienTechId(alienType))
end

/**
 * User pressed close button
 */
function AlienBuy_Close()
    local player = Client.GetLocalPlayer()
    player:CloseMenu(kClassFlashIndex)
    Shared.PlayPrivateSound(player, buttonClickSound, player, 1.0, Vector(0, 0, 0))
end