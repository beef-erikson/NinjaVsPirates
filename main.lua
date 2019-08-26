-- -----------------------------------------------------------------------------------
-- FILE: main.lua
-- DESCRIPTION: Start the app, declare some globals, and setup the player save file
-- -----------------------------------------------------------------------------------

-- App options
_APPNAME = "Pirates vs Ninjas"
_VERSION = "v1.0.14"
_FONT = "MadeinChina"
_SHOOTUPGRADECOST = 35
_LIVESUPGRADECOST = 100

-- Declare display constants
_CX = display.contentWidth*0.5															-- Center X
_CY = display.contentHeight*0.5															-- Center Y
_CW = display.contentWidth 																-- Width
_CH = display.contentHeight 															-- Height

_T = display.screenOriginY																-- Top
_L = display.screenOriginX																-- Left
_R = display.viewableContentWidth - _L 													-- Right
_B = display.viewableContentHeight - _T 												-- Bottom

-- Hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- Include composer
local composer = require "composer"

-- Include load/save library
loadsave = require("loadsave")

-- Load audio
_BACKGROUNDMUSIC = audio.loadStream("audio/background-music.mp3")
_THROW = audio.loadSound("audio/throw.wav")
_ENEMYHIT = audio.loadSound("audio/enemy-hit.wav")
_PLAYERHIT = audio.loadSound("audio/player-hit.wav")
_GAMEOVER = audio.loadSound("audio/game-over.wav")
_CLICK = audio.loadSound("audio/click.wav")

-- Set up save file
user = loadsave.loadTable("user.json")
if (user == nil) then
	user = {}
	user.kills = 0
	user.money = 100
	user.adCounter = 1
	user.shootlevel = 0
	user.tutorial = false
	user.version = _VERSION
	user.shootlevelmax = 10
	user.liveslevel = 0
	user.liveslevelmax = 10
	user.playsound = true
	loadsave.saveTable(user, "user.json")
end

-- temporary add-in for existing players. version control. add onto this later.
if (user.version ~= _VERSION or user.version == nil) then
	user.adCounter = 1
	user.version = _VERSION
	user.tutorial = false
	user.kills = 0
	loadsave.saveTable(user, "user.json")
end

skins = loadsave.loadTable("skins.json")
if (skins == nil) then
	skins = {}
	loadsave.saveTable(skins, "skins.json")
end

-- you should have a migrate_save function that accepts palyer info and does stuff to upgrade it to current version

composer.gotoScene("scene_menu")