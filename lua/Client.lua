// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set the name of the VM for debugging
decoda_name = "Client"

Script.Load("lua/Shared.lua")
Script.Load("lua/Button.lua")
Script.Load("lua/Chat.lua")
Script.Load("lua/DeathMessage_Client.lua")
Script.Load("lua/Notifications.lua")
Script.Load("lua/Scoreboard.lua")
Script.Load("lua/ScoreDisplay.lua")
Script.Load("lua/AlienBuy_Client.lua")
Script.Load("lua/MarineBuy_Client.lua")
Script.Load("lua/Tracer_Client.lua")
Script.Load("lua/GUIManager.lua")
Script.Load("lua/GUIDebugText.lua")

Script.Load("lua/ConsoleCommands_Client.lua")
Script.Load("lua/NetworkMessages_Client.lua")
Script.Load("lua/Main.lua")

Client.propList = {}
Client.lightList = {}
Client.skyBoxList = {}
Client.ambientSoundList = {}
Client.particlesList = {}
Client.tracersList = {}

local gGUIManager = GUIManager()
gGUIManager:Initialize()

// Displays the "F1 for feedback" text.
gGUIManager:CreateGUIScript("GUIFeedback")

function GetGUIManager()
    return gGUIManager
end

// Client tech tree
local gTechTree = TechTree()
gTechTree:Initialize() 

function GetTechTree()
    return gTechTree
end

function ClearTechTree()
    gTechTree:Initialize()    
end

/**
 * Destroys all of the objects created during the level load by the
 * OnMapLoadEntity function.
 */
function DestroyLevelObjects()

    // Remove all of the props.
    for index, models in ipairs(Client.propList) do
        Client.DestroyRenderModel(models[1])
        Shared.DestroyCollisionObject(models[2])
    end
    Client.propList = { }

    // Remove the lights.    
    for index, light in ipairs(Client.lightList) do
        Client.DestroyRenderLight(light)
    end
    Client.lightList = { }
    
    // Remove the skyboxes.    
    for index, skybox in ipairs(Client.skyBoxList) do
        Client.DestroyCinematic(skybox)
    end
    Client.skyBoxList = { }
    
    Client.particlesList = {}
    Client.tracersList = {}
    Client.ambientSoundList = {}

end

function ExitPressed()

    if not Client.GetIsRunningPrediction() then
        // Close buy menu if open, otherwise show in-game menu
        if not Client.GetLocalPlayer():CloseMenu(kClassFlashIndex) then
            ShowInGameMenu()
        end
    end    
    
end

function ShowInGameMenu()
    
    if not Client.GetIsRunningPrediction() then
    
        Client.SetCursor("ui/Cursor_MenuDefault.dds")
        Client.SetMouseVisible(true)
        Client.SetMouseCaptured(false)
        
        MenuManager.SetMenu(kMainMenuFlash)
        
    end 
   
end

/**
 * Called as the map is being loaded to create the entities. If no group, groupName will be "".
 */
