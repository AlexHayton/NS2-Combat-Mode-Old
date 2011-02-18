// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Sentry' (Structure)

Sentry.kMapName = "sentry"

if(Server) then
    Script.Load("lua/Sentry_Server.lua")
end

Sentry.kModelName = PrecacheAsset("models/marine/sentry/sentry.model")

Sentry.kSpinUpSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentr_spin_up")
Sentry.kSpinDownSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_spin_down")
Sentry.kAttackSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_fire_loop")

Sentry.kSentryScanSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_scan")
Sentry.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_taking_damage")
Sentry.kFiringAlertSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_firing")
Sentry.kRicochetMaterialSound = "sound/ns2.fev/materials/%s/ricochet"

// New effects
Sentry.kFireEffect = PrecacheAsset("cinematics/marine/sentry/fire.cinematic")
Sentry.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/sentry/muzzle_smoke.cinematic")

Sentry.kFireShellEffect = PrecacheAsset("cinematics/marine/sentry/fire_shell.cinematic")
//Sentry.kTracerEffect = PrecacheAsset("cinematics/marine/tracer.cinematic")

Sentry.kRicochetEffect = "cinematics/materials/%s/ricochet.cinematic"

PrecacheMultipleAssets(Sentry.kRicochetMaterialSound, kSurfaceList)
PrecacheMultipleAssets(Sentry.kRicochetEffect, kSurfaceList)

// Balance
Sentry.kPingInterval = 4
Sentry.kFov = 160
Sentry.kBaseROF = kSentryAttackBaseROF
Sentry.kRandROF = kSentryAttackRandROF
Sentry.kSpread = Vector( 0.02618, 0.02618, 0.02618 )
Sentry.kBulletsPerSalvo = kSentryAttackBulletsPerSalvo
Sentry.kDamagePerBullet = kSentryAttackDamage
Sentry.kBarrelScanRate = 60      // Degrees per second to scan back and forth with no target
Sentry.kBarrelMoveRate = 150     // Degrees per second to move sentry orientation towards target or back to flat when targeted
Sentry.kTargetCheckTime = .3
Sentry.kRange = 30
Sentry.kReorientSpeed = .05

// Animations
Sentry.kDeathAnimTable = {/*{1.0, "death"},*/ {1.0, "death2"}}
Sentry.kFlinchAnim = "flinch"
Sentry.kFlinchBigAnim = "flinch_big"
Sentry.kAttackStartAnim = "attack_start"
Sentry.kAttackAnim = "attack"
Sentry.kAttackEndAnim = "attack_end"
Sentry.kYawPoseParam = "sentry_yaw" // Sentry yaw pose parameter for aiming
Sentry.kPitchPoseParam = "sentry_pitch"
Sentry.kMuzzleNode = "fxnode_sentrymuzzle"
Sentry.kEyeNode = "fxnode_eye"

Sentry.kMode = enum( {'Unbuilt', 'PoweredDown', 'PoweringUp', 'PoweringDown', 'Scanning', 'SpinningUp', 'Attacking', 'SpinningDown', 'SettingTarget'} )

local networkVars = {

    mode                        = "enum Sentry.kMode",
    desiredMode                 = "enum Sentry.kMode",

    barrelYawDegrees            = "float",
    barrelPitchDegrees          = "float",
    
    // So we can update angles and pose parameters smoothly on client
    targetDirection             = "vector"    
    
}

function Sentry:OnCreate()

    Structure.OnCreate(self)
    
    self.desiredYawDegrees = 0
    self.desiredPitchDegrees = 0    
    self.barrelYawDegrees = 0
    self.barrelPitchDegrees = 0
    self.playingAttackSound = false
    
    self.timeLastScanSound = 0
    
    self.scanStartDegrees = 0
    
    self.timeOfLastTargetAcquisition = 0
    
    self.scanTime = nil
    
    self.mode = Sentry.kMode.Unbuilt
    self.desiredMode = Sentry.kMode.Unbuilt
    
    self.timeOfLastUpdate = Shared.GetTime()
    
end

function Sentry:OnInit()
    Structure.OnInit(self)
    self:SetUpdates(true)
end

function Sentry:GetSentryMode()
    return self.mode
end

function Sentry:GetFov()
    return Sentry.kFov
end

