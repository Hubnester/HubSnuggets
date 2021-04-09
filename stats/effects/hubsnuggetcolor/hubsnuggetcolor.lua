local inited = false
local colorParts = {"bodyColor", "hairColor", "undyColor"}

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
				for i, colorData in ipairs (self.raceConfig[part]) do
					newPartData[i] = {}
					-- Fix for an issue with Aegi
					if type(colorData) == "table" then
						for color1, color2 in pairs (colorData) do
							newPartData[i][string.lower(color1)] = string.lower(color2)
						end
					end
				end
				self.raceConfig[part] = newPartData
			end
			self.timer = 0	-- To make it change colour immediately
			self.index = 0	-- So that it starts with the first colour (1) since it increments before changing
			self.hue = 0
			inited = true
		end
	else
		if not self.colorPartsReplacements.bodyColor then
			local playerImages = world.entityPortrait(self.entityId, "full") or {}
			if #playerImages ~= 0 then
				local playerGender = world.entityGender(self.entityId)
				local colorImages = {body = "", hair = ""}
				for _, imageData in ipairs (playerImages) do
					-- Not going to bother making this configurable since it's path is likely completely hardcoded
					if string.find(imageData.image or "", "/humanoid/" .. self.species .. "/" .. playerGender .. "body.png") then
						colorImages["body"] = imageData.image
					elseif string.find(imageData.image or "", "/humanoid/" .. self.species .. "/hair/") then
						colorImages["hair"] = imageData.image
					end
				end
				local bodySplits = colorImages.body:split("?replace;")
				local hairSplits = colorImages.hair:split("?replace;")
				local bodyTypeSplits = {}
				bodyTypeSplits[1] = bodySplits[2] or ""
				bodyTypeSplits[2] = hairSplits[2] or ""
				bodyTypeSplits[3] = bodySplits[#bodySplits] or ""
				for i, split in ipairs (bodyTypeSplits) do
					self.colorPartsReplacements[colorParts[i]] = {}
					for color1, color2 in split:gmatch("(%x+)=(%x+)") do
						self.colorPartsReplacements[colorParts[i]][color1] = color2
					end
				end
			end
		else
			local directives = self.directives or ""
			local snuggetColor = status.statusProperty("hubsnuggetColor")
			if self.species == "hubsnugget" or self.usableByAnyone then
				-- Honestly this whole thing could be improved later when more colour options are added
				if snuggetColor == "rainbow" then
					self.timer = (self.timer or self.rainbowData.cycleTime or 1) - dt
					if self.timer and self.timer <= 0 then
						self.index = self.index + 1
						if self.index > #(self.rainbowData.order or {}) then
							self.index = 1
						end
						directives = "?replace"
						for part, colors in pairs (self.colorPartsReplacements) do
							for color1, color2 in pairs (colors) do
								local color = (self.raceConfig[part][self.index] or {})[string.lower(color1)]
								if color then
									directives = directives .. ";" .. color2 .. "=" .. color
								end
							end
						end
						self.timer = nil
					end
				elseif snuggetColor == "rgb" then
					directives = "?replace"
					for part, colors in pairs (self.colorPartsReplacements) do
						for _, color2 in pairs (colors) do
							local r = tonumber(string.sub(color2, 1, 2), 16)
							local g = tonumber(string.sub(color2, 3, 4), 16)
							local b = tonumber(string.sub(color2, 5, 6), 16)
							local a = string.sub(color2, 7, 8) or ""
							local hsR, hsG, hsB = hueshift(r, g, b, self.hue)
							local color = string.format("%02x", hsR) .. string.format("%02x", hsG) .. string.format("%02x", hsB) .. a
							directives = directives .. ";" .. color2 .. "=" .. color
						end
					end
					self.hue = self.hue + 2
					if self.hue > 360 then
						self.hue = 0
					end
				end
			end
			if snuggetColor == "rgbHair" then
				directives = "?replace"
				for _, color2 in pairs (self.colorPartsReplacements.hairColor) do
					local r = tonumber(string.sub(color2, 1, 2), 16)
					local g = tonumber(string.sub(color2, 3, 4), 16)
					local b = tonumber(string.sub(color2, 5, 6), 16)
					local a = string.sub(color2, 7, 8) or ""
					local hsR, hsG, hsB = hueshift(r, g, b, self.hue)
					local color = string.format("%02x", hsR) .. string.format("%02x", hsG) .. string.format("%02x", hsB) .. a
					directives = directives .. ";" .. color2 .. "=" .. color
				end
				self.hue = self.hue + 1
				if self.hue > 360 then
					self.hue = 0
				end
			end
			if snuggetColor ~= "rainbow" or not self.timer then
				effect.setParentDirectives(directives)
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

function hueshift(r, g, b, hs)
	-- Convert RGB to HSV (based on: https://www.rapidtables.com/convert/color/rgb-to-hsv.html)
	local r2 = r / 255
	local g2 = g / 255
	local b2 = b / 255
	local M = math.max(r2, g2, b2)
	local m = math.min(r2, g2, b2)
	local d = M - m
	local h
	if d == 0 then
		h = 0
	elseif M == r2 then
		h = 60 * (((g2 - b2) / d) % 6)
	elseif M == g2 then
		h = 60 * (((b2 - r2) / d) + 2)
	elseif M == b2 then
		h = 60 * (((r2 - g2) / d) + 4)
	end
	local s
	if M == 0 then
		s = 0
	else
		s = d / M
	end
	local v = M
	-- Apply hueshift
	h = (h + hs) % 360
	-- Convert HSV to RGB (based on: https://www.rapidtables.com/convert/color/hsv-to-rgb.html)
	local c = v * s
	local x = c * (1 - math.abs(h / 60 % 2 - 1))
	local n = v - c
	local r3, g3, b3
	if h < 60 then
		r3 = c
		g3 = x
		b3 = 0
	elseif h < 120 then
		r3 = x
		g3 = c
		b3 = 0
	elseif h < 180 then
		r3 = 0
		g3 = c
		b3 = x
	elseif h < 240 then
		r3 = 0
		g3 = x
		b3 = c
	elseif h < 300 then
		r3 = x
		g3 = 0
		b3 = c
	else
		r3 = c
		g3 = 0
		b3 = x
	end
	r = math.floor(((r3 + n) * 255) + 0.5)
	g = math.floor(((g3 + n) * 255) + 0.5)
	b = math.floor(((b3 + n) * 255) + 0.5)
	return r, g, b
end