// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages animation and other state of GUIItems in the GUISystem.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")

class 'GUIManager'

function GUIManager:Initialize()

    self.scripts = { }
    self.scriptsSingle = { }

end

function GUIManager:GetNumberScripts()

    return table.count(self.scripts) + table.count(self.scriptsSingle)

end

// Do not call from public interface.
function GUIManager:_SharedCreate(scriptName)

    Script.Load("lua/" .. scriptName .. ".lua")
    
    local creationFunction = _G[scriptName]
    if creationFunction == nil then
        Shared.Message("Error: Failed to load GUI script named " .. scriptName)
        return nil
    else
        local newScript = creationFunction()
        newScript._scriptName = scriptName
        newScript:Initialize()
        return newScript
    end
    
end

function GUIManager:CreateGUIScript(scriptName)

    local createdScript = self:_SharedCreate(scriptName)
    if createdScript ~= nil then
        table.insert(self.scripts, createdScript)
    end

end

// Only ever create one of this named script.
// Just return the already created one if it already exists.
function GUIManager:CreateGUIScriptSingle(scriptName)
    
    // Check if it already exists
    for index, script in ipairs(self.scriptsSingle) do
        if script[2] == scriptName then
            return script[1]
        end
    end
    
    // Not found, create the single instance.
    local createdScript = self:_SharedCreate(scriptName)
    if createdScript ~= nil then
        table.insert(self.scriptsSingle, { createdScript, scriptName })
        return createdScript
    end
    return nil
    
end

function GUIManager:DestroyGUIScript(scriptInstance)

    // Only uninitialize it if the manager has a reference to it.
    if table.removevalue(self.scripts, scriptInstance) then
        scriptInstance:Uninitialize()
    end

end

// Destroy a previously created single named script.
// Nothing will happen if it hasn't been created yet.
function GUIManager:DestroyGUIScriptSingle(scriptName)

    for index, script in ipairs(self.scriptsSingle) do
        if script[2] == scriptName then
            if table.removevalue(self.scriptsSingle, script) then
                script[1]:Uninitialize()
                break
            end
        end
    end
    
end

function GUIManager:Update(deltaTime)

    for index, script in ipairs(self.scripts) do
        script:Update(deltaTime)
    end
    for index, script in ipairs(self.scriptsSingle) do
        script[1]:Update(deltaTime)
    end
    
end

function GUIManager:SendKeyEvent(key, down)

    for index, script in ipairs(self.scripts) do
        if script:SendKeyEvent(key, down) then
            return true
        end
    end
    for index, script in ipairs(self.scriptsSingle) do
        if script[1]:SendKeyEvent(key, down) then
            return true
        end
    end
    return false
    
end

function GUIManager:SendCharacterEvent(character)

    for index, script in ipairs(self.scripts) do
        if script:SendCharacterEvent(character) then
            return true
        end
    end
    for index, script in ipairs(self.scriptsSingle) do
        if script[1]:SendCharacterEvent(character) then
            return true
        end
    end
    return false
    
end