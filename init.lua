UltraPlus = {
	__VERSION	  = '7.7.1',
	__DESCRIPTION = 'Better Path Tracing, Ray Tracing and Hotfixes for CyberPunk',
	__URL		  = 'https://github.com/sammilucia/cyberpunk-ultra-plus',
	__LICENSE	  = [[
	Ultra Team Proprietary Software License
	Copyright © 2025 Ultra Team. All rights reserved.

	This software, including all code, blueprints, configuration files, runtime logic,
	and documentation (collectively, the "Software"), is the exclusive property of the
	Ultra Team. It is licensed, not sold.

	You are granted limited permission to:
	- Use the Software for personal, non-commercial purposes;
	- Showcase or review the Software in videos, streams, screenshots, or written
	  content (e.g., YouTube, Twitch, blogs, or social media), provided proper
	  attribution to "Ultra+" or "Ultra Team" is included.
	
	You may NOT:
	- Redistribute, sublicense, or republish the Software or any part of it;
	- Modify, reverse engineer, decompile, disassemble, or create derivative works
	  based on the Software;
	- Use the Software, its runtime behavior, configuration methods, and/or derived
	  techniques-including engine modifications via UE4SS, Blueprint logic, and/or CVar
	  manipulation-for any commercial purpose, including integration into published
	  games, patches, developer tools, third-party modifications (including but not
	  limited to game mods), and/or middleware, without explicit written permission;
	- Incorporate any part of the Software into a game and/or toolset intended for
	  distribution, sale, or monetized publication;
	- Remove or obscure any copyright, trademark, or proprietary notices.
	
	These restrictions apply regardless of whether the Software is incorporated verbatim,
	adapted, restructured, functionally reimplemented, or recreated by reference.

	The Software is provided "as is", without warranty of any kind. Ultra Team assumes
	no liability for any damages or losses arising from use of the Software.
	
	For licensing, commercial use, or collaboration inquiries, contact any of the
	@Moderators at https://discord.gg/UltraPlace (direct messages is okay for this
	purpose).
	]]
}

Logger		= require('helpers/Logger')
Var			= require('helpers/Variables')
Config		= require('helpers/config')
Cyberpunk	= require('helpers/Cyberpunk')
GameSession	= require('helpers/psiberx/GameSession')
GameUI		= require('helpers/psiberx/GameUI')
Cron		= require('helpers/psiberx/Cron')
Stats		= {
	fps	= 0,
	t	= 0,
}
local UltraPlusFlag	= 'UltraPlus.Initialized'
local options		= require('helpers/options')
local render		= require('render')

local timer	= {
	paused	= true,
	flash	= false,
}

local GRAPHICS_MENU = {
	{ category = '/graphics/presets',		item = 'ResolutionScaling' },
	{ category = '/graphics/presets',		item = 'DLSS' },
	{ category = '/graphics/presets',		item = 'FSR2' },
	{ category = '/graphics/presets',		item = 'XESS' },
	{ category = '/graphics/performance',	item = 'CrowdDensity' },
	{ category = '/graphics/basic',			item = 'DepthOfField' },
	{ category = '/graphics/basic',			item = 'LensFlares' },
	{ category = '/graphics/basic',			item = 'ChromaticAberration' },
	{ category = '/graphics/basic',			item = 'FilmGrain' },
	{ category = '/graphics/basic',			item = 'MotionBlur' },
}

local GRAPHICS_MENU_INDEX = {}
for _, e in ipairs(GRAPHICS_MENU) do
	GRAPHICS_MENU_INDEX[e.item] = e
end

function ToBoolean(value)
	if value == true or value == false then
		return value
	elseif value == 'true' then
		return true
	else
		return false
	end
end

function ToNative(value)
	if type(value) ~= 'string' then
		return value
	end

	local boolean = ToBoolean(value)
	if boolean ~= nil then
		return boolean
	end

	local number = tonumber(value)
	if number ~= nil then
		return number
	end

	return value
end

local function setStatus()
	if Cyberpunk.NeedsConfirmation() then
		if not Var.settings.autoConfirmMenu then
			Config.Status = 'Click "Apply" in the Cyberpunk Menu'
		else
			if timer.flash then
				Config.Status = 'Close CET to \'apply\' changes...'
			else
				Config.Status = ''
			end
		end
	elseif Var.settings.modeChanged then
		if timer.flash then
			Config.Status = 'Load a save game to fully activate ' .. Var.settings.mode
		else
			Config.Status = ''
		end
	else
		Config.Status = 'Let\'s delta'
	end
