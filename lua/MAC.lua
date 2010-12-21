// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MAC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable flying robot marine commander can control. Used to build structures
// and has other special abilities. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")
class 'MAC' (LiveScriptActor)

MAC.kMapName = "mac"

MAC.kModelName = PrecacheAsset("models/marine/mac/mac.model")

MAC.kAttackSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/attack")
MAC.kBuildSound = PrecacheAsset("sound/ns2.fev/marine/structures/mac/build")
MAC.kConfirmSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm")
MAC.kConfirm2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm_2d")
MAC.kStartConstructionSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing")
MAC.kStartConstruction2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing_2d")
MAC.kHelpingSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/help_build")
MAC.kPassbyMACSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_mac")
MAC.kPassbyDrifterSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_driffter")
MAC.kHoverSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/hover")
MAC.kIdleSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/idle")
MAC.kThrustersSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/thrusters")
MAC.kWeldSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/weld")
MAC.kWeldStartSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/weld_start")
MAC.kWeldedSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/welded")
MAC.kUsedSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/use")

// "fxnode_welder"
MAC.kBuildEffect = PrecacheAsset("cinematics/marine/mac/build.cinematic")
MAC.kWelderEffect = PrecacheAsset("cinematics/marine/mac/weld.cinematic")

// "fxnode_jet1" and "fxnode_jet2"
MAC.kJetEffect = PrecacheAsset("cinematics/marine/mac/jet.cinematic")

// "fxnode_light"
MAC.kLightEffect = PrecacheAsset("cinematics/marine/mac/light.cinematic")

// Play at origin
MAC.kSirenEffect = PrecacheAsset("cinematics/marine/mac/siren.cinematic")

// Animations
MAC.kAnimIdle = {{1, "idle"}, {.1, "idle2"}}
MAC.kAnimFly = "fly"
MAC.kAnimFlyStop = "fly_stop"
MAC.kAnimConstruct = "construct"
MAC.kAnimWeld = "construct_weld"
MAC.kAnimAttack = "attack"

MAC.kRightJetNode = "fxnode_jet1"
MAC.kLeftJetNode = "fxnode_jet2"
MAC.kLightNode = "fxnode_light"
MAC.kWelderNode = "fxnode_welder"

// Balance
MAC.kMoveThinkInterval = .05
MAC.kConstructThinkInterval = .4
MAC.kRepairHealthPerSecond = 200
MAC.kWeldThinkInterval = .5
MAC.kHealth = kMACHealth
MAC.kArmor = kMACArmor
MAC.kMoveSpeed = 9
MAC.kHoverHeight = 1.5
MAC.kStartDistance = 3
MAC.kWeldDistance = 3
MAC.kBuildDistance = 2     // Distance at which bot can start building a structure. 
MAC.kOrderScanRadius = 5
MAC.kSpeedUpgradePercent = (1 + kMACSpeedAmount)

MAC.kCapsuleHeight = .2
MAC.kCapsuleRadius = .5

// Greetings
MAC.kGreetingUpdateInterval = 1
MAC.kGreetingInterval = 10
MAC.kGreetingDistance = 5
MAC.kUseTime = 2.0

function MAC:OnCreate()
    
    LiveScriptActor.OnCreate(self)
 
    // Create the controller for doing collision detection.
    self:CreateController(PhysicsGroup.CommanderUnitGroup, MAC.kCapsuleHeight, MAC.kCapsuleRadius)
    
    self:SetUpdates(true)
    
end

function MAC:OnInit()

    LiveScriptActor.OnInit(self)

    self:SetModel(MAC.kModelName)

    self:SetPhysicsType(Actor.PhysicsType.Kinematic)

    if(Server) then
    
        self.justSpawned = true    
        self:SetNextThink(MAC.kMoveThinkInterval)
        
        self:PlaySound(MAC.kHoverSoundName)
        
    end
    
    Shared.CreateAttachedEffect(nil, MAC.kLightEffect, self, Coords.GetTranslation(self:GetOrigin()), "fxnode_light", false)
    
    self:UpdateControllerFromEntity()
    
    self.timeOfLastGreeting = 0
    self.timeOfLastGreetingCheck = 0
    self.timeOfLastChatterSound = 0
        
