// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HydraAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'HydraAbility' (Ability)

HydraAbility.kMapName = "chamber"

HydraAbility.kCreateStartSound = PrecacheAsset("sound/ns2.fev/alien/gorge/create_structure_start")

HydraAbility.kCircleModelName = PrecacheAsset("models/misc/circle/circle.model")

HydraAbility.kCreateEffect = PrecacheAsset("cinematics/alien/gorge/create.cinematic")
HydraAbility.kCreateViewEffect = PrecacheAsset("cinematics/alien/gorge/create_view.cinematic")

// Gorge create hydra
HydraAbility.kAnimHydraAttack = "chamber_attack"
HydraAbility.kAnimIdleTable = { {1, "idle"}/*, {.3, "idle2"}, {.05, "idle3"}*/ }

HydraAbility.kPlacementDistance = 1.1

local networkVars = 
{
    // When true, show ghost hydra (on deploy and after attacking)
    showGhost               = "boolean",
    healthSprayPoseParam    = "compensated float",
    chamberPoseParam        = "compensated float"
}

function HydraAbility:OnInit()
    Ability.OnInit(self)
    self.showGhost = false
    self.healthSprayPoseParam = 0
    self.chamberPoseParam = 0
end

function HydraAbility:OnDraw(player, prevWeapon)

    Ability.OnDraw(self, player, prevWeapon)
    
    // Show ghost when switch to this weapon
    self.showGhost = true
    
end

function HydraAbility:GetIdleAnimation()
    return chooseWeightedEntry( HydraAbility.kAnimIdleTable )
end

function HydraAbility:GetEnergyCost(player)
    return 0
end

function HydraAbility:GetPrimaryAttackDelay()
    return 1.0
end

function HydraAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

// Drop hydra
function HydraAbility:PerformPrimaryAttack(player)

    if not self.showGhost then

        // Show ghost if not doing so
        self.showGhost = true
        
        player:SetActivityEnd(.1)
        
    else

        local coords, valid = self:GetPositionForHydra(player)
        
        if valid then
        
            // If we have enough plasma
            local cost = LookupTechData(kTechId.Hydra, kTechDataCostKey)
            if player:GetPlasma() >= cost then
        
                Shared.PlaySound(player, HydraAbility.kCreateStartSound)
                
                player:SetViewAnimation(HydraAbility.kAnimHydraAttack, nil, nil, 1/player:AdjustFuryFireDelay(1))
                player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))
                               
                if Client then
                    self:CreateWeaponEffect(player, "", "HydraSpray", HydraAbility.kCreateViewEffect)
                else
                    player:CreateAttachedEffect(HydraAbility.kCreateEffect, "Head")
                end
                
                // Create structure on animation complete
                player:SetAnimAndMode(Gorge.kCreateStructure, kPlayerMode.GorgeStructure)
                
                // Don't show ghost any longer until we attack again
                self.showGhost = false
                
            else
                Shared.PlayPrivateSound(player, player:GetNotEnoughResourcesSound(), player, 1.0, Vector(0, 0, 0))
            end
            
        else
        
            Shared.PlayPrivateSound(player, Player.kInvalidSound, player, 1.0, Vector(0, 0, 0))
        
        end    
        
    end
    
end

function HydraAbility:CreateHydra(player)

    // If we have enough plasma
    if Server then
    
        local coords, valid = self:GetPositionForHydra(player)
    
        local cost = LookupTechData(kTechId.Hydra, kTechDataCostKey)
        if valid and (player:GetPlasma() >= cost) then
        
            // Create structure
            local hydra = CreateEntity( Hydra.kMapName, coords.origin, player:GetTeamNumber() )
            hydra:SetOwner(player)
            
            // Check for space
            if hydra:SpaceClearForEntity(coords.origin) then
            
                local angles = Angles()
                angles:BuildFromCoords(coords)
                hydra:SetAngles(angles)
                
                player:PlaySound(player:GetPlaceBuildingSound())
                
                player:AddPlasma( -cost )
                
            else
            
                DestroyEntity(hydra)
                
            end
            
        end
        
    end
    
