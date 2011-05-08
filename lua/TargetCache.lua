
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TargetCache.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
Script.Load("lua/NS2Gamerules.lua") 
Script.Load("lua/TargetCache_Commands.lua")

class 'TargetCache'

TargetCache.kMstl = 1 // marine static target list index
TargetCache.kMmtl = 2 // marine mobile target list index
TargetCache.kAstl = 3 // alien static target list index
TargetCache.kAmtl = 4 // alien mobile target list index
TargetCache.kAshtl = 5 // alien static heal target list. Adds infestation to marine static target list, used by Crags when healing

TargetCache.kAllLogs = "BTIRDd"

TargetCache.kTargetListNames = { 
    "MarineStaticTargets",
    "MarineMobileTargets",
    "AlienStaticTargets",
    "AlienMobileTargets",
    "AlienStaticHealTargets"
}

// called from NS2GameRules. This is not an Entity, so OnCreate doesn't exists. 

function TargetCache:Init() 
    self.targetListCache = {}
    self.tlcVersions = {}
    self.zombieList = {}
    for i,_ in ipairs(TargetCache.kTargetListNames) do
        self.targetListCache[i] = {}
        self.tlcVersions[i] = 0
    end
    self.salVersion = 0
    self.tlcSalVersion = -1   
    // log tuning. Base, Target, Ignored, Rebuild, base (D)etail, local (d)etail 
    self.logs = ""//TargetCache.kAllLogs
    self.enabled = true
    self:Log("Target cache initilized")
end


function TargetCache:_Log(formatString, ...)

    local convertedArg = {}

    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(convertedArg, ToString(v))
    end

    Shared.Message(string.format(formatString, unpack(convertedArg)))
end


// basic logging, used when updating the target lists
function TargetCache:Log(format, ...)
    if self.logs:find("B") then
        self:_Log(format, ...)
    end
end 

// target acquistion logging. Logs when targets are selected (or healed)
function TargetCache:LogTarget(format, ...)
    if self.logs:find("T") then
        self:_Log(format, ...)
    end
end

// logs things that are not put on any list
function TargetCache:LogIgnored(format, ...)
    if self.logs:find("I") then
        self:_Log(format, ...)
    end
end

// logs when static target lists are rebuilt
function TargetCache:LogRebuild(format, ...)
    if self.logs:find("R") then
        self:_Log(format, ...)
    end
end

function TargetCache:IsEnabled()
    return self.enabled
end

//
// called by NS2Gamerules when it entities change
//
function TargetCache:OnEntityChange(oldId, newId)
    if oldId ~= nil then 
        self:_RemoveEntity(Shared.GetEntity(oldId))
    end
    if newId ~= nil then
        self:_InsertEntity(Shared.GetEntity(newId))
    end
end

//
// Some entities goes into a zombie stage when killed (power nodes)
// 
function TargetCache:OnKill(entity)
    // On kill we could handle by simply removing the entity. The problem is
    // that powernodes may become alive again, and there is no OnAlive() call made
    // So we add them to the zombieList. Once per tick, we check the zombielist to see
    // if they are alive. 
    self:_RemoveEntity(entity)
    // note ordering - remove entity will remove from zombie list.
    table.insert(self.zombieList,entity)
end

//
// Check if any zombies are up and running again