end

function MAC:GetExtents()
    return Vector(MAC.kCapsuleRadius, MAC.kCapsuleHeight/2, MAC.kCapsuleRadius)
end

function MAC:GetFov()
    return 120
end

function MAC:GetIsFlying()
    return true
end

function MAC:GetCanBeUsed(player)
    return true
end

function MAC:OnUse(player, elapsedTime, useAttachPoint)

    // Play flavor sounds when using MAC
    if Server then
    
        local time = Shared.GetTime()
        
        if self.timeOfLastUse == nil or (time > (self.timeOfLastUse + MAC.kUseTime)) then    
            Server.PlayPrivateSound(player, MAC.kUsedSoundName, self, 1.0, Vector(0, 0, 0))
            self.timeOfLastUse = time
        end
        
    end
    
    return true
    
end

function MAC:GetHoverHeight()
    return MAC.kHoverHeight
end

function MAC:OverrideOrder(order)
    
    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to unbuilt friendly structures should be construct orders
    if(order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Construct)

    elseif(order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Weld)
        
    elseif(order:GetType() == kTechId.Weld and not GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) then

        // Not valid, cancel order
        order:SetType(kTechId.None)
        
    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
    
        order:SetType(kTechId.Attack)

    elseif((order:GetType() == kTechId.Default or order:GetType() == kTechId.Move) and (order:GetParam() ~= nil)) then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.Move)
        
    else
    
        LiveScriptActor.OverrideOrder(self, order)
        
    end
    
end

function MAC:GetIsOrderHelpingOtherMAC(order)

    if order:GetType() == kTechId.Construct then
    
        // Look for friendly nearby MACs
        local macs = GetGamerules():GetEntities("MAC", self:GetTeamNumber(), self:GetOrigin(), 3)
        for index, mac in ipairs(macs) do
        
            if mac ~= self then
            
                local otherMacOrder = mac:GetCurrentOrder()
                if otherMacOrder ~= nil and otherMacOrder:GetType() == order:GetType() and otherMacOrder:GetParam() == order:GetParam() then
                    return true
                end
                
            end
            
        end
        
    end
    
    return false
end

function MAC:SetOrder(order, clearExisting, insertFirst)

    LiveScriptActor.SetOrder(self, order, clearExisting, insertFirst)
    
    self:SetNextThink(MAC.kMoveThinkInterval)

    // Look for nearby MAC doing the same thing
    if self:GetIsOrderHelpingOtherMAC(order) then
        self:PlayChatSound(MAC.kHelpingSoundName)
    elseif order:GetType() == kTechId.Construct then
        self:PlayChatSound(MAC.kStartConstructionSoundName)        
    else
        self:PlayChatSound(MAC.kConfirmSoundName)
    end
    
    local owner = self:GetOwner()
    if owner then
        Server.PlayPrivateSound(owner, MAC.kConfirm2DSoundName, owner, 1.0, Vector(0, 0, 0))
    end
    
    self:PlaySound(MAC.kThrustersSoundName)
    
    Shared.CreateEffect(nil, MAC.kSirenEffect, self)
    
    Shared.CreateAttachedEffect(nil, MAC.kJetEffect, self, nil, "fxnode_jet1", false)
    
    Shared.CreateAttachedEffect(nil, MAC.kJetEffect, self, nil, "fxnode_jet2", false)
        
end

function MAC:PlayMeleeHitEffects(target, point, direction)
    Shared.PlayWorldSound(nil, MAC.kAttackSoundName, nil, point)
end

function MAC:OverrideTechTreeAction(techNode, position, orientation, commander)

    local success = false
    local keepProcessing = true
    
    // Convert build tech actions into build orders
    if(techNode:GetIsBuild()) then
    
        local order = CreateOrder(kTechId.Build, techNode:GetTechId(), position, orientation)
                
        // Converts default orders into something more appropriate for unit
        self:OverrideOrder(order)
                
        self:SetOrder(order, not commander.queuingOrders, false)
        
        // If MAC was orphaned by commander that has left chair or server, take control
        if self:GetOwner() == nil then
            self:SetOwner(commander)
        end
        
        success = true
        keepProcessing = false
        
    end
    
    return success, keepProcessing
    
