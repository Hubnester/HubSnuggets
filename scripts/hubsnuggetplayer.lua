local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.hubsnuggetSpeciesConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetEntityId = entity.id()
	self.hubsnuggetRace = player.species()
	self.hubsnuggetGender = player.gender()
	
	message.setHandler("hubsnuggetIsLounging", player.isLounging)
	
	hubsnuggetCosmeticsInit()
	hubsnuggetRecipeUnlocks()
end

function update(dt)
	hubUpdate(dt)
	
	hubsnuggetCosmeticsUpdate(dt)
	hubsnuggetLoungingRender(dt)
end

----------------------------------------------------------------------------------------------------------
-------------------------------------------- Cosmetics System --------------------------------------------
----------------------------------------------------------------------------------------------------------

function hubsnuggetCosmeticsInit()
	self.hubsnuggetSpeciesConfig.allowedCosmetics = self.hubsnuggetSpeciesConfig.allowedCosmetics or {}

	if self.hubsnuggetRace == "hubsnugget" and not status.statusProperty("hubsnuggetAlreadyCreated") then
		local slots = {"chest", "legs"}
		for _, slot in ipairs (slots) do
			local item = player.equippedItem(slot) or {}
			if self.hubsnuggetSpeciesConfig.allowedCosmetics[item.name] then
				player.setEquippedItem(slot .. "Cosmetic", item)
				player.setEquippedItem(slot, nil)
			end
		end
		status.setStatusProperty("hubsnuggetAlreadyCreated", true)
	end
end

function hubsnuggetCosmeticsUpdate(dt)
	if self.hubsnuggetRace == "hubsnugget" then
		-- Improve this eventually (maybe change the allowed cosmetics thing to a parameter in the item instead of using a table in the species file)
		local slots = {"headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic" }
		for _, slot in ipairs (slots) do
			local item = player.equippedItem(slot) or {}
			if not self.hubsnuggetSpeciesConfig.allowedCosmetics[item.name] then
				player.setEquippedItem(slot, "hubsnuggetinvis" .. slot:gsub("Cosmetic", ""))
				if item.name then
					player.giveItem(item)
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------
-------------------------------------------- Lounging Render ---------------------------------------------
----------------------------------------------------------------------------------------------------------

function hubsnuggetLoungingRender(dt)
	if self.hubsnuggetRace == "hubsnugget" then
		local loungingIn = player.loungingIn()
		if loungingIn and world.entityType(loungingIn) == "object" and world.getObjectParameter(loungingIn, "sitOrientation") == "lay" then
			local playerImages = world.entityPortrait(self.hubsnuggetEntityId, "full") or {}
			local sitFlipped = world.getObjectParameter(loungingIn, "direction") == "right" and true
			if world.getObjectParameter(loungingIn, "sitFlipDirection") then
				sitFlipped = not sitFlipped
			end
			local cosmeticItem = player.equippedItem("legsCosmetic")
			local cosmeticItemData = (cosmeticItem and root.itemConfig(cosmeticItem.name)) or {config = {}}
			local renderImages = {}
			for _, imageData in ipairs (playerImages) do
				-- Not going to bother making this configurable since it's path is likely completely hardcoded
				if string.find(imageData.image or "", "/humanoid/hubsnugget/" .. self.hubsnuggetGender .. "body.png") then
					imageData.fullbright = true
					table.insert(renderImages, imageData)
				-- Just uses the config since changing the frames parameter doesn't change the image
				elseif cosmeticItemData.config[self.hubsnuggetGender .. "Frames"] and string.find(imageData.image or "", cosmeticItemData.config[self.hubsnuggetGender .. "Frames"]) then
					table.insert(renderImages, imageData)
				end
			end
			for _, renderData in ipairs (renderImages) do
				renderData.image = renderData.image:gsub(":idle", ":" .. self.hubsnuggetSpeciesConfig.layFrame or "sleep") .. ((sitFlipped and "?flipx") or "")
				renderData.position = self.hubsnuggetSpeciesConfig.layImagePosition or {16, 18}
				localAnimator.addDrawable(renderData, "object+1")
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------
------------------------------------------ Recipe Unlock System ------------------------------------------
----------------------------------------------------------------------------------------------------------
function hubsnuggetRecipeUnlocks()
	local unlocks = root.assetJson("/hubsnugget.config").unlocks or {}
	local hasFu = root.itemConfig(unlocks.fuDetectionItem or "fu_precursorspawner")
	if not hasFu then
		for _, unlockData in ipairs (unlocks.defaultRacial or {}) do
			player.giveBlueprint(unlockData)
		end
		for _, treeData in pairs (unlocks.researchUnlocks) do
			for _, nodeData in pairs (treeData) do
				-- Add conditional check
				if not nodeData.raceLocked or self.hubsnuggetRace == "hubsnugget" then
					for _, unlock in ipairs (nodeData.unlocks or {}) do
						player.giveBlueprint(unlock)
					end
				end
			end
		end
	else
		local researched = status.statusProperty("zb_researchtree_researched", {}) or {}
		for tree, treeData in pairs (unlocks.researchUnlocks) do
			researched[tree] = researched[tree] or "0~~~"
			for node, nodeData in pairs (treeData) do
				if nodeData.defaultUnlock and self.hubsnuggetRace == "hubsnugget" and not string.find(researched[tree], node) then
					researched[tree] = researched[tree] .. node .. ","
					status.setStatusProperty("zb_researchtree_researched", researched)
				end
				if string.find(researched[tree], node) then
					for _, unlock in ipairs (nodeData.unlocks or {}) do
						player.giveBlueprint(unlock)
					end
				end
			end
		end
	end
end