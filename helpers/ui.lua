-- helpers/ui.lua

Logger = require('helpers/Logger')
Var = require('helpers/Variables')
local theme = require('helpers/theme')
local ui = ui or {}
local lastScreenWidth, lastScreenHeight = 0, 0

local function tlen(t)
	if type(t) ~= 'table' then return 0 end
	return #t
end

ui.pushColor = function(colorEnum, themeKey)
	local color = theme.color and theme.color[themeKey]
	if not color then
		return 0
	end
	
	ImGui.PushStyleColor(colorEnum, color)
	return 1
end

ui.popColors = function(number)
	if number and number > 0 then
		ImGui.PopStyleColor(number)
	end
end

local function pushStyle(style, theme)
	if type(style) ~= 'table' then
		return 0
	end

	local pushed = 0
	for colIndex, themeKey in pairs(style) do
		if type(colIndex) == 'number' and type(themeKey) == 'string' then
			local rgba = theme and theme.color and theme.color[themeKey]
			if rgba then
				ImGui.PushStyleColor(colIndex, rgba)
				pushed = pushed + 1
			end
		end
	end
	return pushed
end

ui.separator = function()
	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Spacing()
end

ui.space = function()
	ImGui.Spacing()
end

ui.cursor = function(x, y)
	-- account for window borders
	if x then
		ImGui.SetCursorPosX((x + 8) * Var.window.scale)
	end
	if y then
		ImGui.SetCursorPosY((y * Var.window.scale) + Var.window.startY)
	end
end

ui.width = function(px)
	if not px then
		return
	end
	ImGui.SetNextItemWidth(px * Var.window.scale)
end

ui.sameLine = function(px)
	if px then
		ImGui.SameLine(px * Var.window.scale)
	else
		ImGui.SameLine()
	end
end

ui.text = function(...)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.Text(...)
	ImGui.PopStyleColor()
end

ui.window = function(title, flags, func)
	local pushedWindow = pushStyle({
		[ImGuiCol.WindowBg]				= 'bg',
		[ImGuiCol.ChildBg]				= 'bg',
		[ImGuiCol.Border]				= 'darker',
		[ImGuiCol.TitleBg]				= 'bg',
		[ImGuiCol.TitleBgActive]		= 'bg',
		[ImGuiCol.TitleBgCollapsed]		= 'bg',
		[ImGuiCol.ScrollbarBg]			= 'bg',
		[ImGuiCol.ScrollbarGrab]		= 'medium',
		[ImGuiCol.ScrollbarGrabHovered]	= 'mediumer',
		[ImGuiCol.ScrollbarGrabActive]	= 'mediumer',
	}, theme)

	ImGui.SetNextWindowPos(10, 500, ImGuiCond.FirstUseEver)

	local targetWidth  = 433 * Var.window.scale
	local targetHeight = 604 * Var.window.scale
	local isMainTab    = (Var.window.activeTab == 'Ultra+ Config')
	local beginFlags   = isMainTab and (flags + ImGuiWindowFlags.AlwaysAutoResize) or flags

	local screenWidth, screenHeight = GetDisplayResolution()
	if screenWidth ~= lastScreenWidth or screenHeight ~= lastScreenHeight then
		lastScreenWidth, lastScreenHeight = screenWidth, screenHeight

		local baseScale = Var.window.scale
		if screenWidth > 1000 then
			if     screenWidth > 3800 then baseScale = (screenWidth / 1880) * theme.textScale
			elseif screenWidth > 3000 then baseScale = (screenWidth / 1932) * theme.textScale
			elseif screenWidth > 2000 then baseScale = (screenWidth / 1880) * theme.textScale
			else                           baseScale = (screenWidth / 1900) * theme.textScale
			end
		end

		local aspect = screenWidth / math.max(1, screenHeight)
		local fudge	= (aspect > 2.0) and 1.25 or 1.0

		Var.window.scale = baseScale * fudge
		Var.window.lockHeight = nil			-- auto-resize height next frame only
	end

	ImGui.SetNextWindowSize(targetWidth, targetHeight, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSizeConstraints(targetWidth, 0, targetWidth, math.huge)

	if ImGui.Begin(title, true, beginFlags) then
		ImGui.SetWindowFontScale(theme.textScale)

		if (not isMainTab) and Var.window.lockHeight then
			ImGui.SetWindowSize(targetWidth, Var.window.lockHeight, ImGuiCond.Always)
		end

		func()

		-- first tab, the height adapts to section folds/unfolds
		-- other tabs are locked to first tab height (no resizing)
		if isMainTab then
			Var.window.lockHeight = nil			-- main tab can auto-height every frame
		else
			Var.window.lockHeight = Var.window.lockHeight or ImGui.GetWindowHeight()
		end

		ImGui.End()
		ImGui.PopStyleColor(pushedWindow)
	end
end

ui.tab = function(label, func)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.Tab, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.TabHovered, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.TabActive, theme.color.medium)

	local isOpen = ImGui.BeginTabItem(label)
	ImGui.PopStyleColor(4)

	if isOpen then
		Var.window = Var.window or {}
		Var.window.activeTab = label
		func()
		ImGui.EndTabItem()
	end
end

ui.tabBar = function(func)
	ImGui.PushStyleColor(ImGuiCol.TabActive, theme.color.dark)

	if ImGui.BeginTabBar('Tabs') then
		func()
		ImGui.EndTabBar()
	end

	ImGui.PopStyleColor()
