// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
kEffectSurface              = "surface"

// Set to class name to display debug info for objects of that class, to "" to display everything, 
// or nil to disable
gEffectDebugClass = nil

// Graphical debug text (table of GUIDebugText objects)
gDebugTextList = {}

//////////////////////
// Public functions //
//////////////////////
function GetEffectManager()

    if not gEffectManager then    
        gEffectManager = EffectManager()        
    end
    
    return gEffectManager
    
end

// Returns true if this effect should be displayed to the log
function EffectManager:GetDisplayDebug(effectTable, triggeringEntity)

    local debug = false
    
    if Shared.GetDevMode() and not Shared.GetIsRunningPrediction() then

        if (effectTable == nil or not (effectTable[kEffectParamSilent] == true)) then
    
            if  (gEffectDebugClass == "") or (gEffectDebugClass and triggeringEntity and triggeringEntity:isa(gEffectDebugClass)) then
            
                debug = true
                
            else
            
                // Special-case view models for convenience
                if (effectTable[kViewModelCinematicType] or effectTable[kViewModelAnimationType]) and triggeringEntity and triggeringEntity.GetViewModelEntity then
                
                    local viewModelEntity = triggeringEntity:GetViewModelEntity()
                    
                    if viewModelEntity and gEffectDebugClass and viewModelEntity:isa(gEffectDebugClass) then
            
                        debug = true
                        
                    end
                
                end
                
            end
            
        end 
       
    end

    return debug
    
end

// Print debug info to log whenever about to trigger an effect. stringParam will be an asset name or animation name.
function EffectManager:DisplayDebug(stringParam, effectTable, triggeringParams, triggeringEntity)

    if self:GetDisplayDebug(effectTable, triggeringEntity) then
    
        local effectType = "unknown"
        for index, type in ipairs(kEffectTypes) do
            if effectTable[type] then
                effectType = type
                break
            end
        end
    
        local triggeringEntityText = ""
        if triggeringEntity then
            triggeringEntityText = string.format(" on %s", SafeClassName(triggeringEntity))
        end
        
        Print("  Playing %s \"%s\": %s%s", effectType, ToString(stringParam), ToString(triggeringParams), triggeringEntityText)
        
        // Create rising graphical text at world position when debug is on
        local debugText = string.format("%s '%s' (%s)", effectType, ToString(stringParam), GetClientServerString())
        local debugOrigin = triggeringEntity:GetOrigin()
        
        if Client then
            self:AddDebugText(debugText, debugOrigin, triggeringEntity)
        else
            // Send console message to all nearby clients
            local allPlayers = GetGamerules():GetAllPlayers()
            for index, toPlayer in ipairs(allPlayers) do
                if (toPlayer:GetOrigin() - debugOrigin):GetLength() < 25 then
                    local entIdString = ""
                    if triggeringEntity then
                        entIdString = ToString(triggeringEntity:GetId())
                    end
                    Server.SendCommand(toPlayer, string.format("debugtext \"%s\" %s %s", debugText, EncodePointInString(debugOrigin), entIdString))
                end
            end
        end        
    end    
    
end

if Client then

function EffectManager:AddDebugText(debugText, origin, ent)

    local messageOffset = 0
    if ent then
    
        // Count number of debug messages entity already has so we can offset
        // message when drawing it (to avoid overlap)
        for index, debugPair in ipairs(gDebugTextList) do
            if debugPair[2] == ent then
                messageOffset = messageOffset + 1
            end
        end
        
    end
    
    local debugTextObject = GetGUIManager():CreateGUIScript("GUIDebugText")
    debugTextObject:SetDebugInfo(debugText, origin, messageOffset)            
    table.insert(gDebugTextList, {debugTextObject, ent})
    
end

end

function EffectManager:AddEffectData(identifier, data)

    ASSERT(identifier)
    ASSERT(data)
    
    if data ~= nil then
    
        if not self.effectTables then
            self.effectTables = {}
        end
        
        if not self.queuedEffects then
            self.queuedEffects = {}
        end
        
        if not self.loopingSounds then
            self.loopingSounds = {}
        end
        
        // Replace it if we've already added it (hotloading)
        for index, effectTablePair in ipairs(self.effectTables) do
        
            if effectTablePair[1] == identifier then

                Print("Replacing %s", ToString(effectTablePair))            
                table.remove(self.effectTables, index)
                break
                
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

