local hubInteract = interact or function() end

function interact(args)
	if world.time() - self.lastInteract > config.getParameter("interactCooldown", 3.0) and world.entitySpecies(args.sourceId) == "hubsnugget"then
		local text = config.getParameter("hubsnuggetText") or {}
		if #text > 0 then
			monster.say(text[math.random(1, #text)], {playerName = world.entityName(args.sourceId)})
		end
	end
	hubInteract(args)
end