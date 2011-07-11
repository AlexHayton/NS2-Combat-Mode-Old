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
    mapBlipType     = "enum kMinimapBlipType",
    mapBlipTeam     = "integer (" .. ToString(kTeamInvalid) .. " to " .. ToString(kSpectatorIndex) .. ")",
    rotation        = "float",
    ownerEntityId   = "entityid"
}

function MapBlip:OnCreate()

    self.mapBlipType = kMinimapBlipType.TechPoint
    self.mapBlipTeam = kTeamReadyRoom
    self.rotation = 0
    self.ownerEntityId = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function MapBlip:UpdateRelevancy()

	self:SetRelevancyDistance(Math.infinity)
	
	local mask = 0
	
	if self.mapBlipTeam == kTeam1Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
		mask = bit.bor(mask, kRelevantToTeam1)
	end
	if self.mapBlipTeam == kTeam2Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
		mask = bit.bor(mask, kRelevantToTeam2)
	end
		
	self:SetExcludeRelevancyMask( mask )

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

function MapBlip:GetRotation()

    return self.rotation

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
    
    local fowardNormal = entity:GetCoords().zAxis
    self.rotation = math.atan2(fowardNormal.x, fowardNormal.z)
    
    self:SetOrigin(entity:GetOrigin())
    
    self.ownerEntityId = entity:GetId()
    
    self:UpdateRelevancy()
    
end

function MapBlip:GetIsValid ()

 local entity = Shared.GetEntity(self:GetOwnerEntityId())
 if (entity == nil) then
    return false
 end
 
 if (entity.GetIsBlipValid) then
    return entity:GetIsBlipValid()
 end
 
 return true
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