end

function DoNextConstraints()
	if Var.settings.mode ~= Var.mode.HYBRID and Var.settings.mode ~= Var.mode.PTNEXT then
		return
	end

	Cyberpunk.SetOption('RayTracing/Reference', 'EnableRIS', true)

	if Var.settings.mode == Var.mode.PTNEXT then
		Var.settings.sharc = Var.sharc.OFF
		Config.SetSharc()
		Var.settings.blackBar = false
	end

	SaveConfig()
end

function ApplyAllSettings()
	Config.SetMode()
	Config.SetQuality()
	Config.SetSharc()
	DoNextConstraints()
	DoMiscFixes()
	DoLightingAdjustments()
	DoHairAdjustments()
end

function SupportsVanilla(mode)
	return mode == Var.mode.RASTER or mode == Var.mode.RTOnly or mode == Var.mode.PT21
end

local function isUltraPlusInitialized()
	local success, flag = pcall(TweakDB.GetFlat, UltraPlusFlag)
	if not success then
		return false
	end
	return flag
end

local function isPlayerInVehicle()
    local player = Game.GetPlayer()
    if not player then
        return false
    end

    -- in a vehicle (driver/passenger/autopilot/quest ride)
    local okVehicle, vehicle = pcall(function()
        return Game['GetMountedVehicle;GameObject'](player)
    end)
    if not (okVehicle and vehicle) then
        return false
    end

    -- 2using the first-person camera (interior view)
    local okCamera, fppComp = pcall(function()
        return player:GetFPPCameraComponent()
    end)
    if not (okCamera and fppComp) then
        return false
    end

    local okActive, isActive = pcall(function()
        return fppComp:IsActive()
    end)

    return okActive and isActive == true
end

local function isPlayerInElevator()
	local player = Game.GetPlayer()
	if not player then
		return false
	end

	local workSpot = Game.GetWorkspotSystem()
	if not workSpot or not workSpot:IsActorInWorkspot(player) then
		-- not in any workspot; clear cached tag
		if Var.state._lastElevatorTag then Var.state._lastElevatorTag = nil end
		return false
	end

	-- try last known-good tag first
	if Var.state._lastElevatorTag then
		local ok, has = pcall(function()
			return workSpot:IsActorInWorkspotTagged(player, CName.new(Var.state._lastElevatorTag))
		end)
		if ok and has then
			return true
		else
			-- cache stale, clear it
			Var.state._lastElevatorTag = nil
		end
	end

	local tags = {
		'elevator','elevator_cab','elevator_cabin','elevator_platform',
		'elevator_car','elevator_cage','elevator_box','elevator_shaft',
		'service_elevator','quest_elevator','lift','lift_cage','lift_platform','lift_cabin'
	}

	for _, tag in ipairs(tags) do
		local ok, has = pcall(function()
			return workSpot:IsActorInWorkspotTagged(player, CName.new(tag))
		end)
		if ok and has then
			Var.state._lastElevatorTag = tag
			print('Elevator match: ' .. tag)
			return true
		end
	end

	return false
end

local function detectDenoiserMode()
	if Cyberpunk.GetOption('/graphics/presets', 'DLSS_D') then
		Var.settings.denoiserMode = Var.denoiserMode.RR
	elseif Cyberpunk.GetOption('RayTracing', 'EnableNRD') then
		Var.settings.denoiserMode = Var.denoiserMode.NRD
	else
		Var.settings.denoiserMode = Var.denoiserMode.NONE
	end
end