function EffectManager:GetQueuedText()
    return ConditionalValue(self.locked, " (queued)", "")
end

function EffectManager:SetLockedPlayer(player)
    self.lockedPlayer = player    
end

function EffectManager:TriggerQueuedEffects()

    PROFILE("EffectManager:TriggerQueuedEffects")
    
    if self.queuedEffects and self.effectTables then
    
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

    if self.lockedPlayer == nil or (triggeringEntity ~= nil and triggeringEntity:GetParent() == self.lockedPlayer) then
    
        if self.effectTables then
            for index, effectTablePair in ipairs(self.effectTables) do
                self:InternalTriggerMatchingEffects(effectTablePair[2], triggeringEntity, effectName, tableParams)    
            end
        end
    
    else
        table.insert(self.queuedEffects, {effectName, tableParams, triggeringEntity})
    end
    
end

///////////////////////
// Private functions //
///////////////////////
function GetAssetNameFromType(effectTable)

    for index, assetName in ipairs(kEffectTypes) do
    
        if effectTable[assetName] then
        
            return effectTable[assetName]
            
        end
        
    end
    
    return nil

end

// Find string representing animation or choose random animation from table if specified
// Pass surface to substitute in for first %s, if any.
function EffectManager:ChooseAssetName(effectTable, surfaceValue, triggeringEntity)

    local assetName = GetAssetNameFromType(effectTable)   
    if assetName then
    
        if type(assetName) == "table" then
            assetName = chooseWeightedEntry(assetName)
        end

    else
        assetName = ""
    end
    
    if string.find(assetName, "%%s") then
    
        if surfaceValue and surfaceValue ~= "" then
            assetName = string.format(assetName, surfaceValue)
        elseif self:GetDisplayDebug(effectTable, triggeringEntity) then
            Print("EffectManager:ChooseAssetName(): Trying to trigger \"%s\" but surface is \"%s\".", assetName, ToString(surfaceValue))
        end
        
    end
    
    return assetName
    
end

function EffectManager:InternalPrecacheEffectTable(globalEffectTable)

    for currentEffectName, currentEffectTable in pairs(globalEffectTable) do

        for effectBlockDescription, effectBlockTable in pairs(currentEffectTable) do
            
            for effectTableIndex, effectTable in ipairs(effectBlockTable) do

                // Get asset file name from effect data            
                local assetEntry = GetAssetNameFromType(effectTable)

                // nil allowed - means we can stop processing
                if assetEntry == nil then
                
                elseif type(assetEntry) == "string" then
                
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
                elseif not effectTable[kAnimationType] and not effectTable[kViewModelAnimationType] and not effectTable[kOverlayAnimationType] and not effectTable[kRagdollType] then
                    Print("No asset name found in block \"%s\"", ToString(effectTable))                    
                end
                
            end
            
        end
            
    end

end

function EffectManager:InternalTriggerMatchingEffects(inputEffectTable, triggeringEntity, effectName, tableParams, outputEffects)

    PROFILE("EffectManager:InternalTriggerMatchingEffects")
    
    local currentEffectBlockTable = inputEffectTable[effectName]
    
    if currentEffectBlockTable then
    
        for effectTableIndex, effectTable in pairs(currentEffectBlockTable) do
        
            local keepProcessing = true
        
            for assetEntryIndex, assetEntry in ipairs(effectTable) do
            
                if keepProcessing then
                
                    if self:InternalGetEffectMatches(triggeringEntity, assetEntry, tableParams) then
                    
                        if self:GetDisplayDebug(assetEntry, triggeringEntity) then
                            Print("Triggering effect \"%s\" on %s (%s)", effectName, SafeClassName(triggeringEntity), ToString(assetEntry))
                        end
                        
                        // Trigger effect
                        self:InternalTriggerEffect(assetEntry, tableParams, triggeringEntity)

                        // Stop processing this block "done" specified
                        if assetEntry[kEffectParamDone] == true then                    
                    
                            keepProcessing = false
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
            
    end

end

