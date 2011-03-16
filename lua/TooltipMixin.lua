// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TooltipMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TooltipMixin = { }

function TooltipMixin:__initmixin()

    self.displayedTooltips = {}

end

/**
 * Check if we've already displayed this tooltip. Returns false if we haven't, or if time
 * has expired since we've displayed
 */
function TooltipMixin:GetCanDisplayTooltip(tooltipText, timeInterval)

    ASSERT(type(tooltipText) == "string")
    
    local currentTime = Shared.GetTime()
    
    // Return false if we've recently added any tooltip
    if self.timeOfLastTooltip ~= nil and currentTime < (self.timeOfLastTooltip + self.__mixindata.kToolTipInterval) then
    
        return false
        
    end
    
    // Return false if we've too recently shown this particular tooltip
    for index, entity in ipairs(self.displayedTooltips) do
    
        if(tooltipText == entity[1]) then
        
            if(timeInterval == nil or (currentTime < entity[2] + timeInterval)) then
            
                return false
                
            end
            
        end
        
    end
    
    return true
    
end

function TooltipMixin:AddTooltipOnce(tooltipText)

    ASSERT(type(tooltipText) == "string")
    
    if(self:GetCanDisplayTooltip(tooltipText, nil)) then
    
        self:AddTooltip(tooltipText)
        return true
        
    end

    return false
    
end

function TooltipMixin:AddTooltipOncePer(tooltipText, timeInterval)

    ASSERT(type(tooltipText) == "string")
    
    if(timeInterval == nil) then
        timeInterval = 10
    end
    
    if(self:GetCanDisplayTooltip(tooltipText, timeInterval)) then
    
        self:AddTooltip(tooltipText)
        
        return true
        
    end

    return false

end

function TooltipMixin:AddTooltip(message)

    ASSERT(type(message) == "string")
    
    if Client then
        self:AddTooltipClient(message)
    elseif Server then
        self:AddTooltipServer(message)
    end
    
    self:AddDisplayedTooltip(message)
    
end

/**
 * Inform player about something (research complete, a structure that can be used, etc.)
 */
function TooltipMixin:AddTooltipClient(message)
    
    // Strip out surrounding "s
    local message = string.gsub(message, "\"(.*)\"", "%1")
    
    // Hook GUI display 
    HudTooltip_SetMessage(message)
    
    Shared.PlaySound(self, self.__mixindata.kTooltipSound)
    
end

function TooltipMixin:AddTooltipServer(message)
    
    Server.SendCommand(self, string.format("%s \"%s\"", "tooltip", message))
    self.timeOfLastTooltip = Shared.GetTime()

end

function TooltipMixin:AddDisplayedTooltip(message)

    ASSERT(type(message) == "string")
    table.insertunique(self.displayedTooltips, {message, Shared.GetTime()})
    
end

function TooltipMixin:ClearDisplayedTooltips()
    table.clear(self.displayedTooltips)
end