// Fire out out muzzle attach point
function Sentry:GetEyePos()
    return self:GetAttachPointOrigin(Sentry.kEyeNode)
end

function Sentry:GetDeathIconIndex()
    return kDeathMessageIcon.Sentry
end

function Sentry:GetRequiresPower()
    return true
end

function Sentry:GetCanIdle()
    return self:GetSentryMode() == Sentry.kMode.Scanning
end

function Sentry:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then 

        return { 
            kTechId.Attack, kTechId.Stop, kTechId.SetTarget, kTechId.None,
            kTechId.None, kTechId.None, kTechId.Recycle, kTechId.None 
            }
    end
    
    return nil
    
end

function Sentry:GetIsTargetValid(target)

    if(target ~= nil and target:GetIsAlive() and target ~= self and target:GetCanTakeDamage() and target:GetIsVisible()) then
    
        local distance = (target:GetModelOrigin() - self:GetModelOrigin()):GetLength()
        local canSee = self:GetCanSeeEntity(target)
        local inRange = distance < Sentry.kRange
        
        if(canSee and inRange) then
        
            return true, distance
            
        end
        
    end
    
    return false, Entity.invalidId

end

function Sentry:GetTargetDirection()
    return self.targetDirection
end

function Sentry:UpdateAngles(deltaTime)
    
    // Swing barrel yaw towards target        
    if (self:GetSentryMode() == Sentry.kMode.Attacking) then
    
        if self.targetDirection then
        
            local yawDiffRadians = GetAnglesDifference(GetYawFromVector(self.targetDirection), self:GetAngles().yaw)
            local yawDegrees = DegreesTo360(math.deg(yawDiffRadians))        
            self.desiredYawDegrees = Clamp(yawDegrees, -45, 45)
            
            local pitchDiffRadians = GetAnglesDifference(GetPitchFromVector(self.targetDirection), self:GetAngles().pitch)
            local pitchDegrees = DegreesTo360(math.deg(pitchDiffRadians))
            self.desiredPitchDegrees = Clamp(pitchDegrees, -180, 180)       

            self.scanTime = nil
            self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, Sentry.kBarrelMoveRate*deltaTime)
            
        end
        
    // Else when we have no target, swing it back and forth looking for targets
    else
    
        if(self.scanTime == nil) then
            self.scanStartDegrees = 0
            self.barrelYawDegrees = self:GetPoseParam(Sentry.kYawPoseParam)                
            self.scanTime = 0
        else
            self.scanTime = self.scanTime + deltaTime
        end
        
        local sin = math.sin(math.rad(self.scanStartDegrees + self.scanTime*Sentry.kBarrelScanRate))
        self.barrelYawDegrees = sin * self:GetFov() / 2
        
        // Swing barrel pitch back to flat
        self.desiredPitchDegrees = 0
    
    end
    
    // No matter what, swing barrel pitch towards desired pitch
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, Sentry.kBarrelMoveRate*deltaTime)    
    
end

function Sentry:GetIsFunctioning()
    return self:GetIsAlive() and self:GetIsBuilt() and self:GetIsActive()
end

function Sentry:OnUpdate(deltaTime)

    PROFILE("Sentry:OnUpdate")

    Structure.OnUpdate(self, deltaTime)
    
    if self:GetIsFunctioning() then
    
        if Server then
        
            // Handle sentry state changes
            self:UpdateMode(deltaTime)

            self:UpdateAttack(deltaTime)    
        
        end

        // Update barrel position    
        local mode = self:GetSentryMode()
        
        if mode == Sentry.kMode.Scanning or mode == Sentry.kMode.SpinningUp or mode == Sentry.kMode.SpinningDown or mode == Sentry.kMode.Attacking then
            self:UpdateAngles(deltaTime)
        end
        
    end
    
    self:UpdatePoseParameters(deltaTime)
    
    self.timeOfLastUpdate = self.timeOfLastUpdate + deltaTime
    
end

function Sentry:UpdatePoseParameters(deltaTime)

    PROFILE("Sentry:UpdatePoseParameters")
    
    self:SetPoseParam(Sentry.kPitchPoseParam, self.barrelPitchDegrees)
    self:SetPoseParam(Sentry.kYawPoseParam, self.barrelYawDegrees)
    
end

function Sentry:GetCanDoDamage()
    return true
end


Shared.LinkClassToMap("Sentry", Sentry.kMapName, networkVars)