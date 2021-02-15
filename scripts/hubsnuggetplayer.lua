local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.hubsnuggetConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetConfig.loungeableFrames = self.hubsnuggetConfig.loungeableFrames or {}
	self.hubsnuggetRace = player.species()
	self.hubsnuggetEntityId = entity.id()
	
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
		if loungingIn then
			local playerImage = world.entityPortrait(self.hubsnuggetEntityId, "full") or {}
			local playerPosition = entity.position()
			if world.entityType(loungingIn) == "object" then
				local sitType = world.getObjectParameter(loungingIn, "sitOrientation")
				local direction = world.getObjectParameter(loungingIn, "direction")
				local gsubString = ":"
				if sitType == "lay" then
					gsubString = gsubString .. self.hubsnuggetConfig.loungeableFrames.lay or "sleep"
				else
					gsubString = gsubString .. self.hubsnuggetConfig.loungeableFrames.sit or "duck"
				end
				for i, imageData in ipairs (playerImage) do
					imageData.image = imageData.image:gsub(":idle", gsubString) .. ((sitFlipped and "") or "?flipx")
					imageData.position = {15.375, 18}
					localAnimator.addDrawable(imageData, "object+1")
				end
			elseif world.entityType(loungingIn) == "vehicle" then
				
			end
		end
	end
end