// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TimedCallbackMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TimedCallbackMixin = { }

function TimedCallbackMixin:AddTimedCallback(addFunction, callRate)

    if self.timedCallbacks == nil then
        self.timedCallbacks = { }
    end
    table.insert(self.timedCallbacks, { Function = addFunction, Rate = callRate, Time = 0 })

end

function TimedCallbackMixin:UpdateTimedCallbacks(deltaTime)
    
    if self.timedCallbacks then
        
        local removeCallbacks = { }
        for index, callback in ipairs(self.timedCallbacks) do
            callback.Time = callback.Time + deltaTime
            local numberOfIterations = 0
            while callback.Time >= callback.Rate and numberOfIterations < 3 do
                callback.Time = callback.Time - callback.Rate
                local continueCallback, atRate = callback.Function(self, callback.Rate)
                if atRate then
                    callback.Rate = atRate
                end
                if not continueCallback then
                    table.insert(removeCallbacks, callback)
                    break
                end
                numberOfIterations = numberOfIterations + 1
            end
        end
        
        for index, removeCallback in ipairs(removeCallbacks) do
            // Find the callback in the timedCallbacks list.
            for index, timedCallback in ipairs(self.timedCallbacks) do
                if timedCallback == removeCallback then
                    table.remove(self.timedCallbacks, i)
                end
            end
        end
        
    end

end