require "/scripts/vec2.lua"

function update()
	if world.getProperty("ship.level", 0) ~= storage.shipLevel or world.getProperty("hubsnuggetShipType", "default") ~= storage.shipType then
		local shipsConfig = root.assetJson("/universe_server.config").speciesShips["hubsnugget"]
		if shipsConfig then
			local shipConfigPath = shipsConfig[world.getProperty("ship.level", 0) + 1] or shipsConfig[#shipsConfig]
			local shipConfig = root.assetJson(shipConfigPath)
			local reversedFile = string.reverse(shipConfigPath)
			local snipLocation = string.find(reversedFile, "/")
			local shipPathGsub = string.sub(shipConfigPath, -snipLocation + 1)
			-- could cause errors, but the object shouldn't be there if errors could occur here
			local backgroundOverlays = shipConfig.hub_backgroundOverlays[world.getProperty("hubsnuggetShipType", "default")]	
			for i, overlay in ipairs (backgroundOverlays) do
				if string.sub(overlay.image, 1, 1) ~= "/" then
					backgroundOverlays[i].image = shipConfigPath:gsub(shipPathGsub, overlay.image)
				end
			end
			local blockKeyPath = shipConfig.blockKey
			if string.sub(blockKeyPath, 1, 1) ~= "/" then
				blockKeyPath = shipConfigPath:gsub(shipPathGsub, blockKeyPath)
			end
			local blockKey = root.assetJson(blockKeyPath)
			if string.sub(shipConfig.blockImage, 1, 1) ~= "/" then
				shipConfig.blockImage = shipConfigPath:gsub(shipPathGsub, shipConfig.blockImage)
			end
			-- Code for getting [0, 0] position of the ship background
			local blockImage = config.getParameter("blockImageBase")
			local blockImageSize = root.imageSize(shipConfig.blockImage)
			-- Change the base to a square that can fit the block image
			blockImage = blockImage .. "?scalenearest=" .. tostring(math.max(blockImageSize[1], blockImageSize[2]))
			-- Change the base image square to the same size as the block image
			blockImage = blockImage .. "?crop=0;0;" .. tostring(blockImageSize[1]) .. ";" .. tostring(blockImageSize[2])
			-- Add the block image to the base image
			blockImage = blockImage .. "?blendmult=" .. shipConfig.blockImage
			-- Make it so that block pixel is one block
			blockImage = blockImage .. "?scalenearest=8"
			-- Remove all the blocks except the player spawn one from the block image
			blockImage = blockImage .. "?replace"
			for _, blockData in ipairs (blockKey) do
				if not blockData.anchor then
					local hexColour = ""
					local i = 1
					while i <= 3 do
						hexColour = hexColour .. string.format("%02x", blockData.value[i])
						i = i + 1
					end
					hexColour = hexColour .. string.format("%02x", math.ceil((blockData.value[4] or 255) / 2))
					blockImage = blockImage .. ";" .. hexColour .. "=0000"
				end
			end
			-- Get the base ship background image offset from the created block image
			local baseImageOffset = root.imageSpaces(blockImage, {0.69, 0.69}, 0.3)	-- Not sure why but non-whole numbers between 0.5 and 1 seem to have 1 space at 0.3 spacescan, might need to investigate this more later, but this works for now
			object.setConfigParameter("backgroundOverlays", backgroundOverlays)
			object.setConfigParameter("baseImageOffset", baseImageOffset[1])
			storage.shipLevel = world.getProperty("ship.level", 0)
			storage.shipType = world.getProperty("hubsnuggetShipType", "default")
			object.setConfigParameter("shipLevel", storage.shipLevel)
			object.setConfigParameter("shipType", storage.shipType)
		end
	end
end