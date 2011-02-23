// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shared.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Put any classes that are used on both the client and server here.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Utility and constants
Script.Load("lua/Globals.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/MixinUtility.lua")
Script.Load("lua/Actor.lua")
Script.Load("lua/AnimatedModel.lua")
Script.Load("lua/Vector.lua")
Script.Load("lua/Table.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/Effects.lua")
Script.Load("lua/NetworkMessages.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/TechNode.lua")
Script.Load("lua/TechTree.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/LiveScriptActor.lua")
Script.Load("lua/Order.lua")
Script.Load("lua/PropDynamic.lua")
Script.Load("lua/Blip.lua")
Script.Load("lua/MapBlip.lua")

// Neutral structures
Script.Load("lua/Structure.lua")
Script.Load("lua/ResourcePoint.lua")
Script.Load("lua/ResourceTower.lua")
Script.Load("lua/Door.lua")
Script.Load("lua/Reverb.lua")
Script.Load("lua/Location.lua")
Script.Load("lua/Trigger.lua")
Script.Load("lua/Ladder.lua")
Script.Load("lua/MinimapExtents.lua")
Script.Load("lua/DeathTrigger.lua")
Script.Load("lua/Gamerules.lua")
Script.Load("lua/NS2Gamerules.lua")
Script.Load("lua/TechPoint.lua")
Script.Load("lua/BaseSpawn.lua")
Script.Load("lua/ReadyRoomSpawn.lua")
Script.Load("lua/PlayerSpawn.lua")
Script.Load("lua/TeamLocation.lua")
Script.Load("lua/Target.lua")
Script.Load("lua/Weapons/ViewModel.lua")

// Marine structures
Script.Load("lua/MAC.lua")
Script.Load("lua/Extractor.lua")
Script.Load("lua/Armory.lua")
Script.Load("lua/PowerPack.lua")
Script.Load("lua/Observatory.lua")
Script.Load("lua/Scan.lua")
Script.Load("lua/RoboticsFactory.lua")
Script.Load("lua/PrototypeLab.lua")
Script.Load("lua/CommandStructure.lua")
Script.Load("lua/CommandStation.lua")
Script.Load("lua/Sentry.lua")
Script.Load("lua/ARC.lua")
Script.Load("lua/InfantryPortal.lua")
Script.Load("lua/DropPack.lua")
Script.Load("lua/AmmoPack.lua")
Script.Load("lua/MedPack.lua")
Script.Load("lua/CatPack.lua")
Script.Load("lua/Effect.lua")
Script.Load("lua/AmbientSound.lua")
Script.Load("lua/Particles.lua")

// Alien structures
Script.Load("lua/Harvester.lua")
Script.Load("lua/Infestation.lua")
Script.Load("lua/Hive.lua")
Script.Load("lua/Crag.lua")
Script.Load("lua/Whip.lua")
Script.Load("lua/Shift.lua")
Script.Load("lua/Shade.lua")
Script.Load("lua/HydraSpike.lua")
Script.Load("lua/Hydra.lua")
Script.Load("lua/Drifter.lua")
Script.Load("lua/Egg.lua")
Script.Load("lua/Embryo.lua")
Script.Load("lua/Cocoon.lua")
Script.Load("lua/Phantasm.lua")
Script.Load("lua/OnosPhantasm.lua")

// Base players
Script.Load("lua/Spectator.lua")
Script.Load("lua/AlienSpectator.lua")
Script.Load("lua/Ragdoll.lua")
Script.Load("lua/MarineCommander.lua")
Script.Load("lua/AlienCommander.lua")

// Character class behaviors
Script.Load("lua/Marine.lua")
Script.Load("lua/Heavy.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/Gorge.lua")
Script.Load("lua/Lerk.lua")
Script.Load("lua/Fade.lua")
Script.Load("lua/Onos.lua")

// Weapons
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/Weapons/Marine/Rifle.lua")
Script.Load("lua/Weapons/Marine/Pistol.lua")
Script.Load("lua/Weapons/Marine/Shotgun.lua")
Script.Load("lua/Weapons/Marine/Axe.lua")
Script.Load("lua/Weapons/Marine/Minigun.lua")
Script.Load("lua/Weapons/Marine/GrenadeLauncher.lua")
Script.Load("lua/Weapons/Marine/Flamethrower.lua")
Script.Load("lua/Jetpack.lua")

Script.Load("lua/PowerPoint.lua")
Script.Load("lua/Sayings.lua")
Script.Load("lua/NS2Utility.lua")

// Call from shared code
function TriggerTracer(clientPlayer, startPoint, endPoint, velocity)

    if Client then
    
        CreateTracer(startPoint, endPoint, velocity)
        
    else
    
        // Send tracer network message to nearby players, not including this one
        for index, player in ipairs(GetGamerules():GetAllPlayers()) do
        
            if player ~= clientPlayer and player:GetTeamNumber() ~= kTeamReadyRoom then
        
                local dist = (player:GetOrigin() - clientPlayer:GetOrigin()):GetLength()
                if dist < 30 then
                
                    Server.SendNetworkMessage(player, "Tracer", BuildTracerMessage(startPoint, endPoint, velocity), false)
                    
                end
                
            end
            
        end
        
    end
    
end

/**
 * Called when two physics bodies collide.
 */
function OnPhysicsCollision(body1, body2)

    local entity1 = body1:GetEntity()
    local entity2 = body2:GetEntity()
    
    if (entity1 ~= nil and entity1.OnCollision ~= nil) then
        entity1:OnCollision(entity2)
    end
    
    if (entity2 ~= nil and entity2.OnCollision ~= nil) then
        entity2:OnCollision(entity1)
    end

end

// Set the callback function when there's a collision
Event.Hook("PhysicsCollision", OnPhysicsCollision)

/**
 * Called when one physics body enters into a trigger body.
 */
function OnPhysicsTrigger(enterObject, triggerObject, enter)

    local enterEntity   = enterObject:GetEntity()
    local triggerEntity = triggerObject:GetEntity()
    
    if enterEntity ~= nil and triggerEntity ~= nil then
    
        if (enter) then
        
            if (enterEntity.OnTriggerEntered ~= nil) then
                enterEntity:OnTriggerEntered(enterEntity, triggerEntity)
            end
            
            if (triggerEntity.OnTriggerEntered ~= nil) then
                triggerEntity:OnTriggerEntered(enterEntity, triggerEntity)
            end
            
        else
        
            if (enterEntity.OnTriggerExited ~= nil) then
                enterEntity:OnTriggerExited(enterEntity, triggerEntity)
            end
            
            if (triggerEntity.OnTriggerExited ~= nil) then
                triggerEntity:OnTriggerExited(enterEntity, triggerEntity)
            end
            
        end
        
    end

end

// Set the callback functon when there's a trigger
Event.Hook("PhysicsTrigger", OnPhysicsTrigger)