-- helpers/Config.lua

Config = {
	Status = 'Preem.',
	SetMode = require('helpers/setmode').SetMode,
	SetQuality = require('helpers/setquality').SetQuality,
	SetSharc = require('helpers/setsharc').SetSharc,
	SetDLSS = require('helpers/setdlss').SetDLSS,
	SetVram = require('helpers/setvram').SetVram,
	SetGraphics = require('helpers/setgraphics').SetGraphics,
	SetAutoQuality = require('helpers/setautoquality').SetAutoQuality,
	SetDaytime = require('helpers/daytimetasks').SetDaytime,
	SaveMenu = require('helpers/savemenu').SaveMenu,
}

return Config
