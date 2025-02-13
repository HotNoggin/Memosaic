-- LOVE2D DEBUGGER --
if arg[2] == "debug" then
    require("lldebugger").start()
end


local window = require("graphics.window")
local memapi = require("data.memory")
local tick = require("engine.tick")
local canvas = require("graphics.canvas")
local drawing = require("graphics.drawing")


-- Called once at the start of the game
function love.load()
    print("Hello! Memosaic is booting.")
    window.init(4, 0)
    memapi.init()
    drawing.init(canvas, memapi)
    canvas.init(window.WIDTH, window.HEIGHT, drawing, memapi)
    print("Memosaic is ready!")
end


-- Called each frame, continuously
function love.update(dt)
    if tick.update(dt) then
        -- Draw a random char at a random position with random colors
        drawing.char(string.char(math.random(0x00, 0xff)), -- Random char
            math.random(0, 15), math.random(0, 15), -- Random position
            math.random(0, 15), math.random(0, 15)) -- Random colors
        -- Draw the ASCII + color buffers to the screen
        drawing.draw_buffer()
        -- Refresh the canvas image with the new image 5data
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