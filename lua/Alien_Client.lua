// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Texture should have 98x98 alien ability icons in it. The weapon chooses which x/y offset
// into it to use (eg offset of <1, 0> => 98, 0)
Alien.kHUDAbilitiesTexture = "ui/alien_abilities.dds"
Alien.kHUDFlash = "ui/alien_hud.swf"

// For choosing lifeform and upgrades
Alien.kBuyHUDFlash = "ui/alien_buy.swf"
Alien.kBuyHUDTexture = "ui/alien_buildmenu.dds"

Alien.kOpenSound = PrecacheAsset("sound/ns2.fev/alien/common/select")

// Returns all the info about all hive sight blips so it can be rendered by the UI.
// Returns single-dimensional array of fields in the format screenX, screenY, drawRadius, blipType
function PlayerUI_GetBlipInfo()

    local blips = {}
    local blipsIndex = 1

    local player = Client.GetLocalPlayer()
    
    if player then
    
        local eyePos = player:GetEyePos()
        for index, blip in ientitylist(Shared.GetEntitiesWithClassname("Blip")) do
        
            local blipType = blip.blipType
            local blipOrigin = blip:GetOrigin()
            local blipEntId = blip.entId
            
            // Lookup more recent position of blip
            local blipEntity = Shared.GetEntity(blipEntId)
            if blipEntity then
                blipOrigin = blipEntity:GetModelOrigin()
            end
            
            // Get direction to blip. If off-screen, don't render. Bad values are generated if 
            // Client.WorldToScreen is called on a point behind the camera.
            local normToEntityVec = GetNormalizedVector(blipOrigin - eyePos)
            local normViewVec = player:GetViewAngles():GetCoords().zAxis
           
            local dotProduct = normToEntityVec:DotProduct(normViewVec)
            if(dotProduct > 0) then
            
                // Get distance to blip and determine radius
                local distance = (eyePos - blipOrigin):GetLength()
                local drawRadius = 35/distance
                
                // Compute screen xy to draw blip
                local screenPos = Client.WorldToScreen(blipOrigin)

                local trace = Shared.TraceRay(eyePos, blipOrigin, PhysicsMask.Bullets, EntityFilterTwo(player, entity))                               
                local obstructed = ((trace.fraction ~= 1) and ((trace.entity == nil) or trace.entity:isa("Door"))) 
                
                // Add to array
                table.insert(blips, screenPos.x)
                table.insert(blips, screenPos.y)
                table.insert(blips, drawRadius)
                table.insert(blips, blipType)
                table.insert(blips, obstructed)

            end
            
        end
        
    end
    
    return blips

end       

/* Texture used for icons. Pics are masked, so don't worry about boundaries of the images being over the energy circle. */
function PlayerUI_AlienAbilityIconsImage()
    return "alien_abilities"
end

// array of totalPower, minPower, xoff, yoff, visibility (boolean), hud slot
function GetActiveAbilityData(secondary)

    local data = {}
    
    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local ability = player:GetActiveWeapon()
        
        if ability ~= nil and ability:isa("Ability") then
        
            if ( (not secondary) or ( secondary and ability:GetHasSecondary())) then
            
                data = ability:GetInterfaceData(secondary, false)
                
            end
            
        end
        
    end
    
    return data
    
end

/**
 * For current ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function PlayerUI_GetAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        table.addtable(GetActiveAbilityData(false), data)

    end
    
    return data
    
end

/**
 * Return boolean value indicating if there's a special ability
 */
function PlayerUI_HasSpecialAbility()
    local player = Client.GetLocalPlayer()
    return player:isa("Alien") and player:GetHasSpecialAbility()
end

/**
 * For special ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function PlayerUI_GetSpecialAbilityData()

    local player = Client.GetLocalPlayer()
    if player:isa("Alien") and player:GetHasSpecialAbility() then
    
        return player:GetSpecialAbilityInterfaceData()
        
    end

    return {}
    
end

/**
 * For secondary ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean)
 */
function PlayerUI_GetSecondaryAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        
        table.addtable(GetActiveAbilityData(true), data)
        
    end
    
    return data
    
end

/**
 * Return boolean value indicating if inactive powers should be visible
 */
function PlayerUI_GetInactiveVisible()
    local player = Client.GetLocalPlayer()
    return player:isa("Alien") and player:GetInactiveVisible()
end

// Loop through child weapons that aren't active and add all their data into one array
function PlayerUI_GetInactiveAbilities()

    local data = {}
    
    local player = Client.GetLocalPlayer()

    if player and player:isa("Alien") then    
    
        local inactiveAbilities = player:GetHUDOrderedWeaponList()
        
        // Don't show selector if we only have one ability
        if table.count(inactiveAbilities) > 1 then
        
            for index, ability in ipairs(inactiveAbilities) do
            
                if ability:isa("Ability") then
                    local abilityData = ability:GetInterfaceData(false, true)
                    if table.count(abilityData) > 0 then
                        table.addtable(abilityData, data)
                    end
                end
                    
            end
            
        end
        
    end
    
    return data
    
