-- -----------------------------------------------------------------------------------
-- FILE: scene_game.lua
-- DESCRIPTION: The actual 'game' menu where the player plays the game
-- -----------------------------------------------------------------------------------

local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Local includes / sprite sheets
-- -----------------------------------------------------------------------------------
local appodeal = require( "plugin.appodeal" )

local widget = require "widget" 
widget.setTheme("widget_theme_android_holo_dark")

-- Loads physics for collision detection. Note that no gravity present as not neccessary here
local physics = require "physics" 
physics.start()
physics.setGravity(0,0)

-- Ninja images / animation(s)
local playerSheetData = {width=120, height=175, numFrames=8, sheetContentWidth=960, sheetContentHeight=175}
local playerSheet = graphics.newImageSheet("images/characters/ninja.png", playerSheetData)
local playerSequenceData = {
    {name="shooting", start=1, count=6, time=300, loopCount=1},                         -- Runs animation once. Called by playerShoot()
    {name="hurt",  start=7, count=2, time=200, loopCount=1}                             -- Runs animation once. Called by onCollision() -> showPlayerHit()
}

-- Pirate images / animation(s)
local pirateSheetData = {width=185, height=195, numFrames=8, sheetContentWidth=1480, sheetContentHeight=195}
local pirateSheet1 = graphics.newImageSheet("images/characters/pirate1.png", pirateSheetData)
local pirateSheet2 = graphics.newImageSheet("images/characters/pirate2.png", pirateSheetData)
local pirateSheet3 = graphics.newImageSheet("images/characters/pirate3.png", pirateSheetData)
local pirateSequenceData = {
    {name="running", start=1, count=8, time=575, loopCount=0}                           -- Runs animation indefinitely. Called by sendEnemies()
}

-- Poof images / animation(s)
local poofSheetData = {width=165, height=180, numFrames=5, sheetContentWidth=825, sheetContentHeight=180}
local poofSheet = graphics.newImageSheet("images/characters/poof.png", poofSheetData)
local poofSequenceData = {
    {name="poof", start=1, count=5, time=250, loopCount=1}                              -- Runs animation once. Called by onCollision() -> enemyHit(x,y)
}

-- -----------------------------------------------------------------------------------
-- Local game variables
-- -----------------------------------------------------------------------------------
local debug = true                                                                      -- Change to disable FPS
local runtime = 0                                                                       -- Used in delta time equation

local lane = {}                                                                         -- Creates a table that will hold the four lanes

local player, tmr_playershoot, playerMoney                                              -- Forward declares - player info
local playerShootSpeed = 1250 - (user.shootlevel*100)                                   -- Determines how fast the player will shoot
local playerEarnMoney = 10                                                              -- How much money is earned when a pirate is hit

local lives = {}                                                                        -- Table that will hold the lives object
local livesCount = 1 + (user.liveslevel)                                                -- The number of lives the player has

local bullets = {}                                                                      -- Table that will hold the bullet object
local bulletCounter = 0                                                                 -- Number of bullets shot
local bulletTransition = {}                                                             -- Table to hold bullet transistion
local bulletTransitionCounter = 0                                                       -- Number of bullet transitions made

local enemy = {}                                                                        -- Table that will hold the enemy objects
local enemyCounter = 0                                                                  -- Number of enemies sent
local enemySendSpeed = 75                                                               -- How often to send the enemies in ms
local enemyTravelSpeed = 3000                                                           -- How fast enemies travel across the screen (from left to right in ms)
local enemyIncrementSpeed = 1.5                                                         -- How much to increase the enemy speed
local enemyMaxSendSpeed = 10                                                            -- Max send speed, if this is not set, the enemies could just be one big flood

local poof = {}
local poofCounter = 0

local timeCounter = 0                                                                   -- How much time has passed in the game
local pauseGame = false                                                                 -- Is the game paused?
local pauseBackground, btn_pause, pauseText, pause_returnToMenu, pauseReminder          -- Forward declares - pauses

