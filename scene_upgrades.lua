-- -----------------------------------------------------------------------------------
-- FILE: scene_upgrades.lua
-- DESCRIPTION : Handles the upgrade display view / buttons / actions
-- -----------------------------------------------------------------------------------

local composer = require( "composer" )

local scene = composer.newScene()

local widget = require "widget"
widget.setTheme("widget_theme_ios7")

user = loadsave.loadTable("user.json")

local btn_upgrade1, btn_upgrade2, btn_menu, sceneTitle, warningMessage                  -- Local forward declares

-- -----------------------------------------------------------------------------------
-- Scene functions
-- -----------------------------------------------------------------------------------

-- Goes back to main menu
local function onMenuTouch(event)
    if(event.phase == "ended") then
        audio.play(_CLICK)
        composer.gotoScene("scene_menu", "slideDown")
    end
end

local function hideWarningMessage()
    warningMessage.alpha = 0
end

-- Upgrades fire rate
local function onUpgrade1Touch(event)
    if(event.phase == "ended") then
        audio.play(_CLICK)
        if(user.money >= (user.shootlevel * _SHOOTUPGRADECOST + _SHOOTUPGRADECOST)) then
            -- Allow player to proceed with upgrade
            if(user.shootlevel >= user.shootlevelmax) then                              -- Stops and sets label if max level
                btn_upgrade1:setLabel("Max Level")                                                            
            else                                                                        -- Proceed with upgrade
                user.money = user.money - (user.shootlevel * _SHOOTUPGRADECOST + _SHOOTUPGRADECOST)

                sceneTitle.text = "Upgrades - $"..user.money

                user.shootlevel = user.shootlevel + 1
                loadsave.saveTable(user, "user.json")
                user = loadsave.loadTable("user.json")

                btn_upgrade1:setLabel("$"..(user.shootlevel * _SHOOTUPGRADECOST + _SHOOTUPGRADECOST).."  Rank "..user.shootlevel)
            end
        else                                                                            -- Otherwise, display the warning message of not enough money
            warningMessage.alpha = 1                                            
            local tmr_hidewarningmessage = timer.performWithDelay(750, hideWarningMessage, 1)
        end
    end
end

-- Upgrades lives
local function onUpgrade2Touch(event)
    if(event.phase == "ended") then
        audio.play(_CLICK)
        if(user.money >= (user.liveslevel * _LIVESUPGRADECOST + _LIVESUPGRADECOST)) then                         
            -- Allow player to proceed with upgrade - has enough money
            if(user.liveslevel >= user.liveslevelmax) then                              -- Stops and sets label if max level
                btn_upgrade2:setLabel("Max Level")
            else                                                                        -- Proceed with upgrade
                user.money = user.money - (user.liveslevel * _LIVESUPGRADECOST + _LIVESUPGRADECOST)

                sceneTitle.text = "Upgrades - $"..user.money

                user.liveslevel = user.liveslevel + 1
                loadsave.saveTable(user, "user.json")
                user = loadsave.loadTable("user.json")

                btn_upgrade2:setLabel("$"..(user.liveslevel * _LIVESUPGRADECOST + _LIVESUPGRADECOST).."  Rank "..user.liveslevel)
            end
        else                                                                            -- Otherwise, display the warning message of not enough money            
            warningMessage.alpha = 1
            local tmr_hidewarningmessage = timer.performWithDelay(750, hideWarningMessage, 1)
        end
    end
end


-- create()
function scene:create( event )

    local sceneGroup = self.view
    
-- -----------------------------------------------------------------------------------
-- Scene Creation
-- -----------------------------------------------------------------------------------
    
    -- Load graphics
    local background = display.newImageRect(sceneGroup, "images/menuscreen/menu_bg.png", 1425, 950)
        background.x = _CX; background.y = _CY
    
    local backgroundOverlay = display.newImageRect(sceneGroup, "images/menuscreen/menu_bg_overlay.png", 1425, 950)
        backgroundOverlay.x = _CX; backgroundOverlay.y = _CY
    
    local banner = display.newImageRect(sceneGroup, "images/menuscreen/banner.png", 1250, 200)
        banner.x = _CX; banner.y = _CH * 0.2

    -- Set Text on graphics
    sceneTitle = display.newText(sceneGroup, "Upgrades - $"..user.money, 0, 0, _FONT, 60)
        sceneTitle.x = _CX; sceneTitle.y = banner.y

    warningMessage = display.newText(sceneGroup, "Not enough money.", 0, 0, _FONT, 52)
        warningMessage.x = _CX; warningMessage.y = sceneTitle.y + (sceneTitle.height * 1)
        warningMessage.alpha = 0

    -- Buttons
    btn_upgrade1 = widget.newButton {
        width = 480,
        height = 183, 
        defaultFile = "images/menuscreen/btn_shoot.png", 
        overFile = "images/menuscreen/btn_shoot_over.png",
        font = _FONT,
        fontSize = 60,
        labelColor = {default={1,1,1},over={0,0,0}},
        labelYOffset = 15,
        label = "$"..(user.shootlevel*_SHOOTUPGRADECOST + _SHOOTUPGRADECOST).."  Rank "..user.shootlevel,
        onEvent = onUpgrade1Touch
    }
    btn_upgrade1.x = _CX - (btn_upgrade1.width * 0.6)
    btn_upgrade1.y = _CY
    sceneGroup:insert(btn_upgrade1)

    btn_upgrade2 = widget.newButton {
        width = 480,
        height = 183, 
        defaultFile = "images/menuscreen/btn_lives.png", 
        overFile = "images/menuscreen/btn_lives_over.png",
        font = _FONT,
        fontSize = 60,
        labelColor = {default={1,1,1},over={0,0,0}},
        labelYOffset = 15,
        label = "$"..(user.liveslevel*_LIVESUPGRADECOST + _LIVESUPGRADECOST).."  Rank "..user.liveslevel,
        onEvent = onUpgrade2Touch
    }
    btn_upgrade2.x = _CX + (btn_upgrade2.width * 0.6)
    btn_upgrade2.y = _CY
    sceneGroup:insert(btn_upgrade2)

    local btn_menu = widget.newButton {
        width = 426,
        height = 183, 
        defaultFile = "images/menuscreen/btn_menu.png", 
        overFile = "images/menuscreen/btn_menu_over.png",
        onEvent = onMenuTouch
    }
    btn_menu.x = _CX
    btn_menu.y = btn_upgrade1.y + 260
    sceneGroup:insert(btn_menu)

    -- These values are in main.lua
    if(user.shootlevel >= user.shootlevelmax) then
        btn_upgrade1:setLabel("Max Level")
    end
    if(user.liveslevel >= user.liveslevelmax) then
        btn_upgrade2:setLabel("Max Level")
    end

end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

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