function OnMapLoadEntity(className, groupName, values)

    // Create render objects.
    if (className == "prop_static") then
    
        ParsePropStatic(groupName, values)
    
    elseif (className == "light_spot"  or
            className == "light_point" or
            className == "light_ambient") then
            
        local renderLight = Client.CreateRenderLight()
        local coords = values.angles:GetCoords( values.origin )
        
        if (className == "light_spot") then
        
            renderLight:SetType( RenderLight.Type_Spot )
            renderLight:SetOuterCone( values.outerAngle )
            renderLight:SetInnerCone( values.innerAngle )
            renderLight:SetCastsShadows( values.casts_shadows )
            
            if (values.shadow_fade_rate ~= nil) then
                renderLight:SetShadowFadeRate( values.shadow_fade_rate )
            end
        
        elseif (className == "light_point") then
        
            renderLight:SetType( RenderLight.Type_Point )
            renderLight:SetCastsShadows( values.casts_shadows )

            if (values.shadow_fade_rate ~= nil) then
                renderLight:SetShadowFadeRate( values.shadow_fade_rate )
            end
            
        elseif (className == "light_ambient") then
            
            renderLight:SetType( RenderLight.Type_AmbientVolume )
            
            renderLight:SetDirectionalColor(RenderLight.Direction_Right,    values.color_dir_right)
            renderLight:SetDirectionalColor(RenderLight.Direction_Left,     values.color_dir_left)
            renderLight:SetDirectionalColor(RenderLight.Direction_Up,       values.color_dir_up)
            renderLight:SetDirectionalColor(RenderLight.Direction_Down,     values.color_dir_down)
            renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  values.color_dir_forward)
            renderLight:SetDirectionalColor(RenderLight.Direction_Backward, values.color_dir_backward)
            
        end

        renderLight:SetCoords( coords )
        renderLight:SetRadius( values.distance )
        renderLight:SetIntensity( values.intensity )
        renderLight:SetColor( values.color )
        renderLight:SetGroup(groupName)
        
        if (values.atmospheric == true) then
            renderLight:SetAtmospheric( true )
        end
        
        // Save original values so we can alter and restore lights
        renderLight.originalIntensity = values.intensity
        renderLight.originalColor = values.color
        
        table.insert(Client.lightList, renderLight)
    
    elseif (className == "color_grading") then
    
        local renderColorGrading = Client.CreateRenderColorGrading()
        
        renderColorGrading:SetOrigin( values.origin )
        renderColorGrading:SetBalance( values.balance )
        renderColorGrading:SetBrightness( values.brightness )
        renderColorGrading:SetContrast( values.contrast )
        renderColorGrading:SetRadius( values.distance )
        renderColorGrading:SetGroup(groupName)

    elseif (className == "fog_controls") then
            
        Client.SetZoneFogDepthScale(RenderScene.Zone_ViewModel, 1.0 / values.view_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_ViewModel, values.view_zone_color)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_SkyBox, 1.0 / values.skybox_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_SkyBox, values.skybox_zone_color)

        Client.SetZoneFogDepthScale(RenderScene.Zone_Default, 1.0 / values.default_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_Default, values.default_zone_color)
        
    elseif (className == "skybox" or className == "cinematic") then
            
        local coords = values.angles:GetCoords(values.origin)
        
        local zone = RenderScene.Zone_Default
        
        if (className == "skybox") then
            zone = RenderScene.Zone_SkyBox
        end
        
        local cinematic = Client.CreateCinematic(zone)
        
        cinematic:SetCinematic( values.cinematicName )
        cinematic:SetCoords( coords )
        
        local repeatStyle = Cinematic.Repeat_None
        
        if (values.repeatStyle == 0) then
            repeatStyle = Cinematic.Repeat_None
        elseif (values.repeatStyle == 1) then
            repeatStyle = Cinematic.Repeat_Loop
        elseif (values.repeatStyle == 2) then
            repeatStyle = Cinematic.Repeat_Endless
        end
        
        if (className == "skybox") then
        
            table.insert(Client.skyBoxList, cinematic)
            
            // Becuase we're going to hold onto the skybox, make sure it
            // uses the endless repeat style so that it doesn't delete itself
            repeatStyle = Cinematic.Repeat_Endless
            
        end
        
        cinematic:SetRepeatStyle(repeatStyle)
       
    elseif className == AmbientSound.kMapName then
        
        local entity = AmbientSound()
        LoadEntityFromValues(entity, values)
        // Precache the ambient sound effects
        Shared.PrecacheSound(entity.eventName)
        table.insert(Client.ambientSoundList, entity)

    elseif className == Particles.kMapName then
        
        local entity = Particles()
        LoadEntityFromValues(entity, values)
        table.insert(Client.particlesList, entity)

    elseif className == Reverb.kMapName then
        
        local entity = Reverb()
        LoadEntityFromValues(entity, values)
        entity:OnLoad()

    end

end

function ParsePropStatic(groupName, values)
    
    local coords = values.angles:GetCoords(values.origin)

    coords.xAxis = coords.xAxis * values.scale.x
    coords.yAxis = coords.yAxis * values.scale.y
    coords.zAxis = coords.zAxis * values.scale.z

    // Create the visual representation of the prop. All static props
    // can be instanced.
    local renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)       
    renderModel:SetModel(values.model)

    if (values.castsShadows ~= nil) then
        renderModel:SetCastsShadows(values.castsShadows)
    end

    renderModel:SetCoords(coords)
    renderModel:SetIsStatic(true)
    renderModel:SetIsInstanced(true)
    renderModel:SetGroup(groupName)

    // Create the physical representation of the prop.
    local physicsModel = Shared.CreatePhysicsModel(values.model, false, coords, CoordsArray(), nil) 
    physicsModel:SetPhysicsType(CollisionObject.Static)

    // Handle commander mode properties
    renderModel.commAlpha = GetAndCheckValue(values.commAlpha, 0, 1, "commAlpha", 1, true)

    // Make it not block selection and structure placement (GetCommanderPickTarget)
    if renderModel.commAlpha < 1 or groupName == kCommanderInvisibleGroupName then
        physicsModel:SetGroup(PhysicsGroup.CommanderPropsGroup)
    end

    // Insert into list of props - {renderModel, physicsModel} pairs
    table.insert(Client.propList, {renderModel, physicsModel})

end

// TODO: Change this to setting the alpha instead of visibility when supported
function SetCommanderPropState(isComm)

    for index, propPair in ipairs(Client.propList) do
        local prop = propPair[1]
        if prop.commAlpha < 1 then
            prop:SetIsVisible(not isComm)
        end
    end

