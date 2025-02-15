-- LOVE2D DEBUGGER --
if arg[2] == "debug" then
    require("lldebugger").start()
end


local window = require("graphics.window")
local input = require("engine.input")
local memapi = require("data.memory")
local tick = require("engine.tick")
local canvas = require("graphics.canvas")
local drawing = require("graphics.drawing")
local cart = require("engine.cart")
local console = require("editor.console")
local editor = require("editor.editor")

local esc_old = false


-- Called once at the start of the game
function love.load()
    print("Memosaic is booting")
    window.init(4, true)
    input.init(window)
    memapi.init()
    drawing.init(canvas, memapi)
    canvas.init(window.WIDTH, window.HEIGHT, drawing, memapi)
    cart.init(input, memapi, drawing, console)
    cart.load("C:/Users/space/Visual Studio/Memosaic/project/carts/hello_world.memo")
    editor.init(window, input, memapi, drawing, canvas)
    print("Memosaic is ready!\n")
end


-- Called each frame, continuously
function love.update(dt)
    if tick.update(dt) then
        input.update()

        -- Run game (temporary hard path used)
        if love.keyboard.isDown("escape") and not esc_old then
            if cart.running then
                cart.stop()
            else
                cart.run()
            end
        end

        -- Processing ticks
        if cart.running then cart.tick() else editor.update() end

        -- Draw the ASCII + color buffers to the screen
        drawing.draw_buffer()
        -- Refresh the canvas image with the new image data
        canvas.update()

        -- Historic input
        esc_old = love.keyboard.isDown("escape")
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