end

function MAC:GetMoveSpeed()

    local moveSpeed = GetDevScalar(MAC.kMoveSpeed, 8)
    local techNode = self:GetTeam():GetTechTree():GetTechNode(kTechId.MACSpeedTech)

    if techNode and techNode:GetResearched() then
        moveSpeed = moveSpeed * MAC.kSpeedUpgradePercent
    end

    return moveSpeed
    
end

function MAC:ProcessWeldOrder()

    local setNextThink = false
    local order = self:GetCurrentOrder()
    local targetId = order:GetParam()
    local target = Shared.GetEntity(targetId)
    local canBeWeldedNow = false
    local canBeWeldedFuture = false
    
    if(target ~= nil) then
    
        local targetPosition = Vector(target:GetOrigin())
        local distanceToTarget = (targetPosition - Vector(self:GetOrigin())):GetLength()
        canBeWeldedNow, canBeWeldedFuture = target:GetCanBeWelded(self)
        
        // If we're close enough to weld, weld
        if(distanceToTarget < MAC.kWeldDistance) then
            
            if( (canBeWeldedNow or canBeWeldedFuture) and target:OnWeld(self, MAC.kWeldThinkInterval)) then
    
                // Play puff of sparks
                self:CreateAttachedEffect(MAC.kBuildEffect, "fxnode_welder")
                
                Shared.PlayWorldSound(nil, MAC.kWeldSoundName, nil, self:GetOrigin())
                
                self:SetNextThink(MAC.kWeldThinkInterval)
                
                setNextThink = true

            elseif not canBeWeldedNow and not canBeWeldedFuture then
            
                self:CompletedCurrentOrder()
                
            end
        
        else
        
            // otherwise move towards it    
            self:MoveToTarget(PhysicsMask.AIMovement, target:GetEngagementPoint(), self:GetMoveSpeed(), MAC.kMoveThinkInterval)

        end

    end
    
    // If door or structure is welded, complete order
    if(target == nil or (not canBeWeldedNow and not canBeWeldedFuture) ) then
    
        self:CompletedCurrentOrder()
        
    end
    
    return setNextThink
    
end

function MAC:ProcessJustSpawned()

    self.justSpawned = nil
    
    // Now look for nearby command station to see if it has a rally point for us
    local ents = GetGamerules():GetEntities("CommandStation", self:GetTeamNumber(), self:GetOrigin(), 1)

    if(table.maxn(ents) == 1) then
    
        local commandStation = ents[1]
        commandStation:CopyOrders(self)
        
        // Convert rally orders to move and we're done
        for index, order in ipairs(self.orders) do
        
            if(order:GetType() == kTechId.SetRally) then
                order:SetType(kTechId.Move)
            end
            
        end
        
    end  

    // Move bot away from CC so he can be selected    
    local angle = NetworkRandom() * math.pi*2
    local startPoint = self:GetOrigin() + Vector( math.cos(angle)*MAC.kStartDistance , MAC.kHoverHeight, math.sin(angle)*MAC.kStartDistance )
    self:SetOrigin(startPoint)
    
    self:SetAnimationWithBlending(chooseWeightedEntry(MAC.kAnimIdle))

end

function MAC:ProcessMove()

    local currentOrder = self:GetCurrentOrder()
    local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), self:GetMoveSpeed(), MAC.kMoveThinkInterval)
    if(distToTarget < kEpsilon) then
    
        self:SetAnimationWithBlending(MAC.kAnimFlyStop)
        self:CompletedCurrentOrder()
        
        // For playing idle after stop animation ends
        self:SetNextThink(MAC.kMoveThinkInterval)
        
    else
    
        self:SetAnimationWithBlending(MAC.kAnimFly)
        
    end
    
end

function MAC:PlayChatSound(soundName)
    if self.timeOfLastChatterSound == 0 or (Shared.GetTime() > self.timeOfLastChatterSound + 2) then
        self:PlaySound(soundName)
        self.timeOfLastChatterSound = Shared.GetTime()
    end
