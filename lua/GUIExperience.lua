//
// lua\GUIScoreboard.lua
//
// Created by: Alex Hayton (alex.hayton@gmail.com)
//
// Manages the experience bar
//

class 'GUIExperience' (GUIScript)

function GUIExperience:Initialize()
    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize(Vector(GUIMarineHUD.kBackgroundWidth, GUIMarineHUD.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.background:SetPosition(Vector(0, -GUIMarineHUD.kBackgroundHeight, 0) + GUIMarineHUD.kBackgroundOffset)
    self.background:SetTexture(GUIMarineHUD.kTextureName)
    self.background:SetTexturePixelCoordinates(GUIMarineHUD.kBackgroundTextureX1, GUIMarineHUD.kBackgroundTextureY1, GUIMarineHUD.kBackgroundTextureX2, GUIMarineHUD.kBackgroundTextureY2)
    self.background:SetColor(GUIMarineHUD.kExperienceBarColor)
end

function GUIExperience:CreateExperienceBar()

end

function GUIExperience:Update(deltatime)

end