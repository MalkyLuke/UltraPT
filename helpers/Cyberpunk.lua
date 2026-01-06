-- helpers/Cyberpunk.lua

Logger = require('helpers/Logger')
Var = require('helpers/Variables')

local function classify(value)
	value = tostring(value)
	if value == 'true' or value == 'false' then return 'bool' end
	if value:match('^%-?%d+%.%d+$') then return 'float' end
	if value:match('^%-?%d+$') then return 'int' end
	return 'other'
end

local Cyberpunk = {
	SplitOption = function(string)
		-- splits an ini/CVar command into its constituents
		local category, item = string.match(string, '(.-)/([^/]+)$')
		return category, item
	end,

	Get = function(category, item)
		local value = GameOptions.Get(category, item)

		if tostring(value) == 'true' then
			return true
		end

		if tostring(value) == 'false' then
			return false
		end

		if tostring(value):match('^%-?%d+%.%d+$') then -- float
			return tonumber(value)
		end

		if tostring(value):match('^%-?%d+$') then -- integer
			return tonumber(value)
		end

		Logger.info('ERROR: Error getting value for:', category .. '/' .. item, '=', value)
	end,

	GetValue = function(category, item)
		return Game.GetSettingsSystem():GetVar(category, item):GetValue()
	end,

	NeedsConfirmation = function()
		return Game.GetSettingsSystem():NeedsConfirmation()
	end,

	NeedsReload = function()
		return Game.GetSettingsSystem():NeedsLoadLastCheckpoint()
	end,

	Confirm = function()
		Game.GetSettingsSystem():ConfirmChanges()
	end,

	Save = function()
		-- can only be run with CET overlay closed or CTD
		GetSingleton('inkMenuScenario'):GetSystemRequestsHandler():RequestSaveUserSettings()
	end,

	SetValue = function(category, item, bool)
		Game.GetSettingsSystem():GetVar(category, item):SetValue(ToBoolean(bool))
	end,

	GetIndex = function(category, item, index)
		return Game.GetSettingsSystem():GetVar(category, item):GetIndex()
	end,

	SetIndex = function(category, item, index)
		Game.GetSettingsSystem():GetVar(category, item):SetIndex(index)
	end,

	SetBool = function(category, item, bool)
		GameOptions.SetBool(category, item, ToBoolean(bool))
	end,

	SetInt = function(category, item, integer)
		GameOptions.SetInt(category, item, tonumber(integer))
	end,

	SetFloat = function(category, item, float)
		GameOptions.SetFloat(category, item, tonumber(float))
	end,

	GetOption = function(category, item)
		-- selects correct method to use for different settings
		if category == 'internal' then
			return Var.settings[item] == true
		end

		-- graphics (/...) are either bool, or int
		if string.sub(category, 1, 1) == '/' then -- graphics options
			local value = Cyberpunk.GetValue(category, item)
			if classify(value) == 'bool' then
				return value
			else
				return Cyberpunk.GetIndex(category, item) -- int
			end
		end

		-- non-graphics options: return typed value from GameOptions
		return Cyberpunk.Get(category, item)
	end,

	SetOption = function(category, item, value, valueType, force)
		-- sets a live game setting, working out which method to use for different settings
		if value == nil then
			Logger.info('ERROR: Skipping nil value:', category .. '/' .. item, '=', value)
			return
		end

		-- internal pseudo-options live in Var.settings (don’t touch game state)
		if category == 'internal' then
			Var.settings[item] = value
			return
		end

		-- graphics (/...) use either SetValue(bool) or SetIndex(int)
		if string.sub(category, 1, 1) == '/' then
			local kind = classify(value)

			if kind == 'bool' then
				local current = Cyberpunk.GetValue(category, item)				-- boolean
				local target = (tostring(value) == 'true')						-- boolean
				if current ~= target or force then
					Logger.info('Set value for:', category .. '/' .. item, '=', value)
					Cyberpunk.SetValue(category, item, value)					-- SetValue expects a bool-ish input
				end
				return
			elseif kind == 'int' then
				local current	 = Cyberpunk.GetIndex(category, item)				-- integer
				local target = tonumber(value)									-- integer
				if current ~= target or force then
					Logger.info('Set value for:', category .. '/' .. item, '=', value)
					Cyberpunk.SetIndex(category, item, target)
				end
				return
			end
		end

		-- non-graphics: set by kind (or explicit valueType == 'float')
		local kind = classify(value)

		if kind == 'bool' then
			local current = Cyberpunk.Get(category, item)						-- boolean
			local target = (tostring(value) == 'true')							-- boolean
			if current ~= target or force then
				Logger.info('Set value for:', category .. '/' .. item, '=', value)
				Cyberpunk.SetBool(category, item, value)
				if item == 'Clear' then
					Config.SetSharc()
				end
			end
			return
		end

		if kind == 'float' or valueType == 'float' then
			local current = Cyberpunk.Get(category, item)						-- number (float)
			local target = tonumber(value)
			if current ~= target or force then
				Logger.info('Set value for:', category .. '/' .. item, '=', value)
				Cyberpunk.SetFloat(category, item, target)
			end
			return
		end

		if kind == 'int' then
			local current = Cyberpunk.Get(category, item)						-- number (int)
			local target = tonumber(value)
			if current ~= target or force then
				Logger.info('Set value for:', category .. '/' .. item, '=', value)
				Cyberpunk.SetInt(category, item, target)
			end
			return
		end

		Logger.info('ERROR: Couldn\'t set value for:', category .. '/' .. item, '=', value)
	end,

	GetHour = function()
		return Game.GetTimeSystem():GetGameTime():Hours()
	end,

	SetWeather = function(label)
		return Game.GetWeatherSystem():SetWeather(label)
	end,

	GetWeather = function()
		return Game.GetWeatherSystem():GetWeatherState().name
	end,

	IsRaining = function()
		return Game.GetWeatherSystem():GetRainIntensity() > 0 and true or false
	end,
}

return Cyberpunk