end

ui.button = function(label)
	ImGui.PushStyleColor(ImGuiCol.Button, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, theme.color.dark)
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, theme.color.medium)

	local result = ImGui.Button(label)

	ImGui.PopStyleColor(3)
	return result
end

ui.filter = function(label, text, textBufferSize)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, theme.color.dark)
	ImGui.PushStyleColor(ImGuiCol.FrameBgActive, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.Button, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, theme.color.dark)
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.TextSelectedBg, theme.color.medium)

	local newBuffer = ImGui.InputText(label, text, textBufferSize)

	ImGui.SameLine()
	if ImGui.Button('Clear') then
		newBuffer = ''
	end

	ImGui.PopStyleColor(8)
	return newBuffer
end

ui.inputInt = function(label, ...)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.FrameBgActive, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.Button, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.TextSelectedBg, theme.color.medium)

	local result, changed = ImGui.InputInt(label, ...)

	ImGui.PopStyleColor(8)
	return result, changed
end

ui.inputFloat = function(label, value)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.FrameBgActive, theme.color.medium)
	ImGui.PushStyleColor(ImGuiCol.TextSelectedBg, theme.color.medium)

	local result, changed = ImGui.InputFloat(label, value)

	ImGui.PopStyleColor(5)
	return result, changed
end

ui.header = function(text, id, defaultOpen)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.Header, theme.color.dark)
	ImGui.PushStyleColor(ImGuiCol.HeaderHovered, theme.color.dark)
	ImGui.PushStyleColor(ImGuiCol.HeaderActive, theme.color.dark)

	Var.ui		  = Var.ui or {}
	Var.ui.config = Var.ui.config or {}

	local key = id or text

	local saved = Var.ui.config[key]
	if saved == nil then
		saved = (defaultOpen ~= false)
	end

	ImGui.SetNextItemOpen(saved, ImGuiCond.Appearing)

	local windowLabel = id and (text .. '###' .. id) or text

	local open = ImGui.CollapsingHeader(windowLabel)

	ImGui.PopStyleColor(4)

	if open ~= saved then
		Var.ui.config[key] = open
		Var.window = Var.window or {}
		Var.window.lockHeight = nil			-- auto-resize height next frame only
		if SaveConfig then pcall(SaveConfig) end
	end

	return open
end

ui.radio = function(label, isActive)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.CheckMark, theme.color.light)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, theme.color.medium)

	local result = ImGui.RadioButton(label, isActive)

	ImGui.PopStyleColor(4)
	return result
end

ui.checkbox = function(label, value)
	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, theme.color.darker)
	ImGui.PushStyleColor(ImGuiCol.CheckMark, theme.color.light)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, theme.color.medium)

	local result, toggled = ImGui.Checkbox(label, value)

	ImGui.PopStyleColor(4)
	return result, toggled
end

function ui.combo(id, cur, items, width, style)
	local n = tlen(items)
	if n == 0 then
		if width then ImGui.SetNextItemWidth(width) end
		ImGui.BeginDisabled(true)
		ImGui.Combo(id, cur or 0, {'�'}, 1)
		ImGui.EndDisabled()
		return cur or 0, false
	end

	if width then ImGui.SetNextItemWidth(width) end

	local pushed = pushStyle(style, theme)
	local new, changed = ImGui.Combo(id, cur or 0, items, n)

	if pushed > 0 then ImGui.PopStyleColor(pushed) end
	return new, changed
end

ui.tooltip = function(text, ignore)
	if Var.settings.tooltips or ignore then
		if ImGui.IsItemHovered() and text ~= '' then
			ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)
			ImGui.PushStyleColor(ImGuiCol.PopupBg, theme.color.bg)
			ImGui.PushStyleColor(ImGuiCol.Border, theme.color.darker)

			ImGui.BeginTooltip()
			ImGui.PushTextWrapPos(650)
			ImGui.TextWrapped(text)
			ImGui.PopTextWrapPos()
			ImGui.EndTooltip()

			ImGui.PopStyleColor(3)
		end
	end
end

ui.info = function(text, inverted)
	inverted = inverted == nil and false or inverted   

	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 12.0)
	ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 2.0, 2.0)

	if inverted then
		ImGui.PushStyleColor(ImGuiCol.Button, theme.color.bg)
		ImGui.PushStyleColor(ImGuiCol.ButtonHovered, theme.color.bg)

		local currentY = ImGui.GetCursorPosY()
		ImGui.SetCursorPosY(currentY + (2 * Var.window.scale))
	else
		ImGui.PushStyleColor(ImGuiCol.Button, theme.color.dark)
		ImGui.PushStyleColor(ImGuiCol.ButtonHovered, theme.color.dark)
	end

	ImGui.PushStyleColor(ImGuiCol.Text, theme.color.text)

	local buttonSize = 20 * Var.window.scale
	ImGui.PushStyleVar(ImGuiStyleVar.ButtonTextAlign, 0.55, 0.5)

	local result = ImGui.Button('i##Info' .. tostring(text), buttonSize, buttonSize)
	ImGui.PopStyleVar()

	ui.tooltip(text)

	ImGui.PopStyleColor(4)
	ImGui.PopStyleVar(2)
end

return ui
