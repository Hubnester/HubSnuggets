local hubBuildStates = buildStates or function() end

function buildStates(tree)
	hubBuildStates(tree)
	
	local playerRace = player.species()
	local isByos = player.shipUpgrades().shipLevel == 0
	for node, nodeData in pairs (researchTree) do
		if nodeData.hubsnuggetRaceLock then
			for _, race in ipairs (nodeData.hubsnuggetRaceLock) do
				if playerRace ~= race then
					researchTree[node].state = "hidden"
				end
			end
		end
		if nodeData.hubsnuggetShipLock then
			if nodeData.hubsnuggetShipLock == "vanilla" then
				if isByos then
					researchTree[node].state = "hidden"
				end
			else
				if not isByos then
					researchTree[node].state = "hidden"
				end
			end
		end
	end
end