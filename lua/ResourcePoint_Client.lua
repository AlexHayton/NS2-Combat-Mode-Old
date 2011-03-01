// ======= Copyright © 2003-2011, MCMLXXXIV. No rights reserved. =======
//
// lua\ResourcePoint_Client.lua
//
//    Created by:   Alex Hayton (charlie@unknownworlds.com)
//

function ResourcePoint:SetAttached(attached)

    ScriptActor.SetAttached(self, attached)
    
    self:SetEffectState(false)

	self.showGhostModel = false
    
end

function ResourcePoint:ShowGhostModel()
	local modelName = ""
	local player = Client.GetLocalPlayer()

	local teamNumber = player:GetTeamNumber()
	if (teamNumber ~= nil and teamNumber > 0) then	
		if teamNumber == 1 then
			modelName = PrecacheAsset("models/marine/extractor/extractor.model")
		else
			modelName = PrecacheAsset("models/alien/harvester/harvester.model")
		end
	end
		
	self.ghostModel = CreateAnimatedModel(modelName)
	self.ghostModel:SetAnimation("deploy")
	//self.ghostModel:SetCastsShadows(false)
    self.ghostModel:SetIsVisible(true)                    
	self.ghostModel:SetCoords(self:GetOrigin())
	//self.ghostModel:SetAngles(self:GetAngles())
	
end

function ResourcePoint:DestroyGhostModel()
	if self.ghostModel ~= nil then
    
        self.ghostModel:OnDestroy()
        self.ghostModel = nil
        
    end
end

function ResourcePoint:ClearAttached()

    ScriptActor.ClearAttached(self)
    
    self:SetEffectState(true)    
	
	self.showGhostModel = true

end