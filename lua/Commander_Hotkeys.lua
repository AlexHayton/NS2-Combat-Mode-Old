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

    if Client and not Client.GetIsRunningPrediction() then
    
        if input.hotkey ~= 0 then
        
            // Translate hotkey into player button
            for index, techId in ipairs(self.menuTechButtons) do
        
                if self.menuTechButtonsAllowed[index] then
                
                    local hotkey = LookupTechData(techId, kTechDataHotkey)
                    
                    // Check if the last hotkey was released.
                    if hotkey ~= nil and self.lastHotkeyIndex ~= index then
                    
                        self.lastHotkeyIndex = nil
                        
                    end
                    
                    // Check if a new hotkey was pressed. Don't allow the last
                    // key pressed unless it has been released first.
                    if hotkey ~= nil and input.hotkey == hotkey and self.lastHotkeyIndex ~= index then
                        
                        Shared.Message("doing SetHotkeyHit now")
                        
                        self:SetHotkeyHit(index)
                        self.lastHotkeyIndex = index
                        
                        break
                        
                    end
                    
                end
                
            end
        
        else
        
            self.lastHotkeyIndex = nil
            
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
