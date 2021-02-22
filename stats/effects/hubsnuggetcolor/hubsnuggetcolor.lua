local inited = false
local colorParts = {"bodyColor", "hairColor", "undyColor"}

function init()
	
end

function update(dt)
	if not inited then
		self.entityId = entity.id()
		self.species = world.entitySpecies(self.entityId)
		if self.species then
			self.usableByAnyone = effect.getParameter("usableByAnyone")
			self.colorPartsReplacements = {}
			self.rainbowData = effect.getParameter("rainbow")
			self.raceConfig = root.assetJson("/species/" .. self.species .. ".species")
			for _, part in ipairs (colorParts) do
				local newPartData = {}
				for i, colourData in ipairs (self.raceConfig[part]) do
					newPartData[i] = {}
					for color1, color2 in pairs (colourData) do
						newPartData[i][string.lower(color1)] = string.lower(color2)
					end
				end
				self.raceConfig[part] = newPartData
			end
			self.timer = 0	-- To make it change colour immediately
			self.index = 0	-- So that it starts with the first colour (1) since it increments before changing
			inited = true
		end
	else
		if self.species == "hubsnugget" or self.usableByAnyone then
			if not self.colorPartsReplacements.bodyColor then
				local playerImages = world.entityPortrait(self.entityId, "full") or {}
				if #playerImages ~= 0 then
					local playerGender = world.entityGender(self.entityId)
					local bodyImage = ""
					for _, imageData in ipairs (playerImages) do
						-- Not going to bother making this configurable since it's path is likely completely hardcoded
						if string.find(imageData.image or "", "/humanoid/" .. self.species .. "/" .. playerGender .. "body.png") then
							bodyImage = imageData.image
							break
						end
					end
					local bodyTypeSplits = bodyImage:split("?replace;")
					for i, split in ipairs (bodyTypeSplits) do
						if i ~= 1 then
							self.colorPartsReplacements[colorParts[i -1]] = {}
							for color1, color2 in split:gmatch("(%x+)=(%x+)") do
								self.colorPartsReplacements[colorParts[i -1]][color1] = color2
							end
						end
					end
				end
			else
				-- Honestly this whole thing could be improved later when more colour options are added
				local rainbow = status.statusProperty("hubsnuggetRainbow") or true
				if rainbow then
					self.timer = (self.timer or self.rainbowData.cycleTime or 1) - dt
					if self.timer and self.timer <= 0 then
						self.index = self.index + 1
						if self.index > #(self.rainbowData.order or {}) then
							self.index = 1
						end
						local directives = "?replace"
						for part, colours in pairs (self.colorPartsReplacements) do
							for color1, color2 in pairs (colours) do
								local color = (self.raceConfig[part][self.index] or {})[string.lower(color1)]
								if color then
									directives = directives .. ";" .. color2 .. "=" .. color
								end
							end
						end
						effect.setParentDirectives(directives)
						self.timer = nil
					end
				else
					effect.setParentDirectives()
				end
			end
		end
	end
end

-- String split code from Neb
-- local myString = "100, 200, 300, 400"
-- local splited = myString:split(",") it can be any delimiter
-- Result: Splited = {100, 200, 300, 400}
function string:split( inSplitPattern, outResults )
	if not outResults then
		outResults = { }
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( self, theStart ) )
	return outResults
end