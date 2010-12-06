// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Drifter.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable glowing insect that the alien commander can control. Used to build structures
// and has other special abilities. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'Drifter' (LiveScriptActor)

Drifter.kMapName = "drifter"

Drifter.kModelName = PrecacheAsset("models/alien/drifter/drifter.model")

Drifter.kAttackSoundName   = PrecacheAsset("sound/ns2.fev/alien/drifter/attack")
Drifter.kDieSoundName      = PrecacheAsset("sound/ns2.fev/alien/drifter/death")
Drifter.kDriftSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/drift")
Drifter.kFlareSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/flare")
Drifter.kOrderedSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered")
Drifter.kOrdered2DSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered_2d")
Drifter.kSpawnSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/spawn")
Drifter.kWoundSoundName    = PrecacheAsset("sound/ns2.fev/alien/drifter/wound")

Drifter.kAnimIdleTable = {{1.0, "idle"}, {.5, "idle2"}, {.05, "idle3"}, {.05, "idle4"}}
Drifter.kAnimFly = "fly"
Drifter.kAnimLandBuild = "land_build"

Drifter.kMoveSpeed = 9
Drifter.kMoveThinkInterval = .05
Drifter.kBuildDistance = .01        // Distance at which he can start building a structure. 
Drifter.kHealth = 100
Drifter.kArmor = kDrifterArmor
Drifter.kParasiteDamage = 10
Drifter.kFlareTime = 5              // How long the flare affects a player
Drifter.kFlareMaxDistance = 15
            
Drifter.kCapsuleHeight = .05
Drifter.kCapsuleRadius = .5
Drifter.kStartDistance = 4
Drifter.kHoverHeight = 1.2

Drifter.kFlareAnim = "parasite"

local networkVars = {
    // 0-1 scalar used to set move_speed model parameter according to how fast we recently moved
    moveSpeed               = "float",
    timeOfLastUpdate        = "float",
    moveSpeedParam          = "compensated float"
}

function Drifter:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    // Create the controller for doing collision detection.
    self:CreateController(PhysicsGroup.CommanderUnitGroup, Drifter.kCapsuleHeight, Drifter.kCapsuleRadius)
    
end

function Drifter:OnInit()

    self:SetModel(Drifter.kModelName)
    
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)

    LiveScriptActor.OnInit(self)
    
    self.moveSpeed = 0
    self.timeOfLastUpdate = 0
    self.moveSpeedParam = 0

    if(Server) then
    
        self.justSpawned = true    
        self:SetNextThink(Drifter.kMoveThinkInterval)
        
        self:PlaySound(Drifter.kSpawnSoundName)
        
        self:SetUpdates(true)
        
    end
    
    self:UpdateControllerFromEntity()
        
end

function Drifter:GetExtents()
    return Vector(Drifter.kCapsuleRadius, Drifter.kCapsuleHeight/2, Drifter.kCapsuleRadius)
end

function Drifter:GetIsFlying()
    return true
end

function Drifter:GetFlinchSound(damage)
    return Drifter.kWoundSoundName
end

function Drifter:GetKilledSound(doer)
    return Drifter.kDieSoundName
end

function Drifter:GetHoverHeight()
    return Drifter.kHoverHeight
end

function Drifter:GetTechId()
    return kTechId.Drifter
end

function Drifter:GetFov()
    return 120
end

function Drifter:GetDeathIconIndex()
    return kDeathMessageIcon.Drifter
end

function Drifter:SetOrder(order, clearExisting, insertFirst)

    LiveScriptActor.SetOrder(self, order, clearExisting, insertFirst)
    
    self:SetNextThink(Drifter.kMoveThinkInterval)
    
    self:PlaySound(Drifter.kOrderedSoundName)
    
    local owner = self:GetOwner()
    if owner then
        Server.PlayPrivateSound(owner, Drifter.kOrdered2DSoundName, owner, 1.0, Vector(0, 0, 0))
    end
        
end

function Drifter:OverrideTechTreeAction(techNode, position, orientation, commander)

    local success = false
    local keepProcessing = true
    
    // Convert build tech actions into build orders
    if(techNode:GetIsBuild()) then
    
        local order = CreateOrder(kTechId.Build, techNode:GetTechId(), position, orientation)
                
        // Converts default orders into something more appropriate for unit
        self:OverrideOrder(order)
                
        self:SetOrder(order, not commander.queuingOrders, false)
        
        // If Drifter was orphaned by commander that has left chair or server, take control
        if self:GetOwner() == nil then
            self:SetOwner(commander)
        end
        
        success = true
        keepProcessing = false
        
    end
    
    return success, keepProcessing
    