end

function UpdateAmbientSounds(deltaTime)

    for index, ambientSound in ipairs(Client.ambientSoundList) do
        ambientSound:OnUpdate(deltaTime)
    end
    
end

function UpdateParticles(deltaTime)

    for index, particles in ipairs(Client.particlesList) do
        particles:OnUpdate(deltaTime)
    end
    
end

function OnUpdateClient(deltaTime)

    if not Client.GetIsRunningPrediction() then
    
        local player = Client.GetLocalPlayer()
        if player ~= nil then
        
            player:UpdateGUI()
        
            UpdateAmbientSounds(deltaTime)
            
            UpdateDSPEffects()
            
            UpdateParticles(deltaTime)
            
            UpdateTracers(deltaTime)
            
            if Client.GetConnectionProblems() then
                player:AddTooltipOncePer("Connection problems detected...", 5)
            end
            
        end
    
        // Update the GUIManager if there is a local player entity or not.
        gGUIManager:Update(deltaTime)
    
    end

end

// Return true if the event should be stopped here.
function OnSendKeyEvent(key, down)

    if not Client.GetIsRunningPrediction() then
    
        return gGUIManager:SendKeyEvent(key, down)
        
    end
    
    return false

end

// Return true if the event should be stopped here.
function OnSendCharacterEvent(character)

    if not Client.GetIsRunningPrediction() then
    
        return gGUIManager:SendCharacterEvent(character)
        
    end
    
    return false

end

function NotifyGUIItemDestroyed(destroyedItem)
    
    gGUIManager:NotifyGUIItemDestroyed(destroyedItem)

end

function CreateTracer(startPoint, endPoint, velocity)

    if not Client.GetIsRunningPrediction() then

        local tracer = BuildTracer(startPoint, endPoint, velocity)
        table.insert(Client.tracersList, tracer)
        
    end
    
end

function UpdateTracers(deltaTime)
    
    for index, tracer in ipairs(Client.tracersList) do
    
        tracer:OnUpdate(deltaTime)
        
        if tracer:GetTimeToDie() then
            tracer:OnDestroy()
        end
        
    end
    
    table.removeConditional(Client.tracersList, Tracer.GetTimeToDie)    

end

/**
 * Shows or hides the skybox(es) based on the specified state.
 */
function SetSkyboxDrawState(skyBoxVisible)

    for index, skyBox in ipairs(Client.skyBoxList) do
        skyBox:SetIsVisible( skyBoxVisible )
    end

end

function OnMapPreLoad()

    // Clear our list of render objects, lights, props
    Client.propList = {}
    Client.lightList = {}
    Client.skyBoxList = {}
    Client.ambientSoundList = {}
    Client.particlesList = {}
    Client.tracersList = {}
    
    Client.DestroyReverbs()
    Client.ResetSoundSystem()
    
    Shared.PreLoadSetGroupNeverVisible(kCollisionGeometryGroupName)   
    Shared.PreLoadSetGroupPhysicsId(kNonCollisionGeometryGroupName, 0)   
    
    // Any geometry in kCommanderInvisibleGroupName shouldn't interfere with selection or other commander actions
    Shared.PreLoadSetGroupPhysicsId(kCommanderInvisibleGroupName, PhysicsGroup.CommanderPropsGroup)   
    
    // Don't have bullets collide with collision geometry
    Shared.PreLoadSetGroupPhysicsId(kCollisionGeometryGroupName, PhysicsGroup.CollisionGeometryGroup)   
    
end

function ShowFeedbackPage()
    Client.ShowWebpage(kFeedbackURL)
end

/**
 * Callback handler for when the map is finished loading.
 */
function OnMapPostLoad()

    // Set sound falloff defaults
    Client.SetMinMaxSoundDistance(7, 100)
    
    CreateDSPs()
    
    Scoreboard_Clear()
    
end

/**
 * Called once per frame to setup the camera for rendering the scene.
 */
function OnSetupCamera(camera)
    
    local player = Client.GetLocalPlayer()
    
    // If we have a player, use them to setup the camera. 
    if (player ~= nil) then
        camera:SetCoords( player:GetCameraViewCoords() )
        camera:SetFov( player:GetRenderFov() )
        return true
    elseif (MenuManager.GetCinematicCamera(camera)) then
        return true
    end
    
    return false
    
end

Event.Hook("SetupCamera",           OnSetupCamera)
Event.Hook("MapLoadEntity",         OnMapLoadEntity)
Event.Hook("MapPreLoad",            OnMapPreLoad)
Event.Hook("MapPostLoad",           OnMapPostLoad)
Event.Hook("UpdateClient",          OnUpdateClient)
Event.Hook("SendKeyEvent",          OnSendKeyEvent)
Event.Hook("SendCharacterEvent",    OnSendCharacterEvent)