// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
 
function Structure:UpdateEffects()

    LiveScriptActor.UpdateEffects(self)
    
    if (self.clientEffectsActive ~= nil) and (self.clientEffectsActive ~= self:GetEffectsActive()) then
    
        self:TriggerEffects("client_active_changed")
        
    end
    
    self.clientEffectsActive = self:GetEffectsActive()

end