local function updateSpatialRadiusForContext()
    if Var.settings.mode ~= Var.mode.PTNEXT and Var.settings.mode ~= Var.mode.HYBRID then
        if Var.state._spatialBoostActive then
			Cyberpunk.SetOption('Editor/RTXDI',   'SpatialSamplingRadius', Var.config.BASE_SPATIAL_DI)
			Cyberpunk.SetOption('Editor/ReSTIRGI','SpatialSamplingRadius', Var.config.BASE_SPATIAL_GI)
            Var.state._spatialBoostActive = false
            Logger.info('SpatialSamplingRadii restored.')
        end
        return
    end

	-- local inTransit = (Var.state._isInElevator) or (Var.state._isInVehicle)

	if Var.state._isInElevator and not Var.state._spatialBoostActive then
		-- Cyberpunk.SetOption('Editor/RTXDI',    'SpatialSamplingRadius', Var.config.BOOSTED_SPATIAL_DI)
		Cyberpunk.SetOption('Editor/ReSTIRGI', 'SpatialSamplingRadius', Var.config.BOOSTED_SPATIAL_GI)
        Var.state._spatialBoostActive = true
        Logger.info('GI SpatialSamplingRadius boosted (vehicle/elevator).')
	elseif not Var.state._isInElevator and Var.state._spatialBoostActive then
		-- Cyberpunk.SetOption('Editor/RTXDI',    'SpatialSamplingRadius', Var.config.BASE_SPATIAL_DI)
		Cyberpunk.SetOption('Editor/ReSTIRGI', 'SpatialSamplingRadius', Var.config.BASE_SPATIAL_GI)
        Var.state._spatialBoostActive = false
        Logger.info('GI SpatialSamplingRadius restored.')
    end
end

local function confirmChanges()
	if not Var.settings.autoConfirmMenu or not Cyberpunk.NeedsConfirmation() or Var.window.open then
		return
	end

	-- confirm graphics menu changes to Cyberpunk causes CTD when CET overlay
	-- is open due to CET bug https://github.com/ocornut/imgui/pull/3761
	Logger.info('Confirming pending graphics menu changes...')
	-- Cyberpunk.Save()
	Cyberpunk.Confirm()
	Logger.info('Done.')

	SaveConfig()
end

function LoadIni(config, set)
	local iniData = {}
	local category

	local file = io.open(config, 'r')
	if not file then
		Logger.info('Failed to open file:', config)
		return
	end

	Logger.info('	(Loading', config .. ')')
	for line in file:lines() do
		line = line:match('^%s*(.-)%s*$') -- trim whitespace

		if line == '' or string.sub(line, 1, 1) == ';' then
			goto continue
		end

		local currentCategory = line:match('%[(.+)%]') -- match category lines
		if currentCategory then
			category          = currentCategory
			iniData[category] = iniData[category] or {}
			goto continue
		end

		local item, value = line:match('([^=]+)%s*=%s*([^;]+)') -- match items and values, ignore comments
		if item and value then
			item = item:match('^%s*(.-)%s*$')
			value = value:match('^%s*(.-)%s*$')
			iniData[category][item] = value
			if set then
				local success, result = pcall(Cyberpunk.SetOption, category, item, value)
				if not success then
					Logger.info('SetOption failed:', result)
				end
			end
		end

		::continue::
	end
	file:close()

	return iniData
end

function LoadConfig()
	-- get game's live settings, then replace with Var.configFile settings (if they exist and are valid)
	local settingsTable = {}
	local settingsCategories = {
		options.tweaks,
		options.ptFeatures,
		options.rasterFeatures,
		options.postProcessFeatures,
		options.miscFeatures,
	}

	for _, category in pairs(settingsCategories) do
		for _, setting in ipairs(category) do
			local currentValue = Cyberpunk.GetOption(setting.category, setting.item)
			settingsTable[setting.item] = { category = setting.category, value = currentValue }
		end
	end

	local iniData = LoadIni(Var.configFile)
	if not iniData then
		Logger.info('LoadIni() returned no data from', Var.configFile)
		return
	end

	Logger.info('Loading user settings...')
	do
		for item, value in pairs(iniData.UltraPlus or {}) do
			local key = item:match('^internal%.(.+)$')
			if key then
				if value == 'true' or value == 'false' then
					Var.settings[key] = ToBoolean(value)
				else
					Var.settings[key] = value
				end
			elseif settingsTable[item] then
				settingsTable[item].value = value
			end
		end
	end

	do
		local uiSection = iniData.UI
		if uiSection then
			Var.ui        = Var.ui or {}
			Var.ui.config = Var.ui.config or {}
			for key, value in pairs(uiSection) do
				local bool = ToBoolean(value)
				if bool ~= nil then Var.ui.config[key] = bool end
			end
		end
	end

	for item, setting in pairs(settingsTable) do
		Cyberpunk.SetOption(setting.category, item, setting.value)
	end

	DoNextConstraints()

	Var.settings.autoQualityEnabled = (Var.settings.quality == Var.quality.AUTO)

	if Var.settings.restoreGraphicsMenuEnabled and iniData['GraphicsMenu'] then
		Logger.info('Restoring Cyberpunk graphics menu settings from last session...')
		for item, raw in pairs(iniData['GraphicsMenu']) do
			local entry = GRAPHICS_MENU_INDEX[item]
			if entry then
				-- leave game settings as strings (expected by Cyberpunk.lua)
				Cyberpunk.SetOption(entry.category, item, raw)
			end
		end

		Logger.info('    (Done)')
	end
