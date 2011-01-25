// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMapAnnotations.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages text that is drawn in the world to annotate maps.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIMapAnnotations' (GUIScript)

GUIMapAnnotations.kMaxDisplayDistance = 30

GUIMapAnnotations.kNumberOfDataFields = 6

function GUIMapAnnotations:Initialize()

    self.visible = false
    self.annotations = { }

end

function GUIMapAnnotations:Uninitialize()

    self:ClearAnnotations()
    
end

function GUIMapAnnotations:ClearAnnotations()

    for i, annotation in ipairs(self.annotations) do
        GUI.DestroyItem(annotation.Item)
    end
    self.annotations = { }

end

function GUIMapAnnotations:SetIsVisible(setVisible)

    self.visible = setVisible
    
end

function GUIMapAnnotations:AddAnnotation(text, worldOrigin)
    
    local annotationItem = { Item = GUI.CreateTextItem(), Origin = Vector(worldOrigin) }
    annotationItem.Item:SetLayer(kGUILayerDebugText)
    annotationItem.Item:SetFontSize(20)
    annotationItem.Item:SetAnchor(GUIItem.Left, GUIItem.Top)
    annotationItem.Item:SetTextAlignmentX(GUITextItem.Align_Center)
    annotationItem.Item:SetTextAlignmentY(GUITextItem.Align_Center)
    annotationItem.Item:SetColor(Color(1, 1, 1, 1))
    annotationItem.Item:SetText(text)
    annotationItem.Item:SetIsVisible(false)
    table.insert(self.annotations, annotationItem)
    
end

function GUIMapAnnotations:Update(deltaTime)

    for i, annotation in ipairs(self.annotations) do
        if not self.visible then
            annotation.Item:SetIsVisible(false)
        else
            // Set position according to position/orientation of local player.
            local screenPos = Client.WorldToScreen(Vector(annotation.Origin.x, annotation.Origin.y, annotation.Origin.z))
            
            local playerOrigin = PlayerUI_GetEyePos()
            local direction = annotation.Origin - playerOrigin
            local normToAnnotationVec = GetNormalizedVector(direction)
            local normViewVec = PlayerUI_GetForwardNormal()
            local dotProduct = normToAnnotationVec:DotProduct(normViewVec)
            
            local visible = true
            
            if (screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
                screenPos.y < 0 or screenPos.y > Client.GetScreenHeight()) or
                dotProduct < 0 then
                visible = false
            else
                annotation.Item:SetPosition(screenPos)
            end
            
            // Fade based on distance.
            
            local fadeAmount = (direction:GetLengthSquared()) / (GUIMapAnnotations.kMaxDisplayDistance * GUIMapAnnotations.kMaxDisplayDistance)
            if fadeAmount < 1 then
                annotation.Item:SetColor(Color(1, 1, 1, 1 - fadeAmount))
            else
                visible = false
            end
            
            annotation.Item:SetIsVisible(visible)
        end
    end
    
end

function OnCommandAnnotate(...)

    local info = nil
    local args = {...}
    local currentArg = 1
    for i, v in ipairs(args) do
        if currentArg == 1 then
            info = v
        else
            info = info .. " " .. v
        end
        currentArg = currentArg + 1
    end
    
    if info == nil then
        Print("Please provide in some text to annotate")
        return
    end
    
    local origin = PlayerUI_GetEyePos()

    // Remove undesirable characters.
    info = info:gsub(",", "")
    info = info:gsub("?", "")
    local urlString = "http://unknownworldsstats.appspot.com/statlocation?version=" .. ToString(Shared.GetBuildNumber()) .. "&name=user&info=" .. info ..
                      "&value=0&map=" .. Shared.GetMapName() .. "&mapx=" .. string.format("%.2f", origin.x) .. "&mapy=" .. string.format("%.2f", origin.y)..
                      "&mapz=" .. string.format("%.2f", origin.z)
    Shared.GetWebpage(urlString, function (data) end)

end

function OnCommandDisplayAnnotations(display)

    if display == "true" then
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):ClearAnnotations()
        local urlString = "http://unknownworldsstats.appspot.com/statlocationdata?version=" .. ToString(Shared.GetBuildNumber()) .. "&map=" .. Shared.GetMapName()
        Shared.GetWebpage(urlString, ParseAnnotations)
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):SetIsVisible(true)
    else
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):SetIsVisible(false)
    end

end

function ParseAnnotations(data)

    local fields = { }
    data:gsub("([^,]+)", function(c) table.insert(fields, c) end)
    local numberOfAnnotations = table.count(fields) / GUIMapAnnotations.kNumberOfDataFields
    local currentAnnotation = 0
    while currentAnnotation < numberOfAnnotations do
    
        local type = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 1]
        type = ConditionalValue(type == nil, "user", type)
        
        local infoText = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 2]
        infoText = ConditionalValue(infoText == nil, "nil info", infoText)
        
        local value = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 3]
        value = ConditionalValue(value == nil, 0, value)
        
        local mapX = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 4]
        mapX = ConditionalValue(mapX == nil, 0, mapX)
        
        local mapY = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 5]
        mapY = ConditionalValue(mapY == nil, 0, mapY)
        
        local mapZ = fields[currentAnnotation * GUIMapAnnotations.kNumberOfDataFields + 6]
        mapZ = ConditionalValue(mapZ == nil, 0, mapZ)
        
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):AddAnnotation(infoText, Vector(tonumber(mapX), tonumber(mapY), tonumber(mapZ)))
        currentAnnotation = currentAnnotation + 1
        
    end

end

Event.Hook("Console_annotate",              OnCommandAnnotate)
Event.Hook("Console_displayannotations",    OnCommandDisplayAnnotations)