function TargetCache:_VerifyZombieList()
    local now = Shared.GetTime()
    if now ~= self.lastZombieCheckTime and #self.zombieList > 0 then
        self.lastZombieCheckTime = now
        // check zombielist for going alives. Iterate in reverse order to allow removals to work
        for i = #self.zombieList, 1, -1 do
            local zombie = self.zombieList[i]
            if self:_IsPossibleTarget(zombie, self:_IsMobile(zombie)) then
                self:Log("It's ALIVE! (%s)", zombie)
                table.remove(self.zombieList, i)
                self:_InsertEntity(zombie)
            end
        end
        if #self.zombieList ~= self.lastLoggedZombieListSize then
            if self.lastLoggedZombieListSize ~= nil then
                self:Log("%d zombies shambling around", #self.zombieList)
            end
            self.lastLoggedZombieListSize = #self.zombieList
        end
    end
end


//
// insert the given entity into the given list and increment its version
//
function TargetCache:_InsertInTargetList(listIndex, entity)
    local list = self.targetListCache[listIndex]
    table.insertunique(list,  entity)
    self.tlcVersions[listIndex] = self.tlcVersions[listIndex] + 1
    self:Log("Insert %s, added to %s, vers %d, len %d", entity,TargetCache.kTargetListNames[listIndex],self.tlcVersions[listIndex],table.maxn(list))
    if self.logs:find("D") then
        for i,target in ipairs(list) do  
            self:Log("%d : %s", i, target)
        end
    end
end
//
// Call when the insertEntity has been added to the newScriptActorList
//
function TargetCache:_InsertEntity(insertedEntity)
    if self:_IsCacheInvalid() then
        // cache is already invalid, so just return
        return 
    end
    local listIndex = self:_ClassifyEntity(insertedEntity)
    if listIndex ~= 0 then
        self:_InsertInTargetList(listIndex, insertedEntity)
        // special case: alien static heal list is the marine static target list + infestations
        if listIndex == TargetCache.kMstl then
            self:_InsertInTargetList(TargetCache.kAshtl, insertedEntity)
        end
    else
        self:LogIgnored("Insert ignoring %s", insertedEntity)
    end
end

//
// Call when the scriptActorList has changed due to deletion of the given entity.
//
function TargetCache:_RemoveEntity(deletedEntity)
    // always clear the zombie list
    table.removevalue(self.zombieList, deletedEntity)

    if self:_IsCacheInvalid() then
        // cache is already invalid, so just return
        return 
    end

    // a deleted entity may not maintain a status as a valid target, so the classification
    // may not work for it any longer. Go through all the lists and see if the entity was in it
    local found = false
    for i,list in ipairs(self.targetListCache) do
        local index = table.find(list,deletedEntity)
        if index then
            table.remove(list,index)
            self.tlcVersions[i] = self.tlcVersions[i] + 1
            self:Log("Remove %s from %s, vers %d, len %d", deletedEntity, TargetCache.kTargetListNames[i], self.tlcVersions[i], table.maxn(list))
            if self.logs:find("D") then
                for i,target in ipairs(list) do  
                    self:Log("%d : %s",i,target)
                end
            end
            found = true
        end
    end
    if not found then
        self:LogIgnored("Remove ignored %s", deletedEntity)
    end
end


//
// return to which list the given target belongs, or zero if it belongs to none
//
function TargetCache:_ClassifyEntity(target)
    // infestations are healed by Crags
    if target:isa("Infestation") then
        return TargetCache.kAshtl
    end
    local mobile = self:_IsMobile(target)
    if self:_ValidTarget(kAlienTeamType, target, mobile) then
        if mobile then    
            return TargetCache.kMmtl
        else
            return TargetCache.kMstl
        end
    elseif self:_ValidTarget(kMarineTeamType, target, mobile) then
        if mobile then    
            return TargetCache.kAmtl
        else
            return TargetCache.kAstl
        end        
    end
    return 0
end

function TargetCache:_IsPossibleTarget(target, mobile) 
    if target == nil then
        return false
    end
    local isStruct = target:isa("Structure")
    local validType = isStruct or mobile
    local validAndAlive = validType and (isStruct or target:GetIsAlive())
    return validAndAlive and target:GetCanTakeDamage()
end


// true if the target belongs to the given team and is valid
function TargetCache:_ValidTarget(enemyTeamType, target, mobile)
    return self:_IsPossibleTarget(target, mobile) and enemyTeamType == target:GetTeamType()
end
    

// players can move, and drifters, and MACs, and whips
// should really ask the entities instead...
TargetCache.kMobileClasses = { "Player", "Drifter", "MAC", "Whip" }

// true if the target is able to move. Should really be a method on the object instead, but
// I don't want to mess around with changes in multiple files.
function TargetCache:_IsMobile(target)
     for i,mobileCls in ipairs(TargetCache.kMobileClasses) do
         if target:isa(mobileCls) then 
            return true
         end
     end
     return false
end


function TargetCache:_UpdateTargetListCaches() 
    local newLists = {}
    for i,_ in ipairs(TargetCache.kTargetListNames) do
        newLists[i] = {}
    end 

    // insert the possible targets into the correct list
    // static targets are those that don't move, mobile targets are those that can move
    // valid targets are those that can be damaged (enemies that can be hurt)
    for i,target in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
        local listIndex = self:_ClassifyEntity(target)
        if listIndex ~= 0 then
            table.insert(newLists[listIndex], target)
            // kAshtl is a superset of kMstl
            if listIndex == TargetCache.kMstl then
                table.insert(newLists[TargetCache.kAshtl], target)    
            end
        end 
    end

    // make sure we get a consistent ordering
    function idSort(ent1, ent2)
        return ent1:GetId() < ent2:GetId()
    end
    
    // simpler cmpTable, as we know that neither t1 nor t2 is nil or contains holes, and that they are both sorted
    function cmpTable(t1, t2)
        if #t1 ~= #t2 then
            return false
        end
        for i,e1 in ipairs(t1) do
            if e1 ~= t2[i] then
                 return false
            end
        end   
        return true  
    end 
   
    // check if the new versions of each list changes, and change the version number if they do
    for i,newTable in ipairs(newLists) do
        table.sort(newTable,idSort)
        if not cmpTable(newTable, self.targetListCache[i]) then
            self.targetListCache[i] = newTable
            self.tlcVersions[i] = self.tlcVersions[i] + 1
            self:Log("Updating %s, vers %d, len %d",TargetCache.kTargetListNames[i], self.tlcVersions[i],table.maxn(newTable))
            for i,t in ipairs(newTable) do
                self:Log("%d : %s ", i, t)
            end 
       end
    end
    // mark as uptodate
    self.tlcSalVersion = self.salVersion
end

function TargetCache:_IsCacheInvalid() 
    return self.tlcSalVersion ~= self.salVersion
end

function TargetCache:VerifyTargetingListCache()
    self:_VerifyZombieList()
    if self:_IsCacheInvalid() then
        self:_UpdateTargetListCaches()
    end
end

function TargetCache:GetTargetList(listType)
    self:VerifyTargetingListCache()
    return self.targetListCache[listType]
end

// filter the targetList, returning a list of visible (target,sqRange) tuples inside the given range
function TargetCache:RebuildStaticTargetList(attacker, range, targetList)
     // static target list has changed. Rebuild it for the given entity
    local result = {}
    local sqRange = range * range
    local origin = attacker:GetEyePos()

    for i,target in ipairs(targetList) do
        local targetPoint = target:GetEngagementPoint()
        local sqR = (origin - targetPoint):GetLengthSquared()
        if (sqR <= sqRange) then
            // trace as a bullet, but only register hits on target
            local trace = Shared.TraceRay(origin, targetPoint, PhysicsMask.Bullets, EntityFilterOnly(target))
            if trace.entity == target then
                table.insert(result, { target, sqR })
            end
        end
    end
    return result
end

// filter the targetList, returning a list of visible (target,sqRange) tuples inside the given range
function TargetCache:RebuildStaticHealTargetList(attacker, range, targetList)
     // static target list has changed. Rebuild it for the given entity
    local result = {}
    local sqRange = range * range
    local origin = attacker:GetModelOrigin()
    for i,target in ipairs(targetList) do
        local sqR = (origin - target:GetEngagementPoint()):GetLengthSquared() 
        if (sqR <= sqRange) then
            table.insert(result, { target, sqR })
        end       
    end 
    return result
end


function TargetCache:_logRebuild(attacker, list, listType, version)
    self:LogRebuild("Rebuilt %s for %s, vers %d, len %d",TargetCache.kTargetListNames[listType], attacker, version , table.maxn(list))
    if self.logs:find("d") then
        for i,targetAndSqRange in ipairs(list) do 
            local target, sqRange = unpack(targetAndSqRange)      
            self:LogRebuild("%d : %s at range %.2f", i, target, math.sqrt(sqRange))
        end
    end
end
//
// Check and recalculate a static target list of the given type.
//
function TargetCache:GetStaticTargets(listType, attacker, range, list, version)
    self:VerifyTargetingListCache()
    local newVersion = self.tlcVersions[listType]
    if version ~= newVersion then        
        list = self:RebuildStaticTargetList(attacker, range, self.targetListCache[listType])
        version = newVersion
        self:_logRebuild(attacker, list, listType, version)
    end
    return list,version
end

//
// Check and recalculate a static target list of the given type.
//
function TargetCache:GetStaticHealTargets(listType, attacker, range, list, version)
    self:VerifyTargetingListCache()
    local newVersion = self.tlcVersions[listType]
    if version ~= newVersion then
        list = self:RebuildStaticHealTargetList(attacker, range, self.targetListCache[listType])
        version = newVersion
        self:_logRebuild(attacker, list, listType, version)
    end
    return list,version
end


function TargetCache:_GetRawTargetList(staticListUpdateMethod, attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
    self:VerifyTargetingListCache() 
    local result = {}
    local sqRange = range * range
    local origin = attacker:GetModelOrigin()
    for i,target in ipairs(self.targetListCache[mobileListType]) do
        // skip mobile targets which we don't have any range to
        if target:GetIsAlive() then
            local sqR = (origin - target:GetEngagementPoint()):GetLengthSquared()     
            if sqR < sqRange then        
                table.insert(result, {target, sqR})
            end
        end
    end
    
    // make sure the the list of static targets are uptodate
    staticList, staticListVersion = staticListUpdateMethod(self, staticListType, attacker, range, staticList, staticListVersion)
    
    // add in the static targets
    for i,targetAndSqRange in ipairs(staticList) do
        local target, sqRange = unpack(targetAndSqRange)
        if target:GetIsAlive() then
            table.insert(result, targetAndSqRange)
        end
    end
 
    function sortTargets(eR1, eR2)
        local ent1, r1 = unpack(eR1)
        local ent2, r2 = unpack(eR2)
        if r1 ~= r2 then
            return r1 < r2
        end
        // Make deterministic in case that distances are equal
        return ent1:GetId() < ent2:GetId()
    end
    // sort them closest first
    table.sort(result,sortTargets)
    
    return result,staticList,staticListVersion
end 

//
// Prepare to acquire a target by joining a mobile and a static targeting list together. 
// 
// The static list only contains visible static targets.
//
// Arguments: 
// - attacker - the attacker.
// - range - the maximum range of the attack. The returned target list will all be inside this range
// - mobileListType - a TargetCache.kXxxx value indicating the kind of list used for mobile targets
// - staticListType - a TargetCache.kXxxx value indicating the kind of list used for static targets
// - staticList - the current list of static targets
// - staticListVersion - the version of the base static target list the staticList is based on
//
// Return a tripple:
// - a list of (target, sqRange) tuples, sorted on sqRange
// - a list of static targets (the given staticList if version is unchanged, else a new one)
// - the version of the static list
//
function TargetCache:GetRawTargetList(staticListMethod, attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
    return self:_GetRawTargetList(self.GetStaticTargets, staticListMethod, attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
end

//
// Find all heal targets by joining a mobile and a static heal targeting list together. 
// 
// The static list contains all targets in range, including those not visible to the attacker(healer)
//
// Arguments: 
// - attacker - the attacker. 
// - range - the maximum range of the attack. The returned target list will all be inside this range
// - mobileListType - a TargetCache.kXxxx value indicating the kind of list used for mobile targets
// - staticListType - a TargetCache.kXxxx value indicating the kind of list used for static targets
// - staticList - the current list of static targets
// - staticListVersion - the version of the base static target list the staticList is based on
//
// Return a tripple:
// - a list of (target, sqRange) tuples, sorted on sqRange
// - a list of static targets (the given staticList if version is unchanged, else a new one)
// - the version of the static list
//
function TargetCache:GetRawHealTargetList(staticListMethod, attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
    return self:_GetRawTargetList(self.GetStaticHealTargets, staticListMethod, attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
end

//
// Acquire a target, choosing the closest player first, then the closest non-player.
//
// Arguments: 
// - attacker - the attacker. must have an origin
// - range - the maximum range of the attack. The returned target list will all be inside this range
// - mobileListType - a TargetCache.kXxxx value indicating the kind of list used for mobile targets
// - staticListType - a TargetCache.kXxxx value indicating the kind of list used for static targets
// - staticList - the current list of static targets
// - staticListVersion - the version of the base static target list the staticList is based on
//
// Return a tripple:
// - the chosen target
// - a list of static targets (the given staticList if version is unchanged, else a new one)
// - the version of the static list
//
function TargetCache:AcquirePlayerPreferenceTarget(attacker, range, mobileListType, staticListType, staticList, staticListVersion) 
    local targets
    targets, staticList, staticListVersion = self:GetRawTargetList(
            attacker,
            range, 
            mobileListType, 
            staticListType, 
            staticList, 
            staticListVersion) 

    local finalTarget = nil
    local finalRange = nil
    
    Server.dbgTracer.seeEntityTraceEnabled = true
    // We want to target the closest enemy player we can see, if any. 
    // If no player is found, then just choose the closest target that we can see, if any.
    local nonPlayers = {}
    for index, targetAndSqRange in ipairs(targets) do
        local target, sqRange = unpack(targetAndSqRange)
        if target:isa("Player") then
            if attacker:GetCanSeeEntity(target) then
                finalTarget = target
                finalRange = math.sqrt(sqRange)
                break
            end
        else
            table.insert(nonPlayers, targetAndSqRange)
        end                          
    end
    // choose closest non-player
    if finalTarget == nil then
        for index,targetAndSqRange in ipairs(nonPlayers) do
            local target, sqRange = unpack(targetAndSqRange)
            // as everything except can see is already checked in the cached target lists, we
            // don't need to call GetIs_ValidTarget() here
            if attacker:GetCanSeeEntity(target) then
                finalTarget = target
                finalRange = math.sqrt(sqRange)
                break
            end
        end
    end
    Server.dbgTracer.seeEntityTraceEnabled = false
    
    if finalTarget ~= nil then
        self:LogTarget("%s targets %s at range %s", attacker, finalTarget, finalRange)
    end
    return finalTarget,staticList,staticListVersion
end

