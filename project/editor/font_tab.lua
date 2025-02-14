-- Prepare a table for the module
local font_tab = {}


local b = require("bit")


font_tab.char = 0
font_tab.pen = false


function font_tab.update(e)
    local draw = e.drawing

    draw.clrs()

    local m_x = e.input.mouse.x
    local m_y = e.input.mouse.y

    -- Sprite editing
    if e.input.lclick_in(0, 0, 8, 8) then
        if not e.input.lheld then
            font_tab.pen = e.drawing.font_pixel(m_x, m_y, font_tab.char)
        end

        local ptr = (font_tab.char * 8) + m_x + e.memapi.map.font_start
        local byte = e.memapi.peek(ptr)
        if font_tab.pen then
            byte = b.band(byte, b.bnot(b.lshift(1, m_y)))
        else
            byte = b.bor(byte, b.lshift(1, m_y))
        end
        e.memapi.poke(ptr, byte)
    end

    -- Sprite select
    if e.input.lclick_in(8, 0, 8, 16) and not e.input.lheld then
        local idx = m_y * 8 + m_x - 8
        font_tab.char = idx
    end

    -- Sprite drawing
    for x = 0, 7 do
        for y = 0, 7 do
            if e.drawing.font_pixel(x, y, font_tab.char) then
                draw.ink(x, y, 13, 13)
            else
                draw.ink(x, y, 0, 0)
            end
        end
    end

    -- Draw chars
    for x = 0, 7 do
        for y = 0, 16 do
            local idx = (y * 8) + x
            draw.tile(x + 8, y, idx, 13, 0)
            if idx == font_tab.char then
                draw.ink(x + 8, y, 7, 10)
            end
        end
    end

    -- Font saving (primitive)
    if e.input.btn(2) and not e.input.old(2) then
        local font = ""
        for i = e.memapi.map.font_start, e.memapi.map.font_end do
            local byte = e.memapi.peek(i)
            local left = b.rshift(b.band(byte, 0xf0), 4)
            local right = b.band(byte, 0x0f)
            font = font .. e.memapi.hexchar(left) .. e.memapi.hexchar(right)
        end
        print(font)
    end
end


-- Export the module as a table
return font_tab