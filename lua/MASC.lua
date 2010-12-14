// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MASC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'MASC' (LiveScriptActor)

MASC.kMapName = "masc"

MASC.kModelName = PrecacheAsset("models/marine/masc/masc.model")

MASC.kDeploySound = PrecacheAsset("sound/ns2.fev/marine/structure/masc/deploy")
MASC.kFireSound = PrecacheAsset("sound/ns2.fev/marine/structures/masc/fire")
MASC.kFlybySound = PrecacheAsset("sound/ns2.fev/marine/structures/masc/flyby")
MASC.kHitSound = PrecacheAsset("sound/ns2.fev/marine/structures/masc/hit")
MASC.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/masc/scan")
MASC.kUndeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/masc/undeploy")

MASC.kScanEffect = PrecacheAsset("cinematics/marine/masc/scan.cinematic")
MASC.kFireEffect = PrecacheAsset("cinematics/marine/masc/fire.cinematic")
MASC.kFireShellEffect = PrecacheAsset("cinematics/marine/masc/fire_shell.cinematic")
MASC.kExplosionEffect = PrecacheAsset("cinematics/marine/masc/explosion.cinematic")
MASC.kDamagedEffect = PrecacheAsset("cinematics/marine/masc/damaged.cinematic")
MASC.kDeathEffect = PrecacheAsset("cinematics/marine/masc/destroyed.cinematic")

// Animations
MASC.kDeploy = "deploy"
MASC.kUndeploy = "undeploy"
MASC.kMove = "move"
MASC.kIdle = "idle"
MASC.kMoveParam = "move_speed"
MASC.kDeployedAnimIdleTable = { {1.5, "idle_deployed"}/*, {.1, "idle_deployed_fidget1"}, {.1, "idle_deployed_fidget2"}, {.1, "idle_deployed_fidget3"}*/ }
MASC.kUndeployedAnimIdleTable = { {1.5, "idle_undeployed"}/*, {.1, "idle_undeployed_fidget1"}, {.1, "idle_undeployed_fidget2"}, {.1, "idle_undeployed_fidget3"}*/ }
MASC.kAnimShootTable = { {1.5, "shoot"}/*, {.1, "shoot2"}*/ }

// Balance
MASC.kHealth = 400
MASC.kStartDistance = 4
MASC.kDeployTime = 3.0
MASC.kUndeployTime = 3.0
MASC.kFireThinkInterval = .3
MASC.kMoveThinkInterval = .05
MASC.kAttackInterval = 8.0      // Must be greater than fireToHitInterval
MASC.kFireToHitInterval = kMASCFireDelay
MASC.kAttackDamage = kMASCDamage
MASC.kDeployInterval = 3.0
MASC.kUndeployInterval = 3.0
MASC.kFireRange = 22.86         // 75 feet, from mockup
MASC.kSplashRadius = 10
MASC.kUpgradedSplashRadius = 13
MASC.kMoveSpeed = 2.5           // units per second

local networkVars =
{
    // MASCs can only fire when deployed and can only move when not deployed
    deployed        = "boolean",
    deploying       = "boolean",
    undeploying     = "boolean",
}

function MASC:OnInit()

    self:SetModel(MASC.kModelName)

    LiveScriptActor.OnInit(self)

    // Cannons start out mobile
    self.deployed = false
    self.deploying = false
    self.undeploying = false
    self.justSpawned = true

    self:SetAnimationWithBlending(Structure.kAnimDeploy)
    self:SetNextThink(MASC.kMoveThinkInterval)

end

function MASC:GetDeathEffect()
    return MASC.kDeathEffect
end