end

// Look for other MACs and Drifters to greet as we fly by 
function MAC:UpdateGreetings()

    local time = Shared.GetTime()
    if self.timeOfLastGreetingCheck == 0 or (time > (self.timeOfLastGreetingCheck + MAC.kGreetingUpdateInterval)) then
    
        if self.timeOfLastGreeting == 0 or (time > (self.timeOfLastGreeting + MAC.kGreetingInterval)) then
        
            local ents = GetEntitiesIsaMultiple({"MAC", "Drifter"})
            for index, ent in ipairs(ents) do
            
                if (ent ~= self) and (self:GetOrigin() - ent:GetOrigin()):GetLength() < MAC.kGreetingDistance then
                
                    if GetCanSeeEntity(self, ent) then
                        if ent:isa("MAC") then
                            self:PlayChatSound(MAC.kPassbyMACSoundName)
                        elseif ent:isa("Drifter") then
                            self:PlayChatSound(MAC.kPassbyDrifterSoundName)
                        end
                        
                        self.timeOfLastGreeting = time
                        break
                        
                    end
                    
                end                    
                    
            end                
                            
        end
        
        self.timeOfLastGreetingCheck = time
        
    end

end

function MAC:OrderChanged()

    LiveScriptActor.OrderChanged(self)

    if not self:GetHasOrder() then
    
        self:StopSound(MAC.kThrustersSoundName)
        Shared.StopEffect(nil, MAC.kSirenEffect, self)
        
    end    
    
end

function MAC:ProcessBuildConstruct()

    local setNextThink = false
    
    self:SetAnimationWithBlending(MAC.kAnimConstruct)

    local currentOrder = self:GetCurrentOrder()
    
    local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
    
    local engagementDist = ConditionalValue(currentOrder:GetType() == kTechId.Build, GetEngagementDistance(currentOrder:GetParam(), true), GetEngagementDistance(currentOrder:GetParam()))
    if distToTarget < engagementDist then
           
        // Create structure here
        if(currentOrder:GetType() == kTechId.Build) then
        
            local commander = self:GetOwner()
            if commander and commander:isa("Commander") then
            
                local techId = currentOrder:GetParam()
                local techNode = commander:GetTechTree():GetTechNode(techId)
                local cost = techNode:GetCost()
                local team = commander:GetTeam()
                
                if(cost == nil) then
                
                    Print("Cost for techId %d is not defined.", tostring(techId))
                    return
                    
                end
                
                if(team:GetCarbon() >= cost) then
              
                    local success, createdStructureId = commander:AttemptToBuild(techId, currentOrder:GetLocation(), nil, nil, self)
                    
                    // Now construct it
                    if(success) then
                    
                        self:CompletedCurrentOrder()
                    
                        team:AddCarbon(-cost)                                
                        
                        self:SetOrder( CreateOrder(kTechId.Construct, createdStructureId), false, true )
                        
                        self:SetNextThink(MAC.kConstructThinkInterval)
                        
                        setNextThink = true
                        
                    else
                    
                        // Issue alert to commander that way was blocked?
                        self:GetTeam():TriggerAlert(kTechId.MarineAlertMACBlocked, self)
                        
                    end
                    
                else
                
                    self:GetTeam():TriggerAlert(kTechId.MarineAlertNotEnoughResources, self)
                    
                    // Cancel build bots orders so he doesn't move away
                    self:ClearOrders()
                    
                end   
                     
            else
                self:ClearOrders()
            end                
            
        else
        
            // Construct structure
            local constructTarget = GetOrderTargetIsConstructTarget(self:GetCurrentOrder(), self:GetTeamNumber())
            
            if constructTarget then
            
                // Otherwise, add build time to structure
                constructTarget:Construct(MAC.kConstructThinkInterval * kMACConstructEfficacy)
                
                // Play puff of sparks
                self:CreateAttachedEffect(MAC.kBuildEffect, "fxnode_welder")
                
                Shared.PlayWorldSound(nil, MAC.kBuildSound, nil, self:GetOrigin())
                    
            else
            
                self:CompletedCurrentOrder()
                
            end
            
            self:SetNextThink(MAC.kConstructThinkInterval)
            setNextThink = true
            
        end                
        
    else
    
        self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), self:GetMoveSpeed(), MAC.kMoveThinkInterval)
        
    end
    
    return setNextThink

