-- setsharc.lua

Logger = require('helpers/Logger')
Var = require('helpers/Variables')
Config = {}
Cyberpunk = require('helpers/Cyberpunk')

local function applyHistoryMode()
	if not Var.settings.disableSharcBlend then
		Cyberpunk.SetOption('Editor/SHARC', 'HistoryReset', '5')
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrameBiasAllowance', '0.25')
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrame', true)
	else
		Cyberpunk.SetOption('Editor/SHARC', 'HistoryReset', '1')
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrameBiasAllowance', '1.0')
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrame', false)
	end
end

function Config.SetSharc()
	if Var.settings.sharc == Var.sharc.OFF or Var.settings.mode == Var.mode.RT_PT then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', false)
		return
	end

	if Var.settings.sharc == Var.sharc.CACHE or Var.settings.mode == Var.mode.PT16 then
		-- leave SHaRC enabled but set to no bounces; performance hack
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrame', false)
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrameBiasAllowance', '1.0')
		Cyberpunk.SetOption('Editor/SHARC', 'HistoryReset', '0')
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '7')
		Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '0')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '30.0')
		return
	end

	if Var.settings.sharc == Var.sharc.VANILLA then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', false)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrame', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UsePrevFrameBiasAllowance', '0.25')
		Cyberpunk.SetOption('Editor/SHARC', 'HistoryReset', '15')
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '5')
		Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '4')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '50.0')
		return
	end

	if Var.settings.sharc == Var.sharc.FAST then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '6')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '30.0')

		if Var.settings.mode == Var.mode.PT20 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '1')
		elseif Var.settings.mode == Var.mode.PT21 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '1')
		elseif Var.settings.mode == Var.mode.HYBRID then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '2')
		end
		applyHistoryMode()
		return
	end

	if Var.settings.sharc == Var.sharc.MEDIUM then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '5')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '50.0')
		
		if Var.settings.mode == Var.mode.PT20 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '1')
		elseif Var.settings.mode == Var.mode.PT21 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '1')
		elseif Var.settings.mode == Var.mode.HYBRID then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '2')
		end
		applyHistoryMode()
		return
	end

	if Var.settings.sharc == Var.sharc.HIGH then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '5')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '70.0')

		if Var.settings.mode == Var.mode.PT20 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '1')
		elseif Var.settings.mode == Var.mode.PT21 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '2')
		elseif Var.settings.mode == Var.mode.HYBRID then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '3')
		end
		applyHistoryMode()
		return
	end

	if Var.settings.sharc == Var.sharc.INSANE then
		Cyberpunk.SetOption('Editor/SHARC', 'Enable', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIAtPrimary', true)
		Cyberpunk.SetOption('Editor/SHARC', 'UseRTXDIWithAlbedo', true)
		Cyberpunk.SetOption('Editor/SHARC', 'DownscaleFactor', '5')
		Cyberpunk.SetOption('Editor/SHARC', 'SceneScale', '80.0')

		if Var.settings.mode == Var.mode.PT20 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '2')
		elseif Var.settings.mode == Var.mode.PT21 then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '3')
		elseif Var.settings.mode == Var.mode.HYBRID then
			Cyberpunk.SetOption('Editor/SHARC', 'Bounces', '4')
		end
		applyHistoryMode()
		return
	end
end

return Config
