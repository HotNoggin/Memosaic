-- Prepare a table for the module
local sound_tab = {}


function sound_tab.init(memo)
    sound_tab.memo = memo
    sound_tab.memapi = memo.memapi
    sound_tab.cart = memo.cart
    sound_tab.input = memo.input
    sound_tab.drawing = memo.drawing
    sound_tab.audio = memo.audio

    sound_tab.note_colors = {13, 6, 6, 14, 14, 3, 3, 2}
    sound_tab.vol_colors = {13, 12, 12, 11, 11, 10, 10, 2}
    sound_tab.volume_mode = false

    sound_tab.space = false
    sound_tab.tab = false
    sound_tab.oldspace = false
    sound_tab.oldtab = false

    sound_tab.selected = 0
    sound_tab.scroll = 0
    sound_tab.click_started_in_canvas = false
end


function sound_tab.update(editor)
    local draw = sound_tab.drawing
    local ipt = sound_tab.input
    local mem = sound_tab.memapi
    local mx, my = ipt.mouse.x, ipt.mouse.y
    local mpx, mpy = ipt.mouse.px, ipt.mouse.py
    local vol_mode = sound_tab.volume_mode
    if ipt.shift then
        vol_mode = not vol_mode
    end

    sound_tab.space = love.keyboard.isDown("space")
    sound_tab.tab = love.keyboard.isDown("tab")

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

    -- Set scroll
    if ipt.lclick_in(0, 9, 15, 9) then
        sound_tab.scroll = math.min(math.floor(mpx/4), 16)
    end

    if ipt.lclick_in(0, 1, 15, 8) and not ipt.lheld then
        sound_tab.click_started_in_canvas = true
    elseif ipt.lclick and not ipt.lheld then
        sound_tab.click_started_in_canvas = false
    end

    -- Paint sound
    if ipt.lclick_in(0, 1, 15, 8) then
        if sound_tab.click_started_in_canvas then
            local tsize = 8
            local height = 15 - math.floor(((mpy-tsize)/(tsize/2)))
            local start = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 2
            local adr = start + mx + sound_tab.scroll
            local byte = sound_tab.memapi.peek(adr)
            if vol_mode then
                -- Set volume
                byte = bit.bor(bit.band(byte, 0xF0), height)
            else
                -- Set pitch
                byte = bit.bor(bit.band(byte, 0x0F), bit.lshift(height, 4))
            end
            sound_tab.memapi.poke(adr, byte)
        end
    end

    -- Play sound
    if sound_tab.space and not sound_tab.oldspace then
        sound_tab.audio.chirp(sound_tab.selected, 2, 20)
    end

    -- Draw selected sound
    for x = 0, 15 do
        -- Sound data starts at second byte, sounds are 32 bytes long
        local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 2
        local byte = sound_tab.memapi.peek(adr + x + sound_tab.scroll)
        local vol = bit.band(byte, 0x0F)
        local note = bit.rshift(bit.band(byte, 0xF0), 4)
        local halftile = 0b10010010
        local fulltile  = 0b10011010

        -- Volume mode switch
        local val = note
        local val_colors = sound_tab.note_colors
        if vol_mode then
            val = vol
            val_colors = sound_tab.vol_colors
        end

        -- Draw values
        for section = 0, val do
            local y = math.floor((15 - section) / 2) + 1
            local color = val_colors[y]
            draw.tile(x, y, fulltile, color, 0)
            -- half the top if even
            if val % 2 == 0 and section == val then
                draw.tile(x, y, halftile, color, 0)
            end
        end
    end

    -- Switch volume and note mode
    if sound_tab.tab and not sound_tab.oldtab then
        sound_tab.volume_mode = not sound_tab.volume_mode
    end

    -- Draw scrollbar (sound preview)
    for x = 0, 15 do
        local tile = 0b11111010
        local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 2
        local lidx = adr + (x * 2)
        local ridx = lidx + 1
        local lbyte = sound_tab.memapi.peek(lidx)
        local rbyte = sound_tab.memapi.peek(ridx)
        local lcolr, rcolr = 0, 0
        local palette = sound_tab.note_colors
        if vol_mode then
            -- Paint with volume
            lcolr = bit.band(lbyte, 0x0F)
            rcolr = bit.band(rbyte, 0x0F)
            palette = sound_tab.vol_colors
        else
            -- Paint with pitch
            lcolr = bit.rshift(bit.band(lbyte, 0xF0), 4)
            rcolr = bit.rshift(bit.band(rbyte, 0xF0), 4)
        end
        lcolr = math.floor(lcolr / 2)
        rcolr = math.floor(rcolr / 2)
        local link = palette[8 - lcolr]
        local rink = palette[8 - rcolr]
        if x*2 == sound_tab.scroll then link = 0 end
        if x*2 + 1 == sound_tab.scroll then rink = 0 end
        draw.tile(x, 9, tile, link, rink)
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

    sound_tab.oldspace = sound_tab.space
    sound_tab.oldtab = sound_tab.tab
end


-- Export the module as a table
return sound_tab