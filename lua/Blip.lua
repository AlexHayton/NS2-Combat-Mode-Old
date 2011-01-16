// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Blip.lua
//
// Alien hive sight blip. Used to reduce total amount of traffic to clients and also to allow
// them to update smoothly and quickly. Propagated to clients in regular way.
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2008-2010, Unknown Worlds Entertainment, Inc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Blip' (Entity)

Blip.kMapName = "blip"

Blip.networkVars =
{
    // No need to send entId as the entity origin is updated every frame
    blipType = "enum kBlipType"
}

function Blip:OnCreate()

    self.blipType = kBlipType.Undefined
    
    self.entId = Entity.invalidId
    
end

function Blip:OnGetIsRelevant(player)
    return GetGamerules():GetIsRelevant(player, self)   
end

function Blip:Update(entity, blipType, time)

    self.blipType = blipType

    if entity.GetEngagementPoint then
        self:SetOrigin(entity:GetEngagementPoint())
    else
        self:SetOrigin(entity:GetModelOrigin())
    end
    
    self.entId = entity:GetId()
    
    self.timeOfUpdate = time
    
end

function CreateUpdateBlip(blips, entity, blipType, time)

    // Update blip entity if exists, else create new one
    local updated = false
    
    for index, blip in ipairs(blips) do
    
        if blip.entId == entity:GetId() and blip.entId ~= Entity.invalidId then
        
            blip:Update(entity, blipType, time)
            updated = true
            break
            
        end
        
    end
    
    if not updated then
    
        // Create new blip
        local blip = CreateEntity(Blip.kMapName)
        blip:Update(entity, blipType, time)
        
    end
    
end

Shared.LinkClassToMap( "Blip", Blip.kMapName, Blip.networkVars )