end

function MAC:OnThink()

    LiveScriptActor.OnThink(self)

    if(Server and self.justSpawned) then
    
        self:ProcessJustSpawned()
        
    end        
    
    local setNextThink = false
    local currentOrder = self:GetCurrentOrder()
    
    if( currentOrder ~= nil ) then
            
        if(currentOrder:GetType() == kTechId.Move) then
        
            self:ProcessMove()            
            self:UpdateGreetings()
            
        elseif(currentOrder:GetType() == kTechId.Attack) then
        
            self:SetAnimationWithBlending(MAC.kAnimAttack)
            
            self:ProcessAttackOrder(1, GetDevScalar(MAC.kMoveSpeed, 8), MAC.kMoveThinkInterval)
            
        elseif(currentOrder:GetType() == kTechId.Weld) then
        
            self:SetAnimationWithBlending(MAC.kAnimWeld)
            
            setNextThink = self:ProcessWeldOrder()
                    
        elseif((currentOrder:GetType() == kTechId.Build) or (currentOrder:GetType() == kTechId.Construct)) then 
        
            setNextThink = self:ProcessBuildConstruct()

        end
        
    else
    
        if(not self:FindSomethingToDo()) then
            self:OnIdle()
        end
        
    end
    
    if not setNextThink then
        self:SetNextThink(MAC.kMoveThinkInterval)
    end

end

function MAC:OnUpdate(deltaTime)
    LiveScriptActor.OnUpdate(self, deltaTime)
    self:UpdateControllerFromEntity()
end

function MAC:FindSomethingToDo()

    // If there's a friendly structure nearby that needs building, build it
    if self.timeOfLastFindSomethingTime == nil or Shared.GetTime() > self.timeOfLastFindSomethingTime + 1 then

        self.timeOfLastFindSomethingTime = Shared.GetTime()
        
        local ents = GetEntitiesIsaInRadius("Structure", self:GetTeamNumber(), self:GetOrigin(), MAC.kOrderScanRadius)
        
        for index, structure in ipairs(ents) do
        
            if(not structure:GetIsBuilt()) then
            
                local order = CreateOrder(kTechId.Construct, structure:GetId(), structure:GetOrigin(), nil)
                
                self:OverrideOrder(order)
                    
                if(order:GetType() ~= kTechId.None) then
                
                    self:SetOrder(order, false, false)
                    return true
                    
                end
                
            end
            
        end
        
    end
    
    return false
    
end

function MAC:GetDeathIconIndex()
    return kDeathMessageIcon.MAC
end

function MAC:PerformAction(techNode, position)

    if(techNode:GetTechId() == kTechId.MACMine) then
    
        // TODO: 
        return true
        
    end

    return LiveScriptActor.PerformAction(self, techNode, position)
    
end

function MAC:GetMeleeAttackOrigin()
    return self:GetAttachPointOrigin("fxnode_welder")
end

function MAC:GetMeleeAttackDamage()
    return kMACAttackDamage
end

function MAC:GetMeleeAttackInterval()
    return kMACAttackFireDelay 
end

function MAC:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then return 
            {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.Weld,
                kTechId.MACMine, kTechId.MACEMP, kTechId.None, kTechId.None }

    else return nil end
    
end

function MAC:GetWaypointGroupName()
    return kAirWaypointsGroup
end

function MAC:OnKill(damage, attacker, doer, point, direction)

    LiveScriptActor.OnKill(self, damage, attacker, doer, point, direction)

    self:StopSound(MAC.kHoverSoundName)
    self:StopSound(MAC.kThrustersSoundName)
    Shared.StopEffect(nil, MAC.kSirenEffect, self)
    
end

Shared.LinkClassToMap("MAC", MAC.kMapName, {})
