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
		if not self.orientations[shipType].alreadyProcessed then
			-- Convert all possible orientations image formats to the same one
			if self.orientations[shipType].imageLayers then
				self.orientations[shipType].images = self.orientations[shipType].imageLayers
			elseif self.orientations[shipType].image then
				self.orientations[shipType].images = {{image = self.orientations[shipType].image}}
			elseif self.orientations[shipType].dualImage then
				self.orientations[shipType].images = {{image = self.orientations[shipType].dualImage}}
			else 
				sb.logWarn("Unknown orientations image format detected, aborting image data loading for " .. tostring(object.name()) .. " of ship type " .. shipType)
				storage.shipType = shipType
				return
			end
			-- Convert all the image paths to absolute
			for i, imageData in ipairs (self.orientations[shipType].images) do
				if string.sub(imageData.image, 1, 1) ~= "/" then
					self.orientations[shipType].images[i].image = self.directory .. imageData.image
				end
			end
			-- Calculate the image render position
			local imageSize = root.imageSize(self.orientations[shipType].images[1].image:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1))
			local imageOffset = self.orientations[shipType].imagePosition
			self.orientations[shipType].position = vec2.sub(self.position, vec2.div(vec2.sub(vec2.div(imageSize, 2), vec2.add(imageSize, imageOffset)), 8))
			-- So we only need to process this stuff one time while the object stays loaded
			self.orientations[shipType].alreadyProcessed = true
		end
		object.setConfigParameter("renderData", self.orientations[shipType])
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