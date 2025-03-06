-- Prepare a table for the module
local font_tab = {}
local b = require("bit")


function font_tab.init(memo)
    font_tab.draw = memo.drawing
    font_tab.memapi = memo.memapi
    font_tab.input = memo.input

    font_tab.char = string.byte("!")
    font_tab.pen = false
    font_tab.bg = 10
    font_tab.fg = 12
end


function font_tab.update()
    local draw = font_tab.draw
    local ipt = font_tab.input

    draw.clrs()

    local m_x = ipt.mouse.x
    local m_y = ipt.mouse.y

    -- Sprite editing
    if ipt.lclick_in(0, 0, 8, 8) then
        if not ipt.lheld then
            font_tab.pen = font_tab.draw.font_pixel(m_x, m_y - 1, font_tab.char)
        end

        local ptr = (font_tab.char * 8) + m_x + font_tab.memapi.map.font_start
        local byte = font_tab.memapi.peek(ptr)
        if font_tab.pen then
            byte = b.band(byte, b.bnot(b.lshift(1, m_y - 1)))
        else
            byte = b.bor(byte, b.lshift(1, m_y - 1))
        end
        font_tab.memapi.poke(ptr, byte)
    end

    -- Sprite select
    if ipt.lclick_in(8, 1, 8, 14) and not ipt.lheld then
        local idx = (m_y + 1) * 8 + m_x - 8
        font_tab.char = idx
    end

    -- Sprite drawing
    for x = 0, 7 do
        for y = 0, 7 do
            if font_tab.draw.font_pixel(x, y, font_tab.char) then
                draw.ink(x, y + 1, font_tab.bg, font_tab.fg)
            else
                draw.ink(x, y + 1, font_tab.bg, font_tab.bg)
            end
        end
    end

    -- Draw chars
    for x = 0, 7 do
        for y = 2, 16 do
            local idx = (y * 8) + x
            draw.tile(x + 8, y - 1, idx, 13, 0)
            if idx == font_tab.char then
                draw.ink(x + 8, y - 1, 12, 10) -- Gray and blue
            end
        end
    end
end


function font_tab.get_font(e)
    local font = ""
    for i = e.memapi.map.font_start, e.memapi.map.font_end do
        local byte = e.memapi.peek(i)
        local left = b.rshift(b.band(byte, 0xf0), 4)
        local right = b.band(byte, 0x0f)
        font = font .. e.memapi.hexchar(left) .. e.memapi.hexchar(right)
    end
    return font
end


-- Export the module as a table
return font_tab