end

function PlayerUI_GetPlayerEnergy()
    local player = Client.GetLocalPlayer()
    if player and player.GetEnergy then
        return player:GetEnergy()
    end
    return 0
end

function PlayerUI_GetPlayerMaxEnergy()
    return Ability.kMaxEnergy
end


function GetAbility(abilityIndex)

    local ability = nil
    
    local player = Client.GetLocalPlayer()
    if(player and player:isa("Alien")) then
    
        local abilities = player:GetHUDOrderedWeaponList()
        local numAbilities = table.maxn(abilities)   
        
        if(abilityIndex >= 1 and abilityIndex <= numAbilities) then
        
            ability = abilities[abilityIndex]
            
        else
        
            Shared.Message("GetAbility(" .. abilityIndex .. ") outside range 1 - " .. numAbilities)
            
        end
         
    end
    
    return ability
    
end

function Alien:OnInitLocalClient()
    
    Player.OnInitLocalClient(self)
    
    if(self:GetTeamNumber() ~= kTeamReadyRoom) then
        
        RemoveFlashPlayer(kClassFlashIndex)
        
        //GetFlashPlayer(kClassFlashIndex):Load(Alien.kHUDFlash)
        //GetFlashPlayer(kClassFlashIndex):SetBackgroundOpacity(0)
        //Client.BindFlashTexture("alien_abilities", Alien.kHUDAbilitiesTexture)
        //Client.BindFlashTexture("alien_upgradeicons", Alien.kUpgradeIconsTexture)
        
        if self.alienHUD == nil then
            self.alienHUD = GetGUIManager():CreateGUIScript("GUIAlienHUD")
        end
        if self.hiveBlips == nil then
            self.hiveBlips = GetGUIManager():CreateGUIScript("GUIHiveBlips")
        end
    end
    
end

function Alien:OnDestroyClient()
    
    if self.alienHUD then
        GetGUIManager():DestroyGUIScript(self.alienHUD)
        self.alienHUD = nil
    end
    if self.hiveBlips then
        GetGUIManager():DestroyGUIScript(self.hiveBlips)
        self.hiveBlips = nil
    end
end

function Alien:UpdateClientEffects(deltaTime, isLocal)
    
    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    // If we are dead, close the evolve menu.
    if isLocal and GetFlashPlayerDisplaying(kClassFlashIndex) then
    
        if not self:GetIsAlive() then
            self:CloseMenu(kClassFlashIndex)
        end
        
    end
    
    if isLocal then
        
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        
        if not self.darkVisionOn then
            darkVisionFadeAmount = math.max( 1 - (Client.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0 ) 
        end
        
        self.screenEffects.darkVision:SetActive(self.darkVisionOn or darkVisionFadeAmount > 0)   
        
        self.screenEffects.darkVision:SetParameter("startTime", self.darkVisionTime)
        self.screenEffects.darkVision:SetParameter("time", Client.GetTime())
        self.screenEffects.darkVision:SetParameter("amount", darkVisionFadeAmount)
        
    end
    
end

function Alien:CloseMenu(flashIndex)

    if self.showingBuyMenu and Player.CloseMenu(self, flashIndex) then
    
        self.showingBuyMenu = false
        return true
        
    end
    
    return false
    
end

// Bring up evolve menu
function Alien:Buy()
    
    // Don't allow display in the ready room
    if self:GetTeamNumber() ~= 0 and (Client.GetLocalPlayer() == self) then
    
        if not self.showingBuyMenu then
        
            // Can only bring up on infestation
            //if self:GetGameEffectMask(kGameEffect.OnInfestation) then
        
                GetFlashPlayer(kClassFlashIndex):Load(Alien.kBuyHUDFlash)
                GetFlashPlayer(kClassFlashIndex):SetBackgroundOpacity(0)
                self.showingBuyMenu = true
                
                Shared.PlaySound(self, Alien.kOpenSound)
            
            //else
            //    self:AddTooltipOncePer("You must be on infestation to evolve.", 3)
            //end            
            
        else
        
            RemoveFlashPlayer(kClassFlashIndex)
            self.showingBuyMenu = false
            
        end    
        
        Client.SetMouseVisible(self.showingBuyMenu)
        Client.SetMouseCaptured(not self.showingBuyMenu)
        Client.SetMouseClipped(not self.showingBuyMenu)
        
    end
    
end
