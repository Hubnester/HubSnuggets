local hubInit = init or function() end

function init()
	hubInit()
	if world.entitySpecies(entity.id()) == "hubsnugget" then
		status.setStatusProperty("mouthPosition", {0, -0.875})
	end
end