local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.hubsnuggetConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetConfig.allowedCosmetics = self.hubsnuggetConfig.allowedCosmetics or {}
	self.hubsnuggetEntityId = entity.id()
	self.hubsnuggetRace = player.species()
	
	message.setHandler("hubsnuggetIsLounging", player.isLounging)
	
	if self.hubsnuggetRace == "hubsnugget" and not status.statusProperty("hubsnuggetAlreadyCreated") then
		local slots = {"chest", "legs"}
		for _, slot in ipairs (slots) do
			local item = player.equippedItem(slot) or {}
			if self.hubsnuggetConfig.allowedCosmetics[item.name] then
				player.setEquippedItem(slot .. "Cosmetic", item)
				player.setEquippedItem(slot, nil)
			end
		end
		status.setStatusProperty("hubsnuggetAlreadyCreated", true)
	end
end

function update(dt)
	hubUpdate(dt)
	
	if self.hubsnuggetRace == "hubsnugget" then
		-- Snugget cosmetics handling (improve this eventually)
		local slots = {"headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic" }
		for _, slot in ipairs (slots) do
			local item = player.equippedItem(slot) or {}
			if not self.hubsnuggetConfig.allowedCosmetics[item.name] then
				player.setEquippedItem(slot, "hubsnuggetinvis" .. slot:gsub("Cosmetic", ""))
				if item.name then
					player.giveItem(item)
				end
			end
		end
		
		-- Snugget loungeable player rendering
		local loungingIn = player.loungingIn()
		if loungingIn and world.entityType(loungingIn) == "object" and world.getObjectParameter(loungingIn, "sitOrientation") == "lay" then
			local playerImages = world.entityPortrait(self.hubsnuggetEntityId, "full") or {}
			local playerGender = player.gender()
			local sitFlipped = world.getObjectParameter(loungingIn, "direction") == "right" and true
			if world.getObjectParameter(loungingIn, "sitFlipDirection") then
				sitFlipped = not sitFlipped
			end
			local cosmeticItem = player.equippedItem("legsCosmetic")
			local cosmeticItemData = (cosmeticItem and root.itemConfig(cosmeticItem.name)) or {config = {}}
			local renderImages = {}
			for _, imageData in ipairs (playerImages) do
				-- Not going to bother making this configurable since it's path is likely completely hardcoded
				if string.find(imageData.image or "", "/humanoid/hubsnugget/" .. playerGender .. "body.png") then
					imageData.fullbright = true
					table.insert(renderImages, imageData)
				-- Just uses the config since changing the frames parameter doesn't change the image
				elseif cosmeticItemData.config[playerGender.."Frames"] and string.find(imageData.image or "", cosmeticItemData.config[playerGender.."Frames"]) then
					table.insert(renderImages, imageData)
				end
			end
			for _, renderData in ipairs (renderImages) do
				renderData.image = renderData.image:gsub(":idle", ":" .. self.hubsnuggetConfig.layFrame or "sleep") .. ((sitFlipped and "?flipx") or "")
				renderData.position = self.hubsnuggetConfig.layImagePosition or {16, 18}
				localAnimator.addDrawable(renderData, "object+1")
			end
		end
	end
end