end

function SaveConfig()
	local UltraPlus = {}
	local settingsCategories = {
		options.tweaks,
		options.ptFeatures,
		options.rasterFeatures,
		options.postProcessFeatures,
		options.miscFeatures,
	}

	for _, currentCategory in pairs(settingsCategories) do
		for _, currentSetting in pairs(currentCategory) do
			UltraPlus[currentSetting.item] = Cyberpunk.GetOption(currentSetting.category, currentSetting.item)
		end
	end

	UltraPlus['internal.mode']                       = Var.settings.mode
	UltraPlus['internal.quality']                    = Var.settings.quality
	UltraPlus['internal.sharc']                      = Var.settings.sharc
	UltraPlus['internal.vram']                       = Var.settings.vram
	UltraPlus['internal.graphicsMenuOverrides']      = Var.settings.graphicsMenuOverrides
	UltraPlus['internal.showFps']                    = Var.settings.showFps
	UltraPlus['internal.autoQualityEnabled']         = Var.settings.autoQualityEnabled
	UltraPlus['internal.autoQualityTargetFps']       = Var.settings.autoQualityTargetFps
	UltraPlus['internal.console']                    = Var.settings.console
	UltraPlus['internal.hairAdjustments']            = Var.settings.hairAdjustments
	UltraPlus['internal.preemHair']                  = Var.settings.preemHair
	UltraPlus['internal.ptLightingAdjustments']      = Var.settings.ptLightingAdjustments
	UltraPlus['internal.ptLightingMode']             = Var.settings.ptLightingMode
	UltraPlus['internal.increaseBounceLighting']     = Var.settings.increaseBounceLighting	
	UltraPlus['internal.blackBar']                   = Var.settings.blackBar
    UltraPlus['internal.autoConfirmMenu']            = Var.settings.autoConfirmMenu
	UltraPlus['internal.restoreGraphicsMenuEnabled'] = Var.settings.restoreGraphicsMenuEnabled
	UltraPlus['internal.theme']                      = Var.settings.theme
	UltraPlus['internal.disableSharcBlend']          = Var.settings.disableSharcBlend
	UltraPlus['internal.transparencyFix']            = Var.settings.transparencyFix
	UltraPlus['internal.denoiserMode']               = Var.settings.denoiserMode
	UltraPlus['internal.boilingFixBoost']            = Var.settings.boilingFixBoost

	local GraphicsMenu = {}
	for _, enum in ipairs(GRAPHICS_MENU) do
		GraphicsMenu[enum.item] = Cyberpunk.GetOption(enum.category, enum.item)
	end
	
	local UI = {}
	if Var.ui and Var.ui.config then
		for key, value in pairs(Var.ui.config) do
			UI[key] = value
		end
	end
	
	local iniData = {
		UltraPlus	 = UltraPlus,
		GraphicsMenu = GraphicsMenu,
		UI           = UI,
	}

	local iniContent = ''
	for category, settings in pairs(iniData) do
		iniContent = iniContent .. '[' .. category .. ']\n'
		for item, value in pairs(settings) do
			iniContent = iniContent .. item .. ' = ' .. tostring(value) .. '\n'
		end
		iniContent = iniContent .. '\n'
	end

	local file = io.open(Var.configFile, 'w')
	if not file then
		Logger.info('Error opening', Var.configFile, 'for writing')
		return
	end

	file:write(iniContent)
	file:close()

	Logger.info('Saved', Var.configFile)
end

function DoMiscFixes()
	Cyberpunk.SetOption('RayTracing', 'TransparentReflectionEnvironmentBlendFactor', Var.settings.transparencyFix and '0.06' or '1.0')

	if Cyberpunk.GetOption('Visuals', 'MotionBlurScale') == 1.0 then
		Cyberpunk.SetOption('Visuals', 'MotionBlurScale', '0.6')
	end
end

