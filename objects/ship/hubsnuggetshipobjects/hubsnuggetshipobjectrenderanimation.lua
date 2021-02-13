require "/scripts/vec2.lua"

local shipType

function init()
	script.setUpdateDelta(config.getParameter("animationScriptDelta", 1))
	
	self.animationTimer = 0
	if objectAnimator.direction() == 1 then
		self.direction = ""
	else
		self.direction = "?flipx"
	end
end

function update()
	local dt = script.updateDt()
	local renderData = config.getParameter("renderData")
	if renderData then
		localAnimator.clearDrawables()
		-- Determine which frame the image should be
		local frame
		if renderData.animationCycle and renderData.frames then
			frame = math.floor((self.animationTimer / renderData.animationCycle) * renderData.frames)
			if self.animationTimer == 0 then frame = 0 end

			self.animationTimer = self.animationTimer + dt
			if self.animationTimer > renderData.animationCycle then
				self.animationTimer = 0
			end
		else
			frame = 0
		end
		
		-- Get the gsub data for if it's a door
		local doorState = config.getParameter("doorState")
		if doorState then
			if self.doorState ~= doorState then
				self.doorState = doorState
				frame = 1
			else
				frame = 2
			end
			if self.direction == "" then
				for i, _ in ipairs (renderData.images) do
					renderData.images[i] = renderData.images[i]:gsub("default", doorState .. "Right." .. frame)
				end
			else
				for i, _ in ipairs (renderData.images) do
					renderData.images[i] = renderData.images[i]:gsub("default", doorState .. "Left." .. frame)
				end
			end
		end
		
		-- Render the object
		for i, imageData in ipairs (renderData.images) do
				localAnimator.addDrawable({
					image = imageData.image:gsub("<frame>", frame):gsub("<color>", "default"):gsub("<key>", 1) .. self.direction,
					position = renderData.position,
					fullbright = imageData.fullbright
				}, "object+" .. i)
		end
	end
end