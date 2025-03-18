-- Prepare a table for the module
local font_tab = {}
local b = require("bit")


function font_tab.init(memo)
    font_tab.draw = memo.drawing
    font_tab.memapi = memo.memapi
    font_tab.input = memo.input

    font_tab.char = string.byte("!")
    font_tab.pen = false
    font_tab.bg = 0
    font_tab.fg = 13
    font_tab.stashed = "\0\0\0\0\0\0\0\0"
end


function font_tab.update(editor)
    local draw = font_tab.draw
    local ipt = font_tab.input
    local mem = font_tab.memapi

    -- Font tab colors
    editor.bar_bg = 10
    editor.bar_fg = 11
    editor.bar_lit = 13

    draw.clrs()

    -- Set efont flag to false on sprite rows
    for i = mem.map.rflags_start + 1, mem.map.rflags_end - 1 do
        mem.poke(i, 0x00)
    end

    local mx = ipt.mouse.x
    local my = ipt.mouse.y

    -- Sprite editing
    if ipt.lclick_in(0, 1, 7, 8) then
        if not ipt.lheld then
            font_tab.pen = font_tab.draw.font_pixel(mx, my - 1, font_tab.char)
        end

        local ptr = (font_tab.char * 8) + mx + mem.map.font_start
        local byte = mem.peek(ptr)
        if font_tab.pen then
            byte = b.band(byte, b.bnot(b.lshift(1, my - 1)))
        else
            byte = b.bor(byte, b.lshift(1, my - 1))
        end
        mem.poke(ptr, byte)
    end

    -- Char select
    if ipt.lclick_in(8, 1, 15, 14) and not ipt.lheld then
        local idx = (my + 1) * 8 + mx - 8
        font_tab.char = idx
        font_tab.tip_char(editor)
    end

    -- BG select
    if ipt.lclick_in(0, 10, 7, 11) and not ipt.lheld then
        local idx = (my - 10) * 8 + mx
        font_tab.bg = idx
        editor.tooltip = "bg color: " .. tostring(idx)
    end

    -- FG select
    if ipt.lclick_in(0, 13, 7, 14) and not ipt.lheld then
        local idx = (my - 13) * 8 + mx
        font_tab.fg = idx
        editor.tooltip = "fg color: " .. tostring(idx)
    end

    -- Hotkeys
    if ipt.ctrl then
        if ipt.key("c") and not ipt.oldkey("c") then
            font_tab.copy()
            editor.tooltip = "copy char"
        end
        if ipt.key("v") and not ipt.oldkey("v") then
            font_tab.paste()
            editor.tooltip = "paste char"
        end
        if ipt.key("x") and not ipt.oldkey("x") then
            font_tab.copy()
            font_tab.paste("\0\0\0\0\0\0\0\0")
            editor.tooltip = "cut char"
        end
    end
    if love.keyboard.isDown("delete") then
        font_tab.paste("\0\0\0\0\0\0\0\0")
    end
    if ipt.btnp(0) then font_tab.char = font_tab.fontwrap(font_tab.char - 1) end
    if ipt.btnp(1) then font_tab.char = font_tab.fontwrap(font_tab.char + 1) end
    if ipt.btnp(2) then font_tab.char = font_tab.fontwrap(font_tab.char - 8) end
    if ipt.btnp(3) then font_tab.char = font_tab.fontwrap(font_tab.char + 8) end
    if ipt.btnp(0) or ipt.btnp(1) or ipt.btnp(2) or ipt.btnp(3) then
        font_tab.tip_char(editor)
    end

    -- Current char drawing
    for x = 0, 7 do
        for y = 0, 7 do
            if font_tab.draw.font_pixel(x, y, font_tab.char) then
                draw.tile(x, y + 1, 0x80, font_tab.bg, font_tab.fg) -- Char 0x80 is blank dither
            else
                draw.tile(x, y + 1, 0x80, font_tab.bg, font_tab.bg)
            end
        end
    end

    -- Color drawing
    draw.text(0, 9, "bg color", 10) -- blue
    draw.text(0, 12, "fg color", 10)
    local isfg = false
    for count = 0, 1 do
        for x = 0, 7 do
            for y = 0, 1 do
                local idx = (y * 8 + x) % 16
                local draw_y
                if isfg then draw_y = y + 13 else draw_y = y + 10 end
                draw.tile(x, draw_y, 0b11001111, idx, 0) -- x y c fg bg

                if idx == 0 then
                    draw.tile(x, draw_y, 0b11011111, 13, 0)
                end

                if (idx == font_tab.bg and not isfg) or (idx == font_tab.fg and isfg) then
                    draw.char(x, draw_y, 7) -- smiley
                end
            end
        end
        isfg = true
    end

    -- Draw chars
    for x = 0, 7 do
        for y = 2, 15 do
            local idx = (y * 8) + x
            draw.tile(x + 8, y - 1, idx, 13, 0)
            if idx == font_tab.char then
                draw.ink(x + 8, y - 1, 13, 10) -- White and blue
            end
        end
    end
end


function font_tab.update_bar(editor)
    local draw = font_tab.draw
    local ipt = font_tab.input
    local mx = ipt.mouse.x
    local my = ipt.mouse.y

    -- Copy
    draw.char(8, 0, 24)
    if mx == 8 and my == 0 then
        draw.ink(8, 0, editor.bar_lit)
        editor.tooltip = "copy (CTRL+c)"
        if ipt.lclick and not ipt.lheld then
            font_tab.copy()
        end
    end

    -- Paste
    draw.char(9, 0, 25)
    if mx == 9 and my == 0 then
        draw.ink(9, 0, editor.bar_lit)
        editor.tooltip = "paste (CTRL+v)"
        if ipt.lclick and not ipt.lheld then
            font_tab.paste()
        end
    end

    -- Cut
    draw.char(10, 0, 26)
    if mx == 10 and my == 0 then
        draw.ink(10, 0, editor.bar_lit)
        editor.tooltip = "cut (CTRL+x)"
        if ipt.lclick and not ipt.lheld then
            font_tab.copy()
            font_tab.paste("\0\0\0\0\0\0\0\0")
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


function font_tab.tip_char(editor)
    editor.tooltip = "char: " .. string.char(font_tab.char) .. " (" .. font_tab.char .. ")"
end


function font_tab.copy()
    font_tab.stashed = ""
    local mem = font_tab.memapi
    local adr = mem.map.font_start + (font_tab.char * 8)
    for i = 0, 7 do
        local byte = mem.peek(adr + i)
        font_tab.stashed = font_tab.stashed .. string.char(byte)
    end
end


function font_tab.paste(char)
    local topaste = char or font_tab.stashed
    local mem = font_tab.memapi
    local adr = mem.map.font_start + (font_tab.char * 8)
    for i = 0, 7 do
        local byte = string.byte(topaste:sub(i + 1, i + 1))
        mem.poke(adr + i, byte)
    end
end


function font_tab.fontwrap(num)
    local range_start = 0x10
    local range_end = 0x7F
    local range_size = range_end - range_start + 1 -- Include the end value

    return (math.floor(num) - range_start) % range_size + range_start
end


-- Export the module as a table
return font_tab