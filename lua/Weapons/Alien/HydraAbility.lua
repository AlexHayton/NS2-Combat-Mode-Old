// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HydraAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Gorge builds hydra.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'HydraAbility' (Ability)

HydraAbility.kMapName = "hydra_ability"

HydraAbility.kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

// Gorge create hydra
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
    self.showGhost = true
    
end

function HydraAbility:GetEnergyCost(player)
    return 40
end

function HydraAbility:GetPrimaryAttackDelay()
    return 1.0
end

function HydraAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

// Check before energy is spent if a Hydra can be built in the current location.
function HydraAbility:OnPrimaryAttack(player)

    // Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForHydra(player)
    if valid then
        // Ensure they have enough resources.
        local cost = LookupTechData(kTechId.Hydra, kTechDataCostKey)
        if player:GetPlasma() >= cost then
            Ability.OnPrimaryAttack(self, player)
        else
            player:AddTooltip("Not enough resources to create Hydra.")
        end
    else
        player:AddTooltip("Could not place Hydra in that location.")
    end
    
end

// Create hydra
function HydraAbility:PerformPrimaryAttack(player)

    // Make ghost disappear
    if self.showGhost then
    
        player:TriggerEffects("start_create_hydra")
    
        player:SetAnimAndMode(Gorge.kCreateStructure, kPlayerMode.GorgeStructure)
            
        player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))
        
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
                
                player:TriggerEffects("create_hydra")
                
                player:AddPlasma( -cost )
				
				// Increase the hydra count by 1
				player:AddHydra()
                
                player:SetActivityEnd(.5)
                
            else
            
                player:AddTooltip("Not enough space for Hydra in that location.")
                DestroyEntity(hydra)
                
            end
            
        else
        
            if not valid then
                player:AddTooltip("Could not place Hydra in that location.")
            else
                player:AddTooltip("Not enough resources to create Hydra.")
            end
        end
        
    end
    
end

function HydraAbility:GetHUDSlot()
    return 3
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
        elseif trace.entity:isa("Infestation") or (not trace.entity:isa("LiveScriptActor") and not trace.entity:isa("Hydra")) then
            validPosition = true
        end
        
        VectorCopy(trace.endPoint, displayOrigin)
        
    end
    
    // Hydras can only be built on infestation
    if not GetIsPointOnInfestation(displayOrigin) then
        validPosition = false
    end
    
    // Don't allow placing hydras above or below us and don't draw either
    local hydraFacing = player:GetViewAngles():GetCoords().zAxis
    local coords = BuildCoords(trace.normal, hydraFacing, displayOrigin)    
    
    return coords, validPosition

end

if Client then
function HydraAbility:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Shared.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            // Show ghost if we're able to create a hydra
            self.showGhost = player:GetCanNewActivityStart()
            
            // Create ghost
            if not self.ghostHydra and self.showGhost then
            
                self.ghostHydra = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.ghostHydra:SetModel( Shared.GetModelIndex(Hydra.kModelName) )
                self.ghostHydra:SetCastsShadows(false)
                
                // Create build circle to show hydra range
                self.circle = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.circle:SetModel( Shared.GetModelIndex(HydraAbility.kCircleModelName) )
                
            end
            
            // Destroy ghost
            if self.ghostHydra and not self.showGhost then
                self:DestroyHydraGhost()
            end
            
            // Update ghost position 
            if self.ghostHydra then
            
                local coords, valid = self:GetPositionForHydra(player)
                
                if valid then
                    self.ghostHydra:SetCoords(coords)
                end
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

function HydraAbility:DestroyHydraGhost()

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
    self:DestroyHydraGhost()
    Ability.OnDestroy(self)
end

function HydraAbility:OnHolster(player)
    Ability.OnHolster(self, player)
    self:DestroyHydraGhost()
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
