local firstUpdate = true
local colorParts = {"bodyColor", "hairColor", "undyColor"}

function init()
	self.entityId = entity.id()
	self.species = world.entitySpecies(self.entityId)
	
end

function update(dt)
	if firstUpdate then
		-- If i remove this it might actually work for any race if they get the status effect
		if self.species == "hubsnugget" then
			local playerImages = world.entityPortrait(self.entityId, "full") or {}
			local playerGender = world.entityGender(self.entityId)
			local bodyImage = ""
			for _, imageData in ipairs (playerImages) do
				-- Not going to bother making this configurable since it's path is likely completely hardcoded
				if string.find(imageData.image or "", "/humanoid/" .. self.species .. "/" .. playerGender .. "body.png") then
					bodyImage = imageData.image
					break
				end
			end
			local colorReplacementPositions = {}
			local croppedImage = bodyImage
			local i = 1
			while i <= 3 do
				local startPos, endPos = string.find(croppedImage, "?replace")
				colorReplacementPositions[i] = pos
				croppedImage = string.sub(croppedImage, pos + 2, -1)
				i = i + 1
			end
			local colorReplacements = {}
			local posOffset = 2
			for j, pos in ipairs (colorReplacementPositions) do
				local endPos = (colorReplacementPositions[j + 1] and colorReplacementPositions[j + 1] + pos + posOffset) or -1
				local colors = string.sub(bodyImage, pos + posOffset, endPos)gsub()
				posOffset = posOffset + pos + 1
				sb.logInfo(tostring(colors))
			end
		end
		firstUpdate = false
	end
end