local function doRainPathTracingFix()
	-- enable particle PT integration unless player is outdoors AND it's raining
	if Var.settings.rain and not Var.settings.indoors then
		Logger.info('    (It\'s raining: Enabling separate particle colour)')
		Cyberpunk.SetOption('Rendering', 'DLSSDSeparateParticleColor', true)
	else
		Logger.info('    (It\'s not raining: Disabling separate particle colour)')
		Cyberpunk.SetOption('Rendering', 'DLSSDSeparateParticleColor', false)
	end
end

function DoDenoiserFixes()
	-- deceptively simple function, however engine will fight the changes herein,
	-- so Cyberpunk.SetOption() keeps applying until they stick

	-- select effective mode from dropdown
	local mode = Var.settings.denoiserMode or Var.denoiserMode.RR

	-- force RR off for PT16, don't rely on user to do it
	if Var.settings.mode == Var.mode.PT16 and mode == Var.denoiserMode.RR then
		mode = Var.denoiserMode.NRD
	end

	-- if user or photo mode has changed to NRD
 	if mode == Var.denoiserMode.NRD or Cyberpunk.GetOption('RayTracing', 'EnableNRD') then
		Cyberpunk.SetOption('/graphics/presets', 'DLSS_D', false)
		Cyberpunk.SetOption('Developer/FeatureToggles', 'DLSSD', false)
		Cyberpunk.SetOption('RayTracing', 'EnableNRD', true)

		Cyberpunk.SetOption('Editor/RTXDI', 'EnableGradients', false)
		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Indirect/Common', 'AntiFirefly', true)
		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Direct/Common', 'AntiFirefly', true)
		Cyberpunk.SetOption('Editor/RTXDI', 'BiasCorrectionMode', '2')

	elseif mode == Var.denoiserMode.RR then
		Cyberpunk.SetOption('/graphics/presets', 'DLSS_D', true)
		Cyberpunk.SetOption('Developer/FeatureToggles', 'DLSSD', true)
		Cyberpunk.SetOption('RayTracing', 'EnableNRD', false)

		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Indirect/Common', 'AntiFirefly', false)
		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Direct/Common', 'AntiFirefly', false)

		-- RR quirk: continually disables NRD to prevent codepath activation
		-- (even though NRD CVar shows 'off') causing performance issues
		GameOptions.SetBool('RayTracing', 'EnableNRD', false)		-- direct command to avoid spamming log

		if Var.settings.blackBar then
			Cyberpunk.SetOption('Editor/RTXDI', 'BiasCorrectionMode', '3')
			Cyberpunk.SetOption('Editor/RTXDI', 'PermutationSamplingMode', '2') -- minor fix not required
		else
			Cyberpunk.SetOption('Editor/RTXDI', 'BiasCorrectionMode', '2')
			Cyberpunk.SetOption('Editor/RTXDI', 'PermutationSamplingMode', '3') -- apply minor fix to black bar
		end
	else
		Cyberpunk.SetOption('/graphics/presets', 'DLSS_D', false)
		Cyberpunk.SetOption('Developer/FeatureToggles', 'DLSSD', false)
		Cyberpunk.SetOption('RayTracing', 'EnableNRD', false)

		Cyberpunk.SetOption('Editor/RTXDI', 'EnableGradients', false)
		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Indirect/Common', 'AntiFirefly', false)
		Cyberpunk.SetOption('Editor/Denoising/ReLAX/Direct/Common',   'AntiFirefly', false)
		Cyberpunk.SetOption('Editor/RTXDI', 'BiasCorrectionMode', '2')
	end
end

registerForEvent('onUpdate', function(delta)
	Cron.Update(delta)

	Stats.fps = (Stats.fps * 9 + (1 / delta)) / 10
	Stats.t   = (Stats.t or 0) + delta
end)

function DoHairAdjustments()
	if Var.settings.hairAdjustments and Var.settings.preemHair then
		Logger.info('Enabling PT hair adjustments for Preem Hair')
		LoadIni('config/hair_on-preem.ini', true)
	elseif Var.settings.hairAdjustments and not Var.settings.preemHair then
		Logger.info('Enabling PT hair adjustments for vanilla hair')
		LoadIni('config/hair_on.ini', true)
	else
		Logger.info('Disabling PT hair adjustments')
		LoadIni('config/hair_off.ini', true)
	end
end

