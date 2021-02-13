require "/scripts/vec2.lua"

local shipLevel
local shipType

function init()
	script.setUpdateDelta(config.getParameter("animationScriptDelta", 1))
end

function update(dt)
	if config.getParameter("backgroundOverlays") and (config.getParameter("shipLevel", 0) ~= shipLevel or config.getParameter("shipType", "default") ~= shipType) then
		localAnimator.clearDrawables()
		local backgroundOverlays = config.getParameter("backgroundOverlays")
		local baseImageOffset = config.getParameter("baseImageOffset", {0, 0})	
		for i, overlay in ipairs (backgroundOverlays) do
			local centerImageOffset = vec2.div(vec2.div(root.imageSize(overlay.image), 2), 8)
			localAnimator.addDrawable({
				image = overlay.image,
				position = vec2.add(vec2.add(vec2.sub({1024, 1024}, baseImageOffset), centerImageOffset), overlay.position or {0,0}),
				fullbright = overlay.fullbright
			}, "backgroundOverlay+" .. i)
		end
		shipLevel = world.getProperty("ship.level", 0)
		shipType = world.getProperty("hubsnuggetShipType", "default")
	end
end