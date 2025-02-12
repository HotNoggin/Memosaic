-- LOVE2D DEBUGGER --
if arg[2] == "debug" then
    require("lldebugger").start()
end


-- Called once at the start of the game
function love.load()
    print("Hello! Memosaic is booting.")
    local window = require("graphics.window")
    local success = window.init(4)
    if not success then
        error("Love2D window failed to initialize.")
    else
        print("Love2D window successfully initialized.")
    end
end


-- Called each frame, continuously
function love.update(dt)
    
end


-- Called each screen refresh, continuously
function love.draw()

end


-- LOVE2D ERROR HANDLING --
local love_errorhandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return love_errorhandler(msg)
    end
end