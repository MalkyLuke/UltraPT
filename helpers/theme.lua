-- helpers/theme.lua

local defs = {
	ultraplus = {
		name = 'Ultra+',
		color = {
			bg		 = 0xee180808,
			text	 = 0xffffeeee,
			darker   = 0xaa443333,
			dark	 = 0xbb554444,
			medium   = 0xcc665555,
			mediumer = 0xcc887777,
			light	 = 0xccddcccc,
		},
	},

	cybernight = {
		name = 'Cyber Night',
		color = {
			bg		 = 0xee160609,
			text	 = 0xff984fff,
			darker   = 0x444e27a9,
			dark	 = 0x664e27a9,
			medium   = 0x775827a9,
			mediumer = 0xffc34d45,
			light	 = 0xffe1c36c,
		},
	},

	default = {
		name  = 'CET Default',
		color = {
			bg		 = 0xee0f0c0c,
			text	 = 0xffffffff,
			darker   = 0xff492e1d,
			dark	 = 0xff492e1d,
			medium   = 0xff6d4423,
			mediumer = 0xffcb7b38,
			light	 = 0xfffa9642,
		},
	},
}

local order  = { 'ultraplus', 'cybernight', 'default' }

local labels = {}
local index  = {}
for i, k in ipairs(order) do
	labels[i] = defs[k].name
	index[k]  = i
end

local theme = {
	defs 	  = defs,
	order	  = order,
	labels	  = labels,
	index	  = index,
	textScale = 0.88,
	color	  = {},
}

return theme