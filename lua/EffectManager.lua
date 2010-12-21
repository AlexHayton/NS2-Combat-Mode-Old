// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\EffectManager.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Play sounds, cinematics or animations through a simple trigger. Decouples script from 
// artist, sound designer, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'EffectManager' 

// Set to true to use triggering entity's coords
kEffectHostCoords           = "effecthostcoords"

// Singleton on client and server
local gEffectManager = nil

//////////////////////
// Public functions //
//////////////////////
function GetEffectManager()

    if not gEffectManager then
    
        gEffectManager = EffectManager()
        
    end
    
    return gEffectManager
    
end

function EffectManager:GetEffectDebug()
    return false
end

function EffectManager:AddEffectData(identifier, data)

    if data ~= nil then
    
        if not self.effectTables then
            self.effectTables = {}
        end
        
        // Don't add it if we've already added it (hotloading)
        for index, effectTablePair in ipairs(self.effectTables) do
        
            if effectTablePair[1] == identifier then
            
                return
                
            end
            
        end
        
        table.insert(self.effectTables, {identifier, data})
        
    else
        Print("EffectManager:AddEffectData() called with nil effect data.")
    end    
    
end

function EffectManager:PrecacheEffects()

    // Loop through effect tables and precache all assets
    for index, effectTablePair in ipairs(self.effectTables) do
        self:InternalPrecacheEffectTable(effectTablePair[2])
    end
        
end

function EffectManager:GetLocked()
    return (self.locked == true)
end

function EffectManager:GetQueuedText()
    return ConditionalValue(self.locked, " (previously queued)", "")
end

function EffectManager:SetLocked(state)

    if state ~= self.locked then
    
        self.locked = state
        
    end
    
end

function EffectManager:TriggerQueuedEffects()

    if self.queuedEffects then
    
        for index, queuedEffect in ipairs(self.queuedEffects) do
        
            for index, effectTablePair in ipairs(self.effectTables) do
            
                self:InternalTriggerMatchingEffects(effectTablePair[2], queuedEffect[3], queuedEffect[1], queuedEffect[2])    
                
            end

        end
        
    end
    
    if self.queuedEffects == nil or table.count(self.queuedEffects) > 0 then
        self.queuedEffects = {}
    end
    
end

function EffectManager:TriggerEffects(effectName, tableParams, triggeringEntity)

    if self:GetEffectDebug() then
        Print("TriggerEffects(%s, %s)%s", effectName, SafeClassName(triggeringEntity), self:GetQueuedText())
    end
    
    if self.locked then
    
        table.insert(self.queuedEffects, {effectName, tableParams, triggeringEntity})
        
    else
    
        for index, effectTablePair in ipairs(self.effectTables) do
            self:InternalTriggerMatchingEffects(effectTablePair[2], triggeringEntity, effectName, tableParams)    
        end
        
    end
    
end

///////////////////////
// Private functions //
///////////////////////
function GetAssetEntry(effectTable)

    if effectTable[kCinematicType] then
        return effectTable[kCinematicType]
    elseif effectTable[kWeaponCinematicType] then
        return effectTable[kWeaponCinematicType]
    elseif effectTable[kViewModelCinematicType] then
        return effectTable[kViewModelCinematicType]
    elseif effectTable[kSoundType] then
        return effectTable[kSoundType]
    elseif effectTable[kParentedSoundType] then
        return effectTable[kParentedSoundType]
    end
    
    return nil
    
end

function EffectManager:InternalPrecacheEffectTable(globalEffectTable)

    for currentEffectName, currentEffectTable in pairs(globalEffectTable) do

        for effectBlockDescription, effectBlockTable in pairs(currentEffectTable) do
            
            for effectTableIndex, effectTable in ipairs(effectBlockTable) do
            
                local assetEntry = GetAssetEntry(effectTable)
                
                if type(assetEntry) == "string" then
                
                    if string.find(assetEntry, "%%") ~= nil then
                    
                        PrecacheMultipleAssets(assetEntry, kSurfaceList)
                        
                    else
                    
                        PrecacheAsset(assetEntry) 
                        
                    end
                    
                elseif type(assetEntry) == "table" then
                
                    for index, assetNameEntry in ipairs(assetEntry) do
                    
                        PrecacheAsset(assetNameEntry[2]) 
                        
                    end

                // else if not an animation
                elseif not effectTable[kAnimationType] and not effectTable[kViewModelAnimationType] and not effectTable[kOverlayAnimationType] then
                    Print("No asset name found in block \"%s\"", ToString(effectTable))                    
                end
                
            end
            
        end
            
    end

