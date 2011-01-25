// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Crag.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that gives the commander defense and protection abilities.
//
// Passive ability - heals nearby players and structures
// Triggered ability - emit defensive umbra (8 seconds)
// Active ability - stream Babblers out towards target, hampering their ability to attack
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Crag' (Structure)

Crag.kMapName = "crag"

Crag.kModelName = PrecacheAsset("models/alien/crag/crag.model")

// Same as NS1
Crag.kHealRadius = 10
Crag.kHealAmount = 10
Crag.kMaxTargets = 3
Crag.kThinkInterval = .25
Crag.kHealInterval = 2.0
Crag.kUmbraDuration = 8
Crag.kUmbraRadius = 5

// Umbra blocks 1 out of this many bullet
Crag.kUmbraBulletChance = 2

function Crag:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetNextThink(Crag.kThinkInterval)
    
end

function Crag:GetIsAlienStructure()
    return true
end

// Sort entities by priority (players before structures, most damaged before least)
function Crag:GetSortedTargetList()

    local ents = GetGamerules():GetEntities("LiveScriptActor", self:GetTeamNumber(), self:GetOrigin(), Crag.kHealRadius)
    
    local targets = {}
    
    // Only include hurt entities
    for index, entity in ipairs(ents) do

        if (entity:GetHealth() < entity:GetMaxHealth()) or (entity:GetArmor() < entity:GetMaxArmor()) then
            
            // Crags don't heal self
            if entity ~= self then
    
                table.insert(targets, entity)
                
            end
            
        end
        
    end
    
    // The comparison function must return a boolean value specifying whether the first argument should 
    // be before the second argument in the sequence (he default behavior is <).
    // All table.sort functions need to be deterministic.
    // For example, if ent1 < ent2 than later the same ent2 cannot be < ent1.
    function sortCragTargets(ent1, ent2)
    
        local p1 = ent1:isa("Player")
        local p2 = ent2:isa("Player")
    
        // Heal players before structures
        if p1 and not p2 then
            return true
        end
        
        if not p1 and p2 then
            return false
        end

        // Healing ourself takes priority after players
        if ent1 == self then
            return true
        end
        
        // Heal most hurt entities first (looks at total percentage of health)
        // ent2 ~= self is required so this function is deterministic.
        if ent2 ~= self and ent1:GetHealthScalar() <= ent2:GetHealthScalar() then
            return true
        end
                
        return false
        
    end
    
    table.sort(targets, sortCragTargets)
    
    return targets
    
end

function Crag:PerformHealing()

    local ents = self:GetSortedTargetList()
    
    local entsHealed = 0
    
    for index, entity in ipairs(ents) do
    
        if (entity:AddHealth(Crag.kHealAmount) > 0) then
        
            entity:TriggerEffects("crag_target_healed")
            
            entsHealed = entsHealed + 1
            
        end
        
        // Can only heal a certain number of targets
        if (entsHealed >= Crag.kMaxTargets) then
        
            break
            
        end
    
    end
    
    if entsHealed > 0 then
    
        local energyCost = LookupTechData(kTechId.CragHeal, kTechDataCostKey, 0)
    
        self:AddEnergy(-energyCost)
        
        self:TriggerEffects("crag_heal")
        
    end
    
end

function Crag:UpdateHealing()

    local time = Shared.GetTime()
    
    if (self.timeOfLastHeal == nil or (time > self.timeOfLastHeal + Crag.kHealInterval)) then
    
        // Only heal if it has the energy to do so
        local energyCost = LookupTechData(kTechId.CragHeal, kTechDataCostKey, 0)
        
        if self:GetEnergy() >= energyCost then
    
            self:PerformHealing()
            
            self.timeOfLastHeal = time
            
        end
        
    end
    
end

// Look for nearby friendlies to heal
function Crag:OnThink()

    Structure.OnThink(self)
    
    if self:GetIsBuilt() then
    
        self:UpdateHealing()
        
    end
        
    self:SetNextThink(Crag.kThinkInterval)
    
end

function Crag:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        // Transform into mature crag
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeCrag) then
        
            success = self:Upgrade(kTechId.MatureCrag)
            
        end
        
    end
    
    return success    
    
end

function Crag:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.CragHeal, kTechId.CragUmbra }
        
        // Allow structure to be ugpraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Crag) then
            techButtons[upgradeIndex] = kTechId.UpgradeCrag
        elseif(self:GetTechId() == kTechId.MatureCrag) then
            techButtons[upgradeIndex] = kTechId.CragBabblers
        end
       
    elseif(techId == kTechId.UpgradesMenu) then 
    
        techButtons = {kTechId.CarapaceTech, kTechId.BacteriaTech, kTechId.BoneShieldTech, kTechId.AlienArmor1Tech, kTechId.AlienArmor2Tech, kTechId.AlienArmor3Tech, kTechId.None}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
        
    end
    
    return techButtons
    
end

function Crag:GetIsUmbraActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastUmbra ~= nil) and (Shared.GetTime() < (self.timeOfLastUmbra + Crag.kUmbraDuration))
end

function Crag:TriggerUmbra(commander)

    self:TriggerEffects("crag_trigger_umbra")

    // Think immediately instead of waiting up to Crag.kThinkInterval
    self.timeOfLastUmbra = Shared.GetTime()
    
    return true
    
end

function Crag:TargetBabblers(position)

    self:TriggerEffects("crag_trigger_babblers")
    return true
    
end

function Crag:PerformActivation(techId, position, commander)

    local success = false
    
    if techId == kTechId.CragUmbra then
        success = self:TriggerUmbra(commander)
    elseif techId == kTechId.CragBabblers then
        success = self:TargetBabblers(position)
    end
    
    return success
    
end

Shared.LinkClassToMap("Crag", Crag.kMapName, {})

class 'MatureCrag' (Crag)

MatureCrag.kMapName = "maturecrag"

Shared.LinkClassToMap("MatureCrag", MatureCrag.kMapName, {})
