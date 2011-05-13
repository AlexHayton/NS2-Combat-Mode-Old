// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handled Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/MarineTeamSquads.lua")
Script.Load("lua/Commander.lua")

class 'MarineCommander' (Commander)

MarineCommander.kMapName = "marine_commander"

if(Client) then
    Script.Load("lua/MarineCommander_Client.lua")
end

MarineCommander.kSentryFiringSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_firing")
MarineCommander.kSentryTakingDamageSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_taking_damage")
MarineCommander.kSoldierLostSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/soldier_lost")
MarineCommander.kSoldierNeedsAmmoSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_ammo")
MarineCommander.kSoldierNeedsHealthSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_health")
MarineCommander.kSoldierNeedsOrderSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_order")
MarineCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/upgrade_complete")
MarineCommander.kResearchCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/research_complete")
MarineCommander.kObjectiveCompletedSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/complete")
MarineCommander.kMoveToWaypointSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/move")
MarineCommander.kAttackOrderSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/move")
MarineCommander.kStructureUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/base_under_attack")
MarineCommander.kBuildStructureSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/build")
MarineCommander.kDefendTargetSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/defend")
MarineCommander.kCommanderEjectedSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/commander_ejected")

MarineCommander.kOrderClickedEffect = PrecacheAsset("cinematics/marine/order.cinematic")
MarineCommander.kSelectSound = PrecacheAsset("sound/ns2.fev/marine/commander/select")
MarineCommander.kChatSound = PrecacheAsset("sound/ns2.fev/marine/common/chat")

MarineCommander.kUpdateSquadInterval = .3

local networkVars = 
{
    numSquads = "integer (0 to " .. GetMaxSquads() .. ")",
    
    // 0 if no squad selected
    selectedSquad = "integer (0 to " .. GetMaxSquads() .. ")"
}

function MarineCommander:OnInit()
    
    Commander.OnInit(self)
    
    self.numSquads = 0
    self.selectedSquad = 0
    
end

function MarineCommander:GetNumSquads()
    return self.numSquads
end

function MarineCommander:GetTeamType()
    return kMarineTeamType
end

function MarineCommander:GetOrderConfirmedEffect()
    return MarineCommander.kOrderClickedEffect
end

function MarineCommander:OnSelectionChanged()

    Commander.OnSelectionChanged(self)
    
    if(table.maxn(self.selectedEntities) > 0) then
    
        Shared.PlayPrivateSound(self, MarineCommander.kSelectSound, nil, 1.0, self:GetOrigin())
        
    end

end

// Top row always the same. Alien commander can override to replace. 
function MarineCommander:GetTopRowTechButtons()
    return { kTechId.BuildMenu, kTechId.AdvancedMenu, kTechId.AssistMenu, kTechId.SquadMenu }
end

function MarineCommander:GetSelectionRowsTechButtons(techId)

    local techButtons = {}
    
    if(techId == kTechId.BuildMenu) then 
    
        techButtons = { kTechId.CommandStation, kTechId.Extractor, kTechId.InfantryPortal, kTechId.Armory,
                        kTechId.Sentry, kTechId.None, kTechId.None, kTechId.RootMenu}
                        
    elseif(techId == kTechId.AdvancedMenu) then 
    
        techButtons = { kTechId.PowerPack, kTechId.Observatory, kTechId.RoboticsFactory, kTechId.PrototypeLab,
                        kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu}
        
    elseif(techId == kTechId.AssistMenu) then 
    
        techButtons = { kTechId.AmmoPack, kTechId.MedPack, kTechId.None, kTechId.None,
                        kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu}
        
    elseif(techId == kTechId.SquadMenu) then 
    
        techButtons = { kTechId.SelectRedSquad, kTechId.SelectBlueSquad, kTechId.SelectGreenSquad, kTechId.SelectYellowSquad,
                        kTechId.SelectOrangeSquad, kTechId.None, kTechId.None, kTechId.RootMenu}

    end
    
    return techButtons
    
end

function MarineCommander:ProcessNumberKeysMove(input, newPosition)

    if (bit.band(input.commands, Move.MovementModifier) ~= 0) then
    
        local squadNumber = nil
        
        if (bit.band(input.commands, Move.Weapon1) ~= 0) then
            squadNumber = 1
        elseif (bit.band(input.commands, Move.Weapon2) ~= 0) then
            squadNumber = 2
        elseif (bit.band(input.commands, Move.Weapon3) ~= 0) then
            squadNumber = 3
        elseif (bit.band(input.commands, Move.Weapon4) ~= 0) then
            squadNumber = 4
        elseif (bit.band(input.commands, Move.Weapon5) ~= 0) then
            squadNumber = 5
        end

        if squadNumber then
            self:SelectSquad(squadNumber)
        end
        
    end
    
    return Commander.ProcessNumberKeysMove(self, input, newPosition)
    
end

function MarineCommander:SelectSquad(squadNumber)

    local newSelection = {}
    local time = Shared.GetTime()
    
    local playerList = GetEntitiesForTeam(GetSquadClass(), self:GetTeamNumber())    
    for index, player in ipairs(playerList) do
    
        if player:GetSquad() == squadNumber then
            table.insert(newSelection, {player:GetId(), time})
        end

    end
    
    if table.count(newSelection) > 0 then
        self:SortSelection(newSelection)
        self:InternalSetSelection(newSelection)
    end

end

function MarineCommander:BuildSortedSquadList()

    local squadEntities = GetEntitiesForTeam(GetSquadClass(), self:GetTeamNumber())
    
    // Count number of squads to propagate to client
    local numSquads = 0
    local squads = {}
    for index, ent in ipairs(squadEntities) do
    
        local squad = ent:GetSquad()
        if(squad ~= nil and squad > 0 and not table.find(squads, squad)) then
        
            table.insert(squads, squad)
            
        end
        
    end
    
    // Sort list from smallest to highest so it displays predictably on HUD
    function sort(squad1, squad2)
        return squad1 < squad2
    end    
    table.sort(squads, sort)
    
    return squads
    
end

function MarineCommander:GetSortedSquadList()
    return self.sortedSquadList
end

function MarineCommander:UpdateSquads(deltaTime)

    if self.timeSinceLastSquadUpdate == nil then
        self.timeSinceLastSquadUpdate = 0
    end
    
    self.timeSinceLastSquadUpdate = self.timeSinceLastSquadUpdate + deltaTime
    
    if self.timeSinceLastSquadUpdate >= MarineCommander.kUpdateSquadInterval then
    
        // Only update every so often
        self.sortedSquadList = self:BuildSortedSquadList()
        self.numSquads = table.count( self.sortedSquads )
        
        // If we have a squad selected, set our selection to all ents in this squad
        if (self.selectedSquad ~= 0) then
        
            local squadEntities = GetEntitiesForTeam(GetSquadClass(), self:GetTeamNumber())
            local selection = {}
            
            for index, ent in ipairs(squadEntities) do
            
                if ent:GetSquad() == self.selectedSquad then
                    table.insert(selection, ent:GetId())
                end
                
            end
            
            self:SetSelection(selection)
            
        end
        
        self.timeSinceLastSquadUpdate = 0
        
    end
    
end

function MarineCommander:UpdateSelection(deltaTime)

    self:UpdateSquads(deltaTime)
    
    Commander.UpdateSelection(self, deltaTime)
    
end

function MarineCommander:GetChatSound()
    return MarineCommander.kChatSound
end

function MarineCommander:GetPlayerStatusDesc()
    return "Commander"
end

Shared.LinkClassToMap( "MarineCommander", MarineCommander.kMapName, networkVars )