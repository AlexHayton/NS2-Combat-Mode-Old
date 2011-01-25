// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Sentry:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetDesiredMode(Sentry.kMode.PoweringUp)
        
end

function Sentry:OnDestroy()
    
    if self:GetSentryMode() == Sentry.kMode.Attacking then
        self:SetFiringSoundState(false)
    end
    
    Structure.OnDestroy(self)
    
end

function Sentry:OnKill(damage, attacker, doer, point, direction)

    self:SetFiringSoundState(false)
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)
    
end

function Sentry:OverrideOrder(order)
    
    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to enemies => attack
    if(order:GetType() == kTechId.Default and orderTarget and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(orderTarget:GetTeamNumber()) == self:GetTeamNumber()) then
    
        order:SetType(kTechId.Attack)

    else
    
        LiveScriptActor.OverrideOrder(self, order)
        
    end
    
end

function Sentry:OrderChanged()

    LiveScriptActor.OrderChanged(self)
    
    if not self:GetHasOrder() then
        self:SetDesiredMode(Sentry.kMode.Scanning)
    else
    
        local orderType = self:GetCurrentOrder():GetType()
        if orderType == kTechId.Attack then
            self:SetDesiredMode(Sentry.kMode.Attacking)
        elseif orderType == kTechId.Stop then
            self:SetDesiredMode(Sentry.kMode.Scanning)
        end
        
    end

end

// Control looping centrally to make sure fire sound doesn't stop or start unnecessarily
function Sentry:SetFiringSoundState(state)

    if state ~= self.playingAttackSound then
    
        if state then
            self:PlaySound(Sentry.kAttackSoundName)
        else
            self:StopSound(Sentry.kAttackSoundName)
        end
        
        self.playingAttackSound = state
        
    end
    
end

function Sentry:SetMode(mode)
    
    // Change animations
    if self.mode ~= mode then
    
        local firingSoundState = false
           
        // Don't play power up if we're deploying
        if mode == Sentry.kMode.PoweringUp and self.mode ~= Sentry.kMode.Unbuilt then        
        
            // Start scanning for targets once built
            local animName = Structure.kAnimPowerUp
            self:SetAnimation(animName)
            
            self:GetAnimationLength(animName)
            
            self:TriggerEffects("power_up")
        
        elseif mode == Sentry.kMode.PoweringDown then
        
            local powerDownAnim = self:GetPowerDownAnimation()
            self:SetAnimation(powerDownAnim)
            
            modeTime = self:GetAnimationLength(powerDownAnim)
            
            self:TriggerEffects("power_down")
        
        elseif mode == Sentry.kMode.Scanning then
        
        elseif mode == Sentry.kMode.SpinningUp then
        
            local anim = Sentry.kAttackStartAnim
            
            // Spin up faster!
            self:SetAnimation(anim, true, 3)
            modeTime = self:GetAnimationLength(anim)
            
            self:PlaySound(Sentry.kSpinUpSoundName)
        
        elseif mode == Sentry.kMode.Attacking then
        
            self:SetAnimation(Sentry.kAttackAnim)
            firingSoundState = true            
        
        elseif mode == Sentry.kMode.SpinningDown then
        
            self:SetAnimation(Sentry.kAttackEndAnim)
            self:PlaySound(Sentry.kSpinDownSoundName)

        end
        
        self.mode = mode
        
        self:SetFiringSoundState(firingSoundState)
        
    end
    
end