end

function Drifter:OverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // If target is enemy, attack it
    if (order:GetType() == kTechId.Default) and orderTarget ~= nil and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
    
        Print("Attack")
        order:SetType(kTechId.Attack)
        
    else
    
        LiveScriptActor.OverrideOrder(self, order)
        
    end
    
end

function Drifter:PlayMeleeHitEffects(target, point, direction)
    Shared.PlayWorldSound(nil, Drifter.kAttackSoundName, nil, point)
end

function Drifter:ProcessJustSpawned()

    self.justSpawned = nil
    
    // Now look for nearby hive to see if it has a rally point for us
    local ents = GetGamerules():GetEntities("Hive", self:GetTeamNumber(), self:GetOrigin(), 1)

    if(table.maxn(ents) == 1) then
    
        local hive = ents[1]
        hive:CopyOrders(self)
        
        // Convert rally orders to move and we're done
        for index, order in ipairs(self.orders) do
        
            if(order:GetType() == kTechId.SetRally) then
                order:SetType(kTechId.Move)
            end
            
        end
        
    end  
    
    // Move glowy outside of hive so he can be selected    
    local angle = NetworkRandom() * math.pi*2
    local startPoint = self:GetOrigin() + Vector( math.cos(angle)*Drifter.kStartDistance , 0 , math.sin(angle)*Drifter.kStartDistance )
    self:SetOrigin(startPoint)

    self:OnIdle()
    
end

function Drifter:OnThink()

    LiveScriptActor.OnThink(self)

    if(Server and self.justSpawned) then
        self:ProcessJustSpawned()           
    end        

    // Check to see if it's time to go off. Don't process other orders while getting ready to explode.
    if self.flareExplodeTime then
    
        if Shared.GetTime() > self.flareExplodeTime then
            self:PerformFlare()
        else
            self:SetNextThink(Drifter.kMoveThinkInterval)
        end
        
        return
        
    end
    
    local currentOrder = self:GetCurrentOrder()
    if( currentOrder ~= nil ) then
    
        local drifterMoveSpeed = GetDevScalar(Drifter.kMoveSpeed, 8)
        
        local currentOrigin = Vector()
        VectorCopy(self:GetOrigin(), currentOrigin)
        
        if(currentOrder:GetType() == kTechId.Move) then

            local distToTarget = self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), drifterMoveSpeed, Drifter.kMoveThinkInterval)
            if(distToTarget < kEpsilon) then
                self:CompletedCurrentOrder()
            end
            
        elseif(currentOrder:GetType() == kTechId.Attack) then
        
            self:ProcessAttackOrder(5, drifterMoveSpeed, Drifter.kMoveThinkInterval)
                        
        elseif(currentOrder:GetType() == kTechId.Build) then 
        
            local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
            if(distToTarget < Drifter.kBuildDistance) then
            
                // Play land_build animation, then build it
                if not self.landed then
                
                    self:SetAnimationWithBlending(Drifter.kAnimLandBuild, nil, true)
                    local length = self:GetAnimationLength(Drifter.kAnimLandBuild)
                    self:SetActivityEnd(length)
                    self.landed = true
                
                elseif self:GetCanNewActivityStart() then
                   
                    // Create structure here
                    local commander = self:GetOwner()
                    if(commander and commander:isa("Commander")) then
                    
                        local techId = currentOrder:GetParam()
                        local techNode = commander:GetTechTree():GetTechNode(techId)
                        
                        if techNode == nil then
                            Print("Drifter:OnThink(): Couldn't find tech node for build id %s (%s)", EnumToString(kTechId, techId), ToString(techId))
                        else
                        
                            local cost = techNode:GetCost()
                            local team = commander:GetTeam()

                            if(team:GetCarbon() >= cost) then
                            
                                // Check to make sure there is infestation here
                                local success = false
                                local createdStructureId = -1
                                success, createdStructureId = commander:AttemptToBuild(techId, currentOrder:GetLocation(), nil, nil, self)
                                    
                                if(success) then
                                
                                    team:AddCarbon(-cost)
                                    
                                    self:CompletedCurrentOrder()
                                    
                                    self:SendEntityChanged(createdStructureId)
                                    
                                    // Now remove Drifter - we're morphing into structure
                                    DestroyEntity(self)
                                    
                                else
                                
                                    // TODO: Issue alert to commander that way was blocked?
                                    self:ClearOrders()
                                    
                                end
                                                
                            else
                                
                                // Play more resources required
                                self:GetTeam():TriggerAlert(kTechId.AlienAlertNotEnoughResources, self)
                                    
                                // Cancel build bots orders so he doesn't move away
                                self:ClearOrders()
                                    
                            end 
                            
                        end
                        
                    else
                        self:ClearOrders()    
                    end                
                    
                end
                
            else
            
                self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), drifterMoveSpeed, Drifter.kMoveThinkInterval)
                
            end
            
        end
        
        // Check difference in location to set moveSpeed
        local distanceMoved = (self:GetOrigin() - currentOrigin):GetLength()
        
        self.moveSpeed = (distanceMoved / drifterMoveSpeed) / Drifter.kMoveThinkInterval
        
        if self:GetCanNewActivityStart() then
        
            if self.moveSpeed == 0 then
                self:OnIdle()
            else
                self:SetAnimation(Drifter.kAnimFly)
            end
            
        end
        
        self:SetNextThink(Drifter.kMoveThinkInterval)

    end
    
