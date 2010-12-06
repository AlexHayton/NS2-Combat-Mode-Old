// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Flamethrower' (ClipWeapon)

if Client then
    Script.Load("lua/Weapons/Marine/Flamethrower_Client.lua")
end

Flamethrower.kMapName                 = "flamethrower"

Flamethrower.kModelName = PrecacheAsset("models/marine/flamethrower/flamethrower.model")
Flamethrower.kViewModelName = PrecacheAsset("models/marine/flamethrower/flamethrower_view.model")

Flamethrower.kAttackStartSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_start")
Flamethrower.kAttackLoopSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_loop")
Flamethrower.kAttackEndSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/attack_end")
Flamethrower.kDrawSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/draw")
Flamethrower.kIdleSoundName = PrecacheAsset("sound/ns2.fev/marine/flamethrower/idle")

Flamethrower.kBurnBigCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_big.cinematic")
Flamethrower.kBurnHugeCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_huge.cinematic")
Flamethrower.kBurnMedCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_med.cinematic")
Flamethrower.kBurnSmallCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_small.cinematic")
Flamethrower.kBurn1PCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_1p.cinematic")
Flamethrower.kFlameCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame.cinematic")
Flamethrower.kFlameFirstPersonCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_1p.cinematic")
Flamethrower.kFlameoutCinematic = PrecacheAsset("cinematics/marine/flamethrower/flameout.cinematic")
Flamethrower.kImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/impact.cinematic")
Flamethrower.kPilotCinematic = PrecacheAsset("cinematics/marine/flamethrower/pilot.cinematic")
Flamethrower.kScorchedCinematic = PrecacheAsset("cinematics/marine/flamethrower/scorched.cinematic")

Flamethrower.kMuzzleNode = "fxnode_flamethrowermuzzle"

Flamethrower.kFireAnimTable = { {.5, "attack"}, {.5, "attack2"} }
Flamethrower.kAnimIdleTable = { {1.0, "idle"}, {.05, "idle2"}, {.04, "idle3"}, {.4, "idle4"}, {.04, "idle5"} }

Flamethrower.kAttackDelay = kFlamethrowerFireDelay
Flamethrower.kRange = 10
Flamethrower.kDamage = kFlamethrowerDamage

local networkVars = { }

function Flamethrower:OnInit()

    ClipWeapon.OnInit(self)

    if Client then
        self.pilotLightState = false
    end

end

function Flamethrower:GetPrimaryAttackDelay()
    return Flamethrower.kAttackDelay
end

function Flamethrower:OnHolster(player)

    ClipWeapon.OnHolster(self, player)

    Shared.StopSound(player, self:GetFireSoundName())
    
    self:SetPilotLightState(false)

end

function Flamethrower:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponName)
    
    self:SetPilotLightState(true)
    
end

function Flamethrower:GetClipSize()
    return kFlamethrowerClipSize
end

function Flamethrower:CreatePrimaryAttackEffect(player)

    // Create 1st person or world flame effect
    local flameEffect = ConditionalValue(player:GetIsFirstPerson(), Flamethrower.kFlameFirstPersonCinematic, Flamethrower.kFlameCinematic)
    
    self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Flamethrower.kMuzzleNode, flameEffect)
    
    // Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()

end

function Flamethrower:GetRange()
    return Flamethrower.kRange
end

function Flamethrower:GetWarmupTime()
    return .15
end

function Flamethrower:PlayPrimaryAttackSound(player)

    // Play single shot (concurrently with loop) the first time we fire
    if(self.loopingWeaponSoundPlaying == 0) then
    
        Shared.PlaySound(player, Flamethrower.kAttackStartSoundName)
        
    end
    
    ClipWeapon.PlayPrimaryAttackSound(self, player)    
        
end

function Flamethrower:GetViewModelName()
    return Flamethrower.kViewModelName
end

function Flamethrower:FirePrimary(player, bullets, range, penetration)

    if Server then
    
    local barrelPoint = self:GetBarrelPoint(player)
    local ents = GetGamerules():GetEntities("LiveScriptActor", -1, barrelPoint, range)
    
    local fireDirection = player:GetViewAngles():GetCoords().zAxis
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - barrelPoint)
            local dotProduct = fireDirection:DotProduct(toEnemy)
        
            // Look for enemies in cone in front of us    
            if dotProduct > .9 then
        
                // Do damage to them and catch them on fire
                ent:TakeDamage(Flamethrower.kDamage, player, self, ent:GetModelOrigin(), toEnemy)
                
                if GetGamerules():CanEntityDoDamageTo(player, ent) then
                
                    ent:SetOnFire(player, self)
                    
                    // Play on fire cinematic
                    Shared.CreateEffect(nil, Flamethrower.kImpactCinematic, ent, Coords.GetIdentity())
                    
                end
                
            end
            
        end
        
    end    
    
    end
    
end

function Flamethrower:GetTechId()
    return kTechId.Flamethrower
end

function Flamethrower:GetDeathIconIndex()
    return kDeathMessageIcon.Flamethrower
end

function Flamethrower:GetDrawSound()
    return Flamethrower.kDrawSoundName
end

function Flamethrower:GetIsPrimaryAttackLooping()
    return true
end

function Flamethrower:GetFireSoundName()
    return Flamethrower.kAttackLoopSoundName
end

function Flamethrower:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Flamethrower:GetPrimaryAttackAnimation()
    return chooseWeightedEntry( Flamethrower.kFireAnimTable )   
end

function Flamethrower:GetBaseIdleAnimation()
    return chooseWeightedEntry( Flamethrower.kAnimIdleTable )    
end

function Flamethrower:OnPrimaryAttack(player)

    ClipWeapon.OnPrimaryAttack(self, player)
    
    self:SetPilotLightState(false)
    
end

function Flamethrower:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self:SetOverlayAnimation( nil )
    
    Shared.StopSound(player, self:GetFireSoundName())
    
    if self:GetClip() > 0 then
        self:CreateWeaponEffect(player, Weapon.kHumanAttachPoint, Flamethrower.kMuzzleNode, Flamethrower.kFlameoutCinematic)
    end
    
    self.loopingWeaponSoundPlaying = 0
    
    Shared.PlaySound(player, Flamethrower.kAttackEndSoundName)
    
    self:SetPilotLightState(true)
    
end

function Flamethrower:GetSwingSensitivity()
    return .8
end

if Server then
function Flamethrower:SetPilotLightState(state)
end
end

Shared.LinkClassToMap("Flamethrower", Flamethrower.kMapName, networkVars)