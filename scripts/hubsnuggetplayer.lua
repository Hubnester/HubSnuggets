local hubInit = init or function() end
local hubUpdate = update or function() end

function init()
	hubInit()
	
	self.hubsnuggetConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetRace = player.species()
end

function update(dt)
	hubUpdate(dt)
	
	-- Improve this eventually
	if self.hubsnuggetRace == "hubsnugget" then
		local slots = { "headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic"}
		for _, slot in ipairs (slots) do
			local item = player.equippedItem(slot) or {}
			if not self.hubsnuggetConfig.allowedCosmetics[item.name] then
				player.setEquippedItem(slot, "hubsnuggetinvis" .. slot:gsub("Cosmetic", ""))
				if item.name then
					player.giveItem(item)
				end
			end
		end
	end
end