require "/scripts/util.lua"

local hubInit = init or function() end
local hubUpdate = update or function() end
local hubInteract = interact or function() end

function init()
	hubInit()
	
	self.hubsnuggetCosmeticQueryCooldown = config.getParameter("hubsnuggetCosmeticQueryCooldown", 3)
	self.hubsnuggetCosmeticQueryTimer = self.hubsnuggetCosmeticQueryCooldown
	self.hubsnuggetCosmeticQueryRange = config.getParameter("hubsnuggetCosmeticQueryRange", 5)
	self.hubsnuggetSpeciesConfig = root.assetJson("/species/hubsnugget.species")
	self.hubsnuggetCosmeticImageOverrides = config.getParameter("hubsnuggetCosmeticImageOverrides", {})
	self.hubsnuggetBlankCosmetic = config.getParameter("hubsnuggetBlankCosmetic", "/monsters/pets/snugget/hubsnuggetpetblankcosmetic.png")
	self.hubsnuggetEntityId = entity.id()
	
	storage.hubsnuggetCosmeticItem = storage.hubsnuggetCosmeticItem or config.getParameter("hubsnuggetCosmeticItem")
	hubsnuggetRenderCosmetic()
end

function update(dt)
	hubUpdate(dt)
	
	if self.hubsnuggetCosmeticQueryTimer <= 0 then
		hubsnuggetCosmeticQuery()
		self.hubsnuggetCosmeticQueryTimer = self.hubsnuggetCosmeticQueryCooldown
	end
	self.hubsnuggetCosmeticQueryTimer = self.hubsnuggetCosmeticQueryTimer - dt
end

function interact(args)
	if world.time() - self.lastInteract > config.getParameter("interactCooldown", 3.0) and world.entitySpecies(args.sourceId) == "hubsnugget"then
		local text = config.getParameter("hubsnuggetText") or {}
		if #text > 0 then
			monster.say(text[math.random(1, #text)], {playerName = world.entityName(args.sourceId)})
		end
	end
	hubInteract(args)
end

-- Not sure if i can really do the changes to this without completely overwriting it
function setAnchor(entityId)
	if not self.anchorId or self.anchorId == entityId or not world.entityExists(self.anchorId) then
		storage.anchorPosition = world.entityPosition(entityId)
		self.anchorId = entityId
		world.callScriptedEntity(entityId, "setPet", entity.id(), {
			foodLikings = storage.foodLikings,
			knownPlayers = storage.knownPlayers,
			petResources = petResources(),
			seed = monster.seed(),
			hubsnuggetCosmeticItem = storage.hubsnuggetCosmeticItem
		})
		return true
	else
		return false
	end
end

function hubsnuggetCosmeticQuery()
	local position = mcontroller.position()
	local items = world.itemDropQuery(position, self.hubsnuggetCosmeticQueryRange)
	for _, entityId in ipairs (items) do
		local itemName = world.entityName(entityId)
		if self.hubsnuggetSpeciesConfig.allowedCosmetics[itemName] then
			local itemData = world.takeItemDrop(entityId, self.hubsnuggetEntityId)
			local oldItem = storage.hubsnuggetCosmeticItem
			storage.hubsnuggetCosmeticItem = itemData
			world.spawnItem(oldItem, position)
			hubsnuggetRenderCosmetic()
			break
		end
	end
end

function hubsnuggetRenderCosmetic()
	if storage.hubsnuggetCosmeticItem then
		local itemConfig = root.itemConfig(storage.hubsnuggetCosmeticItem.name)
		if self.hubsnuggetCosmeticImageOverrides[storage.hubsnuggetCosmeticItem.name] then
			animator.setPartTag("hubsnuggetCosmetic", "partImage", self.hubsnuggetCosmeticImageOverrides[storage.hubsnuggetCosmeticItem.name])
		else
			local partImage = storage.hubsnuggetCosmeticItem.parameters.maleFrames or itemConfig.config.maleFrames
			if string.sub(partImage, 1, 1) ~= "/" then
				partImage = itemConfig.directory .. partImage
			end
			animator.setPartTag("hubsnuggetCosmetic", "partImage", partImage)
		end
		local directives = storage.hubsnuggetCosmeticItem.parameters.directives or itemConfig.config.directives or ""
		if directives == "" then
			local colorOptionsConfig = storage.hubsnuggetCosmeticItem.parameters.colorOptions or itemConfig.config.colorOptions or {}
			local colorOptions = {}
			for _,color in ipairs(colorOptionsConfig) do
				if type(color) == "string" then
					table.insert(colorOptions, color)
				else
					local colorDirectives = "replace"
					for k, v in pairs (color) do
						colorDirectives = colorDirectives .. ";" .. k .. "=" .. v
					end
					table.insert(colorOptions, colorDirectives)
				end
			end
			if #colorOptions > 0 then
				local colorIndex = storage.hubsnuggetCosmeticItem.parameters.colorIndex or itemConfig.config.colorIndex or 0
				directives = "?" .. util.tableWrap(colorOptions, colorIndex + 1)
			end
		end
		animator.setPartTag("hubsnuggetCosmetic", "directives", directives)
	else	
		animator.setPartTag("hubsnuggetCosmetic", "partImage", self.hubsnuggetBlankCosmetic)
		animator.setPartTag("hubsnuggetCosmetic", "directives", "")
	end
end