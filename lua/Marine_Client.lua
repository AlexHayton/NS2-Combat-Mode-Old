// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Marine.k2DHUDFlash = "ui/marine_hud_2d.swf"
Marine.kBuyMenuTexture = "ui/marine_buymenu.dds"
Marine.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Marine.kBuyMenuiconsTexture = "ui/marine_buy_icons.dds"

function Marine:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    if(self:GetTeamNumber() ~= kTeamReadyRoom) then
    
        // Add marine-specific HUD
        //GetFlashPlayer(kClassFlashIndex):Load(Marine.k2DHUDFlash)
        //GetFlashPlayer(kClassFlashIndex):SetBackgroundOpacity(0)
       
        // For armory menu
        Client.BindFlashTexture("marine_buymenu", Marine.kBuyMenuTexture)
        Client.BindFlashTexture("marine_buymenu_upgrades", Marine.kBuyMenuUpgradesTexture)
        Client.BindFlashTexture("marine_buy_icons", Marine.kBuyMenuiconsTexture)
        
        if self.marineHUD == nil then
            self.marineHUD = GetGUIManager():CreateGUIScriptSingle("GUIMarineHUD")
        end
        if self.waypoints == nil then
            self.waypoints = GetGUIManager():CreateGUIScriptSingle("GUIWaypoints")
        end
		if self.experienceBar == nil then
			self.experienceBar = GetGUIManager():CreateGUIScriptSingle("GUIExperience")
		end
        
    end    
end

function Marine:OnDestroyClient()

    Player.OnDestroyClient(self)

    if self.marineHUD then
        self.marineHUD = nil
        GetGUIManager():DestroyGUIScriptSingle("GUIMarineHUD")
    end
    if self.waypoints then
        self.waypoints = nil
        GetGUIManager():DestroyGUIScriptSingle("GUIWaypoints")
    end
	if self.experienceBar then
        self.experienceBar = nil
        GetGUIManager():DestroyGUIScriptSingle("GUIExperience")
    end

end

function Marine:UpdateClientEffects(deltaTime, isLocal)
    
    Player.UpdateClientEffects(self, deltaTime, isLocal)

    // Synchronize the state of the light representing the flash light.
    self.flashlight:SetIsVisible( self.flashlightOn )

    if (self.flashlightOn) then
    
        local coords = Coords(self:GetViewCoords())
        coords.origin = coords.origin + coords.zAxis * 0.75
        
        self.flashlight:SetCoords( coords )
        
    end
    
    // If we're too far from an armory, close the menu
    if Client.GetMouseVisible() and isLocal and GetFlashPlayerDisplaying(kClassFlashIndex) then
    
        if not GetArmory(self) then
            self:CloseMenu(kClassFlashIndex)
        end
        
    end
    
end

function Marine:CloseMenu(flashIndex)

    if Client.GetLocalPlayer() == self and Client.GetMouseVisible() then
        
        RemoveFlashPlayer(flashIndex)
        
        Shared.StopSound(self, Armory.kResupplySound)

        Client.SetMouseVisible(false)
        Client.SetMouseClipped(false)
        Client.SetMouseCaptured(true)
        
        // Quick work-around to not fire weapon when closing menu
        self.timeClosedMenu = Shared.GetTime()
        
        return true
            
    end
   
    return false
    
end
