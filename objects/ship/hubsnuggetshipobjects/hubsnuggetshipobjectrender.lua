require "/scripts/vec2.lua"

local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.position = entity.position()
	self.orientations = config.getParameter("hubsnuggetOrientations") or {}
	self.directory = root.itemConfig(object.name()).directory
	self.isDoor = config.getParameter("isDoor")
end

function update(dt)
	hubUpdate(dt)
	local shipType = world.getProperty("hubsnuggetShipType", "default")
	if shipType ~= storage.shipType then
		local orientations = self.orientations[shipType] or self.orientations["default"]
		if not orientations.alreadyProcessed then
			-- Convert all possible orientations image formats to the same one
			if orientations.imageLayers then
				orientations.images = orientations.imageLayers
			elseif orientations.image then
				orientations.images = {{image = orientations.image}}
			elseif orientations.dualImage then
				orientations.images = {{image = orientations.dualImage}}
			else 
				sb.logWarn("Unknown orientations image format detected, aborting image data loading for " .. tostring(object.name()) .. " of ship type " .. shipType)
				storage.shipType = shipType
				return
			end
			-- Convert all the image paths to absolute
			for i, imageData in ipairs (orientations.images) do
				if string.sub(imageData.image, 1, 1) ~= "/" then
					orientations.images[i].image = self.directory .. imageData.image
				end
			end
			-- Calculate the image render position
			local imageSize = root.imageSize(orientations.images[1].image:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1))
			local imageOffset = orientations.imagePosition
			orientations.position = vec2.sub(self.position, vec2.div(vec2.sub(vec2.div(imageSize, 2), vec2.add(imageSize, imageOffset)), 8))
			-- So we only need to process this stuff one time while the object stays loaded
			orientations.alreadyProcessed = true
		end
		object.setConfigParameter("renderData", orientations)
		storage.shipType = shipType
	end
	
	if self.isDoor then
		if animator.animationState("doorState") == "open" then
			object.setConfigParameter("doorState", "open")
		else
			object.setConfigParameter("doorState", "close")
		end
	end
end