end

function Drifter:GetIdleAnimation()
    return chooseWeightedEntry(Drifter.kAnimIdleTable)
end

function Drifter:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)
    
    self:UpdateControllerFromEntity()
    
    if self.timeOfLastUpdate ~= 0 then
    
        // Blend smoothly towards target value
        self.moveSpeedParam = Clamp(Slerp(self.moveSpeedParam, self.moveSpeed, (Shared.GetTime() - self.timeOfLastUpdate)*1), 0, 1)
        self:SetPoseParam("move_speed", self.moveSpeedParam)
        
    end
    
    self.timeOfLastUpdate = Shared.GetTime()
    
end

function Drifter:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then 
        return { kTechId.BuildMenu, kTechId.Move, kTechId.Stop, kTechId.DrifterParasite, kTechId.DrifterFlare }
    elseif(techId == kTechId.BuildMenu) then 
        return { kTechId.RootMenu, kTechId.Hive, kTechId.Harvester, kTechId.Whip, kTechId.Crag, kTechId.Shift, kTechId.Shade }
    end
    
    return nil
    
end

function Drifter:PerformActivation(techId, position, commander)

    if(techId == kTechId.DrifterFlare) then
    
        self:SetAnimationWithBlending(Drifter.kFlareAnim, nil, true)
        
        self:PlaySound(Drifter.kFlareSoundName)
        
        self.flareExplodeTime = Shared.GetTime() + self:GetAnimationLength(Drifter.kFlareAnim)
        
        return true
        
    end

    return LiveScriptActor.PerformAction(self, techNode, position)
    
end

function Drifter:PerformFlare()

    // Look for enemy non-Commanders that can see drifter
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local time = Shared.GetTime()
    
    // Blind enemies them temporarily. Show effect for friendly players too, but very mild.
    local score = 0
    for index, player in ipairs(GetGamerules():GetAllPlayers()) do
    
        local scalar = 0
        local canSee = player:GetCanSeeEntity(self)
        local isEnemy = (enemyTeamNumber == player:GetTeamNumber())
        
        // Scalar is 1 if player is enemy, and can see drifter
        if isEnemy and canSee then
            scalar = 1
            
        // Scalar is lower if player isn't enemy and can see drifter
        elseif canSee then
            scalar = .25
            
        // Scalar is low if player can't see it and is nearby
        else
            
            local dist = (player:GetOrigin() - self:GetOrigin()):GetLength()
            if dist < Drifter.kFlareMaxDistance then
            
                // Make sure we're in the same room
                scalar = .2
                
            end
            
        end
        
        if scalar > 0 then
            player:SetFlare(time, time + Drifter.kFlareTime, scalar)
            score = score + 1
        end
        
    end
    
    self:AddScoreForOwner(score)
    
    // Kill self
    self:Kill(self, self)
    
    self.flareExplodeTime = nil

end

function Drifter:GetWaypointGroupName()
    return kAirWaypointsGroup
end

function Drifter:GetMeleeAttackDamage()
    return kDrifterAttackDamage
end

function Drifter:GetMeleeAttackInterval()
    return kDrifterAttackDelay
end


Shared.LinkClassToMap("Drifter", Drifter.kMapName, networkVars)