if(Server) then
function MASC:OnThink()

    LiveScriptActor.OnThink(self)
    
    if(self.justSpawned) then

        // Move MASC away from factory so it can be selected
        local angle = NetworkRandom() * math.pi*2
        local startPoint = self:GetOrigin() + Vector( math.cos(angle)*MASC.kStartDistance, 0, math.sin(angle)*MASC.kStartDistance )
        self:SetOrigin(startPoint)

        self.justSpawned = nil

    end

    // If deployed, check for targets
    local currentOrder = self:GetCurrentOrder()

    if(self.deploying) then

        self.deployed = true
        self.deploying = false

        // Set random last fire time so if we deploy many sieges together they don't fire all at the same time for aesthetic effect
        self.timeOfLastSalvo = Shared.GetTime() + NetworkRandomInt(0, MASC.kAttackInterval)

        self:SetNextThink(MASC.kFireThinkInterval)

    elseif(self.undeploying) then

        self.deployed = false
        self.undeploying = false

    elseif(self.deployed) then

        self:UpdateFireSalvo()

        self:UpdateHit()

        self:SetNextThink(MASC.kFireThinkInterval)

    // If not and we're not near our order point, drive there
    elseif( currentOrder ~= nil and currentOrder:GetType() == kTechId.Move ) then

        local vectorToWaypoint = currentOrder:GetLocation() - self:GetOrigin()
        local distToTarget = vectorToWaypoint:GetLength()

        if(distToTarget > kEpsilon) then

            local distanceToMove = MASC.kMoveSpeed * MASC.kMoveThinkInterval

            local moveNormal = Vector()
            VectorCopy(vectorToWaypoint, moveNormal)
            moveNormal:Normalize()

            local desiredEndPoint = self:GetOrigin() + moveNormal*distanceToMove

            if (distanceToMove > distToTarget) then
                VectorCopy( currentOrder:GetLocation(), desiredEndPoint )
            end

            // Check for collisions to desired end point
            local trace = Shared.TraceRay(self:GetOrigin(), desiredEndPoint, EntityFilterOne(self))
            if(trace.fraction < 1) then
                self:SetOrigin(trace.endPoint)
            else
                self:SetOrigin(desiredEndPoint)
            end

            // Now trace down so siege stays on ground
            trace = Shared.TraceRay(self:GetOrigin(), self:GetOrigin() - Vector(0, 100, 0), EntityFilterOne(self))
            if(trace.fraction < 1) then
                self:SetOrigin(trace.endPoint)
            end

            SetAnglesFromVector(self, vectorToWaypoint)

            self:SetAnimationWithBlending(MASC.kMove)

            self:SetPoseParam(MASC.kMoveParam, .5)

        else
            self:CompletedCurrentOrder()

            self:SetPoseParam(MASC.kMoveParam, 0)

            self:SetAnimationWithBlending(self:GetIdleAnimation())

        end

        self:SetNextThink(MASC.kMoveThinkInterval)

    else
        self:SetNextThink(MASC.kMoveThinkInterval)
    end

end
end

function MASC:GetTechId()
    return kTechId.MASC
end

function MASC:GetDeathIconIndex()
    return kDeathMessageIcon.MASC
end

function MASC:GetIdleAnimation()

    local idleAnimName = ""

    if(self.deployed) then
        idleAnimName = chooseWeightedEntry( MASC.kDeployedAnimIdleTable )
    else
        idleAnimName = chooseWeightedEntry( MASC.kUndeployedAnimIdleTable )
    end

    return idleAnimName

end

function MASC:GetIsTargetValid(target) 
    return target ~= nil and target:isa("Structure") and (GetEnemyTeamNumber(self:GetTeamNumber()) == target:GetTeamNumber()) and target:GetIsAlive() and ((target:GetOrigin() - self:GetOrigin()):GetLengthXZ() < MASC.kFireRange) and self:GetCanSeeEntity(target)
end

function MASC:AcquireTarget()

    local newTarget = nil
    
    // Find the nearest enemy structure in range
    local shortestDistanceToTarget = nil
    
    local targets = GetGamerules():GetEntities("Structure" , GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), MASC.kFireRange, true)

    for index, structure in pairs(targets) do

        if(structure:GetIsAlive()) then

            // Is it closest?
            local distanceToTarget = (structure:GetOrigin() - self:GetOrigin()):GetLengthXZ()
            if(newTarget == nil or distanceToTarget < shortestDistanceToTarget) then

                // New closest target
                newTarget = structure
                shortestDistanceToTarget = distanceToTarget

            end

        end

    end
    
    if newTarget ~= nil then
    
        Print("MASC:Acquired new target: %s", SafeClassName(newTarget))
        self:GiveOrder(kTechId.Attack, newTarget:GetId(), nil)

    end
    
    return newTarget

end

