// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/MapMapBlip.lua
//
// Map MapBlips are displayed on player minimaps. Used to reduce total amount of traffic to
// clients and also to allow them to update smoothly and quickly. Propagated to clients in
// regular way.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'MapBlip' (Entity)

MapBlip.kMapName = "MapBlip"

MapBlip.networkVars =
{
    mapBlipType = "enum kMinimapBlipType",
    mapBlipTeam = "integer (" .. ToString(kTeamInvalid) .. " to " .. ToString(kSpectatorIndex) .. ")"
}

function MapBlip:OnCreate()

    self.mapBlipType = kMinimapBlipType.TechPoint
    self.mapBlipTeam = kTeamReadyRoom
    self.ownerEntityId = Entity.invalidId
    
end

function MapBlip:GetOwnerEntityId()

    return self.ownerEntityId

end

function MapBlip:GetType()

    return self.mapBlipType

end

function MapBlip:GetTeamNumber()

    return self.mapBlipTeam

end

function MapBlip:GetIsSighted()

    local owner = Shared.GetEntity(self.ownerEntityId)
    
    if owner then
        if owner:GetTeamNumber() == kTeamReadyRoom and owner:GetAttached() then
            owner = owner:GetAttached()
        end
        return owner:GetIsSighted()
    end
    
    return false
    
end

function MapBlip:OnGetIsRelevant(player)
    return GetGamerules():GetIsRelevant(player, self)   
end

function MapBlip:Update(entity, blipType, blipTeam)

    self.mapBlipType = blipType
    self.mapBlipTeam = blipTeam

    if entity.GetEngagementPoint then
        self:SetOrigin(entity:GetEngagementPoint())
    else
        self:SetOrigin(entity:GetModelOrigin())
    end
    
    self.ownerEntityId = entity:GetId()
    
end

function CreateUpdateMapBlip(mapBlips, entity, blipType, blipTeam)

    // Update MapBlip entity if exists, else create new one
    local updated = false
    
    for index, mapBlip in ipairs(mapBlips) do
    
        if mapBlip:GetOwnerEntityId() == entity:GetId() then
        
            mapBlip:Update(entity, blipType, blipTeam)
            updated = true
            break
            
        end
        
    end
    
    if not updated then
    
        // Create new MapBlip
        local mapBlip = CreateEntity(MapBlip.kMapName)
        mapBlip:Update(entity, blipType, blipTeam)
        
    end
    
end

Shared.LinkClassToMap( "MapBlip", MapBlip.kMapName, MapBlip.networkVars )