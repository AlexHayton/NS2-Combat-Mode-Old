// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Embryo.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Aliens change into this while evolving into a new lifeform. Looks like an egg.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Embryo' (Alien)

Embryo.kMapName = "embryo"
Embryo.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Embryo.kBaseHealth = 50
Embryo.kThinkTime = .1
Embryo.kXExtents = .25
Embryo.kYExtents = .25
Embryo.kZExtents = .25

local networkVars = 
{
    evolvePercentage = "float"
}

function Embryo:OnInit()

    Alien.OnInit(self)
    
    self:SetModel(Embryo.kModelName)
    
    self:TriggerEffects("player_start_gestate")
    
    self.lastThinkTime = Shared.GetTime()
    
    self:SetNextThink(Embryo.kThinkTime)
    
    self:SetViewOffsetHeight(.2)
    
    self:SetDesiredCameraDistance(2)
    
    self.originalAngles = Angles(self:GetAngles())
    
    self.evolvePercentage = 0
    
end

function Embryo:OnInitLocalClient()

    Alien.OnInitLocalClient(self)
    
    // Disabled for now
    //self.embryoHUD = GetGUIManager():CreateGUIScript("GUIEmbryoHUD")
    
end

function Embryo:OnDestroyClient()

    Alien.OnDestroyClient(self)
    
    if self.embryoHUD then
        GetGUIManager():DestroyGUIScript(self.embryoHUD)
        self.embryoHUD = nil
    end
    
end

function Embryo:GetMaxViewOffsetHeight()
    return .2
end

function Embryo:SetGestationTechId(techId)

    self.gestationClass = LookupTechData(techId, kTechDataGestateName)
    self.gestationStartTime = Shared.GetTime()
    
    self.gestationTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, LookupTechData(techId, kTechDataGestateTime))
    self.evolveTime = 0
    
    self:SetHealth(Embryo.kBaseHealth)
    self.maxHealth = LookupTechData(techId, kTechDataMaxHealth)   
    
end

function Embryo:GetEvolutionTime()
    return self.evolveTime
end

// Allow players to rotate view, chat, scoreboard, etc. but not move
function Embryo:OverrideInput(input)

    // Completely override movement and commands
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0

    // Only allow some actions like going to menu, chatting and Scoreboard (not jump, use, etc.)
    input.commands = bit.band(input.commands, Move.Exit) + bit.band(input.commands, Move.TeamChat) + bit.band(input.commands, Move.TextChat) + bit.band(input.commands, Move.Scoreboard)

end

function Embryo:ConstrainMoveVelocity(moveVelocity)

    // Embryos can't move    
    moveVelocity.x = 0
    moveVelocity.y = 0
    moveVelocity.z = 0
    
end

function Embryo:PostUpdateMovePhysics(input, runningPrediction)
    self:SetAngles(self.originalAngles)
end

if Server then

    function Embryo:OnThink()

        Alien.OnThink(self)
        
        // Take into account metabolize effects
        local amount = GetAlienEvolveResearchTime(Embryo.kThinkTime, self)
        self.evolveTime = self.evolveTime + amount

        self.evolvePercentage = Clamp((self.evolveTime / self.gestationTime) * 100, 0, 100)
        
        if self.evolveTime >= self.gestationTime then
        
            // Replace player with new player
            self:Replace(self.gestationClass)
            
            self:TriggerEffects("player_end_gestate")
            
            self:TriggerEffects("egg_death")
            

        end
        
        self.lastThinkTime = Shared.GetTime()
        
        self:SetNextThink(Embryo.kThinkTime)
        
    end
    
end

function Embryo:GetCanDoDamage()
    return false
end

Shared.LinkClassToMap("Embryo", Embryo.kMapName, networkVars)