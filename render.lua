-- render.lua

Logger = require('helpers/Logger')
Var = require('helpers/Variables')
Config = require('helpers/config')
Cyberpunk = require('helpers/Cyberpunk')
local theme = require('helpers/theme')

Stats = {
	fps = 0,
}
local options = require('helpers/options')
local ui = require('helpers/ui')
local render = {}
local FPS_UPDATE_INTERVAL = 0.05
local lastFpsUpdate = -1
local cachedFpsText = 'Real FPS: --'
local cachedAQText = ''
local lastAQLevel = nil
local hudFlags = ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoMove
	+ ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.AlwaysAutoResize
	+ ImGuiWindowFlags.NoFocusOnAppearing + ImGuiWindowFlags.NoBringToFrontOnFocus
	+ ImGuiWindowFlags.NoMouseInputs + ImGuiWindowFlags.NoBackground
local comboStyle = {
	[ImGuiCol.Text]			  = 'text',
	[ImGuiCol.Button]		  = 'dark',
	[ImGuiCol.ButtonHovered]  = 'medium',
	[ImGuiCol.ButtonActive]	  = 'medium',
	[ImGuiCol.FrameBg]		  = 'darker',
	[ImGuiCol.FrameBgHovered] = 'dark',
	[ImGuiCol.FrameBgActive]  = 'medium',
	[ImGuiCol.PopupBg]		  = 'bg',
	[ImGuiCol.Border]		  = 'darker',
	[ImGuiCol.Header]		  = 'dark',
	[ImGuiCol.HeaderHovered]  = 'medium',
	[ImGuiCol.HeaderActive]	  = 'medium',
	[ImGuiCol.TextSelectedBg] = 'medium',
}

local function strip_backticks(text)
	return text and text:gsub('`', '') or text
end

local function themeIndexOf(key)
	return theme.index[key] or 1
end

local function qualityOrderFor(mode)
	if SupportsVanilla(mode) then
		return { 'VANILLA', 'FAST', 'MEDIUM', 'HIGH', 'INSANE', 'AUTO' }
	else
		return { 'FAST', 'MEDIUM', 'HIGH', 'INSANE', 'AUTO' }
	end
end

