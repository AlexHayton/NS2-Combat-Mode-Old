// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides cloaking abilities and confuse and deceive capabilities.
//
// Disorient (Passive) - Enemy structures and players flicker in and out when in range of Shade, 
// making it hard for Commander and team-mates to be able to support each other. Extreme reverb 
// sounds for enemies (and slight reverb sounds for friendlies) enhance the effect.
//
// Cloak (Triggered) - Instantly cloaks self and all enemy structures and aliens in range
// for a short time. Mutes or changes sounds too? Cleverly used, this would ideally allow a 
// team to get a stealth hive built. Allow players to stay cloaked for awhile, until they attack
// (even if they move out of range - great for getting by sentries).
//
// Phantasm (Targeted) - Allow Commander to create fake Fade, Onos, Hive (and possibly 
// ammo/medpacks). They can be pathed around and used to create tactical distractions or divert 
// forces elsewhere.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Shade' (Structure)

Shade.kMapName = "shade"

Shade.kModelName = PrecacheAsset("models/alien/shade/shade.model")

Shade.kAnimIdle = "idle"

Shade.kIdleSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shade/idle")

Shade.kBlindEffect = PrecacheAsset("cinematics/alien/shade/blind.cinematic")
Shade.kGlowEffect = PrecacheAsset("cinematics/alien/shade/glow.cinematic")
Shade.kPhantasmEffect = PrecacheAsset("cinematics/alien/shade/phantasm.cinematic")

Shade.kCloakDuration = 10
Shade.kCloakRadius = 15
 
function Shade:GetIsAlienStructure()
    return true
end

function Shade:GetIdleSound()
    return Shade.kIdleSoundEffect
end

function Shade:GetIdleAnimation()
    return Shade.kAnimIdle
end

function Shade:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.ShadeDisorient, kTechId.ShadeCloak, kTechId.ShadePhantasmMenu }
        
        // Allow structure to be upgraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Shade) then
            techButtons[upgradeIndex] = kTechId.MatureShade
        end
       
    elseif techId == kTechId.UpgradesMenu then 
    
        techButtons = {kTechId.FeintTech, kTechId.None, kTechId.None}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
        
    elseif techId == kTechId.ShadePhantasmMenu then        
    
        techButtons = {kTechId.ShadePhantasmFade, kTechId.ShadePhantasmOnos, kTechId.ShadePhantasmHive}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu

    end
    
    return techButtons
    
end

function Shade:GetDeathEffect()
    return Structure.kAlienDeathLargeEffect
end

function Shade:GetDamageEffectOffset()
    return Vector(0, 9, 10)
end

function Shade:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)

    if success then
    
        // Transform into mature shade
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeShade) then
        
            success = self:Upgrade(kTechId.MatureShade)
            
        end
    
    end
    
    return success
    
end

// Cloaking is handled in Player:UpdateCloaking
function Shade:GetIsCloakActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfCloak ~= nil) and (Shared.GetTime() < (self.timeOfCloak + Shade.kCloakDuration))
end

function Shade:TriggerCloak()
    self.timeOfCloak = Shared.GetTime()
    return true
end

function Shade:GetActivationTechAllowed(techId)
    // Passive ability, just here for the tooltip
    if techId == kTechId.ShadeDisorient then
        return false
    end
end

function Shade:PerformActivation(techId, position, commander)

    local success = false
    
    if techId == kTechId.ShadeCloak then
    
        success = self:TriggerCloak()    
    
    end
    
    return success
    
end

Shared.LinkClassToMap("Shade", Shade.kMapName, {})

class 'MatureShade' (Shade)

MatureShade.kMapName = "matureshade"

Shared.LinkClassToMap("MatureShade", MatureShade.kMapName, {})