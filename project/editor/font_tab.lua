-- Prepare a table for the module
local font_tab = {}


local b = require("bit")

font_tab.sprite = 0


function font_tab.update(e)
    local draw = e.drawing

    draw.clrs()

    -- Sprite editing
    for x = 0, 7 do
        for y = 0, 7 do
            local byte = e.memapi.peek(font_tab.char + e.memapi.map.font_start)
        end
    end

    -- Draw chars
    for x = 0, 7 do
        for y = 0, 16 do
            local idx = (y * 8) + x
            draw.char(x, y, idx)
        end
    end
end


-- Export the module as a table
return font_tab