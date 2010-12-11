// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Spectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Player.lua")

class 'Spectator' (Player)

Spectator.kMapName = "spectator"
Spectator.kMaxSpeed = Player.kWalkMaxSpeed * 5
Spectator.kAcceleration = 100

Spectator.kDeadSound = PrecacheAsset("sound/ns2.fev/common/dead")

local networkVars = {

    // 0 is free look, 1 is following player
    specMode = "integer (0 to 1)",
    
    // When in follow mode, this is the player to follow
    specTarget = "entityid",
    
    timeOfLastInput = "float"

}

function Spectator:OnInit()

    Player.OnInit(self)
    
    if (Server) then
        
        self:SetIsVisible(false)
        
        self.alive = false
        
        self.smoothCamera = false
 
    else
              
        // Play ambient "you are dead" sound
        if Client.GetLocalPlayer() == self then
        
            if self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index then
                Shared.PlaySound(self, Spectator.kDeadSound)
            end
            
        end
 
    end
    
    self:DestroyPhysicsController()
    
    self.specMode = 0
    self.specTarget = Entity.invalidId
    self.timeOfLastInput = 0

end

function Spectator:OnDestroy()
    if Client then
        Shared.StopSound(self, Spectator.kDeadSound)
    end
    Player.OnDestroy(self)
end

function Spectator:GetPlayFootsteps()
    return false
end

/**
 * Update position from velocity, performing collision with the world.
 */
function Spectator:UpdatePositionNoClip(velocity, time)

    // Compute desired offset from current position
    local offset = velocity * time
    local newOrigin = Vector(self:GetOrigin()) + offset
    self:SetOrigin(newOrigin)
        
end

//function Spectator:GetMovementMask()
//    return emptyMask
//end

function Spectator:GetGravityForce(input)
    return 0
end

// Return 0, 0 to indicate no collision
function Spectator:GetTraceCapsule()
    return 0, 0
end

function Spectator:GetMaxSpeed()
    return Spectator.kMaxSpeed
end

function Spectator:GetAcceleration()
    return Spectator.kAcceleration
end

function Spectator:SetOriginAnglesVelocity(input)

    Player.UpdateViewAngles(self, input)    
    
    local velocity = self:GetVelocity()
    local angles        = self:ConvertToViewAngles(input.pitch, input.yaw, 0)   
    local viewCoords    = angles:GetCoords()
    
    // Apply acceleration in the direction we're looking (flying)
    local moveVelocity = viewCoords:TransformVector( input.move ) * self:GetAcceleration()
    velocity = velocity + moveVelocity * input.time
        
    // Apply friction
    local frictionForce = Vector(-velocity.x, -velocity.y, -velocity.z) * 5
    velocity = velocity + frictionForce * input.time
    
    // Clamp speed
    local velocityLength = velocity:GetLength()
    if velocityLength > self:GetMaxSpeed() then    
        velocity:Scale( self:GetMaxSpeed() / velocityLength )
    end

    //if(Shared.GetDevMode()) then
        self:UpdatePositionNoClip(velocity, input.time)
    //else            
    //    self:UpdatePosition(velocity, input.time)
    //end

    self:SetVelocity(velocity)
    
end

function Spectator:UpdateHelp()

    if self:AddTooltipOncePer("You are spectating. Press jump to change between free camera or following a player (attack to cycle between players)", 90) then
        return true
    end

    return false
    
end

function Spectator:UpdateFromSpecTarget(input)

    // Set our position, angles, fov, viewangles to those of our spec target
    local entity = Shared.GetEntity(self.specTarget)
    if entity ~= nil then
    
        self:SetOrigin(entity:GetOrigin())
        self:SetFov(entity:GetFov())
        
    end
    
    // So we can rotate around target
    local viewAngles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    self:SetViewAngles(viewAngles, true)
    
end

