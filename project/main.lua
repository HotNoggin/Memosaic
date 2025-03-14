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


function love.focus(focus)
    if focus then
        print("Refocused")
        -- HOT RELOADING --
        local change = false
        local editorsave = memo.editor.get_save()
        local path = love.filesystem.getSaveDirectory() .. "/" .. memo.editor.console.cartfile
        if path[#path] == "/" then -- This is a folder
            return
        end
        local diskfile = io.open(path, "r")

        if not diskfile then -- There is no file here
            return
        end

        local disksave = diskfile:read("*a")

        if disksave ~= editorsave then
            print("External changes detected")
            -- Only handle conflict if the editor has its own unsaved changes
            -- Otherwise just load the changes from the disk
            if memo.editor.get_save() ~= memo.editor.cart_at_save then
                print("Queue conflict resolution")
                memo.editor.hotreload = true
            else
                print("No local changes")
                memo.editor.sendcmd("reload")
            end
        else
            print("No external changes")
        end
    else
        print("Unfocused")
        memo.editor.save_at_unfocus = memo.editor.get_save()
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