// Look at desired mode and current state and call SetMode() accordingly.
function Sentry:UpdateMode(deltaTime)

    if self.desiredMode ~= self.mode then
    
        if self.desiredMode == Sentry.kMode.Attacking then
        
            if self.mode == Sentry.kMode.Scanning or self.mode == Sentry.kMode.SpinningDown then
                self:SetMode(Sentry.kMode.SpinningUp)
            end
            
        elseif self.desiredMode == Sentry.kMode.Scanning then
        
            if self.mode == Sentry.kMode.Attacking or self.mode == Sentry.kMode.SpinningUp then
                self:SetMode(Sentry.kMode.SpinningDown)
            end

        elseif self.desiredMode == Sentry.kMode.SettingTarget then
            
            // If we're attacking or spinning up, spin down
            if self.mode == Sentry.kMode.Attacking or self.mode == Sentry.kMode.SpinningUp then            
                self:SetMode(Sentry.kMode.SpinningDown)                
            // If we're scanning, power down
            elseif self.mode == Sentry.kMode.Scanning then
                self:SetMode(Sentry.kMode.PoweringDown)
            end
            
        end
        
    end

end

function Sentry:SetDesiredMode(mode)
    self.desiredMode = mode
end

function Sentry:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == self:GetDeployAnimation() and self.mode == Sentry.kMode.PoweringUp then
    
        self:SetMode(Sentry.kMode.Scanning)
    
    elseif animName == Sentry.kAttackStartAnim then
    
        self:SetMode(Sentry.kMode.Attacking)

    elseif animName == Sentry.kAttackEndAnim then

        if self.desiredMode == Sentry.kMode.SettingTarget then    
            self:SetMode(Sentry.kMode.PoweringDown)
        else
            self:SetMode(Sentry.kMode.Scanning)
        end

    elseif animName == self:GetPowerUpAnimation() then
    
        self:SetMode(Sentry.kMode.Scanning)
        
    elseif animName == self:GetPowerDownAnimation() then
    
        if self.desiredMode == Sentry.kMode.SettingTarget then    
            self:SetMode(Sentry.kMode.SettingTarget)
        else
            self:SetMode(Sentry.kMode.PoweredDown)
        end
    end
        
end

function Sentry:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    if not newPoweredState then
        self:SetMode(Sentry.kMode.PoweringDown)    
    else
        self:SetMode(Sentry.kMode.PoweringUp)
    end
    
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end