// Loop through all filters specified and see if they equal ones specified 
function EffectManager:InternalGetEffectMatches(triggeringEntity, assetEntry, tableParams)

    PROFILE("EffectManager:InternalGetEffectMatches")

    for filterName, filterValue in pairs(assetEntry) do
    
        if table.find(kEffectFilters, filterName) then
    
            if not tableParams then
                return false
            end
            
            local triggerFilterValue = tableParams[filterName]
        
            // Check class and doer names via :isa
            if (filterName == kEffectFilterClassName) or (filterName == kEffectFilterDoerName) then

                if triggeringEntity and triggeringEntity:isa("ViewModel") and triggeringEntity:GetWeapon() and triggeringEntity:GetWeapon():isa(filterValue) then
                
                    // Allow view models to trigger animations for weapons                
                    
                elseif not triggeringEntity or not triggeringEntity:isa(filterValue) then        
                    return false            
                end

            else
            
                // Otherwise makes ure specified parameters match
                if filterValue ~= triggerFilterValue then

                    if triggeringEntity and self:GetDisplayDebug(assetEntry, triggeringEntity) then
                        Print("  Effect not triggered because filter %s failed (%s ~= %s)%s (ent: %s, params: %s)", ToString(filterName), ToString(filterValue), ToString(triggerParamValue), self:GetQueuedText(), SafeClassName(triggeringEntity), ToString(tableParams)) 
                    end
                    
                    return false
                    
                end
            
            end
            
        end            
        
    end
        
    return true

end

