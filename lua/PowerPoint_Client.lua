// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPoint_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function PowerPoint:UpdatePoweredLights()
    
    if not self.lightList then    
        self.lightList = GetLightsForPowerPoint(self)
    end
    
    for lightIndex, renderLight in ipairs(self.lightList) do
        self:UpdatePoweredLight(renderLight)
    end
end

function PowerPoint:UpdatePoweredLight(renderLight)

    local lightMode = self:GetLightMode()
    local timeOfChange = self:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange
    
    // Set original color in case it was recently set to red
    renderLight:SetColor( renderLight.originalColor )
    renderLight:SetIntensity( renderLight.originalIntensity )
    
    // Don't affect lights that have this set in editor
    if not renderLight.ignorePowergrid then
    
        // Bring lights back on
        if lightMode == kLightMode.Normal then
        
            local scalar = math.sin( Clamp(timePassed/PowerPoint.kPowerOnTime, 0, 1) * math.pi / 2)
            renderLight:SetIntensity( renderLight.originalIntensity * scalar )

        elseif lightMode == kLightMode.NoPower then
        
            if timePassed < PowerPoint.kPowerDownTime then
            
                local scalar = math.sin( Clamp(timePassed/PowerPoint.kPowerDownTime, 0, 1) * math.pi / 2)
                renderLight:SetIntensity( renderLight.originalIntensity * (1 - scalar) )

            elseif timePassed < (PowerPoint.kPowerDownTime + PowerPoint.kOffTime) then
            
                renderLight:SetIntensity( 0 )
                
            else

                // Fade red in and out to make it very clear that the power is out
                local scalar = math.sin(((timePassed - PowerPoint.kPowerDownTime - PowerPoint.kOffTime) / (PowerPoint.kAuxPowerCycleTime/2)) * math.pi / 2)
                local halfIntensity = (1 - PowerPoint.kAuxPowerMinIntensity)/2
                local intensity = PowerPoint.kAuxPowerMinIntensity + halfIntensity + scalar * halfIntensity
                renderLight:SetIntensity( renderLight.originalIntensity * intensity)
                renderLight:SetColor( Color(1, 0, 0) )
            
            end

        elseif lightMode == kLightMode.LowPower then
        
            // Cycle lights up and down telling everyone that there's an imminent threat
            local scalar = math.cos ((timePassed / (PowerPoint.kLowPowerCycleTime/2)) * math.pi / 2)
            local halfIntensity = (1 - PowerPoint.kLowPowerMinIntensity)/2
            local intensity = PowerPoint.kLowPowerMinIntensity + halfIntensity + scalar * halfIntensity
            renderLight:SetIntensity( renderLight.originalIntensity * intensity)

        // Cycle once when taking damage
        elseif lightMode == kLightMode.Damaged then

            local scalar = math.sin( Clamp(timePassed/PowerPoint.kDamagedCycleTime, 0, 1) * math.pi)
            local intensity = 1 - scalar * (1 - PowerPoint.kDamagedMinIntensity)
            renderLight:SetIntensity( renderLight.originalIntensity * intensity )
                    
        end
        
    end
    
end

function PowerPoint:OnUpdate(deltaTime)

    Structure.OnUpdate(self, deltaTime)
    
    self:CreateEffects()
    
    self:DeleteEffects()    

end

function PowerPoint:CreateEffects()

    // Create looping cinematics if we're low power or no power
    local lightMode = self:GetLightMode() 
    
    if lightMode == kLightMode.LowPower and not self.lowPowerEffect then
    
        self.lowPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.lowPowerEffect:SetCinematic(PowerPoint.kDamagedEffect)        
        self.lowPowerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.lowPowerEffect:SetCoords(self:GetCoords())
        self.timeCreatedLowPower = Shared.GetTime()
    
    elseif lightMode == kLightMode.NoPower and not self.noPowerEffect then

        self.noPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.noPowerEffect:SetCinematic(PowerPoint.kOfflineEffect)        
        self.noPowerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.noPowerEffect:SetCoords(self:GetCoords())
        self.timeCreatedNoPower = Shared.GetTime()
    
    end

end

function PowerPoint:DeleteEffects()

    local lightMode = self:GetLightMode() 

    // Delete old effects when they shouldn't be played any more, and also every three seconds
    local kReplayInterval = 3
    
    if (lightMode ~= kLightMode.LowPower and self.lowPowerEffect) or (self.timeCreatedLowPower and (Shared.GetTime() > self.timeCreatedLowPower + kReplayInterval)) then
    
        Client.DestroyCinematic(self.lowPowerEffect)
        self.lowPowerEffect = nil
        self.timeCreatedLowPower = nil

    end

    if (lightMode ~= kLightMode.NoPower and self.noPowerEffect) or (self.timeCreatedNoPower and (Shared.GetTime() > self.timeCreatedNoPower + kReplayInterval)) then
            
        Client.DestroyCinematic(self.noPowerEffect)
        self.noPowerEffect = nil
        self.timeCreatedNoPower = nil

    end

end

function PowerPoint:OnDestroy()

    if self.lowPowerEffect then
        Client.DestroyCinematic(self.lowPowerEffect)
        self.lowPowerEffect = nil
    end

    if self.noPowerEffect then
        Client.DestroyCinematic(self.noPowerEffect)
        self.noPowerEffect = nil
    end

    Structure.OnDestroy(self)
    
end