end

function EffectManager:InternalTriggerMatchingEffects(inputEffectTable, triggeringEntity, effectName, tableParams, outputEffects)

    local currentEffectBlockTable = inputEffectTable[effectName]
    
    if currentEffectBlockTable then
    
        for effectTableIndex, effectTable in pairs(currentEffectBlockTable) do
        
            local keepProcessing = true
        
            for assetEntryIndex, assetEntry in ipairs(effectTable) do
            
                if keepProcessing then
                
                    if self:InternalGetEffectMatches(triggeringEntity, assetEntry, tableParams) then
                    
                        // Trigger effect
                        self:InternalTriggerEffect(assetEntry, tableParams, triggeringEntity)

                        // Stop processing this block if it specified "stop" = true
                        if assetEntry[kEffectParamStop] == true then                    
                    
                            keepProcessing = false
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
            
    end

end

function EffectManager:InternalGetEffectMatches(triggeringEntity, assetEntry, tableParams)

    // Check class name
    local className = assetEntry[kEffectFilterClassName]
    if className then
    
        if not triggeringEntity or not triggeringEntity:isa(className) then
        
            return false
            
        end
        
    end
    
    // Loop through all filters specified and see if they equal ones specified 
    if tableParams then
    
        for paramName, paramValue in pairs(assetEntry) do
        
            if paramName == kEffectFilterDamageType or paramName == kEffectFilterIsAlien or paramName == kEffectFilterFlinchSevere then
            
                local triggerParamValue = tableParams[paramName]
                
                if paramValue ~= triggerParamValue then
                
                    //Print("  Effect not triggered because filter %s failed (%s ~= %s)%s", ToString(paramName), ToString(paramValue), ToString(triggerParam), self:GetQueuedText())
                
                    return false
                    
                end
            
            end
            
        end
        
    end
        
    return true

end

