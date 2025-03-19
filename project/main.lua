-- LOVE2D DEBUGGER
-- local lldebugger = require("lldebugger")
-- if arg[2] == "debug" then
--     lldebugger.start()
-- end

local memo = require("engine.memo")

local esc_old = false
local tick_audio = false

io.stdout:setvbuf("no")


-- Called once at the start of the game
function love.load()
    math.randomseed(os.time())
    memo.init({win_scale = 4, vsync = true})
    memo.audio.start()
    local str = "ABC001111222222223333333333333333444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444445555A"
end


-- Called each frame, continuously
function love.update(dt)
    if memo.tick.update(dt) then
        memo.input.update()

        -- Run game (temporary hard path used)
        if love.keyboard.isDown("escape") and not esc_old then
            if memo.cart.running then
                memo.cart.stop()
                -- Prevents the esc from being read by both editor and this
                memo.editor.escdown = true
                memo.editor.tab = memo.editor.ranfrom
                memo.editor.opened()
            end
        end

        -- Processing ticks
        if memo.cart.running then
            memo.cart.tick()
        else
            memo.editor.update()
        end

        -- Play the instructions in the audio buffer
        tick_audio = not tick_audio
        if tick_audio then
            memo.audio.tick()
        end

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