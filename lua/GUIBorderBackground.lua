
// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIBorderBackground.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a background that can scale to any size while maintaining the same border size.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIBorderBackground' (GUIScript)

function GUIBorderBackground:Initialize(settingsTable)

    self.width = settingsTable.Width
    self.height = settingsTable.Height
    
    self.background = GUI.CreateGraphicsItem()
    self.background:SetSize(Vector(self.width, self.height, 0))
    self.background:SetPosition(Vector(settingsTable.X, settingsTable.Y, 0))
    // The background is an invisible container only.
    self.background:SetColor(Color(0, 0, 0, 0))
    
    self.partTextureWidth = settingsTable.TexturePartWidth
    self.partTextureHeight = settingsTable.TexturePartHeight
    
    local textureName = settingsTable.TextureName
    
    // Corner parts.
    self.topLeftBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.topLeftBackground:SetTexture(textureName)
    else
        self.topLeftBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.topLeftBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[1].X1, settingsTable.TextureCoordinates[1].Y1, settingsTable.TextureCoordinates[1].X2, settingsTable.TextureCoordinates[1].Y2)
    self.background:AddChild(self.topLeftBackground)
    
    self.topRightBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.topRightBackground:SetTexture(textureName)
    else
        self.topRightBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.topRightBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[3].X1, settingsTable.TextureCoordinates[3].Y1, settingsTable.TextureCoordinates[3].X2, settingsTable.TextureCoordinates[3].Y2)
    self.background:AddChild(self.topRightBackground)
    
    self.bottomLeftBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomLeftBackground:SetTexture(textureName)
    else
        self.bottomLeftBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.bottomLeftBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[7].X1, settingsTable.TextureCoordinates[7].Y1, settingsTable.TextureCoordinates[7].X2, settingsTable.TextureCoordinates[7].Y2)
    self.background:AddChild(self.bottomLeftBackground)
    
    self.bottomRightBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomRightBackground:SetTexture(textureName)
    else
        self.bottomRightBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.bottomRightBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[9].X1, settingsTable.TextureCoordinates[9].Y1, settingsTable.TextureCoordinates[9].X2, settingsTable.TextureCoordinates[9].Y2)
    self.background:AddChild(self.bottomRightBackground)
    
    // Scaled middle parts.
    self.topMiddleBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.topMiddleBackground:SetTexture(textureName)
    else
        self.topMiddleBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.topMiddleBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[2].X1, settingsTable.TextureCoordinates[2].Y1, settingsTable.TextureCoordinates[2].X2, settingsTable.TextureCoordinates[2].Y2)
    self.background:AddChild(self.topMiddleBackground)
    
    self.bottomMiddleBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomMiddleBackground:SetTexture(textureName)
    else
        self.bottomMiddleBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.bottomMiddleBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[8].X1, settingsTable.TextureCoordinates[8].Y1, settingsTable.TextureCoordinates[8].X2, settingsTable.TextureCoordinates[8].Y2)
    self.background:AddChild(self.bottomMiddleBackground)
    
    self.leftCenterBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.leftCenterBackground:SetTexture(textureName)
    else
        self.leftCenterBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.leftCenterBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[4].X1, settingsTable.TextureCoordinates[4].Y1, settingsTable.TextureCoordinates[4].X2, settingsTable.TextureCoordinates[4].Y2)
    self.background:AddChild(self.leftCenterBackground)
    
    self.rightCenterBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.rightCenterBackground:SetTexture(textureName)
    else
        self.rightCenterBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.rightCenterBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[6].X1, settingsTable.TextureCoordinates[6].Y1, settingsTable.TextureCoordinates[6].X2, settingsTable.TextureCoordinates[6].Y2)
    self.background:AddChild(self.rightCenterBackground)
    
    // Middle part.
    self.middleBackground = GUI.CreateGraphicsItem()
    if textureName and string.len(textureName) > 0 then
        self.middleBackground:SetTexture(textureName)
    else
        self.middleBackground:SetColor(Color(0, 0, 0, 0))
    end
    self.middleBackground:SetTexturePixelCoordinates(settingsTable.TextureCoordinates[5].X1, settingsTable.TextureCoordinates[5].Y1, settingsTable.TextureCoordinates[5].X2, settingsTable.TextureCoordinates[5].Y2)
    self.background:AddChild(self.middleBackground)
    
    // Now that they are all created, set their initial sizes.
    self:SetSize(Vector(self.width, self.height, 0))
    