function DoLightingAdjustments()
	-- PTNextV2 / PTNextV3 dropdown
	if Var.settings.mode == Var.mode.HYBRID or Var.settings.mode == Var.mode.PTNEXT then
		local sel = Var.settings.ptLightingMode or Var.ptLightingMode.NATURAL

		if sel == Var.ptLightingMode.VANILLA or sel == 'Vanilla' then
			Logger.info('PT Lighting: Vanilla')
			LoadIni('config/ptlighting_off.ini', true)
		elseif sel == Var.ptLightingMode.ORIGINAL or sel == 'PTNext Original' then
			Logger.info('PT Lighting: PTNext Original')
			LoadIni('config/ptlighting_next.ini', true)
		elseif sel == Var.ptLightingMode.BOLD or sel == 'Bold' then
			Logger.info('PT Lighting: Bold')
			LoadIni('config/ptlighting_contrast.ini', true)
		else
			Logger.info('PT Lighting: Natural')
			LoadIni('config/ptlighting_natural.ini', true)
		end

		if Var.settings.increaseBounceLighting then
			Logger.info('    Increasing Bounce Light')
			Cyberpunk.SetOption('RayTracing/Reference', 'DiffuseSkyScale', '2.0')
			Cyberpunk.SetOption('RayTracing/Reference', 'DiffuseGlobalScale', '1.5')
		end

		return
	end

	-- non-PTNext checkbox
	if not Var.settings.ptLightingAdjustments then
		Logger.info('Disabling lighting fixes')
		LoadIni('config/ptlighting_off.ini', true)
		return
	end

	if Var.settings.mode == Var.mode.PT21 then
		Logger.info('Enabling lighting fixes for PT21')
		LoadIni('config/ptlighting_21.ini', true)
	else
		Logger.info('Disabling lighting fixes')
		LoadIni('config/ptlighting_off.ini', true)
	end

	if Var.settings.increaseBounceLighting then
		Logger.info('    Increasing Bounce Light')
		Cyberpunk.SetOption('RayTracing/Reference', 'DiffuseSkyScale', '2.0')
		Cyberpunk.SetOption('RayTracing/Reference', 'DiffuseGlobalScale', '1.5')
	end
end

function EnablePTNext()
	if Var.settings.mode ~= Var.mode.HYBRID and Var.settings.mode ~= Var.mode.PTNEXT then
		return
	end

	Cyberpunk.SetOption('Editor/RTXDI', 'SpatialSamplingRadius', '24.0')
	Cyberpunk.SetOption('Editor/RTXDI', 'NumInitialSamples', '8')
	Cyberpunk.SetOption('Editor/RTXDI', 'SpatialNumSamples', '1')

	Cron.After(1.5, function()
		Config.SetMode()
		Config.SetQuality()

		if Var.settings.autoQualityEnabled then
			Config.SetAutoQuality(Var.settings.autoQualityLevel)
		end
		
		DoNextConstraints()

		Logger.info('    PTNext enabled.')
	end)
end

local function preparePtNext()
	if Var.settings.mode ~= Var.mode.HYBRID and Var.settings.mode ~= Var.mode.PTNEXT then
		return
	end

	Cyberpunk.SetOption('Editor/ReGIR', 'BuildCandidatesCount', '8')
	Cyberpunk.SetOption('Editor/ReGIR', 'ShadingCandidatesCount', '4')
	Cyberpunk.SetOption('Editor/ReGIR', 'LightSlotsCount', '128')

	Cron.After(3.0, function()
		Cyberpunk.SetOption('Editor/RTXDI', 'SpatialSamplingRadius', '24.0')
		Cyberpunk.SetOption('Editor/RTXDI', 'NumInitialSamples', '8')
		Cyberpunk.SetOption('Editor/RTXDI', 'SpatialNumSamples', '1')

		-- PTNextV2 quirk: ReGIRDI off at boot; correct to V2 only.
		if Var.settings.mode == Var.mode.PTNEXT then
			Cyberpunk.SetOption('Editor/ReGIR', 'UseForDI', false)
		end
	end)

	Logger.info('    PTNext ready...')
end

local function initUltraPlus()
	if isUltraPlusInitialized() then
		Logger.info('    (CET reload detected)')
		Logger.info('Reinitializing...')
	else
		Logger.info('Initializing...')
	end

	Logger.debug('Debug mode enabled')

	LoadIni('config/common.ini', true)
	LoadConfig()

	if not Var.settings.denoiserMode then
		detectDenoiserMode()
		Logger.info('    Detected initial PT denoiser mode: ' .. Var.settings.denoiserMode)
	end

	if not SupportsVanilla(Var.settings.mode) and Var.settings.quality == Var.quality.VANILLA then
		Var.settings.quality = Var.quality.MEDIUM
		Var.settings.autoQualityEnabled = (Var.settings.quality == Var.quality.AUTO)
		SaveConfig()
	end

	Logger.info('Applying user settings...')
	ApplyAllSettings()
