-- LOVE2D DEBUGGER
-- local lldebugger = require("lldebugger")
-- if arg[2] == "debug" then
--     lldebugger.start()
-- end

local memo = require("engine.memo")


local esc_old = false


-- Handling nil access in a good way
setmetatable(_G, {
    __index = function(table, key)
        error(key .. " doesn't exist")
    end
})

io.stdout:setvbuf("no")


-- Called once at the start of the game
function love.load()
    memo.init({win_scale = 4, vsync = true})
    memo.mimosa.run(
[[
"Hello " a =
"World!" b =
a b + out
]]
)
end


-- Called each frame, continuously
function love.update(dt)
    if memo.tick.update(dt) then
        memo.input.update()

        -- Run game (temporary hard path used)
        if love.keyboard.isDown("escape") and not esc_old then
            if memo.cart.running then
                memo.cart.stop()
                memo.editor.tab = 0
            end
        end

        -- Processing ticks
        if memo.cart.running then memo.cart.tick() else memo.editor.update() end

        -- Draw the ASCII + color buffers to the screen
        memo.drawing.draw_buffer()
        -- Refresh the canvas image with the new image data
        memo.canvas.update()
        -- Historic input
        esc_old = love.keyboard.isDown("escape")
        memo.input.poptext()
    end
end


-- Called each screen refresh, continuously
function love.draw()
    memo.window.display_canvas(memo.canvas)
end


function love.wheelmoved(x, y)
    if y > 0 then memo.input.wheel = 1 elseif
    y < 0 then memo.input.wheel = -1
    end
end


function love.textinput(txt)
    memo.input.text = memo.input.text .. txt
end


-- -- LOVE2D ERROR HANDLING --
-- local love_errorhandler = love.errorhandler

-- function love.errorhandler(msg)
--     if lldebugger then
--         error(msg, 2)
--     else
--         return love_errorhandler(msg)
--     end
-- end