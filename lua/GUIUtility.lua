//======= Copyright © 2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIUtility.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
  
// Returns true if the passed in point is contained within the passed in GUIItem.
// Also returns the point inside the passed in GUIItem where that point is located.
// Returns false if the point is not contained in the passed in GUIItem.
function GUIItemContainsPoint(guiItem, pointX, pointY)

    ASSERT(guiItem ~= nil)
    ASSERT(pointX ~= nil)
    ASSERT(pointY ~= nil)
    
    local itemScreenPosition = guiItem:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
    local itemSize = guiItem:GetSize()
    local xWithin = pointX >= itemScreenPosition.x and pointX <= itemScreenPosition.x + itemSize.x
    local yWithin = pointY >= itemScreenPosition.y and pointY <= itemScreenPosition.y + itemSize.y
    if xWithin and yWithin then
        local xPositionWithin = pointX - itemScreenPosition.x
        local yPositionWithin = pointY - itemScreenPosition.y
        return true, xPositionWithin, yPositionWithin
    end
    return false, 0, 0

end

function GUISetColor(item, color)
    item:SetColor(color)   
end

// Pass in a GUIItem and a table with named X1, Y1, X2, Y2 elements.
// These are pixel coordinates.
function GUISetTextureCoordinatesTable(item, coordinateTable)

    item:SetTexturePixelCoordinates(coordinateTable.X1, coordinateTable.Y1,
                                    coordinateTable.X2, coordinateTable.Y2)
end