end

function GUIBorderBackground:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIBorderBackground:SetSize(sizeVector)

    self.width = sizeVector.x
    self.height = sizeVector.y
    
    self.background:SetSize(Vector(self.width, self.height, 0))
    
    // Corner parts.
    self.topLeftBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.topLeftBackground:SetPosition(Vector(0, 0, 0))
    
    self.topRightBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.topRightBackground:SetPosition(Vector(self.width - self.partTextureWidth, 0, 0))
    
    self.bottomLeftBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.bottomLeftBackground:SetPosition(Vector(0, self.height - self.partTextureHeight, 0))
    
    self.bottomRightBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.bottomRightBackground:SetPosition(Vector(self.width - self.partTextureWidth, self.height - self.partTextureHeight, 0))
    
    // Scaled middle parts.
    local topMiddleWidth = self.width - self.partTextureWidth * 2
    // Only bother with this part if it is needed.
    self.topMiddleBackground:SetIsVisible(false)
    if topMiddleWidth > 0 then
        self.topMiddleBackground:SetIsVisible(true)
        self.topMiddleBackground:SetSize(Vector(topMiddleWidth, self.partTextureHeight, 0))
        self.topMiddleBackground:SetPosition(Vector(self.partTextureWidth, 0, 0))
    end
    
    local bottomMiddleWidth = self.width - self.partTextureWidth * 2
    self.bottomMiddleBackground:SetIsVisible(false)
    if bottomMiddleWidth > 0 then
        self.bottomMiddleBackground:SetIsVisible(true)
        self.bottomMiddleBackground:SetSize(Vector(bottomMiddleWidth, self.partTextureHeight, 0))
        self.bottomMiddleBackground:SetPosition(Vector(self.partTextureWidth, self.height - self.partTextureHeight, 0))
    end
    
    local leftCenterHeight = self.height - self.partTextureHeight * 2
    self.leftCenterBackground:SetIsVisible(false)
    if leftCenterHeight > 0 then
        self.leftCenterBackground:SetIsVisible(true)
        self.leftCenterBackground:SetSize(Vector(self.partTextureWidth, leftCenterHeight, 0))
        self.leftCenterBackground:SetPosition(Vector(0, self.partTextureHeight, 0))
    end
    
    local rightCenterHeight = self.height - self.partTextureHeight * 2
    self.rightCenterBackground:SetIsVisible(false)
    if rightCenterHeight > 0 then
        self.rightCenterBackground:SetIsVisible(true)
        self.rightCenterBackground:SetSize(Vector(self.partTextureWidth, rightCenterHeight, 0))
        self.rightCenterBackground:SetPosition(Vector(self.width - self.partTextureWidth, self.partTextureHeight, 0))
    end
    
    // Middle part.
    local middleWidth = self.width - self.partTextureWidth * 2
    local middleHeight = self.height - self.partTextureHeight * 2
    self.middleBackground:SetIsVisible(false)
    if middleWidth > 0 and middleHeight > 0 then
        self.middleBackground:SetIsVisible(true)
        self.middleBackground:SetSize(Vector(middleWidth, middleHeight, 0))
        self.middleBackground:SetPosition(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    end

end

function GUIBorderBackground:SetPosition(setPosition)

    self.background:SetPosition(setPosition)

end

function GUIBorderBackground:SetAnchor(horzAnchor, vertAnchor)

    self.background:SetAnchor(horzAnchor, vertAnchor)

end

function GUIBorderBackground:SetIsVisible(setIsVisible)

    self.background:SetIsVisible(setIsVisible)

end

function GUIBorderBackground:AddChild(childItem)

    self.background:AddChild(childItem)

end

function GUIBorderBackground:GetBackground()

    return self.background

end