function EffectManager:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)

    local coords = triggeringParams[kEffectHostCoords]    
    local cinematicName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local success = false
    
    // World cinematics
    if effectTable[kCinematicType] then
    
        Shared.CreateEffect(nil, cinematicName, nil, coords)
        success = true

    // World positioned shared cinematics
    elseif effectTable[kPlayerCinematicType] then
    
        Shared.CreateEffect(player, cinematicName, nil, coords)
        success = true        

    // Parent effect to triggering entity
    elseif effectTable[kParentedCinematicType] then
    
        local attachPoint = effectTable[kEffectParamAttachPoint] 
        if attachPoint then
            Shared.CreateAttachedEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity(), attachPoint, false)
        else
            Shared.CreateEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity())
        end
        
        success = true
        
    // Third-person weapon cinematics
    elseif effectTable[kWeaponCinematicType] then

        if Server then
        
            local attachPoint = effectTable[kEffectParamAttachPoint] 
            if attachPoint then
                
                if player then
                
                    Shared.CreateAttachedEffect(player, cinematicName, triggeringEntity, Coords.GetIdentity(), attachPoint, false)
                    success = true
                    
                else
                    Print("InternalTriggerCinematic(%s, weapon_cinematic): Couldn't find parent for entity (%s).%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
                end
                
            else
               Print("InternalTriggerCinematic(%s, weapon_cinematic): No attach point specified.%s", cinematicName, self:GetQueuedText()) 
            end
            
        else
            success = true            
        end

    // View model cinematics            
    elseif effectTable[kViewModelCinematicType] then
    
        if Client then
        
            local attachPoint = effectTable[kEffectParamAttachPoint]
            if attachPoint then
            
                if player then
                
                    local viewModel = player:GetViewModelEntity()
                    if viewModel then
                    
                        Shared.CreateAttachedEffect(player, cinematicName, viewModel, Coords.GetTranslation(player:GetViewOffset()), attachPoint, true)    
                        success = true
                        
                    else
                        Print("InternalTriggerCinematic(%s, viewmodel_cinematic): No view model entity found for entity %s.%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
                    end

                else
                    Print("InternalTriggerCinematic(%s): Couldn't find parent for entity %s.%s", cinematicName, SafeClassName(triggeringEntity), self:GetQueuedText())
                end
                
            else
                Print("InternalTriggerCinematic(%s): No attach point specified.%s", cinematicName, self:GetQueuedText())
            end        
            
        else
            success = true
        end        

    elseif effectTable[kLoopingCinematicType] then
        
        if triggeringEntity and triggeringEntity.AttachEffect then
        
            success = triggeringEntity:AttachEffect(cinematicName, coords, Cinematic.Repeat_Endless)            
            
        end

    elseif effectTable[kStopCinematicType] then
    
        Shared.StopEffect(player, cinematicName, triggeringEntity)
        
        if triggeringEntity and triggeringEntity.RemoveEffect then
            success = triggeringEntity:RemoveEffect(cinematicName)
        end

    end    
    
    if success then
        self:DisplayDebug(ToString(cinematicName), effectTable, triggeringParams, triggeringEntity)
    end
    
    
    return success
    
end

// Assumes triggering entity is either a player, or a weapon who's owner is a player
function GetPlayerFromTriggeringEntity(triggeringEntity)

    if triggeringEntity then
        
        if triggeringEntity:isa("Player") then
            return triggeringEntity
        else
            local parent = triggeringEntity:GetParent()
            if parent then
                return parent
            end
        end
        
    end

    return nil
    
end

function EffectManager:GetPlayingLoopingSound(player, soundAssetName)
    
    for index, loopingSoundEntry in ipairs(self.loopingSounds) do
    
        if (loopingSoundEntry[1] == player:GetId()) and (loopingSoundEntry[2] == soundAssetName) then
            return true
        end
        
    end
    
    return false
    
end

function EffectManager:PlayLoopingSound(player, soundAssetName)

    Shared.PlaySound(player, soundAssetName)
    
    table.insert(self.loopingSounds, {player:GetId(), soundAssetName})
    
end           

function EffectManager:StopLoopingSound(player, soundAssetName)

    if player then
    
        for index, loopingSoundEntry in ipairs(self.loopingSounds) do
        
            if (loopingSoundEntry[1] == player:GetId()) and (loopingSoundEntry[2] == soundAssetName) then
            
                Shared.StopSound(player, soundAssetName)
                
                table.remove(self.loopingSounds, index)
                
                return true
                
            end
            
        end    
        
    end
    
    return false
    
end

// Returns false if an error was encountered (returns true even if sound was supposed to have stopped when not playing
function EffectManager:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)

    local success = false
    local soundAssetName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)
    local coords = triggeringParams[kEffectHostCoords]    
    local player = GetPlayerFromTriggeringEntity(triggeringEntity)
    local volume = ConditionalValue(triggeringParams[kEffectParamVolume], triggeringParams[kEffectParamVolume], 1.0)
    
    self:DisplayDebug(ToString(soundAssetName), effectTable, triggeringParams, triggeringEntity)
    
    // Play world sound
    if effectTable[kSoundType] then
    
        if player then
        
            // Shared player sound
            Shared.PlaySound(player, soundAssetName)
            success = true
            
        else
        
            // World sound
            Shared.PlayWorldSound(nil, soundAssetName, nil, coords.origin)
            success = true
            
        end
        
    // Play parented sound
    elseif effectTable[kParentedSoundType] then
    
        Shared.PlayWorldSound(player, soundAssetName, triggeringEntity, Vector(0, 0, 0))
        success = true

    // Looping sounds
    elseif effectTable[kLoopingSoundType] then
    
        if not self:GetPlayingLoopingSound(player, soundAssetName) then
        
            self:PlayLoopingSound(player, soundAssetName)

        end
        
        // Mark as succes either way because this is the common usage
        success = true

    elseif effectTable[kPrivateSoundType] then
    
        Shared.PlayPrivateSound(player, soundAssetName, player, volume, Vector(0, 0, 0))
        success = true
        
    elseif effectTable[kStopSoundType] then
    
        if not self:StopLoopingSound(player, soundAssetName) then
            Shared.StopSound(player, soundAssetName)
        end
        
        success = true
        
    end
    
    return success
    
end

