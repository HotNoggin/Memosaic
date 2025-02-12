-- Prepare a table for the module
local tick = {}

tick.FPS = 60
tick.time = 0
tick.tick_duration = 1/tick.FPS


-- Return true if enough time has passed since the last tick
function tick.update(dt)
    tick.time = tick.time + dt
    if tick.time >= tick.tick_duration then
        tick.time = 0
        return true
    end
    return false
end

-- Export the module as a table
return tick