function MASC:UpdateFireSalvo()

    // Check for a new target if we need one, otherwise play sound and get ready to hit
    if(not self.firingSalvo) then

        local target = self:GetTarget()
        
        if not self:GetIsTargetValid(target) then
        
            target = self:AcquireTarget()
            
        end

        // If enough time has elapsed since our last attack, fire
        if( target ~= nil and ( ( Shared.GetTime() - self.timeOfLastSalvo ) > MASC.kAttackInterval ) ) then

            // Do damage to target
            self:PlaySound(MASC.kFireSound)

            self:SetAnimationWithBlending(chooseWeightedEntry(MASC.kAnimShootTable), self:GetBlendTime(), true)

            self.timeOfLastSalvo = Shared.GetTime()
            self.timeOfNextHit = Shared.GetTime() + MASC.kFireToHitInterval
            self.firingSalvo = true

            Print("Siege firing on %s, will hit in %s seconds", SafeClassName(target), MASC.kFireToHitInterval)

        end

    end

end

function MASC:UpdateHit()

    if(self.firingSalvo) then

        // If enough time has elapsed since our last salvo, actually hit the target
        local target = self:GetTarget()
        
        // Make sure target is still valid
        if target ~= nil then
 
            if Shared.GetTime() > self.timeOfNextHit then
            
                // Play big hit sound at origin
                Shared.PlayWorldSound(nil, MASC.kHitSound, nil, target:GetOrigin())

                // Do damage to everything in radius. Use upgraded splash radius if researched.
                local damageRadius = ConditionalValue(GetTechSupported(self, kTechId.MASCSplashTech), MASC.kUpgradedSplashRadius, MASC.kSplashRadius)
                local hitEntities = GetEntitiesIsaInRadius("Structure", GetEnemyTeamNumber(self:GetTeamNumber()), target:GetOrigin(), damageRadius, false)

                // Do damage to every target in range
                RadiusDamage(hitEntities, target:GetOrigin(), damageRadius, MASC.kAttackDamage, self)

                // Play hit effect on each
                for index, target in ipairs(hitEntities) do
                
                    Shared.CreateEffect(nil, MASC.kExplosionEffect, target)
                    
                end
                
            end
            
        else

            // Acquire new target if target is gone
            self.firingSalvo = false
            self:CompletedCurrentOrder()            
            
        end

    end

end

function MASC:PerformActivation(techId, position, commander)

    if(not self.deploying and not self.undeploying) then

        if(techId == kTechId.MASCDeploy and not self.deployed) then

            self:PlaySound(MASC.kDeploySound)

            self:SetAnimationWithBlending(MASC.kDeploy)

            // Cancel waypoint
            self.waypoint = nil

            self:SetNextThink(MASC.kDeployInterval)

            self.deploying = true

            return true

        elseif(techId == kTechId.MASCUndeploy and self.deployed) then

            // Cancel firing if we were
            self:StopSound(MASC.kFireSound)

            self.firingSalvo = false

            if self:GetTarget() ~= nil then
                self:CompletedCurrentOrder()
            end

            self.timeOfNextHit = nil

            self:PlaySound(MASC.kUndeploySound)

            self:SetAnimationWithBlending(MASC.kUndeploy)

            self:SetNextThink(MASC.kUndeployInterval)

            self.deployed = false

            self.undeploying = true

            return true

        end

    end

    return false

end

function MASC:GetActivationTechAllowed(techId)

    if(techId == kTechId.MASCDeploy or techId == kTechId.Move) then
        return not self.deploying and not self.undeploying and not self.deployed
    elseif(techId == kTechId.MASCUndeploy or techId == kTechId.Attack) then
        return not self.deploying and not self.undeploying and self.deployed
    end

    return true

end

function MASC:GetTechButtons(techId)
    if(techId == kTechId.RootMenu and not self.deploying and not self.undeploying) then
        if(self.deployed) then
            return  {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.MASCUndeploy, kTechId.None, kTechId.None, kTechId.Recycle }
        else
            return  {   
                        kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.MASCDeploy, kTechId.None, kTechId.Recycle, kTechId.None }
        end
    else
        return nil
    end
end

Shared.LinkClassToMap("MASC", MASC.kMapName, networkVars)
