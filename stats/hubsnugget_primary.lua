local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.hubsnuggetConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetEntityId = entity.id()
	self.hubsnuggetRace = world.entitySpecies(self.hubsnuggetEntityId)
end

function update(dt)
	hubUpdate(dt)
	if self.hubsnuggetRace == "hubsnugget" then
		local hubsnuggetIsLounging = world.sendEntityMessage(self.hubsnuggetEntityId, "hubsnuggetIsLounging")
		if hubsnuggetIsLounging:result() then
			status.setStatusProperty("mouthPosition", self.hubsnuggetConfig.loungingMouthPosition or {0, 0.75})
		else
			status.setStatusProperty("mouthPosition", self.hubsnuggetConfig.mouthPosition or {0, -1.875})
		end
	end
end