function EffectManager:InternalTriggerAnimation(effectTable, triggeringParams, triggeringEntity)
    
    local success = false
    local blendTime = ConditionalValue(effectTable[kEffectParamBlendTime], effectTable[kEffectParamBlendTime], 0)
    local force = ConditionalValue(effectTable[kEffectParamForce], effectTable[kEffectParamForce], false)
    
    // Speed is passed in from triggerer
    local effectSpeed = ConditionalValue(effectTable[kEffectParamAnimationSpeed], effectTable[kEffectParamAnimationSpeed], 1)
    local triggererSpeed = ConditionalValue(triggeringParams[kEffectParamAnimationSpeed], triggeringParams[kEffectParamAnimationSpeed], 1)    
    local speed = effectSpeed * triggererSpeed
    
    local parent = nil
    if triggeringEntity and triggeringEntity.GetParent then
        parent = triggeringEntity:GetParent()
    end
    
    local animationName = self:ChooseAssetName(effectTable, triggeringParams[kEffectSurface], triggeringEntity)
    if animationName == "" then
    
        // Empty animations are allowed and do nothing (ie, to not play idle)
        success = true
        
    else
    
        if effectTable[kAnimationType] then
        
            if blendTime == 0 then
            
                triggeringEntity:SetAnimation(animationName, force)
                success = true
                
            elseif triggeringEntity.SetAnimationWithBlending then
            
                triggeringEntity:SetAnimationWithBlending(animationName, blendTime, force)
                success = true
                
            else
                Print("No SetAnimationWithBlending function on %s%s", SafeClassName(triggeringEntity), self:GetQueuedText())
            end
        
        // Assumes triggering entity is player or weapon. Either way it plays the view model animation on the player.
        elseif effectTable[kViewModelAnimationType] then

            if parent and parent.SetViewAnimation then        
                triggeringEntity = parent
            end        
            
            // Get view model entity form our parent - assumes this is being called
            if triggeringEntity and triggeringEntity.SetViewAnimation then
                
                triggeringEntity:SetViewAnimation(animationName, not force, ConditionalValue(blend ~= 0, blend, nil), speed)
                success = true

            else
                Print("EffectManager:InternalTriggerAnimation(): Tried to play view model animation \"%s\" but entity %s isn't a player or a weapon.%s", animationName, SafeClassName(triggeringEntity), self:GetQueuedText())
            end

        elseif effectTable[kOverlayAnimationType] then
        
            if parent and parent.SetOverlayAnimation then
                triggeringEntity = parent
            end
            
            if triggeringEntity and triggeringEntity.SetOverlayAnimation then
            
                triggeringEntity:SetOverlayAnimation(animationName, not force)        
                success = true
                
            else
                Print("EffectManager:InternalTriggerAnimation(): Tried to play overlay animation \"%s\" but entity %s doesn't have method.%s", assetName, SafeClassName(triggeringEntity), self:GetQueuedText())
            end

        end
        
    end
    
    if success then
        self:DisplayDebug(ToString(animationName), effectTable, triggeringParams, triggeringEntity)
    end
    
    return success

end

function EffectManager:InternalTriggerRagdoll(effectTable, triggeringParams, triggeringEntity)

    local success = false
    
    if effectTable[kRagdollType] then
    
        if triggeringEntity and triggeringEntity.SetRagdoll then
        
            local deathTime = ConditionalValue(effectTable[kEffectParamDeathTime], effectTable[kEffectParamDeathTime], nil)
            triggeringEntity:SetRagdoll(deathTime)
        
            self:DisplayDebug(kRagdollType, effectTable, triggeringParams, triggeringEntity)
        
            success = true
            
        end
        
    end
    
    return success
    
end

function EffectManager:InternalTriggerEffect(effectTable, triggeringParams, triggeringEntity)

    local success = false
    
    if effectTable[kCinematicType] or effectTable[kWeaponCinematicType] or effectTable[kViewModelCinematicType] or effectTable[kPlayerCinematicType] or effectTable[kParentedCinematicType] or effectTable[kLoopingCinematicType] or effectTable[kStopCinematicType] then
    
        success = self:InternalTriggerCinematic(effectTable, triggeringParams, triggeringEntity)
        
    elseif effectTable[kSoundType] or effectTable[kParentedSoundType] or effectTable[kLoopingSoundType] or effectTable[kPrivateSoundType] or effectTable[kStopSoundType] then
    
        success = self:InternalTriggerSound(effectTable, triggeringParams, triggeringEntity)
        
    elseif effectTable[kAnimationType] or effectTable[kViewModelAnimationType] or effectTable[kOverlayAnimationType] then
    
        success = self:InternalTriggerAnimation(effectTable, triggeringParams, triggeringEntity)

    elseif effectTable[kRagdollType] then
    
        success = self:InternalTriggerRagdoll(effectTable, triggeringParams, triggeringEntity)
        
    end
    
    if not success and self:GetDisplayDebug(effectTable, triggeringEntity) then
        Print("InternalTriggerEffect(%s) - didn't trigger effect (%s).", ToString(effectTable), SafeClassName(triggeringEntity))
    end
    
    return success
    
end
