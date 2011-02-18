// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Scan.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Invisible entity that gives LOS to marine team for a short time. Also used to parent
// the particle system to.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Scan' (Structure)

Scan.kMapName = "scan"

Scan.kScanEffect = PrecacheAsset("cinematics/marine/observatory/scan.cinematic")

Scan.kScanDistance = kScanRadius

function Scan:OnInit()

    Structure.OnInit(self)
    
    if Client then
    
        self:SetUpdates(true)
        
        // Glowing growing circles
        self.scanEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        
        self.scanEffect:SetCinematic(Scan.kScanEffect)
        
        self.scanEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        
    end
    
    self:SetIsVisible(false)
    
    self:SetNextThink(kScanDuration)
    
end

function Scan:OnThink()
    DestroyEntity(self)
end

function Scan:OnDestroy()

    if Client and self.scanEffect then
        Client.DestroyCinematic(self.scanEffect)
        self.scanEffect = nil
    end
    
    Structure.OnDestroy(self)

end

if Client then

    function Scan:OnUpdate(deltaTime)
    
        if self.scanEffect ~= nil and self:GetId() ~= Entity.invalidId then
        
            Structure.OnUpdate(self, deltaTime)
            
            local coords = Coords.GetIdentity()
            VectorCopy(self:GetOrigin(), coords.origin)
            self.scanEffect:SetCoords(coords)
            
        end 
       
    end
    
end

function Scan:GetRequiresPower()
    return false
end

Shared.LinkClassToMap("Scan", Scan.kMapName, {})