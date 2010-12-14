// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Hotkeys.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handle commander hotkeys. This will change to a cleaner solution later.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Commander:HandleCommanderHotkeys(input)

    if Client then
    
        if input.hotkey ~= 0 and self.hotkeyAllowed then
        
            // Translate hotkey into player button
            for index, techId in ipairs(self.menuTechButtons) do
        
                if self.menuTechButtonsAllowed[index] then
                
                    local hotkey = LookupTechData(techId, kTechDataHotkey)
                    
                    if hotkey ~= nil and input.hotkey == hotkey then
                    
                        self:SetHotkeyHit(index)
                        self.hotkeyAllowed = false
                        
                        break
                        
                    end
                    
                end
                
            end
            
        else
            self.hotkeyAllowed = true
        end
    
    end
    
end

gHotkeyDescriptions = { 
    [Move.A] = "A",
    [Move.B] = "B",
    [Move.C] = "C",
    [Move.D] = "D",
    [Move.E] = "E",
    [Move.F] = "F",
    [Move.G] = "G",
    [Move.H] = "H",
    [Move.I] = "I",
    [Move.J] = "J",
    [Move.K] = "K",
    [Move.L] = "L",
    [Move.M] = "M",
    [Move.N] = "N",
    [Move.O] = "O",
    [Move.P] = "P",
    [Move.Q] = "Q",
    [Move.R] = "R",
    [Move.S] = "S",
    [Move.T] = "T",
    [Move.U] = "U",
    [Move.V] = "V",
    [Move.W] = "W",
    [Move.X] = "X",
    [Move.Y] = "Y",
    [Move.Z] = "Z",         
}
