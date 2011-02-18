// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function CommandStation:OnCreate()

    CommandStructure.OnCreate(self)    
    
    self:SetLevelTechId(1, kTechId.CommandStation)
    self:SetLevelTechId(2, kTechId.CommandFacilityUpgrade)
    self:SetLevelTechId(3, kTechId.CommandCenterUpgrade)
    
    self:SetTechId(kTechId.CommandStation)
    
    self:SetModel(CommandStation.kModelName)
    
end

function CommandStation:OnKill(damage, attacker, doer, point, direction)

    CommandStructure.OnKill(self, damage, attacker, doer, point, direction)
    
    if self:GetAttached() then
        self:GetAttached():SetTechLevel(1)
    end

end

function CommandStation:GetTeamType()
    return kMarineTeamType
end

function CommandStation:GetCommanderClassName()
    return MarineCommander.kMapName   
end

function CommandStation:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        local techPoint = self:GetAttached()
        local techLevel = nil
        
        if(researchId == kTechId.CommandFacilityUpgrade) then
            success = self:Upgrade(kTechId.CommandFacility)
            techLevel = 2
        elseif(researchId == kTechId.CommandCenterUpgrade) then
            success = self:Upgrade(kTechId.CommandCenter)
            techLevel = 3
        end    
        
        if techPoint and techLevel then
            techPoint:SetTechLevel(techLevel)
        end
        
    end
    
    return success
    
end

function CommandStation:GetIsPlayerInside(player)
    local vecDiff = (player:GetModelOrigin() - self:GetModelOrigin())
    return vecDiff:GetLength() < self:GetExtents():GetLength()
end

function CommandStation:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Marine") and player:GetTeamNumber() == self:GetTeamNumber() and self:GetIsPlayerInside(player)
end

function CommandStation:KillPlayersInside()

    // Now kill any other players that are still inside the command station so they're not stuck!
    local players = GetGamerules():GetAllPlayers()
    
    for index, player in ipairs(players) do
    
        if not player:isa("Commander") and not player:isa("Spectator") then
        
            if self:GetIsPlayerInside(player) then
        
                player:Kill(self, self, self:GetOrigin())
                
            end
            
        end
    
    end

end

function CommandStation:LoginPlayer(player)

    local commander = CommandStructure.LoginPlayer(self, player)
    
    self:KillPlayersInside()  

    if not self.hasBeenOccupied then
    
        // Create some initial MACs
        for i = 1, kInitialMACs do
            local mac = CreateEntity(MAC.kMapName, self:GetOrigin(), self:GetTeamNumber())
            mac:SetOwner(commander)
        end
        
        self.hasBeenOccupied = true

    end  
    
end

function CommandStation:GetDamagedAlertId()
    return kTechId.MarineAlertCommandStationUnderAttack
end

