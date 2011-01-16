// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIGrenadeDisplay.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// Displays the current number of grenades for the grenade launcher
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIGrenadeDisplay'

function GUIGrenadeDisplay:Initialize()

    /*
    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize( Vector(256, 512, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/RifleDisplay.dds")
    */
    
    self.numGrenades = 0

    // Create the grenade indicators.
        
    self.maxGrenades = 6
    self.grenade = { }
   
    for i =1,self.maxGrenades do
        self.grenade[i] = GUI.CreateGraphicsItem()
        self.grenade[i]:SetTexture("ui/RifleDisplay.dds")
        self.grenade[i]:SetSize( Vector(58, 20, 0) )
        self.grenade[i]:SetPosition( Vector( 6, 267 + 24 * (i - 1), 0 ) )
        self.grenade[i]:SetTexturePixelCoordinates( 77, 266, 135, 286 )
    end
 
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIGrenadeDisplay:Update(deltaTime)
    
        for i=1,self.maxGrenades do
        // We subtract one from the aux weapon clip, because one grenade is
        // in the chamber.
        self.grenade[i]:SetIsVisible( self.numGrenades - 1 >= self.maxGrenades - i + 1 )
    end

end

function GUIGrenadeDisplay:SetNumGrenades(numGrenades)
    self.numGrenades = numGrenades
end