// Sort entities by priority (players before structures, entity that hit us recently before others)
function Sentry:GetSortedTargetList()

    local sentryAttackOrigin = self:GetAttackOrigin()
    local ents = GetGamerules():GetEntities("LiveScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()), sentryAttackOrigin, Sentry.kRange)
    
    local targets = {}    
    for index, currentTarget in pairs(ents) do
        
        local validTarget, distanceToTarget = self:GetIsTargetValid(currentTarget)
        if validTarget then
            table.insertunique(targets, currentTarget)
        end
        
    end    
    
    function sortSentryTargets(ent1, ent2)
    
        // Prioritize damage-dealing targets
        if ent1:GetCanDoDamage() ~= ent2:GetCanDoDamage() then
        
            // But don't pick out players over structures unless closer
            if ent1:isa("Player") == ent2:isa("Player") then
                return ent1:GetCanDoDamage()
            end
            
        end

        // Shoot closer targets
        local dist1 = (sentryAttackOrigin - ent1:GetEngagementPoint()):GetLength()
        local dist2 = (sentryAttackOrigin - ent2:GetEngagementPoint()):GetLength()        
        if dist1 ~= dist2 then
            return dist1 < dist2
        end
        
        // Make deterministic in case that distances are equal
        return ent1:GetId() < ent2:GetId()

    end
    
    table.sort(targets, sortSentryTargets)
    
    return targets
    
end

function Sentry:AcquireTarget(deltaTime)

    local targetAcquired = nil
    local currentTime = self.timeOfLastUpdate + deltaTime

    if currentTime > (self.timeOfLastTargetAcquisition + Sentry.kTargetCheckTime) then

        local targets = self:GetSortedTargetList()
        if table.count(targets) > 0 then
            targetAcquired = targets[1]
        end
        
        self.timeOfLastTargetAcquisition = currentTime
        
    end
    
    if targetAcquired ~= nil then
        self:GiveOrder(kTechId.Attack, targetAcquired:GetId(), nil)
    end
    
    return targetAcquired
    
end

function Sentry:UpdateAttackTarget(deltaTime)

    local orderLocation = nil
    local order = self:GetCurrentOrder()
    if order then
        
        orderLocation = order:GetLocation()
    
        local target = self:GetTarget()    
        local attackEntValid = (target ~= nil and GetCanSeeEntity(self, target) and (target:GetOrigin() - self:GetOrigin()):GetLength() < Sentry.kRange)
        local attackLocationValid = (order:GetType() == kTechId.Attack and orderLocation ~= nil)
        local currentTime = self.timeOfLastUpdate + deltaTime
        
        if (attackEntValid or attackLocationValid) and (self.timeNextAttack == nil or (currentTime > self.timeNextAttack)) then
        
            local currentAnim = self:GetAnimation()
            local mode = self:GetSentryMode()
            
            if mode == Sentry.kMode.Attacking then
        
                self:FireBullets()

                // Random rate of fire so it can't be gamed         
                self.timeNextAttack = currentTime + Sentry.kBaseROF + NetworkRandom() * Sentry.kRandROF
                            
            else
                self.timeNextAttack = currentTime + .1
            end        

        end    
        
    end
   
end

function Sentry:UpdateAttack(deltaTime)

    // If alive and built (map-placed structures don't die when killed)
    local mode = self:GetSentryMode()
    local currentTime = self.timeOfLastUpdate + deltaTime
    
    if self:GetIsFunctioning() then

        // If we have order
        local order = self:GetCurrentOrder()
        if order ~= nil and (order:GetType() == kTechId.SetTarget) then
        
            self:UpdateSetTarget()
                
        else
        
            // Get new attack order if any enemies nearby
            self:AcquireTarget(deltaTime)
            
            // Maybe fire another bullet at target
            self:UpdateAttackTarget(deltaTime)

            // We may have gotten a new order in acquire target, but ping if not        
            if((self:GetSentryMode() == Sentry.kMode.Scanning) and (self.timeLastScanSound == 0 or (currentTime > self.timeLastScanSound + Sentry.kPingInterval))) then
        
                Shared.PlayWorldSound(nil, Sentry.kSentryScanSoundName, nil, self:GetModelOrigin())
                self.timeLastScanSound = currentTime
            
            end

        end

        self:UpdateTargetState()
  
    end

end

function Sentry:GetAttackOrigin()
    return self:GetAttachPointOrigin(Sentry.kMuzzleNode)    
end

function Sentry:FireBullets()

    local worldAimYaw = self:GetAngles().yaw - (self.barrelYawDegrees/180) * math.pi
    local worldAimPitch = self:GetAngles().pitch + (self.barrelPitchDegrees/180) * math.pi
    local direction = GetNormalizedVector(Vector(math.sin(worldAimYaw), math.sin(worldAimPitch), math.cos(worldAimYaw)))    
    
    local fireCoords = BuildCoords(Vector(0, 1, 0), direction)
    local startPoint = self:GetAttackOrigin()
    
    for bullet = 1, Sentry.kBulletsPerSalvo do

        // Add some spread to bullets
        local x = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 1)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 2)) - .5)
        local y = (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 3)) - .5) + (NetworkRandom(string.format("%s:FireBullet %d, %d", self:GetClassName(), bullet, 4)) - .5)
        
        local spreadDirection = direction + x * Sentry.kSpread.x * fireCoords.xAxis + y * Sentry.kSpread.y * fireCoords.yAxis
        local endPoint = startPoint + spreadDirection * Sentry.kRange
        
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        
        if (trace.fraction < 1) then
        
            if not GetBlockedByUmbra(trace.entity) then
            
                if Server then
                if trace.entity and trace.entity.TakeDamage then
                
                    local direction = (trace.endPoint - startPoint):GetUnit()
                    
                    trace.entity:TakeDamage(Sentry.kDamagePerBullet, self, self, endPoint, direction)
                
                else
                    TriggerHitEffects(self, trace.entity, trace.endPoint, trace.surface)    
                end
                
                end
                
            end
            
        end
    
    end
    
    self:CreateAttachedEffect(Sentry.kFireEffect, Sentry.kMuzzleNode)
    
    self:CreateAttachedEffect(Sentry.kBarrelSmokeEffect, Sentry.kMuzzleNode)

    if Server then
    self:GetTeam():TriggerAlert(kTechId.MarineAlertSentryFiring, self)    
    end
    