local onGameOver, gameOverBox, gameoverBackground, btn_returnToMenu                     -- Forward declares - gameover
local theCat                                                                            -- It came back the very next day                              

-- create()
function scene:create( event )

    local sceneGroup = self.view

-- -----------------------------------------------------------------------------------
-- Ad info - currently using appodeal. Call for this at onGameOver()
-- -----------------------------------------------------------------------------------

local appodeal = require( "plugin.appodeal" )
 
local function adListener( event )
 
    if ( event.phase == "init" ) then  -- Successful initialization
        print( event.isError )
    end
end
 
-- Initialize the Appodeal plugin
appodeal.init( adListener, { appKey="1e23674338408367825a183bcbc30898ad5ac18b7cbaf493" } )

-- -----------------------------------------------------------------------------------
-- Game Functions
-- -----------------------------------------------------------------------------------

    local function returnToMenu(event)
        if(event.phase == "ended") then 
            audio.play(_CLICK)
            composer.gotoScene("scene_menu", "slideRight")
            if (debug) then
                fpsText:removeSelf()
            end
        end 
    end

    local function onLaneTouch(event)
        local id = event.target.id                                                      -- Captures the lane.id

        if(event.phase == "began") then                                                 -- Switch lanes to what was clicked
            transition.to(player, {y=lane[id].y, time=125})                            
        end
    end

    local function playerShoot()
        audio.play(_THROW)

        bulletCounter = bulletCounter + 1
        bullets[bulletCounter] = display.newImageRect(sceneGroup, "images/gamescreen/shuriken.png", 64, 64)
        bullets[bulletCounter].x = player.x - (player.width * 0.5)                      -- Sets X of shuriken
        bullets[bulletCounter].y = player.y                                             -- Sets Y of shuriken
        bullets[bulletCounter].id = "bullet"                                            -- Id for collision
        physics.addBody(bullets[bulletCounter])                                         -- Makes bullet into collision object
        bullets[bulletCounter].isSensor = true                                          -- Use when a bullet or if object needs to pass through objects
        -- Moves bullet across screen and destruction at given x value
        bulletTransition[bulletCounter] = transition.to(bullets[bulletCounter], {x=-250, time=2000, rotation=1000, onComplete=function(self)
            if (self~=nil) then display.remove(self); end                               -- Good practice. Check to make sure it's there before destroying
        end})

        player:setSequence("shooting")                                                  -- Loads animation declared above
        player:play()                                                                   -- Plays animation
    end

    local function sendEnemies()
        -- In math terms, Modulo (%) will return the remainder of a division. 10%2 = 0, 11%2 = 1, 14%5 = 4, 19%8 = 3
        timeCounter = timeCounter + 1                                       
        if((timeCounter%enemySendSpeed) == 0) then                                      -- Check to see if time to send enemy
            enemyCounter = enemyCounter + 1                                 
            enemySendSpeed = enemySendSpeed - enemyIncrementSpeed           

            if(enemySendSpeed <= enemyMaxSendSpeed) then                                -- If send speed to faster than max send speed, equal it to max
                enemySendSpeed = enemyMaxSendSpeed
            end

            local temp = math.random(1,3)                                               -- Change if adding more enemies
            
            if(temp == 1) then
                    enemy[enemyCounter] = display.newSprite(pirateSheet1, pirateSequenceData)  
            elseif(temp == 2) then
                    enemy[enemyCounter] = display.newSprite(pirateSheet2, pirateSequenceData)
            else
                    enemy[enemyCounter] = display.newSprite(pirateSheet3, pirateSequenceData)
            end

            enemy[enemyCounter].x = _L - 50                                             -- Enemy starting X
            enemy[enemyCounter].y = lane[math.random(1,#lane)].y                        -- Enemy starting Y
            enemy[enemyCounter].id = "enemy"                                            -- Id for collision
            physics.addBody(enemy[enemyCounter])                                        -- Sets to collidable object
            enemy[enemyCounter].isFixedRotation = true                                  -- Makes certain it doesn't rotate
            sceneGroup:insert(enemy[enemyCounter])                                      -- Inserts into scene

            transition.to(enemy[enemyCounter], {x=_R+50, time=enemyTravelSpeed, onComplete=function(self) 
                if(self~=nil) then display.remove(self); end
            end})

            enemy[enemyCounter]:setSequence("running")                                  -- Load animation declared above
            enemy[enemyCounter]:play()                                                  -- Play animation
        end
    end

    local function playerHit()                                                          -- Called from onCollision() -> showPlayerHit()
        audio.play(_PLAYERHIT)

        player.x = _R - (player.width * 1.2)                                            -- Prevents from being 'pushed off' screen
        player.alpha = 1                                                                -- Used for blinking effect

        lives[livesCount].alpha = 0                                                     -- Takes away 'heart' and life
        livesCount = livesCount - 1                                                                                                 

        if(livesCount <= 0) then                                                        -- GameOver check
            onGameOver()
        end
    end

    local function enemyHit(x,y)                                                        -- X/Y passed from onCollision() -> removeOnEnemyHit(obj1, obj2)
        audio.play(_ENEMYHIT)   

        user.money = user.money + playerEarnMoney                                       -- Sets players money and saves
        playerMoney.text = "$"..user.money
        user.kills = user.kills + 1                                                     -- Sets kill count
        loadsave.saveTable(user, "user.json")

        local poof = display.newSprite(poofSheet, poofSequenceData)                     -- Sets poof sheet and x,y that onCollision passes
            poof.x = x
            poof.y = y
            sceneGroup:insert(poof)
        poof:setSequence("poof")
        poof:play()

        local function removePoof()                                                     -- Removes poof animation after 255 ms
            if(poof ~= nil) then
                display.remove(poof)
            end
        end
        timer.performWithDelay(255, removePoof, 1)
    end

    local function onCollision(event)

        local function removeOnEnemyHit(obj1, obj2)                                     -- Removes 'bullet' and 'enemy'
            display.remove(obj1)
            display.remove(obj2)
            if(obj1.id == "enemy") then                                                 -- Runs enemyHit(x,y) with coords of enemy
                enemyHit(event.object1.x,event.object1.y)                           
            else
                enemyHit(event.object2.x,event.object2.y)
            end
        end

        local function showPlayerHit()                                                  -- Sets hurt animation and fades player
            player:setSequence("hurt")
            player:play()
            player.alpha = 0.5                                                          -- 'Flash' effect
            local tmr_onPlayerHit = timer.performWithDelay(200, playerHit, 1)           -- Calls playerHit() after 100ms
        end

        local function removeOnPlayerHit(obj1,obj2)                                     -- 'enemy' collides with 'player', player stays
            if(obj1~=nil) and (obj1.id == "enemy") then
                display.remove(obj1)
            end
            if(obj2~=nil) and (obj2.id == "enemy") then
                display.remove(obj2)
            end
        end

        -- Since we are using global objects rather than table-based, we must check each id possibility
        if( (event.object1.id == "bullet" and event.object2.id == "enemy") or (event.object1.id == "enemy" and event.object2.id == "bullet") ) then
            removeOnEnemyHit(event.object1, event.object2)
        elseif(event.object1.id == "enemy" and event.object2.id == "player") then
            showPlayerHit()
            removeOnPlayerHit(event.object1, nil)
        elseif(event.object1.id == "player" and event.object2.id == "enemy") then
            showPlayerHit()
            removeOnPlayerHit(nil, event.object2)
        end
    end

    local function onPauseTouch(event)
        if (event.phase == "began") then
            audio.play(_CLICK)
            if (pauseGame == false) then                                                -- Pauses the game
                -- Stop all events/timers
                pauseGame = true 
                physics.pause()

                timer.cancel(tmr_playershoot)
                Runtime:removeEventListener("enterFrame", sendEnemies)
                Runtime:removeEventListener("collision", onCollision)

                transition.pause()

                for i=1,#lane do 
                    lane[i]:removeEventListener("touch", onLaneTouch)
                end
                for i=1,#enemy do 
                    if(enemy[i].isPlaying) then
                        enemy[i]:pause()
                    end
                end

                -- Create background
                pauseBackground = display.newRect(sceneGroup,0,0,_CW*1.25,_CH*1.25)
                    pauseBackground.x = _CX; pauseBackground.y = _CY
                    pauseBackground:setFillColor(0)
                    pauseBackground.alpha = 0.6
                    pauseBackground:addEventListener("touch", onPauseTouch)

                local pauseText = display.newText(sceneGroup, "Game Paused", 0, 0, _FONT, 60)
                    pauseText.x = _CX; pauseText.y = _CY - pauseText.height

                local pauseReminder = display.newText(sceneGroup, "Return To Game", 0, 0, _FONT, 56)
                    pauseReminder.x = btn_pause.x + 275; pauseReminder.y = btn_pause.y

                -- Return to menu button
                pause_returnToMenu = widget.newButton {
                    width = 426,
                    height = 183,
                    defaultFile = "images/gamescreen/btn_menu.png",
                    overFile = "images/gamescreen/btn_menu_over.png",
                    onEvent = returnToMenu
                }             
                pause_returnToMenu.x = _CX
                pause_returnToMenu.y = pauseText.y + pause_returnToMenu.height
                sceneGroup:insert(pause_returnToMenu)

                btn_pause:toFront()                                                     -- Since btn_pause was created before pauseBackground, we need to do this
            else                                                                        -- Unpause the game
                pauseGame = false
                -- Start all events/timers again
                physics.start()
                Runtime:addEventListener("enterFrame", sendEnemies)
                Runtime:addEventListener("collision", onCollision)
                tmr_playershoot = timer.performWithDelay(playerShootSpeed, playerShoot, 0)
                transition.resume()

                for i=1,#lane do
                    lane[i]:addEventListener("touch", onLaneTouch)
                end 
                for i=1,#enemy do 
                    if(enemy[i].isPlaying == false) then
                        enemy[i]:play()
                    end
                end

                -- Remove items created by pausing
                display.remove(pauseBackground)
                display.remove(pauseText)
                display.remove(pause_returnToMenu)
                display.remove(pauseReminder)
            end  
            return true
        end
    end

    -- Global
    function onGameOver()
        audio.play(_GAMEOVER)

        -- Stop all timers
        if(tmr_playershoot) then timer.cancel(tmr_playershoot); end                     -- Stops timer of player shooting
        Runtime:removeEventListener("enterFrame", sendEnemies)                          -- Stops listener of sendEnemies()
        Runtime:removeEventListener("collision", onCollision)                           -- Stops listener of onCollision()

        transition.pause()                                                              -- Stops listener of player moving / switching lanes

        sceneGroup:remove(btn_pause)                                                    -- Removes pause button

        for i=1,#lane do
            lane[i]:removeEventListener("touch", onLaneTouch)                           -- Stops listener of onLaneTouch
        end

        for i=1,#enemy do                                                               -- Removes all enemy instances
            if(enemy[i] ~= nil) then
                display.remove(enemy[i])
            end
        end

        -- Background
        local gameoverBackground = display.newRect(sceneGroup, 0, 0, _CW * 1.25, _CH * 1.25)
            gameoverBackground.x = _CX
            gameoverBackground.y = _CY
            gameoverBackground:setFillColor(0)
            gameoverBackground.alpha = 0.6

        local gameOverBox = display.newImageRect(sceneGroup, "images/gamescreen/title_gameover.png", 924, 154)
            gameOverBox.x = _CX; gameOverBox.y = _CY - gameOverBox.height
        
        -- Button
        local btn_returnToMenu = widget.newButton {
            width = 426,
            height = 183,
            defaultFile = "images/gamescreen/btn_menu.png",
            overFile = "images/gamescreen/btn_menu_over.png",
            onEvent = returnToMenu
        }
        btn_returnToMenu.x = _CX
        btn_returnToMenu.y = gameOverBox.y + btn_returnToMenu.height
        sceneGroup:insert(btn_returnToMenu)

        -- Display ad
        if (user.adCounter == 3) then 
            appodeal.show( "interstitial" )
            user.adCounter = 1
            loadsave.saveTable(user, "user.json")
        else
            local tmp = user.adCounter + 1 
            user.adCounter = tmp
            loadsave.saveTable(user, "user.json")
        end
        
    end


-- -----------------------------------------------------------------------------------
-- Add Graphics and Text
-- -----------------------------------------------------------------------------------

    local background = display.newImageRect(sceneGroup, "images/gamescreen/story-background.png", 1425, 925)
        background.x = _CX
        background.y = _CY

    for i=1,4 do
        lane[i] = display.newImageRect(sceneGroup, "images/gamescreen/lane.png", 1425, 200)
        lane[i].x = _CX
        lane[i].y = (200*i) - 100
        lane[i].id = i
        lane[i]:addEventListener("touch", onLaneTouch)
    end

    for i=1,livesCount do
        lives[i] = display.newImageRect(sceneGroup, "images/gamescreen/heart.png", 50, 51)
        lives[i].x = _L + (i*65) - 25
        lives[i].y = _B - 50
    end

    btn_pause = display.newImageRect(sceneGroup, "images/gamescreen/btn_pause.png", 77, 71)
        btn_pause.x = _L + (btn_pause.width)
        btn_pause.y = _T + (btn_pause.height)
        btn_pause:addEventListener("touch", onPauseTouch)

    -- Create delta-time
    local function getDeltaTime()
        local temp = system.getTimer()                                                  -- Get current game time in ms
        local dt = (temp-runtime) / (1000/60)                                           -- 60 fps or 30 fps as base (Optional divison equation. Take out if SDK changed.)
        runtime = temp                                                                  -- Store game time
        return dt
    end

    -- All movement/rotation/scaling (besides transitions) go here for delta-time
    local function frameUpdate()                                                        -- Frame update function
        local dt = getDeltaTime()                                                       -- Delta Time value
        -- bullets[bulletCounter].rotation = bullets[bulletCounter].rotation + (1*dt)
    end

    -- FPS Display
    local function updateFPS()
        local dt = getDeltaTime()

        local fps = (1-dt)*60
        local round = math.floor(fps+0.5)
        fpsText.text = "FPS: "..round
    end

    if (debug) then
        fpsText = display.newText("", 0, 0, _FONT, 50)                                  -- Sets up FPS display
        fpsText.x = _CX; fpsText.y = 50
        timer.performWithDelay(500, updateFPS, 0)
    end


-- -----------------------------------------------------------------------------------
-- Collision detection and player data
-- -----------------------------------------------------------------------------------

    player = display.newSprite(playerSheet, playerSequenceData)
        player.x = _R - (player.width*1.2)
        player.y = lane[1].y
        player.id = "player"
        sceneGroup:insert(player)
        physics.addBody(player)

    playerWall = display.newRect(sceneGroup, 0, 0, 50, _CH)                             -- Wall off-screen for collision detection and enemy clean-up
        playerWall.x = _R + 75
        playerWall.y = _CY
        playerWall.id = "player"
        physics.addBody(playerWall)

    playerMoney = display.newText(sceneGroup, "$"..user.money, 0, 0, _FONT, 72)
        playerMoney.anchorX = 1                                                         -- Changes anchor point where Corona defines X/Y. Sets anchor to very right of playerMoney string
        playerMoney.x = _R - 5
        playerMoney.y = _B - 50


-- -----------------------------------------------------------------------------------
-- Timers and runtimes
-- -----------------------------------------------------------------------------------

    tmr_playershoot = timer.performWithDelay(playerShootSpeed, playerShoot, 0)
    Runtime:addEventListener("enterFrame", sendEnemies)                                 -- Run sendEnemies per frame as per defined in config.lua (30 FPS currently) 
    Runtime:addEventListener("collision", onCollision)                                  -- Collision detector
    Runtime:addEventListener( "enterFrame", frameUpdate )                               -- Used for determining frame updates

end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

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