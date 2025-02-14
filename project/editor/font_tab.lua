-- Prepare a table for the module
local font_tab = {}


local b = require("bit")

font_tab.char = 0


function font_tab.update(e)
    local draw = e.drawing

    draw.clrs()

    if e.input.lclick_in(0, 0, 8, 8) and not e.input.lheld then
        local x = e.input.mouse.x
        local y = e.input.mouse.y
        local ptr = font_tab.char + x + e.memapi.map.font_start
        local byte = e.memapi.peek(ptr)
        if e.drawing.font_pixel(x, y, font_tab.char) then
            byte = b.band(byte, b.bnot(b.lshift(1, y)))
        else
            byte = b.bor(byte, b.lshift(1, y))
        end
        e.memapi.poke(ptr, byte)
    end

    -- Sprite drawing
    for x = 0, 7 do
        for y = 0, 7 do
            if e.drawing.font_pixel(x, y, font_tab.char) then
                draw.ink(x, y, 0, 0)
            else
                draw.ink(x, y, 10, 10)
            end
        end
    end

    -- Draw chars TOTALLY BROKEN
    for x = 0, 7 do
        for y = 0, 16 do
            local idx = (y * 8) + x
            draw.tile(x + 8, y, idx, 13, 0)
        end
    end
end


-- Export the module as a table
return font_tab