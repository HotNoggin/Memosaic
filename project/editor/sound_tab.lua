-- Prepare a table for the module
local sound_tab = {}


function sound_tab.init(memo)
    sound_tab.memo = memo
    sound_tab.memapi = memo.memapi
    sound_tab.cart = memo.cart
    sound_tab.input = memo.input
    sound_tab.drawing = memo.drawing
    sound_tab.audio = memo.audio

    sound_tab.vol_colors = {13, 6, 6, 14, 14, 3, 3, 2}

    sound_tab.selected = 0
end


function sound_tab.update(editor)
    local draw = sound_tab.drawing
    local ipt = sound_tab.input
    local mem = sound_tab.memapi
    local mx, my = ipt.mouse.x, ipt.mouse.y
    local mpx, mpy = ipt.mouse.px, ipt.mouse.py

    -- Editor tab colors
    editor.bar_bg = 3
    editor.bar_fg = 14
    editor.bar_lit = 6

    draw.clrs()

    -- Select sound
    if ipt.lclick_in(0, 11, 15, 14) and not ipt.lheld then
        local tx = math.floor(mx / 2)
        local ty = my - 11
        local idx = ty * 8 + tx
        sound_tab.selected = idx
        editor.tooltip = "sound #" .. idx
    end

    -- Paint sound
    if ipt.lclick_in(0, 1, 15, 8) then
        local tsize = 8
        local vol = 15 - math.floor(((mpy-tsize)/(tsize/2)))
        local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 2 + mx
        local byte = sound_tab.memapi.peek(adr)
        byte = bit.bor(bit.band(byte, 0xF0), vol)
        sound_tab.memapi.poke(adr, byte)
    end

    -- Draw selected sound
    for x = 0, 15 do
        -- Sound data starts at second byte, sounds are 32 bytes long
        local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 2
        local byte = sound_tab.memapi.peek(adr + x)
        local vol = bit.band(byte, 0x0F)
        local note = bit.rshift(bit.band(byte, 0xF0), 4)
        local halftile = 0b10010010
        local fulltile  = 0b10011010
        for section = 0, vol do
            local y = math.floor((15 - section) / 2) + 1
            local color = sound_tab.vol_colors[y]
            draw.tile(x, y, fulltile, color, 0)
            -- half the top if even
            if vol % 2 == 0 and section == vol then
                draw.tile(x, y, halftile, color, 0)
            end
        end
    end

    if ipt.key("a") and not ipt.oldkey("a") then
        sound_tab.audio.chirp(sound_tab.selected, 2, 20)
    end

    -- Draw selection numbers
    for x = 0, 7 do
        for y = 0, 3 do
            local i = math.floor(y * 8) + x
            local str = tostring(i)
            if #str == 1 then str = "0" .. str end
            local fg, bg = 2, 0
            if (x + y) % 2 == 0 then fg, bg = 0, 2 end
            if i == sound_tab.selected then
                if fg == 2 then fg = 14 end
                if bg == 2 then bg = 14 end
            end
            draw.text(x * 2, y + 11, str, fg, bg)
        end
    end
end


-- Export the module as a table
return sound_tab