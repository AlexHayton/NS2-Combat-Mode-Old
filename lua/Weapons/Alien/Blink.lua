// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Blink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Blink - Attacking many times in a row will create a cool visual "chain" of attacks, 
// showing the more flavorful animations in sequence. Base class for swipe and stab.
//
// TODO: Hold shift for "rebound" type ability. Shift while looking at enemy lets you blink above, behind or off of a wall.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Blink' (Ability)
Blink.kMapName = "blink"

if Client then
    Script.Load("lua/Weapons/Alien/Blink_Client.lua")
end

Blink.kBlinkSound = PrecacheAsset("sound/ns2.fev/alien/fade/blink")

Blink.kBlinkInEffect = PrecacheAsset("cinematics/alien/fade/blink_in.cinematic")
Blink.kBlinkOutEffect = PrecacheAsset("cinematics/alien/fade/blink_out.cinematic")
Blink.kBlinkViewEffect = PrecacheAsset("cinematics/alien/fade/blink_view.cinematic")
Blink.kBlinkPreviewEffect = PrecacheAsset("cinematics/alien/fade/blink_preview.cinematic")

// Blink
Blink.kSecondaryAttackDelay = 0
Blink.kBlinkEnergyCost = kBlinkEnergyCost
Blink.kBlinkDistance = 20
Blink.kOrientationScanRadius = 2.5

local networkVars = {
    showingGhost        = "boolean",
}

kBlinkType = enum( {'Unknown', 'OnObject', 'InAir', 'Attack'} )

function Blink:OnInit()

    Ability.OnInit(self)
    self.showingGhost = false
    
end

function Blink:OnHolster(player)

    Ability.OnHolster(self, player)
    
    if self.showingGhost then
    
        self.showingGhost = false
        
        if Client then
            self:DestroyGhost()
        end
        
    end
    
end

function Blink:GetHasSecondary()
    return true
end

function Blink:GetSecondaryEnergyCost(player)
    return ConditionalValue(self.showingGhost, Blink.kBlinkEnergyCost, 0)
end

function Blink:GetSecondaryAttackDelay()
    return Blink.kSecondaryAttackDelay
end

function Blink:GetSecondaryAttackRequiresPress()
    return true
end

function Blink:GetBlinkOrientation(player, origin)

    // Look for any enemy players or structures nearby. Bias towards closest ones.
    local ents = GetEntitiesForTeamWithinRangeAreVisible("LiveScriptActor", GetEnemyTeamNumber(player:GetTeamNumber()), origin, Blink.kOrientationScanRadius, true)
    
    // Remove player from the list so we don't try to face ourselves
    table.removevalue(ents, player)
    
    // The comparison function must return a boolean value specifying whether the first argument should 
    // be before the second argument in the sequence (he default behavior is <).
    function sortFadeTargets(ent1, ent2)

        // Choose the closest target
        if (ent1:GetOrigin() - origin):GetLength() < (ent2:GetOrigin() - origin):GetLength() then
            return true
        end
        
        return false
        
    end
    
    table.sort(ents, sortFadeTargets)

    // Don't allow fade to face down too much as it affects transform when crossing with up (won't be needed anyways)
    local fadeFacing = Vector(0, 0, 0)
    VectorCopy(player:GetViewAngles():GetCoords().zAxis, fadeFacing)
    fadeFacing.y = 0
    fadeFacing:Normalize()

    // Set facing to first entity in the list
    if table.count(ents) > 0 then
    
        // Face towards model origin    
        local targetFacingOrigin = Vector(ents[1]:GetModelOrigin())        
        local toVector = ents[1]:GetModelOrigin() - origin
        toVector.y = 0        
        VectorCopy(GetNormalizedVector(toVector), fadeFacing)
            
    end    

    return fadeFacing
    
end