end

registerForEvent('onInit', function()
	Logger.info('UltraPlus initializing')
	GameSession.Listen(function(state)
		GameSession.PrintState(state)
		timer.paused = GameSession.IsPaused()
		Logger.info('Game paused: ', timer.paused)
	end)

	GameSession.OnResume(function(state)
		timer.paused = false

		EnablePTNext()
	end)

	GameSession.OnLoad(function(state)
		Logger.info('LOAD')
		timer.paused = true

		preparePtNext()
	end)

	GameUI.OnFastTravelStart(function()
		Logger.info('Fast Travel Start')
		timer.paused = true

		preparePtNext()
	end)

	GameUI.OnFastTravelFinish(function()
		Logger.info('Fast Travel Finish')
		timer.paused = false

		EnablePTNext()
	end)

	GameUI.OnPhotoModeOpen(function()
		Logger.info('Photo Mode Opened')
		Var.state._isPhotoMode = true
	end)

	GameUI.OnPhotoModeClose(function()
		Logger.info('Photo Mode Closed')
		Var.state._isPhotoMode = false
	end)

	local firstStart = true
	GameSession.OnStart(function(state)
		timer.paused = false

		if firstStart then
			firstStart = false
		end

		Var.settings.modeChanged = false

		EnablePTNext()
	end)

	Cron.Every(30.0, function()
		if timer.paused then
			return
		end

		Config.SetDaytime(Cyberpunk.GetHour())
	end)

	Cron.Every(1.0, function()
		DoDenoiserFixes()
		confirmChanges()

		if timer.paused then
			return
		end

	    -- Var.state._isInVehicle  = isPlayerInVehicle()
	    -- Var.state._isInElevator = isPlayerInElevator()
	    -- updateSpatialRadiusForContext()

		if not Var.settings.autoQualityEnabled then
			return
		end

		local percentageDifference = (Stats.fps - Var.settings.autoQualityTargetFps + 2) / (Var.settings.autoQualityTargetFps + 2) * 100
		local scale = math.floor(math.abs(percentageDifference) / 10)
		if scale == 0 then
			return
		end
		local direction = (percentageDifference > 0) and 1 or -1

		Var.settings.autoQualityLastLevel = Var.settings.autoQualityLevel
		Var.settings.autoQualityLevel = Var.settings.autoQualityLevel + (direction * scale)

		if Var.settings.autoQualityLevel > 6 then Var.settings.autoQualityLevel = 6 end
		if Var.settings.autoQualityLevel < 1 then Var.settings.autoQualityLevel = 1 end
		if Var.settings.autoQualityLevel == Var.settings.autoQualityLastLevel then
			return
		end

		Config.SetAutoQuality(Var.settings.autoQualityLevel)
	end)

	Cron.Every(0.5, {tick = 0}, function(timerinfo)
		timerinfo.tick = (timerinfo.tick + 1) % 4

		if timerinfo.tick == 0 then
			timer.flash = not timer.flash
			setStatus()
		end

		if timer.paused then
			return
		end
	end)

	Cron.Every(5.0, function() 
		if timer.paused then
			return
		end

		local testRain = Cyberpunk.IsRaining()
		local testIndoors = IsEntityInInteriorArea(GetPlayer())

		if testRain ~= Var.settings.rain or testIndoors ~= Var.settings.indoors then
			Var.settings.rain = testRain
			Var.settings.indoors = testIndoors
			doRainPathTracingFix()
		end
	end)

	initUltraPlus()
end)

registerForEvent('onTweak', function()
	-- called early during engine init
	LoadIni('config/common.ini', true)
	LoadIni('config/traffic.ini', true)
end)

registerForEvent('onOverlayOpen', function()
	Var.window.open = true
end)

registerForEvent('onOverlayClose', function()
	Var.window.open = false
	-- doWindowClose()
end)

registerForEvent('onDraw', function()
	render.renderHud(Stats.fps)

	if not Var.window.open then
		return
	end

	render.renderUI(Stats.fps)
end)
