local runtime = 0
 
local function getDeltaTime()
    local temp = system.getTimer()  -- Get current game time in ms
    local dt = (temp-runtime) / (1000/60)  -- 60 fps or 30 fps as base
    runtime = temp  -- Store game time
    return dt
end

-- A box object
local box = display.newRect( 50, 0, 100, 100 )
 
-- Frame update function
local function frameUpdate()
 
   -- Delta Time value
   local dt = getDeltaTime()
 
   -- Move your box, 5 pixels with delta compensation
   box:translate( 0, 5.0*dt )
 
   -- For rotation...
   -- INCORRECT: do not multiply with the entire value!
   -- box.rotation = (box.rotation+1) * dt
   -- CORRECT: only multiply with the changing value:
   box.rotation = box.rotation + (1*dt)
 
   -- Same goes for scaling...
   -- INCORRECT: 1.0 and 0.01 have to be separated, as 1.0 represents the current scale:
   -- box:scale( 1.01*dt, 1.01*dt )
   -- CORRECT: only affect the changing value
   local scale = 1 + (0.01*dt)
   box:scale( scale, scale )
end
 
-- Frame update listener
--Runtime:addEventListener( "enterFrame", frameUpdate )
