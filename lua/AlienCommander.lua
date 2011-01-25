// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienCommander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handled Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Commander.lua")
class 'AlienCommander' (Commander)
AlienCommander.kMapName = "alien_commander"

AlienCommander.kOrderClickedEffect = PrecacheAsset("cinematics/alien/order.cinematic")
AlienCommander.kSelectSound = PrecacheAsset("sound/ns2.fev/alien/commander/select")
AlienCommander.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
AlienCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/upgrade_complete")
AlienCommander.kResearchCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/research_complete")
AlienCommander.kStructureUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/base_under_attack")

function AlienCommander:GetTeamType()
    return kAlienTeamType
end

function AlienCommander:GetOrderConfirmedEffect()
    return AlienCommander.kOrderClickedEffect
end

if(Client) then
function AlienCommander:SetupHud()

    Commander.SetupHud(self)
    
end
end

function AlienCommander:SetSelectionCircleMaterial(entity)
 
    if(entity:isa("Structure") and not entity:GetIsBuilt()) then
    
        SetMaterialFrame("alienBuild", entity.buildFraction)

    else

        // Allow entities without health to be selected (infest nodes)
        local healthPercent = 1
        if(entity.health ~= nil and entity.maxHealth ~= nil) then
            healthPercent = entity.health / entity.maxHealth
        end
        
        SetMaterialFrame("alienHealth", healthPercent)
        
    end
   
end

function AlienCommander:OnSelectionChanged()

    Commander.OnSelectionChanged(self)
    
    if(table.maxn(self.selectedEntities) > 0) then
    
        Shared.PlaySound(self, AlienCommander.kSelectSound)
        
    end

end

function AlienCommander:GetChatSound()
    return AlienCommander.kChatSound
end

Shared.LinkClassToMap( "AlienCommander", AlienCommander.kMapName, {} )