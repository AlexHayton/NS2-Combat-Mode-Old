// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Hive:OnInit()

    CommandStructure.OnInit(self)
    
    // Create glowy "plankton" swimming around hive, along with mist and glow
    local coords = self:GetCoords()
    self:AttachEffect(Hive.kSpecksEffect, coords)
    self:AttachEffect(Hive.kGlowEffect, coords, Cinematic.Repeat_Loop)
    
    // For mist creation
    self:SetUpdates(true)
        
end

function Hive:OnUpdate(deltaTime)

    CommandStructure.OnUpdate(self, deltaTime)
    
    // Attach mist effect if we don't have one already
    local coords = self:GetCoords()
    
    if self:GetTechId() == kTechId.Hive then
    
        self:AttachEffect(Hive.kIdleMistEffect, coords, Cinematic.Repeat_Loop)
        
    elseif self:GetTechId() == kTechId.HiveMass then
    
        self:RemoveEffect(Hive.kIdleMistEffect)
        self:AttachEffect(Hive.kL2IdleMistEffect, coords, Cinematic.Repeat_Loop)
        
    elseif self:GetTechId() == kTechId.HiveColony then
    
        self:RemoveEffect(Hive.kL2IdleMistEffect)
        self:AttachEffect(Hive.kL3IdleMistEffect, coords, Cinematic.Repeat_Loop)
        
    end

end