end

// Update rotation state when setting target
function Sentry:UpdateSetTarget()

    if self:GetSentryMode() == Sentry.kMode.SettingTarget then
    
        local currentOrder = self:GetCurrentOrder()
        if currentOrder ~= nil then
        
            local target = self:GetTarget()
            
            local vecToTarget = nil
            if currentOrder:GetLocation() ~= nil then
                vecToTarget = currentOrder:GetLocation() - self:GetModelOrigin()
            elseif target ~= nil then
                vecToTarget =  target:GetModelOrigin() - self:GetModelOrigin()
            else
                Print("Sentry:UpdateSetTarget(): sentry has attack order without valid entity id or location.")
                self:CompletedCurrentOrder()
                return 
            end            
            
            // Move sentry to face target point
            local currentYaw = self:GetAngles().yaw
            local desiredYaw = GetYawFromVector(vecToTarget)
            local newYaw = InterpolateAngle(currentYaw, desiredYaw, Sentry.kReorientSpeed)

            local angles = Angles(self:GetAngles())
            angles.yaw = newYaw
            self:SetAngles(angles)
                        
            // Check if we're close enough to final orientation
            if(math.abs(newYaw - desiredYaw) == 0) then

                self:CompletedCurrentOrder()
                
                // So barrel doesn't "snap" after power-up
                self.barrelYawDegrees = 0
                
                self:SetMode(Sentry.kMode.PoweringUp)
                
            end
            
        else
        
            // Deleted order while setting target
            self:SetDesiredMode(Sentry.kMode.PoweringUp)
            
        end 
       
    end
    
end

function Sentry:SetOrder(order, clearExisting, insertFirst)

    LiveScriptActor.SetOrder(self, order, clearExisting, insertFirst)

    local order = self:GetCurrentOrder()    
    local mode = self:GetSentryMode()
    
    if order ~= nil and (order:GetType() == kTechId.SetTarget) then
        self:SetDesiredMode(Sentry.kMode.SettingTarget)
    elseif order ~= nil and (order:GetType() == kTechId.Attack) then
        self:SetDesiredMode(Sentry.kMode.Attacking)
    end
    
end

function Sentry:UpdateTargetState()

    local order = self:GetCurrentOrder()

    // Update hasTarget so model swings towards target entity or location
    local hasTarget = false
    
    if order ~= nil then
    
        // We have a target if we attacking an entity that's still valid or attacking ground
        local orderParam = order:GetParam()
        hasTarget = (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) and 
                    ((orderParam ~= Entity.invalidId and self:GetIsTargetValid(Shared.GetEntity(orderParam)) or (orderParam == Entity.invalidId)) )
    end
    
    if hasTarget then
    
        local target = self:GetTarget()
        if target ~= nil then
            self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        else
            self.targetDirection = GetNormalizedVector(self:GetCurrentOrder():GetLocation() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        end
        
    else
    
        if (self:GetSentryMode() == Sentry.kMode.Attacking) then
        
            self:CompletedCurrentOrder()
            
            // Give new attack order
            local targets = self:GetSortedTargetList()
            if table.count(targets) > 0 then
                self:GiveOrder(kTechId.Attack, targets[1]:GetId(), nil)
            end
            
        end
        
        self.targetDirection = nil
        
    end
    
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end