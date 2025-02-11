-- LOVE2D DEBUGGER --
if arg[2] == "debug" then
    require("lldebugger").start()
end


-- My code goes here


-- LOVE2D ERROR HANDLING --
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end