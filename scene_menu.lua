-- -----------------------------------------------------------------------------------
-- FILE: scene_menu.lua
-- DESCRIPTION: Starts the main menu
-- -----------------------------------------------------------------------------------

local composer = require( "composer" )

local scene = composer.newScene()

local widget = require "widget"
widget.setTheme("widget_theme_ios7")

-- Local forward references
local btn_play, btn_upgrades, btn_sounds
local movePirate, moveNinja

user = loadsave.loadTable("user.json")

-- Switches to scene_game.lua
local function onPlayTouch(event)
    if(event.phase == "ended") then
        audio.play(_CLICK)
        composer.gotoScene("scene_game", "slideLeft")
    end
end

-- Switches to scene_upgrades.lua
local function onUpgradesTouch(event)
    if(event.phase == "ended") then
        audio.play(_CLICK)
        composer.gotoScene("scene_upgrades", "slideUp")
    end
end

-- Toggles sound on and off
local function onSoundsTouch(event)
    if(event.phase == "ended") then
        if(user.playsound == true) then                                                 -- Mute the game
            audio.setVolume(0)
            btn_sounds.alpha = 0.5
            user.playsound = false
        else                                                                            -- Unmute the game
            audio.setVolume(1)
            btn_sounds.alpha = 1
            user.playsound = true
        end
        loadsave.saveTable(user, "user.json")
    end
end

-- -----------------------------------------------------------------------------------
-- Scene creation
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

    local sceneGroup = self.view

    -- Load Graphics
    local background = display.newImageRect(sceneGroup, "images/menuscreen/menu_bg.png", 1425, 950)
    	background.x = _CX; background.y = _CY;

    local backgroundOverlay = display.newImageRect(sceneGroup, "images/menuscreen/menu_bg_overlay.png", 1425, 950)
    	backgroundOverlay.x = _CX; backgroundOverlay.y = _CY;

    local gameTitle = display.newImageRect(sceneGroup, "images/menuscreen/title.png", 508, 210)
        gameTitle.x = _CX; gameTitle.y = _CH * 0.2;

    local myPirate = display.newImageRect(sceneGroup, "images/menuscreen/menu_pirate.png", 209, 358)
        myPirate.x = _L - myPirate.width; myPirate.y = _CH * 0.7; 

    local myNinja = display.newImageRect(sceneGroup, "images/menuscreen/menu_ninja.png", 234, 346)
        myNinja.x = _R + myNinja.width; myNinja.y = _CH * 0.7;

    -- Create some buttons
    local btn_play = widget.newButton {
        width = 426,
        height = 183, 
        defaultFile = "images/menuscreen/btn_play.png", 
        overFile = "images/menuscreen/btn_play_over.png",
        onEvent = onPlayTouch
    }
    btn_play.x = _CX
    btn_play.y = _CY
    sceneGroup:insert(btn_play)

    local btn_upgrades = widget.newButton {
        width = 426,
        height = 183,
        defaultFile = "images/menuscreen/btn_upgrades.png",
        overFile = "images/menuscreen/btn_upgrades_over.png",
        onEvent = onUpgradesTouch
    }
    btn_upgrades.x = _CX
    btn_upgrades.y = btn_play.y + (btn_upgrades.height * 1.25)
    sceneGroup:insert(btn_upgrades)

    btn_sounds = widget.newButton {
        width = 78,
        height = 79,
        defaultFile = "images/menuscreen/btn_music.png",
        overFile = "images/menuscreen/btn_music_over.png",
        onEvent = onSoundsTouch
    }
    btn_sounds.x = _L + 200
    btn_sounds.y = _T + 190
    sceneGroup:insert(btn_sounds)

    -- Version Display (Change version number in main.lua)
    local versionText = display.newText(sceneGroup, _VERSION, 0, 0, _FONT, 50)
        versionText.x = _CX; versionText.y = btn_upgrades.y + (btn_upgrades.height * 0.5 + 25)

    -- Transitions
    local moveNinja = transition.to(myNinja, {x=950, delay = 250})
    local movePirate = transition.to(myPirate, {x=250, delay = 250})

end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        audio.play(_BACKGROUNDMUSIC, {loops=-1, delay=1500})

        -- Kills previous scene to ensure reloading.
        local prevScene = composer.getSceneName("previous")
        if(prevScene) then 
            composer.removeScene(prevScene)
        end
    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen

    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene