// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
    
    BlendedActor.OnSynchronized(self)
    
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
        
            Client.DestroyCinematic(attachedEffect[1])
            
        end
        
        self.attachedEffects = nil
        
    end
    
end

function ScriptActor:RemoveEffect(effectName)
    
    if self.attachedEffects then
    
        for index, attachedEffect in ipairs(self.attachedEffects) do
        
            if attachedEffect[2] == effectName then
            
                Client.DestroyCinematic(attachedEffect[1])
                
                local success = table.removevalue(self.attachedEffects, attachedEffect)
                
                return true
                
            end
            
        end
        
    end
    
    return false

end

// Uses loopmode endless by default
function ScriptActor:AttachEffect(effectName, coords, loopMode)

    if self.attachedEffects == nil then
        self.attachedEffects = {}
    end

    // Don't create it if already created    
    for index, attachedEffect in ipairs(self.attachedEffects) do
        if attachedEffect[2] == effectName then
            return false
        end
    end

    local cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
    
    cinematic:SetCinematic( effectName )
    cinematic:SetCoords( coords )
    
    if loopMode == nil then
        loopMode = Cinematic.Repeat_Endless
    end
    
    cinematic:SetRepeatStyle(loopMode)

    table.insert(self.attachedEffects, {cinematic, effectName})
    
    return true
    
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

function ScriptActor:AddClientEffect(effectName)

    self:SetUpdates(true)
    
    if not self.clientEffects then
        self.clientEffects = {}
    end
    
    // Create trailing spit that is attached to projectile
    local clientEffect = Client.CreateCinematic(RenderScene.Zone_Default)
    clientEffect:SetCinematic(effectName)
    clientEffect:SetRepeatStyle(Cinematic.Repeat_Endless)  
    
    table.insert(self.clientEffects, clientEffect)
    
end

function ScriptActor:UpdateAttachedEffects()

    if self.attachedEffects then

        for index, effectPair in ipairs(self.attachedEffects) do
    
            local coords = Coords.GetIdentity()
            VectorCopy(self:GetOrigin(), coords.origin)
            effectPair[1]:SetCoords(coords)
            
        end
        
    end
    
end

function ScriptActor:OnUpdate(deltaTime)

    BlendedActor.OnUpdate(self, deltaTime)
    
    self:UpdateAttachedEffects()
    
end

