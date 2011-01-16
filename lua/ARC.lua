// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'ARC' (LiveScriptActor)

ARC.kMapName = "arc"

ARC.kModelName = PrecacheAsset("models/marine/arc/arc.model")

ARC.kDeploySound = PrecacheAsset("sound/ns2.fev/marine/structure/arc/deploy")
ARC.kFireSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/fire")
ARC.kFlybySound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/flyby")
ARC.kHitSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/hit")
ARC.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/scan")
ARC.kUndeploySound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/undeploy")

ARC.kScanEffect = PrecacheAsset("cinematics/marine/arc/scan.cinematic")
ARC.kFireEffect = PrecacheAsset("cinematics/marine/arc/fire.cinematic")
ARC.kFireShellEffect = PrecacheAsset("cinematics/marine/arc/fire_shell.cinematic")
ARC.kExplosionEffect = PrecacheAsset("cinematics/marine/arc/explosion.cinematic")
ARC.kDamagedEffect = PrecacheAsset("cinematics/marine/arc/damaged.cinematic")

// Animations
ARC.kDeploy = "deploy"
ARC.kUndeploy = "undeploy"
ARC.kMove = "move"
ARC.kIdle = "idle"
ARC.kMoveParam = "move_speed"
ARC.kAnimShootTable = { {1.5, "shoot"}/*, {.1, "shoot2"}*/ }

// Balance
ARC.kHealth = 400
ARC.kStartDistance = 4
ARC.kDeployTime = 3.0
ARC.kUndeployTime = 3.0
ARC.kFireThinkInterval = .3
ARC.kMoveThinkInterval = .05
ARC.kAttackInterval = 8.0      // Must be greater than fireToHitInterval
ARC.kFireToHitInterval = kARCFireDelay
ARC.kAttackDamage = kARCDamage
ARC.kDeployInterval = 3.0
ARC.kUndeployInterval = 3.0
ARC.kFireRange = 22.86         // 75 feet, from mockup
ARC.kSplashRadius = 10
ARC.kUpgradedSplashRadius = 13
ARC.kMoveSpeed = 2.5           // units per second

local networkVars =
{
    // ARCs can only fire when deployed and can only move when not deployed
    deployed        = "boolean",
    deploying       = "boolean",
    undeploying     = "boolean",
}

function ARC:OnInit()

    self:SetModel(ARC.kModelName)

    LiveScriptActor.OnInit(self)

    // Cannons start out mobile
    self.deployed = false
    self.deploying = false
    self.undeploying = false
    self.justSpawned = true

    self:SetAnimationWithBlending(Structure.kAnimDeploy)
    self:SetNextThink(ARC.kMoveThinkInterval)

end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

if(Server) then
function ARC:OnThink()

    LiveScriptActor.OnThink(self)
    
    if(self.justSpawned) then

        // Move ARC away from factory so it can be selected
        local angle = NetworkRandom() * math.pi*2
        local startPoint = self:GetOrigin() + Vector( math.cos(angle)*ARC.kStartDistance, 0, math.sin(angle)*ARC.kStartDistance )
        self:SetOrigin(startPoint)

        self.justSpawned = nil

    end

    // If deployed, check for targets
    local currentOrder = self:GetCurrentOrder()

    if(self.deploying) then

        self.deployed = true
        self.deploying = false

        // Set random last fire time so if we deploy many sieges together they don't fire all at the same time for aesthetic effect
        self.timeOfLastSalvo = Shared.GetTime() + NetworkRandomInt(0, ARC.kAttackInterval)

        self:SetNextThink(ARC.kFireThinkInterval)

    elseif(self.undeploying) then

        self.deployed = false
        self.undeploying = false

    elseif(self.deployed) then

        self:UpdateFireSalvo()

        self:UpdateHit()

        self:SetNextThink(ARC.kFireThinkInterval)

    // If not and we're not near our order point, drive there
    elseif( currentOrder ~= nil and currentOrder:GetType() == kTechId.Move ) then

        local vectorToWaypoint = currentOrder:GetLocation() - self:GetOrigin()
        local distToTarget = vectorToWaypoint:GetLength()

        if(distToTarget > kEpsilon) then

            local distanceToMove = ARC.kMoveSpeed * ARC.kMoveThinkInterval

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

            self:SetAnimationWithBlending(ARC.kMove)

            self:SetPoseParam(ARC.kMoveParam, .5)

        else
            self:CompletedCurrentOrder()

            self:SetPoseParam(ARC.kMoveParam, 0)

            self:OnIdle()

        end

        self:SetNextThink(ARC.kMoveThinkInterval)

    else
        self:SetNextThink(ARC.kMoveThinkInterval)
    end

end
end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

function ARC:GetIsTargetValid(target) 
    return target ~= nil and target:isa("Structure") and (GetEnemyTeamNumber(self:GetTeamNumber()) == target:GetTeamNumber()) and target:GetIsAlive() and ((target:GetOrigin() - self:GetOrigin()):GetLengthXZ() < ARC.kFireRange) and self:GetCanSeeEntity(target)
