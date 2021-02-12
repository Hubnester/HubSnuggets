local hubInit = init or function() end

function init()
	hubInit()
	if world.entitySpecies(entity.id()) == "hubsnugget" then
		status.setStatusProperty("mouthPosition", root.assetJson("/species/hubsnugget.species").mouthPosition or {0, -0.875})
	end
end