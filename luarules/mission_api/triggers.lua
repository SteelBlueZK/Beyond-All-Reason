local schema = VFS.Include('luarules/mission_api/triggers_schema.lua')
local parameters = schema.Parameters

--[[
	triggerId = {
		type = triggerTypes.TimeElapsed,
		settings = { -- all individual settings, and settings table itself, are optional
			prerequisites = {},
			repeating = false,
			maxRepeats = nil,
			difficulties = {},
			coop = false,
			active = true,
		},
		parameters = {
			gameFrame = 123,
			interval = 300,
		},
		actions = { 'actionId1', 'actionId2' },
	}
]]

local triggers = {}

local function prevalidateTriggers()
	for triggerId, trigger in pairs(triggers) do
		if not trigger.type then
			Spring.Log('triggers.lua', LOG.ERROR, "[Mission API] Trigger missing type: " .. triggerId)
		end

		if not trigger.actions or next(trigger.actions) == nil then
			Spring.Log('triggers.lua', LOG.ERROR, "[Mission API] Trigger has no actions: " .. triggerId)
		end

		for _, parameter in pairs(parameters[trigger.type]) do
			local value = trigger.parameters[parameter.name]
			local type = type(value)

			if value == nil and parameter.required then
				Spring.Log('triggers.lua', LOG.ERROR, "[Mission API] Trigger missing required parameter. Trigger: " .. triggerId .. ", Parameter: " .. parameter.name)
			end

			if value ~= nil and type ~= parameter.type then
				Spring.Log('triggers.lua', LOG.ERROR, "[Mission API] Unexpected parameter type, expected " .. parameter.type .. ", got " .. type .. ". Trigger: " .. triggerId .. ", Parameter: " .. parameter.name)
			end
		end
	end
end

local function preprocessRawTriggers(rawTriggers)
	for triggerId, rawTrigger in pairs(rawTriggers) do
		local settings = rawTrigger.settings or {}
		settings.prerequisites = settings.prerequisites or {}
		settings.repeating = settings.repeating or false
		settings.maxRepeats = settings.maxRepeats or nil
		settings.difficulties = settings.difficulties or nil
		settings.coop = settings.coop or false
		settings.active = settings.active or true

		rawTrigger.settings = settings
		rawTrigger.triggered = false
		rawTrigger.repeatCount = 0

		triggers[triggerId] = table.copy(rawTrigger)
	end

	prevalidateTriggers()
end

local function postvalidateTriggers()
	local actions = GG['MissionAPI'].Actions
	for triggerId, trigger in pairs(triggers) do
		for _, actionId in pairs(trigger.actions) do
			if not actions[actionId] then
				Spring.Log('triggers.lua', LOG.ERROR, "[Mission API] Trigger has action that does not exist. Trigger: " .. triggerId .. ", Action: " .. actionId)
			end
		end
	end
end

local function postprocessTriggers()
	postvalidateTriggers()
end

local function getTriggers()
	return triggers
end

return {
	GetTriggers = getTriggers,
	PreprocessRawTriggers = preprocessRawTriggers,
	PostprocessTriggers = postprocessTriggers,
}
