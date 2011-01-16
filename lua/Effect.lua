// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Effect.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Effect'

Effect.mapName = "effect"

function Effect:SetOrigin(newOrigin)

    self.origin = Vector()
    VectorCopy(newOrigin, self.origin)

end

function Effect:SetAngles(newAngles)
end

function Effect:OnLoad()

    self.radius = GetAndCheckValue(self.radius, 0, 1000, "radius", 0)
    self.offOnExit = GetAndCheckBoolean(self.offOnExit, "offOnExit", false)
    self.startsOn = GetAndCheckBoolean(self.startsOn, "startsOn", false)
    
    self.playing = false
    self.triggered = false
    self.startedOn = false
    
end

function Effect:GetOrigin()
    return self.origin
end

function Effect:GetRadius()
    return self.radius
end

function Effect:GetOffOnExit()
    return self.offOnExit
end

function Effect:GetStartsOn()
    return self.startsOn
end

if (Client) then

    // Check if effect should be turned on or of
    function Effect:OnUpdate(deltaTime)
    
        local player = Client.GetLocalPlayer()
        local origin = player:GetOrigin()
        
        if(Client and self:GetStartsOn() and not self.startedOn) then    
        
            self:StartPlaying()
            self.startedOn = true
            
        else

            local distance = (origin - self:GetOrigin()):GetLength()
            
            if(distance < self:GetRadius()) then
            
                self:StartPlaying()
                self.triggered = true
                
            elseif(self:GetOffOnExit() and self.triggered) then
            
                self:StopPlaying()
                
            end
            
        end
        
    end

end
