require "/scripts/vec2.lua"

function init()
	initCommonParameters()
end

function initCommonParameters()
	self.energyCost = config.getParameter("energyCost")
	self.transformedMovementParameters = {}
	self.transformedMovementParameters.collisionPoly = config.getParameter("collisionPoly")
	self.basePoly = mcontroller.baseParameters().standingPoly
	self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
	self.size = config.getParameter("size", 1)
	self.positionOffsetMod = config.getParameter("positionOffsetMod", 0)
end

function uninit()
	storePosition()
	deactivate()
end

function update(args)
	restoreStoredPosition()

	if not self.specialLast and args.moves["special1"] then
		attemptActivation()
	end
	self.specialLast = args.moves["special1"]

	if not args.moves["special1"] then
		self.forceTimer = nil
	end

	if self.active then
		mcontroller.controlParameters(self.transformedMovementParameters)
		status.setResourcePercentage("energyRegenBlock", 1.0)

		checkForceDeactivate(args.dt)
	end


	self.lastPosition = mcontroller.position()
end

function attemptActivation()
	if not self.active
			and not tech.parentLounging()
			and not status.statPositive("activeMovementAbilities")
			and status.overConsumeResource("energy", self.energyCost) then

		local pos = transformPosition()
		if pos then
			mcontroller.setPosition(pos)
			activate()
		end
	elseif self.active then
		local pos = restorePosition()
		if pos then
			mcontroller.setPosition(pos)
			deactivate()
		elseif not self.forceTimer then
			animator.playSound("forceDeactivate", -1)
			self.forceTimer = 0
		end
	end
end

function checkForceDeactivate(dt)
	if self.forceTimer then
		self.forceTimer = self.forceTimer + dt

		if self.forceTimer >= self.forceDeactivateTime then
			deactivate()
			self.forceTimer = nil
		else
			attemptActivation()
		end
		return true
	else
		return false
	end
end

function storePosition()
	if self.active then
		storage.restorePosition = restorePosition()

		-- try to restore position. if techs are being switched, this will work and the storage will
		-- be cleared anyway. if the client's disconnecting, this won't work but the storage will remain to
		-- restore the position later in update()
		if storage.restorePosition then
			storage.lastActivePosition = mcontroller.position()
			mcontroller.setPosition(storage.restorePosition)
		end
	end
end

function restoreStoredPosition()
	if storage.restorePosition then
		-- restore position if the player was logged out (in the same planet/universe) with the tech active
		if vec2.mag(vec2.sub(mcontroller.position(), storage.lastActivePosition)) < 1 then
			mcontroller.setPosition(storage.restorePosition)
		end
		storage.lastActivePosition = nil
		storage.restorePosition = nil
	end
end

function positionOffset()
	return minY(self.transformedMovementParameters.collisionPoly) - minY(self.basePoly)
end

function transformPosition(pos)
	pos = pos or mcontroller.position()
	local groundPos = world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, {pos[1], pos[2] - positionOffset()}, 1, self.collisionSet)
	if groundPos then
		return groundPos
	else
		return world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, pos, 1, self.collisionSet)
	end
end

function restorePosition(pos)
	pos = pos or mcontroller.position()
	local groundPos = world.resolvePolyCollision(self.basePoly, {pos[1], pos[2] + positionOffset()}, 1, self.collisionSet)
	if groundPos then
		return groundPos
	else
		return world.resolvePolyCollision(self.basePoly, pos, 1, self.collisionSet)
	end
end

function activate()
	if not self.active then
		animator.playSound("activate")
	end
	local posOffset = {0, positionOffset()}
	posOffset[2] = posOffset[2] - self.positionOffsetMod
	tech.setParentOffset(posOffset)
	tech.setToolUsageSuppressed(true)
	tech.setParentDirectives("?scalenearest=" .. self.size)
	status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
	self.active = true
end

function deactivate()
	if self.active then
		animator.playSound("deactivate")
	end
	animator.stopAllSounds("forceDeactivate")
	tech.setParentOffset({0, 0})
	tech.setToolUsageSuppressed(false)
	tech.setParentDirectives()
	status.clearPersistentEffects("movementAbility")
	self.active = false
end

function minY(poly)
	local lowest = 0
	for _,point in pairs(poly) do
		if point[2] < lowest then
			lowest = point[2]
		end
	end
	return lowest
end