local function renderMainTab()
	ui.text(Config.Status)
	ui.sameLine()
	local modeOrder = { 'RASTER', 'RTOnly', 'RT_PT', 'PT16', 'PT20', 'PT21', 'PTNEXT', 'HYBRID' }
	local modeTooltip = {
		RASTER	= 'Configures normal raster, with optimisations and fixes.',
		RTOnly	= 'Configures normal ray tracing, with optimisations and fixes.',
		RT_PT	= 'Normal raytracing with path traced bounce lighting. Leave Path Tracing '..
				  'DISABLED in graphics options for this to work correctly.\n\n'..
				  'RT+PT is an excellent choice for lower end PCs which can\'t run full path '..
				  'tracing.\n\n'..
				  'NOTE: Requires NRD (disable Ray Reconstruction).',
		PT16	= 'PT16 is the path tracing method of Cyberpunk 1.63. Requires NRD (disable Ray '..
				  'Reconstruction).\n\n'..
				  'PT16 is lower detail, but is extremely fast and very consistent. It\'s '..
				  'great for playthroughs on lower-end PCs.',
		PT20	= 'PT20 is the path tracing method from Cyberpunk 2.0.\n\nPT20 is very fast '..
				  'at low quality (Fast, Medium) but becomes very expensive at higher qualities.',
		PT21	= 'PT21 is the path tracing method introduced in Cyberpunk 2.10.\n\n'..
				  'PT21 has good performance and is consistent for playthroughs, but is '..
				  'generally obsoleted by PTNextV3.',
		PTNEXT	= 'PTNextV2 is an unreleased, more advanced path tracing method using ReGIRGI '..
				  'for global illumination, and ReGIRDI direct illumination (lights).\n\n'..
				  'NOTE: SHaRC is broken with PTNextV2 and is forced off.',
		HYBRID	= 'PTNextV3 is an unreleased, more advanced path tracing method using ReGIRGI '..
				  'for global illumination, and RTXDI direct illumination (lights).',
	}
	ui.space()
	if ui.header('Rendering Mode', 'section.rendering_mode') then
		ui.sameLine()
		ui.info(
			'Select your desired rendering mode (hover over modes for details):\n\n'..
			'NOTE: Some modes do not support SHaRC (SHaRC controls are disabled)',
			true)
		local oldMode = Var.settings.mode

		for _, key in ipairs(modeOrder) do
			local value		 = Var.mode[key]
			local isSelected = (oldMode == value)

			local changed	 = ui.radio(value, isSelected)
			local reselected = (not changed) and ImGui.IsItemClicked(0) and isSelected

			if changed then
				Var.settings.mode = value
				Var.settings.modeChanged = (oldMode ~= value)

				if not SupportsVanilla(Var.settings.mode) and Var.settings.quality == Var.quality.VANILLA then
					Var.settings.quality = Var.quality.MEDIUM
					Var.settings.autoQualityEnabled = (Var.settings.quality == Var.quality.AUTO)
					Config.SetQuality()
					SaveConfig()
				end

				SaveConfig()
				ApplyAllSettings()

			elseif reselected and (key == 'HYBRID' or key == 'PTNEXT') then EnablePTNext() end

			ui.tooltip(modeTooltip[key] or '')
			if key ~= 'RT_PT' then ui.sameLine() end
		end
	end

	local qualityOrder = qualityOrderFor(Var.settings.mode)

	ui.space()
	if ui.header('Quality Level', 'section.quality') then
		ui.sameLine()
		ui.info(
			'Select your desired quality level (affects detail, performance, and noise):\n\n'..
			'- Vanilla: Settings are the same (or close as possible) to the unmodded game\n'..
			'- Fast: As fast as possible, while still maintaining image stability\n'..
			'- Medium: Still fast, but with the highest return quality improvements\n'..
			'- High: \'I can handle it\', but still balanced for higher-end cards\n'..
			'- Insane: I don\'t care, I want the best!\n\n'..
			'- Auto: Give me the best possible quality at my FPS target (set below)\n\n'..
			'NOTE: Auto Quality takes full control of SHaRC (so disables SHaRC controls).',
			true)
		for _, key in ipairs(qualityOrder) do
			local value = Var.quality[key]
			if ui.radio(value .. '##Quality', Var.settings.quality == value) then
				Var.settings.quality = value
				Config.SetQuality()

				if Var.settings.quality == Var.quality.AUTO then
					Var.settings.autoQualityEnabled = true
				else
					Var.settings.autoQualityEnabled = false
				end

				SaveConfig()
			end

			ui.sameLine()
		end
	end

	local sharcOrder = { 'OFF', 'CACHE', 'VANILLA', 'FAST', 'MEDIUM', 'HIGH', 'INSANE' }

	ui.space()
	local isDisabled =
		(Var.settings.mode == Var.mode.RASTER) or
		(Var.settings.mode == Var.mode.RTOnly) or
		(Var.settings.mode == Var.mode.RT_PT)  or
		(Var.settings.mode == Var.mode.PT16)   or
		(Var.settings.mode == Var.mode.PTNEXT) or
		Var.settings.autoQualityEnabled

	if ui.header('SHaRC Lighting Cache Quality', 'section.sharc') then
		ui.sameLine()
		ui.info(
			'SHaRC caches large blobs of colour from traced rays, speeding up path tracing and adding additional bounce lighting. '..
			'Rays are drawn on the SHaRC colored background (instead of a black background) giving the denoiser less work to do.\n\n'..
			'- Off [AMD Pink Tracing]: Disables SHaRC to work around the AMD bug.\n'..
			'- Off [Cache Only]: SHaRC is enabled as a performance improvement, but with no additional bounce detail.\n\n'..
			'- Fast: Adds 1 bounce of detail at 30% resolution.\n'..
			'- Med: Adds 1-2 bounces at 50% resolution\n'..
			'- High: Adds 2-3 bounces at 75% resolution.\n'..
			'- Insane: Adds 3-4 bounces at 75% resolution.\n\n'..
			'NOTE: Auto Quality takes full control of SHaRC (SHaRC controls are disabled).',
			true)
		if isDisabled then
			ImGui.BeginDisabled(true)
		end

		if Var.settings.mode == Var.mode.PTNEXT and Var.settings.sharc ~= Var.sharc.OFF then
			Var.settings.sharc = Var.sharc.OFF
			Config.SetSharc()
			SaveConfig()
		end

		for i, key in ipairs(sharcOrder) do
			local value = Var.sharc[key]
			if ui.radio(value .. '##Sharc', Var.settings.sharc == value) then
				Var.settings.sharc = value

				Config.SetSharc()
				SaveConfig()
			end
			if (i < #sharcOrder) and (key ~= 'CACHE') then ui.sameLine() end
		end

		if isDisabled then
			ImGui.EndDisabled()
		end
	end

	local vramOrder = { 'OFF', '4/6/8', '10/12', '16', '20/24/32', 'Auto' }

	ui.space()
	if ui.header('VRAM Gigabiggies', 'section.vram') then
		ui.sameLine()
		ui.info(
			'Ultra+ will optimise asset streaming based on VRAM.\n\n'..
			'NOTE 1: This is not exact, we make assumptions about your PC based on the '..
			'setting you choose. Try HIGHER or LOWER than your actual VRAM until '..
			'streaming is smooth.\n\n'..
			'NOTE 2: If you run out of VRAM (especially with texture mods) this setting '..
			'will not magically fix it. For 12GB or less VRAM, lower Texture Quality to '..
			'\'Medium\' in the main menu (accessible only before loading a game).',
			true)
		for i, key in ipairs(vramOrder) do
			local value = Var.vram[key] or key
			if ui.radio(value .. '##GB', Var.settings.vram == value) then
				Var.settings.vram = value

				Config.SetVram(Var.settings.vram)
				SaveConfig()
			end
			if i < #vramOrder then
				ui.sameLine()
			end
		end
	end

	ui.space()
	if ui.header('Path Tracing Tweaks', 'section.tweaks') then
		do
			ui.text('PT Denoiser')
			ui.sameLine(88)

			local labels = {
				Var.denoiserMode.RR,
				Var.denoiserMode.NRD,
				Var.denoiserMode.NONE,
			}

			local current   = Var.settings.denoiserMode or Var.denoiserMode.RR
			local curIndex  = 0
			for i, label in ipairs(labels) do
				if current == label then
					curIndex = i - 1
					break
				end
			end

			local width = (Var.window.intSize + 12) * Var.window.scale
			local newIndex, comboChanged =
				ui.combo('##pt_denoiser_combo', curIndex, labels, width, comboStyle)

			if comboChanged then
				Var.settings.denoiserMode = labels[newIndex + 1] or Var.denoiserMode.RR
				SaveConfig()
				DoDenoiserFixes()
			end

			ui.sameLine()
			ui.info(
				'Select which denoiser to use for path tracing:\n\n'..
				'- Ray Reconstruction: DLSS Ray Reconstruction (DLSS_D + DLSSD, NRD off)\n'..
				'- NRD: NVIDIA ReLAX/NRD (DLSSD off, NRD on)\n'..
				'- No Denoiser: All denoisers off for raw PT rays (debug/tuning)'
			)
		end

		for _, setting in pairs(options.tweaks) do
			setting.value = Cyberpunk.GetOption(setting.category, setting.item)
			local changed
			local isDisabled =
				(setting.item == 'DLSS_D') and
				Var.state._isPhotoMode
			if isDisabled then
				ImGui.BeginDisabled(true)
			end
			setting.value, changed = ui.checkbox(setting.name, setting.value)
			if isDisabled then
				ImGui.EndDisabled()
			end
			ui.sameLine()
			ui.info(setting.tooltip)
			if changed then
				Cyberpunk.SetOption(setting.category, setting.item, setting.value)
				SaveConfig()
			end
		end

		do
			local increaseBounceLighting	= Var.settings.increaseBounceLighting
			local bounceLightingChanged		= false

			if Var.settings.mode == Var.mode.PTNEXT or Var.settings.mode == Var.mode.HYBRID then
				-- PTNext dropdown
				ui.text('PT Lighting')
				ui.sameLine(88)

				local labels = {
					Var.ptLightingMode.VANILLA,
					Var.ptLightingMode.ORIGINAL,
					Var.ptLightingMode.NATURAL,
					Var.ptLightingMode.BOLD,
				}

				local current	= Var.settings.ptLightingMode or Var.ptLightingMode.NATURAL
				local curIndex	= 0
				for i, label in ipairs(labels) do
					if current == label then
						curIndex = i - 1
						break
					end
				end

				local width = (Var.window.intSize + 12) * Var.window.scale
				local newIndex, comboChanged = ui.combo('##pt_lighting_combo', curIndex, labels, width, comboStyle)
				if comboChanged then
					Var.settings.ptLightingMode = labels[newIndex + 1] or Var.ptLightingMode.NATURAL
					SaveConfig()
					DoLightingAdjustments()
				end
				ui.sameLine()
				ui.info(
					'Adjusts the balance of sun, sky, indoor and street lights, emissives, shadows, '..
					'and bounce lighting for all path tracing modes. Different settings will look '..
					'better or worse depending on your LUT, screen brightness, and whether SHaRC is '..
					'on or off.\n\n'..
					'In some scenes, the difference is big, in others, it\'s barely noticable.\n\n'..
					'There is NO \'correct\' answer, choose the setting you prefer (and that suits all '..
					'your other settings).'
				)

				ui.sameLine(250)
				increaseBounceLighting, bounceLightingChanged = ui.checkbox('More Bounce Light', Var.settings.increaseBounceLighting)
				ui.sameLine()
				ui.info(
					'\'More Bounce Light\' is another way to increase brightness of shadows '..
					'(versus e.g. Env Tuner). If the current LUT has dark shadows, try enabling '..
					'this setting. (It can take a few seconds to change, best to compare by taking '..
					'screenshots.)'
				)
			else
				-- non-PTNext checkbox
				local lightingEnabled, changed = ui.checkbox('Enable PT Lighting Fixes', Var.settings.ptLightingAdjustments)

				ui.sameLine()
				ui.info(
					'When enabled, adjusts path tracing lighting for PT21. '..
					'Direct lights, global illumination, sun, bounce lighting should look better '..
					'with PT21 when enabled.'
				)
				ui.sameLine(250)
				increaseBounceLighting, bounceLightingChanged = ui.checkbox('Increase Bounce Light', Var.settings.increaseBounceLighting)

				ui.sameLine()
				ui.info(
					'\'More Bounce Light\' is another way to increase brightness of shadows '..
					'(versus e.g. Env Tuner). If the current LUT has dark shadows, try enabling '..
					'this setting. (It can take a few seconds to change, best to compare by taking '..
					'screenshots.)'
				)

				if changed then
					Var.settings.ptLightingAdjustments = lightingEnabled
					SaveConfig()
					DoLightingAdjustments()
				end
			end

			if bounceLightingChanged then
				Var.settings.increaseBounceLighting = increaseBounceLighting
				SaveConfig()
				DoLightingAdjustments()
			end
		end

		do
			local hairEnabled, changed = ui.checkbox('Enable PT Hair Fixes', Var.settings.hairAdjustments)

			ui.sameLine()
			ui.info(
				'Adjusts hair to look more realistic with path traced lighting.\n\nNOTE: '..
				'If Preem Hair is installed, also check \'Preem Hair Support\' to the right.'
			)
			if changed then
				Var.settings.hairAdjustments = hairEnabled
				DoHairAdjustments()
				SaveConfig()
			end
		end

		do
			ui.sameLine(250)
			local preemHair, changed = ui.checkbox('Preem Hair Support', Var.settings.preemHair)

			if changed then
				Var.settings.preemHair = preemHair

				if preemHair and not Var.settings.hairAdjustments then
					Var.settings.hairAdjustments = true
				end

				DoHairAdjustments()
				SaveConfig()
			end
		end
		
		do
			local isDisabled =
				(Var.settings.mode ~= Var.mode.PTNEXT
					and Var.settings.mode ~= Var.mode.HYBRID
					and Var.settings.mode ~= Var.mode.PT21
					and Var.settings.mode ~= Var.mode.PT20
					and Var.settings.mode ~= Var.mode.PT16)

			if isDisabled then
				ImGui.BeginDisabled(true)
			end

			local changed
			Var.settings.boilingFixBoost, changed = ui.checkbox(
				'Boost Boiling Fixes',
				Var.settings.boilingFixBoost
			)

			if isDisabled then
				ImGui.EndDisabled()
			end

			ui.sameLine()
			ui.info(
				'Boiling noise is large moving blobs of color (like boiling water - hence the name), '..
				'especially in darker areas with just a few lights, or when you move the camera quickly.\n\n'..
				'If you experience boiling or PT noise, first try changing to Ray Reconstruction to preset '..
				'J or K. If that doesn\'t fix it, enable this checkbox to fix remaining noise, at a small '..
				'cost of slightly softer fine detail (probably only visible by comparing with screenshots.'
			)

			if changed then
				SaveConfig()
				Config.SetMode()
			end
		end

		do
			local isDisabled =
				(Var.settings.sharc == Var.sharc.CACHE)   or
				(Var.settings.mode  == Var.mode.PT16)     or
				(Var.settings.sharc == Var.sharc.VANILLA) or
				(Var.settings.mode  == Var.mode.PTNEXT)
			if Var.settings.autoQualityEnabled and not Var.settings.disableSharcBlend then
				Var.settings.disableSharcBlend = true
				SaveConfig()
				Config.SetSharc()
			end
			if isDisabled or Var.settings.autoQualityEnabled then
				ImGui.BeginDisabled(true)
			end
			local changed
			Var.settings.disableSharcBlend, changed = ui.checkbox(
				'Disable SHaRC Frame Blending (Recommended)',
				Var.settings.disableSharcBlend
			)
			if changed then
				SaveConfig()
				Config.SetSharc()
			end
			if isDisabled or Var.settings.autoQualityEnabled then
				ImGui.EndDisabled()
			end
			ui.sameLine()
			ui.info(
				'Checked (recommended): SHaRC image from the prior-frame is not blended '..
				'with the current frame (for maximum image stability).\n\n'..
				'Unchecked (game default): SHaRC blends 25% of the previous frame with '..
				'the current frame.\n\n'..
				'(Other SHaRC parameters follow your selected SHaRC Quality above.)'
			)
		end

		do
			local enabled, changed = ui.checkbox('Enable Glass Transparency Fix', Var.settings.transparencyFix)

			ui.sameLine()
			ui.info(
				'Enable ONLY if glass appears white. Glass should be fixed in Cyberpunk '..
				'2.31, however some people have reported it\'s still white.\n\n'..
				'(Recommended to keep disabled unless you actually have the problem.)'
			)
			if changed then
				Var.settings.transparencyFix = enabled
				DoMiscFixes()
				SaveConfig()
			end
		end

		do
			local blackBarDisabled = (Var.settings.mode == Var.mode.PTNEXT)
			if blackBarDisabled and Var.settings.blackBar then
				Var.settings.blackBar = false
				SaveConfig()
			end
			if blackBarDisabled then
				ImGui.BeginDisabled(true)
			end
			local blackBar, changed = ui.checkbox('Enable Left Screen Black Bar Fix', Var.settings.blackBar)
			if blackBarDisabled then
				ImGui.EndDisabled()
			end
			ui.sameLine()
			ui.info(
				'Due to a game bug, a black bar appears on the left of the screen, '..
				'causing ghosting when turning left. (You\'re not an ambiturner.)\n\n'..
				'Enabling this checkbox fixes the issue by disabling RTXDI debiasing '..
				'at the expense of some detail.'
			)
			if changed then
				Var.settings.blackBar = blackBar
				SaveConfig()
			end
		end
	end

	ui.space()
	if ui.header('Configuration', 'section.config') then
		local isDisabled = not Var.settings.autoQualityEnabled
		local changed
		ui.text('FPS Target')
		ui.sameLine()
		ui.width(Var.window.intSize)

		if isDisabled then
			ImGui.BeginDisabled()
		end
		Var.settings.autoQualityTargetFps, changed = ui.inputInt('##FpsTarget', tonumber(Var.settings.autoQualityTargetFps), 1)
		if isDisabled then
			ImGui.EndDisabled()
		end
		if changed then
			SaveConfig()
		end
		ui.sameLine()
		ui.info(
			'When Auto Quality is enabled, Ultra+ will adjust Quality in real-time to '..
			'maintain your FPS target.\n\n'..
			'To set an FPS Target, choose your desired real FPS.'
		)

		ui.sameLine(250)
		Var.settings.showFps, changed = ui.checkbox('Show FPS Overlay', Var.settings.showFps)
		if changed then
			SaveConfig()
		end

		Var.settings.restoreGraphicsMenuEnabled, changed = ui.checkbox('Restore Graphics Menu Settings on Startup', Var.settings.restoreGraphicsMenuEnabled)
		if changed then
			SaveConfig()
		end

		ui.separator()

		Var.settings.restoreGraphicsMenuEnabled, changed = ui.checkbox('Restore Graphics Menu Settings on Startup', Var.settings.restoreGraphicsMenuEnabled)
		if changed then
			SaveConfig()
		end
		local autoConfirmChanged
		Var.settings.autoConfirmMenu, autoConfirmChanged = ui.checkbox('Enable Auto-Apply Cyberpunk Menu Changes', Var.settings.autoConfirmMenu)
		ui.sameLine()
		ui.info(
			'When enabled, Ultra+ will automatically click Apply for pending Cyberpunk '..
			'Menu changes. Disable to confirm manually in-game.'
		)
		if autoConfirmChanged then
			SaveConfig()
		end

		ui.separator()

		Var.settings.console, changed = ui.checkbox('Enable Console Output', Var.settings.console)
		if changed then
			SaveConfig()
		end

		ui.sameLine(250)
		Var.settings.tooltips, changed = ui.checkbox('Enable Tooltips', Var.settings.tooltips)
		if changed then
			SaveConfig()
		end

		ui.separator()

		ImGui.SetCursorPosY(ImGui.GetCursorPosY() + (3 * Var.window.scale))
		ui.text('Theme')
		ui.sameLine(250)
		local cur0 = themeIndexOf(Var.settings.theme) - 1
		local width = (Var.window.intSize + 70) * Var.window.scale
		ImGui.SetCursorPosY(ImGui.GetCursorPosY() - (3 * Var.window.scale))
		local new0, changed = ui.combo('##cfg_theme_combo', cur0, theme.labels, width, comboStyle)
		if changed then
			Var.settings.theme = theme.order[new0 + 1]
			SaveConfig()
		end
	end
end

local function renderSetting(setting, inputType, width)
	setting.value = Cyberpunk.GetOption(setting.category, setting.item)

	ui.width(width)
	local changed

	if inputType == 'Checkbox' then
		setting.value, changed = ui.checkbox(setting.name, setting.value)
	elseif inputType == 'InputInt' then
		setting.value, changed = ui.inputInt(setting.name, setting.value)
	elseif inputType == 'InputFloat' then
		setting.value, changed = ui.inputFloat(setting.name, tonumber(setting.value))
	end

	ui.tooltip(setting.tooltip)

	if changed then
		if inputType == 'InputFloat' then
			Cyberpunk.SetOption(setting.category, setting.item, setting.value, 'float')
		else
			Cyberpunk.SetOption(setting.category, setting.item, setting.value)
		end
		SaveConfig()
	end
end

local function renderFeaturesTab()
	local settingGroups = {
		{ options.ptFeatures,		   'Path Tracing', 'Checkbox', 'section.features.pt' },
		{ options.rasterFeatures,	   'Raster',	   'Checkbox', 'section.features.raster' },
		{ options.postProcessFeatures, 'Post Process', 'Checkbox', 'section.features.post' },
		{ options.miscFeatures,		   'Misc',		   'Checkbox', 'section.features.misc' },
	}

	for _, group in ipairs(settingGroups) do
		local settings, heading, inputType, id = table.unpack(group)

		if ui.header(heading, id) then
			if type(settings) == 'table' then
				for _, setting in pairs(settings) do
					renderSetting(setting, inputType)
				end
			else
				Logger.info("ERROR: 'settings' is not a table for group " .. heading)
			end
		end
	end
end

local function renderDebugTab()
	ui.space()
	ui.text('Filter by:')
	ui.sameLine()
	ui.width(120)

	local before = Var.window.filterText or ''
	local raw = ui.filter('##Filter', before, 100)
	local new = strip_backticks(raw or '')
	if new ~= before then
		Var.window.filterText = new
		SaveConfig()
	end

	ui.separator()

	ImGui.BeginChild('DebugScrollRegion', 0, 0, false, ImGuiWindowFlags.AlwaysVerticalScrollbar)

	local settingGroups = {
		{ options.rtxDi, 'Checkbox' },
		{ options.rtxGi, 'Checkbox' },
		{ options.reGir, 'Checkbox' },
		{ options.reLax, 'Checkbox' },
		{ options.reBlur, 'Checkbox' },
		{ options.nrd, 'Checkbox' },
		{ options.rtOptions, 'Checkbox' },
		{ options.sharc, 'Checkbox' },
		{ options.rtInt, 'InputInt', Var.window.intSize },
		{ options.rtFloat, 'InputFloat', Var.window.floatSize },
	}

	for _, group in ipairs(settingGroups) do
		local settings, inputType, width = table.unpack(group)
		if type(settings) == 'table' then
			local hasVisibleItems = false
			for _, setting in pairs(settings) do
				if Var.window.filterText == '' or string.find(string.lower(setting.name), string.lower(Var.window.filterText)) then
					if not hasVisibleItems then hasVisibleItems = true end
					renderSetting(setting, inputType, width)
				end
			end
			if hasVisibleItems then
				ui.separator()
			end
		else
			Logger.info("ERROR: 'settings' is not a table for input type: " .. tostring(inputType))
		end
	end

	ImGui.EndChild()
end

local function renderTabs()
	ui.tabBar(function()
		ui.tab('Ultra+ Config', renderMainTab)
		ui.tab('Rendering Features', renderFeaturesTab)
		ui.tab('Debug', renderDebugTab)
	end)
end

local function renderFps()
	if Var.settings.showFps or (Stats.fps == 0) then
		return
	end

	local fpsText
	if Stats.fps < 100 then
		fpsText = string.format('Real FPS:     %.0f', Stats.fps) -- lazy makeshift round function
	else
		fpsText = string.format('Real FPS:   %.0f', Stats.fps)
	end

	ImGui.SetCursorPos(388, 43)
	ui.text(fpsText)
end

local function renderQuality()
	if Var.settings.showFps or not Var.settings.autoQualityEnabled then
		return
	end

	local level = tonumber(Var.settings.autoQualityLevel) or 1
	local percentage = math.floor((level / 6) * 100)

	ImGui.SetCursorPos(358, 73)
	if percentage < 100 then
		ui.text(('Auto Quality:   %d%%'):format(percentage))
	else
		ui.text(('Auto Quality: %d%%'):format(percentage))
	end
end

render.renderUI = function(fps)
	Stats.fps = fps

	local windowFlags =
		ImGuiWindowFlags.NoResize +
		ImGuiWindowFlags.NoScrollbar +
		ImGuiWindowFlags.NoScrollWithMouse

	local sel = theme.defs[Var.settings.theme]
	theme.color = (sel and sel.color) or {}

	ui.window('Ultra+ v'..UltraPlus.__VERSION..'###UltraPlus', windowFlags, function()
		renderTabs()
		renderFps()
		renderQuality()
	end)
end

function render.renderHud(fps)
	if not Var.settings.showFps or Var.state._isPhotoMode or (fps == 0) then
		return
	end

	if (Stats.t or 0) - lastFpsUpdate >= FPS_UPDATE_INTERVAL then
		cachedFpsText = string.format('Real FPS: %.0f', fps)
		lastFpsUpdate = Stats.t or 0

		if Var.settings.autoQualityEnabled then
			local level = tonumber(Var.settings.autoQualityLevel) or 1
			if level ~= lastAQLevel then
				local pct = math.floor((level / 6) * 100)
				cachedAQText = string.format('Auto Quality: %d%%', pct)
				lastAQLevel = level
			end
		end
	end

	ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)

	ImGui.SetNextWindowPos(0, 0, ImGuiCond.Always)
	ImGui.SetNextWindowBgAlpha(0.0)

	if ImGui.Begin('UltraPlus_HUD', true, hudFlags) then

		ImGui.SetWindowFontScale(theme.textScale)
		ImGui.TextUnformatted(cachedFpsText)

		if Var.settings.autoQualityEnabled then
			ImGui.TextUnformatted(cachedAQText)
		end
	end

	ImGui.End()
	ImGui.PopStyleVar()
end

return render