function EffectManager:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)

    local coords = triggeringParams[kEffectHostCoords]    
    local assetName = nil
    local success = false
    
    if effectTable[kCinematicType] then
    
        assetName = effectTable[kCinematicType]        
        Shared.CreateEffect(nil, assetName, nil, coords)
        success = true
        
    elseif effectTable[kWeaponCinematicType] then

        assetName = effectTable[kWeaponCinematicType]  
        
        local attachPoint = effectTable[kEffectParamAttachPoint] 
        if attachPoint then
        
            if triggeringEntity and triggeringEntity:isa("Player")then
                Shared.CreateAttachedEffect(triggeringEntity, cinematicName, self, Coords.GetIdentity(), attachPoint, false)
            else
                Print("InternalTriggerCinematic(%s, weapon_cinematic): Triggering entity not a player (%s).%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
            end
            
        else
           Print("InternalTriggerCinematic(%s, weapon_cinematic): No attach point specified.%s", assetName, self:GetQueuedText()) 
        end
            
    elseif effectTable[kViewModelCinematicType] then
    
        if Client then
        
        assetName = effectTable[kViewModelCinematicType]   
        
        local attachPoint = effectTable[kEffectParamAttachPoint]
        if attachPoint then
        
            if triggeringEntity and triggeringEntity.GetViewModelEntity and triggeringEntity.GetViewOffset then
            
                local viewModel = triggeringEntity:GetViewModelEntity()
                if viewModel then
                    Shared.CreateAttachedEffect(triggeringEntity, assetName, viewModel, Coords.GetTranslation(triggeringEntity:GetViewOffset()), attachPoint, true)    
                    success = true
                else
                    Print("InternalTriggerCinematic(%s, viewmodel_cinematic): No view model entity found for entity %s.%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
                end

            else
                Print("InternalTriggerCinematic(%s): No GetViewModelEntity or GetViewOffset method for entity %s.%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
            end
            
        else
            Print("InternalTriggerCinematic(%s): No attach point specified.%s", assetName, self:GetQueuedText())
        end        
        
        end
        
    end    
    
    if success then
        if assetName and self:GetEffectDebug() then
            Print("  Playing cinematic \"%s\": %s%s", assetName, ToString(triggeringParams), self:GetQueuedText())
        end
    else
        Print("  Error playing cinematic \"%s\": %s%s", assetName, ToString(triggeringParams), self:GetQueuedText())
    end
    
end

function EffectManager:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)

    local assetName = effectTable[kSoundType]
    local coords = triggeringParams[kEffectHostCoords]    
    
    if self:GetEffectDebug() then
        Print("  Playing sound \"%s\": %s%s", assetName, ToString(triggeringParams), self:GetQueuedText())
    end
    
    // Play world sound
    if effectTable[kSoundType] then
        
        if triggeringEntity and triggeringEntity:isa("Player") then
            Shared.PlaySound(triggeringEntity, assetName)
        else
            Shared.PlayWorldSound(nil, assetName, nil, coords.origin)
        end
        
    // Play parented sound
    elseif effectTable[kParentedSoundType] then
    
        if not triggeringEntity or triggeringEntity:isa("Player") then
            Shared.PlaySound(nil, assetName, triggeringEntity)
        else
            Shared.PlaySound(triggeringEntity, assetName, triggeringEntity)
        end
        
    end
    
end

function EffectManager:InternalTriggerAnimation(effectTable, triggeringParams, triggeringEntity)
    
    local animationName = ""
    local blendTime = ConditionalValue(effectTable[kEffectParamBlendTIme], effectTable[kEffectParamBlendTIme], 0)
    local force = ConditionalValue(effectTable[kEffectParamForce], effectTable[kEffectParamForce], false)
    local speed = ConditionalValue(effectTable[kEffectParamAnimationSpeed], effectTable[kEffectParamAnimationSpeed], 1)    
    
    if effectTable[kAnimationType] then
    
        animationName = effectTable[kAnimationType]
        
        if blendTime == 0 then
            triggeringEntity:SetAnimation(animationName, force)
        elseif triggeringEntity.SetBlendedAnimation then
            triggeringEntity:SetBlendedAnimation(animationName, force)
        else
            Print("No SetBlendedAnimation function on %s%s", SafeClassName(triggeringEntity), self:GetQueuedText())
        end
    
    elseif effectTable[kViewModelAnimationType] then
    
        animationName = effectTable[kViewModelAnimationType]
        
        local viewModelEntity = triggeringEntity:GetViewModelEntity()
        if triggeringEntity and triggeringEntity.SetViewAnimation then
            
            triggeringEntity:SetViewAnimation(animationName, not force, ConditionalValue(blend ~= 0, blend, nil), speed)
            
        else
            Print("EffectManager:InternalTriggerAnimation(): Tried to play view model animation \"%s\" but entity %s doesn't have method.%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
        end

    elseif effectTable[kOverlayAnimationType] then
    
        animationName = effectTable[kOverlayAnimationType]
        if triggeringEntity and triggeringEntity.SetOverlayAnimation then
        
            triggeringEntity:SetOverlayAnimation(animationName, not force)        
            
        else
            Print("EffectManager:InternalTriggerAnimation(): Tried to play overlay animation \"%s\" but entity %s doesn't have method.%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
        end
        
    end
    
    if self:GetEffectDebug() then
        Print("  Playing animation \"%s\": %s%s", animationName, ToString(triggeringParams), self:GetQueuedText())
    end

end

function EffectManager:InternalTriggerEffect(effectTable, triggeringParams, triggeringEntity)

    if effectTable[kCinematicType] or effectTable[kWeaponCinematicType] or effectTable[kViewModelCinematicType] then
    
        self:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)
        
    elseif effectTable[kSoundType] or effectTable[kParentedSoundType] then
    
        self:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)
        
    elseif effectTable[kAnimationType] or effectTable[kViewModelAnimationType] or effectTable[kOverlayAnimationType] then
    
        self:InternalTriggerAnimation(effectTable, triggeringParams, triggeringEntity)
        
    end
    
end