end

function ARC:AcquireTarget()

    local newTarget = nil
    
    // Find the nearest enemy structure in range
    local shortestDistanceToTarget = nil
    
    local targets = GetGamerules():GetEntities("Structure" , GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), ARC.kFireRange, true)

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
    
        Print("ARC:Acquired new target: %s", SafeClassName(newTarget))
        self:GiveOrder(kTechId.Attack, newTarget:GetId(), nil)

    end
    
    return newTarget

end

function ARC:UpdateFireSalvo()

    // Check for a new target if we need one, otherwise play sound and get ready to hit
    if(not self.firingSalvo) then

        local target = self:GetTarget()
        
        if not self:GetIsTargetValid(target) then
        
            target = self:AcquireTarget()
            
        end

        // If enough time has elapsed since our last attack, fire
        if( target ~= nil and ( ( Shared.GetTime() - self.timeOfLastSalvo ) > ARC.kAttackInterval ) ) then

            // Do damage to target
            self:PlaySound(ARC.kFireSound)

            self:SetAnimationWithBlending(chooseWeightedEntry(ARC.kAnimShootTable), self:GetBlendTime(), true)

            self.timeOfLastSalvo = Shared.GetTime()
            self.timeOfNextHit = Shared.GetTime() + ARC.kFireToHitInterval
            self.firingSalvo = true

            Print("Siege firing on %s, will hit in %s seconds", SafeClassName(target), ARC.kFireToHitInterval)

        end

    end

end

function ARC:UpdateHit()

    if(self.firingSalvo) then

        // If enough time has elapsed since our last salvo, actually hit the target
        local target = self:GetTarget()
        
        // Make sure target is still valid
        if target ~= nil then
 
            if Shared.GetTime() > self.timeOfNextHit then
            
                // Play big hit sound at origin
                Shared.PlayWorldSound(nil, ARC.kHitSound, nil, target:GetOrigin())

                // Do damage to everything in radius. Use upgraded splash radius if researched.
                local damageRadius = ConditionalValue(GetTechSupported(self, kTechId.ARCSplashTech), ARC.kUpgradedSplashRadius, ARC.kSplashRadius)
                local hitEntities = GetEntitiesIsaInRadius("Structure", GetEnemyTeamNumber(self:GetTeamNumber()), target:GetOrigin(), damageRadius, false)

                // Do damage to every target in range
                RadiusDamage(hitEntities, target:GetOrigin(), damageRadius, ARC.kAttackDamage, self)

                // Play hit effect on each
                for index, target in ipairs(hitEntities) do
                
                    Shared.CreateEffect(nil, ARC.kExplosionEffect, target)
                    
                end
                
            end
            
        else

            // Acquire new target if target is gone
            self.firingSalvo = false
            self:CompletedCurrentOrder()            
            
        end

    end

end

function ARC:PerformActivation(techId, position, commander)

    if(not self.deploying and not self.undeploying) then

        if(techId == kTechId.ARCDeploy and not self.deployed) then

            self:PlaySound(ARC.kDeploySound)

            self:SetAnimationWithBlending(ARC.kDeploy)

            // Cancel waypoint
            self.waypoint = nil

            self:SetNextThink(ARC.kDeployInterval)

            self.deploying = true

            return true

        elseif(techId == kTechId.ARCUndeploy and self.deployed) then

            // Cancel firing if we were
            self:StopSound(ARC.kFireSound)

            self.firingSalvo = false

            if self:GetTarget() ~= nil then
                self:CompletedCurrentOrder()
            end

            self.timeOfNextHit = nil

            self:PlaySound(ARC.kUndeploySound)

            self:SetAnimationWithBlending(ARC.kUndeploy)

            self:SetNextThink(ARC.kUndeployInterval)

            self.deployed = false

            self.undeploying = true

            return true

        end

    end

    return false

end

function ARC:GetActivationTechAllowed(techId)

    if(techId == kTechId.ARCDeploy or techId == kTechId.Move) then
        return not self.deploying and not self.undeploying and not self.deployed
    elseif(techId == kTechId.ARCUndeploy or techId == kTechId.Attack) then
        return not self.deploying and not self.undeploying and self.deployed
    end

    return true

end

function ARC:GetTechButtons(techId)
    if(techId == kTechId.RootMenu and not self.deploying and not self.undeploying) then
        if(self.deployed) then
            return  {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCUndeploy, kTechId.None, kTechId.None, kTechId.Recycle }
        else
            return  {   
                        kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCDeploy, kTechId.None, kTechId.Recycle, kTechId.None }
        end
    else
        return nil
    end
end

function ARC:GetCanDoDamage()
    return true
end

Shared.LinkClassToMap("ARC", ARC.kMapName, networkVars)
