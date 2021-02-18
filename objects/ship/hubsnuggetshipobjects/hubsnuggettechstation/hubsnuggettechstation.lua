local hubzbInit = init or function() end

local hubzbFirstInit = true

function init()
	if hubzbFirstInit then
		local zbCompat = config.getParameter("zbCompat", {})
		local zbCompatApplied = config.getParameter("zbCompatApplied")
		local zbInstalled = root.itemConfig(zbCompat.detectionItem)
		if zbInstalled then
			if not zbCompatApplied then
				local oldParameters = {}
				for parameter, newData in pairs (zbCompat.configOverrides or {}) do
					oldParameters[parameter] = config.getParameter(parameter)
					object.setConfigParameter(parameter, newData)
				end
				object.setConfigParameter("zbCompatApplied", true)
				object.setConfigParameter("zbCompatOldParameters", oldParameters)
			end
			for _, script in ipairs(zbCompat.scripts or {}) do
				require(script)
			end
		elseif zbCompatApplied then
			local oldParameters = config.getParameter("zbCompatOldParameters", {})
			for parameter, oldData in pairs (oldParameters) do
				object.setConfigParameter(parameter, oldData)
			end
			object.setConfigParameter("zbCompatApplied", false)
			object.setConfigParameter("zbCompatOldParameters", nil)
		end
		hubzbFirstInit = false
		init()
	else
		hubzbInit()
	end
end