if Server then

    // Go to next player on team if we're playing, or next player in world if we're not
    function Spectator:SetNextTarget()

        local teamNumber = ConditionalValue(((self:GetTeamNumber() == kTeamReadyRoom) or (self:GetTeamNumber() == kSpectatorIndex)), -1, self:GetTeamNumber())
        local currentEntity = nil

        if self.specTarget ~= Entity.invalidId then
            currentEntity = Shared.GetEntity(self.specTarget)
        end
        
        local done = false
        local hitEnd = false
        
        repeat
            
            currentEntity = Shared.FindNextEntity(currentEntity)
            
            if(currentEntity and currentEntity:isa("Player") and not currentEntity:isa("Commander") and currentEntity ~= self and ((teamNumber == -1) or (currentEntity:GetTeamNumber() == teamNumber))) then
            
                self.specTarget = currentEntity:GetId()
                self:SetOrigin(currentEntity:GetOrigin())
                
                done = true
                
                self:AddTooltip(string.format("Following %s", ConditionalValue(currentEntity:isa("Player"), currentEntity:GetStatusDescription(), currentEntity:GetClassName())))
                     
            end
            
            if currentEntity == nil then
                if not hitEnd then 
                    hitEnd = true
                else
                    self:AddTooltip("No targets found.")
                    done = true
                end
            end
            
        until done
       
    end
    
end

function Spectator:OnProcessMove(input)
  
    // Don't allow setting of animations during OnProcessMove() as they will get reverted
    SetRunningProcessMove(self)
  
    // Update from target
    if self.specMode == 1 and self.specTarget ~= Entity.invalidId then
        self:UpdateFromSpecTarget(input)
    // Else let them float around
    else
        self:SetOriginAnglesVelocity(input)
    end
    
    // Don't switch between targets or take input too quickly
    local time = Shared.GetTime()
    
    if time > self.timeOfLastInput + .3 then
    
        // If attack pressed, spawn player if possible (cannot spawn them into the spectator or ready room team)
        local validTeam = self:GetTeamNumber() ~= kSpectatorIndex and self:GetTeamNumber() ~= kTeamReadyRoom
        if( bit.band(input.commands, Move.PrimaryAttack) ~= 0 and Server and validTeam) then
            self:SpawnPlayerOnAttack()
            self.timeOfLastInput = time
        end

        if( bit.band(input.commands, Move.Jump) ~= 0 and Server) then
        
            // Switch modes
            self.specMode = (self.specMode + 1) % 2
            
            if self.specMode == 1 then
                self:SetIsThirdPerson(3)
                self:SetNextTarget()
            else
                self:SetIsThirdPerson(0)
                self:AddTooltip("Free look mode")
            end
            
            self.timeOfLastInput = time
            
        end
        
        if( bit.band(input.commands, Move.SecondaryAttack) ~= 0 and Server and self.specMode == 1) then
        
            // Cycle targets
            self:SetNextTarget()
            self.timeOfLastInput = time
            
        end
        
        // When exit hit, bring up menu
        if((bit.band(input.commands, Move.Exit) ~= 0) and (Client ~= nil)) then
            ShowInGameMenu()
            self.timeOfLastInput = time
        end
    
    end
    
    // Handle scoreboard
    self.showScoreboard = (bit.band(input.commands, Move.Scoreboard) ~= 0)
    
    self:UpdateCamera(input.time)
    
    if Client and not Client.GetIsRunningPrediction() then
        self:UpdateChat(input)
    end
    
    SetRunningProcessMove(nil)
    
end

if Server then

// Marines spawn at predetermined time at IP but allow them to spawn manually if cheats are on
function Spectator:SpawnPlayerOnAttack()

    if (Shared.GetCheatsEnabled() or not GetGamerules():GetGameStarted()) and ((self.timeOfDeath == nil) or (Shared.GetTime() > self.timeOfDeath + kFadeToBlackTime)) then
    
        local success, player = self:GetTeam():ReplaceRespawnPlayer(self)
        
        return success
        
    end
    
    return false
    
end

//Spectators cannot have orders.
function Spectator:OverrideOrder(order)
    
end

function Spectator:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst)

    return kTechId.None

end

function Spectator:SetOrder(order, clearExisting, insertFirst)

end

function Spectator:CopyOrdersFrom(source)

end

function Spectator:CopyOrders(dest)

end

end

if Client then

// Don't change visibility on client
function Spectator:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    self:SetIsVisible(false)
    
    local activeWeapon = self:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        activeWeapon:SetIsVisible( false )
    end
    
    local viewModel = self:GetViewModelEntity()    
    if(viewModel ~= nil) then
        viewModel:SetIsVisible( false )
    end

end

end

Shared.LinkClassToMap( "Spectator", Spectator.kMapName, networkVars )