end

function HydraAbility:GetHUDSlot()
    return 2
end

// Given a gorge player's position and view angles, return a position and orientation
// for a hydra. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function HydraAbility:GetPositionForHydra(player)

    local validPosition = false
    local drawHydra = true
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * HydraAbility.kPlacementDistance

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = Vector()
    VectorCopy(trace.endPoint, displayOrigin)
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * HydraAbility.kPlacementDistance
        trace = Shared.TraceRay(origin, origin - Vector(0, HydraAbility.kPlacementDistance, 0), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    
        if trace.entity == nil then
            validPosition = true
        elseif not trace.entity:isa("LiveScriptActor") and not trace.entity:isa("Hydra") then
            validPosition = true
        end
        
        VectorCopy(trace.endPoint, displayOrigin)

        
    end
    
    // Don't allow placing hydras above or below us and don't draw either
    local hydraFacing = Vector()
    VectorCopy(player:GetViewAngles():GetCoords().zAxis, hydraFacing)
    
    if math.abs(player:GetViewAngles():GetCoords().zAxis:DotProduct(trace.normal)) > .8 then
        hydraFacing = Vector(1, 0, 0)    
    end
    
    local coords = BuildCoords(trace.normal, hydraFacing, displayOrigin)    
    
    return coords, validPosition

end

function HydraAbility:OnSecondaryAttack(player)
    // Make ghost disappear
    self.showGhost = false
end

if Client then
function HydraAbility:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Client.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            // Create ghost
            if not self.ghostHydra and self.showGhost then
            
                self.ghostHydra = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.ghostHydra:SetModel( Shared.GetModelIndex(Hydra.kModelName) )
                
                // Create build circle to show hydra range
                self.circle = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.circle:SetModel( Shared.GetModelIndex(HydraAbility.kCircleModelName) )
                
            end
            
            // Destroy ghost
            if self.ghostHydra and not self.showGhost then
                self:DestroyGhost()
            end
            
            // Update ghost position 
            if self.ghostHydra then
            
                local coords, valid = self:GetPositionForHydra(player)
                
                self.ghostHydra:SetCoords(coords)
                self.ghostHydra:SetIsVisible(valid)
                
                // Check plasma
                if player:GetPlasma() < LookupTechData(kTechId.Hydra, kTechDataCostKey) then
                
                    valid = false
                    
                end
                
                // Scale and position circle to show range
                if self.circle then
                
                    local coords = BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), coords.origin + Vector(0, .01, 0), 2 * Hydra.kRange)
                    self.circle:SetCoords(coords)
                    self.circle:SetIsVisible(valid)
                    
                end
                
                // TODO: Set color of structure according to validity
                
            end
          
        end
        
    end
    
end

function HydraAbility:DestroyGhost()

    if Client then
    
        if self.ghostHydra ~= nil then
        
            Client.DestroyRenderModel(self.ghostHydra)
            self.ghostHydra = nil
            
        end
        
        if self.circle ~= nil then
        
            Client.DestroyRenderModel(self.circle)
            self.circle = nil
            
        end
        
    end
    
end

function HydraAbility:OnDestroy()
    self:DestroyGhost()
    Ability.OnDestroy(self)
end

function HydraAbility:OnHolster(player)
    Ability.OnHolster(self, player)
    self:DestroyGhost()
end

end

function HydraAbility:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)

    // Move away from health spray
    self.healthSprayPoseParam = Clamp(Slerp(self.healthSprayPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("health_spray", self.healthSprayPoseParam)
    
    // Move away from chamber 
    self.chamberPoseParam = Clamp(Slerp(self.chamberPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("chamber", self.chamberPoseParam)
    
end

Shared.LinkClassToMap("HydraAbility", HydraAbility.kMapName, networkVars )
