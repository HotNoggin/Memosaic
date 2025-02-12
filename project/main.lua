-- LOVE2D DEBUGGER --
if arg[2] == "debug" then
    require("lldebugger").start()
end



local window = require("graphics.window")
local memapi = require("data.memory")
local tick = require("engine.tick")
local canvas = require("graphics.canvas")
local drawing = require("graphics.drawing")
local memory = {}


-- Called once at the start of the game
function love.load()
    print("Hello! Memosaic is booting.")
    local success = window.init(4, 0)
    if not success then
        error("Love2D window failed to initialize.")
    else
        print("Love2D window successfully initialized.")
    end
    memory = memapi.create_memory()
    drawing.init(canvas)
    canvas.init(window.WIDTH, window.HEIGHT, drawing)
end


-- Called each frame, continuously
function love.update(dt)
    if tick.update(dt) then
        canvas.update()
    end
end


-- Called each screen refresh, continuously
function love.draw()
    window.display_canvas(canvas)
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