function Blink:PerformBacktrace(player, startPos, endPos, endPosDiffStep, maxTraces, blinkPosition)

    local numTraces
    local trace = nil
    
    for numTraces = 1, maxTraces do
    
        trace = Shared.TraceRay(startPos, Vector(endPos + endPosDiffStep * numTraces), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
        VectorCopy(trace.endPoint, blinkPosition)
        
        validPosition = GetHasRoomForCapsule(player:GetExtents(), blinkPosition + Vector(0, player:GetExtents().y, 0), PhysicsMask.AllButPCsAndRagdolls, player)
        
        if validPosition then
            break            
        end
        
    end
    
    return trace, validPosition                       
    
end

// Controls placement of the fade "ghost" when blinking
function Blink:GetBlinkPosition(player)
    
    local playerViewDirection = player:GetViewAngles():GetCoords().zAxis
    local startOrigin = Vector(player:GetEyePos())
    local endOrigin = startOrigin + playerViewDirection * Blink.kBlinkDistance

    // Trace distance in front
    local trace = Shared.TraceRay(startOrigin, endOrigin, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local originalBlinkPosition = trace.endPoint
    local blinkPosition = trace.endPoint
    
    local validPosition = false
    local blinkType = kBlinkType.Unknown
    
    // Hit something
    if trace.fraction ~= 1 then
    
        // If we hit a prop or wall, try to blink "on top" of it
        if trace.entity == nil or (trace.entity:isa("ScriptActor") and not trace.entity:isa("Player")) then
        
            // Trace from inside entity out away and up from us, then trace from that position back towards us
            local justInsideObject = trace.endPoint + playerViewDirection * .2
            trace = Shared.TraceRay(justInsideObject, justInsideObject + Vector(playerViewDirection * 1) + Vector(0, 8, 0), PhysicsMask.AllButPCsAndRagdolls, EntityFilterOne(trace.entity))            

            trace = Shared.TraceRay(trace.endPoint, originalBlinkPosition, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
          
            // To avoid floor interpenetration
            blinkPosition = trace.endPoint + Vector(0, .025, 0)
            
            local extents = player:GetExtents()
            validPosition = GetHasRoomForCapsule(extents, blinkPosition + Vector(0, extents.y, 0), PhysicsMask.AllButPCsAndRagdolls, player)
            
            // Make sure we can see ghost (to be sure it's not outside the level)
            if validPosition then
            
                local model = Shared.GetModel(player.modelIndex)
                trace = Shared.TraceRay(startOrigin, blinkPosition + model:GetOrigin(), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
                validPosition = (trace.fraction == 1)
                
            end
            
            if validPosition then
            
                blinkType = kBlinkType.OnObject

            // If that fails, try to blink just in front of it (towards us)            
            else
            
                // Trace towards us until it's valid
                trace, validPosition = self:PerformBacktrace(player, startOrigin, originalBlinkPosition, playerViewDirection * -2*Fade.XZExtents, 20, blinkPosition)
                blinkPosition = trace.endPoint
                
                if validPosition then                    
                
                    blinkType = kBlinkType.InAir
                    
                end
                    
            end            
        
        // If we hit a friend or enemy, blink above, behind or to side of them, depending on exact direction
        elseif trace.entity ~= nil and trace.entity:isa("LiveScriptActor") then
        
            validPosition = GetHasRoomForCapsule(player:GetExtents(), blinkPosition, PhysicsMask.AllButPCsAndRagdolls, player)
            blinkType = kBlinkType.Attack
            
        end
        
    else
    
        // Floating in air, trace down to ground
        trace = Shared.TraceRay(endOrigin, endOrigin - Vector(0, 2, 0), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
        if trace.fraction ~= 1 then

            local groundPoint = Vector(trace.endPoint + Vector(0, .02, 0))        
            trace, validPosition = self:PerformBacktrace(player, endOrigin, groundPoint, Vector(0, Fade.YExtents/4, 0), 30, blinkPosition)
            
            if validPosition then
                blinkType = kBlinkType.OnObject
            end
        
        else
        
            VectorCopy(endOrigin, blinkPosition)
            blinkPosition.y = blinkPosition.y - Fade.YExtents
            validPosition = GetHasRoomForCapsule(player:GetExtents(), blinkPosition, PhysicsMask.AllButPCsAndRagdolls, player)
            
            if validPosition then
                blinkType = kBlinkType.InAir
            else
                trace, validPosition = self:PerformBacktrace(player, startOrigin, endOrigin, playerViewDirection * -2*Fade.XZExtents, 20, blinkPosition)
                if validPosition then
                    blinkType = kBlinkType.InAir
                end
            end
            
        end
        
    end
    
    // Determine facing - orient towards the nearest living entity (bias towards enemies)
    local fadeFacing = self:GetBlinkOrientation(player, blinkPosition)
    local coords = BuildCoords(Vector(0, 1, 0), fadeFacing, blinkPosition)
    
    return coords, validPosition, blinkType
    
end

function Blink:PerformBlink(player)

    local coords, valid = self:GetBlinkPosition(player)
    
    if valid then

        // Local/view model effects    
        self.showingGhost = false

        self:TriggerEffects("blink_out", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        // Play world effects. Play particle effect at vanishing position, along with ghostly fade blink-out
        if Client then
            self:CreateBlinkOutEffect(player)
        end
            
        // Animate camera extremely quickly
        local blinkDistance = (coords.origin - self:GetOrigin()):GetLength()
        local blinkTime = math.min(blinkDistance / 120, .06)
        
        if Client then
        
            local destCoords = coords
            destCoords.origin = destCoords.origin + player:GetViewOffset()
            
            self:SetBlinkCamera(player:GetViewAnglesCoords(), destCoords, blinkTime)             
            
        end
        
        // Set new position and facing
        player:SetOrigin(coords.origin)        
        
        local angles = Angles()
        angles:BuildFromCoords(coords)
        player:SetOffsetAngles(angles)        
        
        self:TriggerEffects("blink_in", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        player:SetAnimAndMode(Fade.kBlinkInAnim, kPlayerMode.FadeBlinkIn)
        
        // Blink time dependent on blink out and blink in animations        
        player:SetActivityEnd(blinkTime)
        
    end
    
    return valid
    
end

function Blink:GetIsBlinking()
    return (self.blinkEndTime ~= nil) and (Shared.GetTime() < (self.blinkEndTime + kEpsilon))
end

function Blink:PerformPrimaryAttack(player)

    self.showingGhost = false
    
end

// Create ghost or cancel ghost
function Blink:PerformSecondaryAttack(player)

    // If we've already got a ghost, blink to it
    if self.showingGhost then
    
        self:PerformBlink(player)    
        return true

    else    

        // Show ghost if not displayed
        self.showingGhost = not self.showingGhost

        if Client then
            self:TriggerEffects("blink_ghost")
        end
        
    end
    
    Ability.PerformSecondaryAttack(self, player)
    
    return true
    
end

Shared.LinkClassToMap("Blink", Blink.kMapName, networkVars )
