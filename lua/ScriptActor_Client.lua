// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Base class for all visible entities that aren't players. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ScriptActor:OnSynchronized()

    PROFILE("ScriptActor:OnSynchronized")

    // Make sure to call OnInit() for client entities that have been propagated by the server
    if(not self.clientInitedOnSynch) then
    
        self:OnInit()
        
        self.clientInitedOnSynch = true
        
    end
    
    Actor.OnSynchronized(self)
    
end

function ScriptActor:OnDestroy()

    // Only call OnDestroyClient() for entities that are on the Client
    // Note: It isn't possible to check if this entity is the local player
    // at this point because there are cases where the local player entity
    // has changed before OnDestroy() is called
    if(Client) then
        self:OnDestroyClient()
    end
    
    self:DestroyAttachedEffects()

    BlendedActor.OnDestroy(self)
    
end

// Called on the Client only, after children OnDestroy() functions.
function ScriptActor:OnDestroyClient()
end

function ScriptActor:DestroyAttachedEffects()

    if self.attachedEffects ~= nil then
    
        for index, attachedEffect in ipairs(self.attachedEffects) do
        
            Client.DestroyCinematic(attachedEffect)
            
        end
        
        self.attachedEffects = nil
        
    end
    
end

// Uses loopmode endless by default
function ScriptActor:AttachEffect(effectName, coords, loopMode)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
    
    cinematic:SetCinematic( effectName )
    cinematic:SetCoords( coords )
    
    if loopMode == nil then
        loopMode = Cinematic.Repeat_Endless
    end
    
    cinematic:SetRepeatStyle(loopMode)

    if self.attachedEffects == nil then
        self.attachedEffects = {}
    end
    
    table.insert(self.attachedEffects, cinematic)
    
end

function ScriptActor:GetCameraViewCoords()

    local cameraCoords = self:GetViewCoords()
    cameraCoords.origin = self:GetEyePos()
    return cameraCoords
    
end

// The engine calls this function when rendering the view for the controlling player (set by SetConstrollingPlayer).
// Return radians.
function ScriptActor:GetRenderFov()
    // 90 degrees by default
    return math.pi/2
end


