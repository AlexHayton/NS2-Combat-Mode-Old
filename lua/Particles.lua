// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Particles.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Effect.lua")

class 'Particles' (Effect)

Particles.kMapName = "particles"

if (Client) then

    function Particles:StartPlaying()

        if(not self.playing) then
        
            if self.cinematicNameIndex == nil then
                self.cinematicNameIndex = Shared.GetCinematicIndex(self.cinematicName)
            end

            local coords = Coords()
            VectorCopy(Vector(1, 0, 0), coords.xAxis)
            VectorCopy(Vector(0, 1, 0), coords.yAxis)
            VectorCopy(Vector(0, 0, 1), coords.zAxis)
            VectorCopy(self.origin, coords.origin)
            
            Client.PlayParticlesWithIndex(self.cinematicNameIndex, coords)
            
            self.playing = true
            
        end
        
    end

    function Particles:StopPlaying()

        if(self.playing) then
        
            if self.cinematicNameIndex == nil then
                self.cinematicNameIndex = Shared.GetCinematicIndex(self.cinematicName)
            end

            Client.StopParticlesWithIndex(self.cinematicNameIndex, self:GetOrigin())
            
            self.playing = false
            
        end
        
    end

end

