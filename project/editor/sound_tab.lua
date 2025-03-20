-- Prepare a table for the module
local sound_tab = {}

local bit = require("bit")


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

    sound_tab.stashed = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"

    sound_tab.selected = 0
    sound_tab.len = 0
    sound_tab.waveform = 0
    sound_tab.scroll = 0
    sound_tab.click_started_in_canvas = false
    sound_tab.erase_started_in_canvas = false
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

    local highlight = 14
    if vol_mode then highlight = 11 end

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
        sound_tab.scroll = mx
    end

    -- Sound keyboard navigation
    if ipt.btn(0) then
        sound_tab.scroll = math.max(0, sound_tab.scroll - 1)
    end
    if ipt.btn(1) then
        sound_tab.scroll = math.min(sound_tab.scroll + 1, 15)
    end

    if ipt.rclick_in(0, 1, 15, 8) and not ipt.held then
        sound_tab.erase_started_in_canvas = true
    else
        sound_tab.erase_started_in_canvas = false
    end
    if ipt.lclick_in(0, 1, 15, 8) and not ipt.lheld then
        sound_tab.click_started_in_canvas = true
    elseif ipt.lclick and not ipt.lheld then
        sound_tab.click_started_in_canvas = false
    end

    local header = sound_tab.memapi.peek(sound_tab.memapi.map.sounds_start + sound_tab.selected * 32)
    local basenote = header % 128

    -- Paint sound
    if ipt.lclick_in(0, 1, 15, 8) then
        if sound_tab.click_started_in_canvas then
            local start = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 1
            local adr = start + mx + sound_tab.scroll
            if ipt.ctrl then
                sound_tab.memapi.poke(adr, 0x00) -- Fully erase pitch and volume
                editor.tooltip = "erase note"
            else
                local tsize = 8
                local height = 15 - math.floor(((mpy-tsize)/(tsize/2)))
                local byte = sound_tab.memapi.peek(adr)
                if vol_mode then
                    -- Set volume
                    byte = bit.bor(bit.band(byte, 0xF0), height)
                    editor.tooltip = "volume: " .. height
                else
                    -- Set volume to max if muted
                    local vol = byte % 16
                    if vol == 0 then byte = 0x0F end
                    -- Set pitch
                    byte = bit.bor(bit.band(byte, 0x0F), bit.lshift(height, 4))
                    editor.tooltip = "note: " .. sound_tab.to_key(height + basenote)
                        .. " (" .. height + basenote .. ")"
                end
                sound_tab.memapi.poke(adr, byte)
            end
        end
    end
    -- Erase sound
    if ipt.rclick_in(0, 1, 15, 8) then
        if sound_tab.erase_started_in_canvas then
            local start = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 1
            local adr = start + mx + sound_tab.scroll
            sound_tab.memapi.poke(adr, 0x00) -- Fully erase pitch and volume
            editor.tooltip = "erase note"
        end
    end

    -- Select waveform
    if ipt.lclick_in(12, 10, 15, 10) and not ipt.lheld then
        local waves = {"sqr", "sin", "saw", "noz"}
        sound_tab.waveform = mx - 12
        editor.tooltip = "preview: " .. waves[mx - 11] .. " (" .. mx - 12 .. ")"
    end

    -- Play sound
    if sound_tab.space and not sound_tab.oldspace then
        sound_tab.audio.chirp(sound_tab.selected, sound_tab.waveform, 0, sound_tab.len, 0)
        -- sound, wav, base, len, at
    end
    draw.tile(1, 10, 21, highlight) -- button up
    if mx == 1 and my == 10 then
        draw.char(1, 10, 22) -- button down
        editor.tooltip = "play (SPACE)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.audio.chirp(sound_tab.selected, sound_tab.waveform, 0, sound_tab.len, 0)
        end
    end

    -- Switch volume and note mode
    if (sound_tab.tab and not sound_tab.oldtab)
    or (mx == 0 and my == 10 and ipt.lclick and not ipt.lheld) then
        sound_tab.volume_mode = not sound_tab.volume_mode
        if sound_tab.volume_mode then
            editor.tooltip = "mode: volume"
        else
            editor.tooltip = "mode: notes"
        end
    end

    -- Preview speeds
    if mx == 3 and my == 10 and ipt.lclick and not ipt.lheld then
        sound_tab.len = math.max(sound_tab.len - 1, 0)
        editor.tooltip = "length: " .. sound_tab.len + 1 .. "x"
    end
    if mx == 5 and my == 10 and ipt.lclick and not ipt.lheld then
        sound_tab.len = math.min(sound_tab.len + 1, 7)
        editor.tooltip = "length: " .. sound_tab.len + 1 .. "x"
    end

    -- Set base note
    if mx == 6 and my == 10 and ipt.lclick and not ipt.lheld then
        local note = 0
        if ipt.ctrl then
            note = sound_tab.up_base(-12)
        else
            note = sound_tab.up_base(-1)
        end
        editor.tooltip = "base: " .. sound_tab.to_key(note) .. " ("..note..")"
    end
    if mx == 10 and my == 10 and ipt.lclick and not ipt.lheld then
        local note = 0
        if ipt.ctrl then
            note = sound_tab.up_base(12)
        else
            note = sound_tab.up_base(1)
        end
        editor.tooltip = "base: " .. sound_tab.to_key(note) .. " ("..note..")"
    end

    -- Hotkeys
    if ipt.ctrl then
        if ipt.key("c") and not ipt.oldkey("c") then
            sound_tab.copy()
            editor.tooltip = "copy sound"
        end
        if ipt.key("v") and not ipt.oldkey("v") then
            sound_tab.paste()
            editor.tooltip = "paste sound"
        end
        if ipt.key("x") and not ipt.oldkey("x") then
            sound_tab.copy()
            sound_tab.paste("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
            editor.tooltip = "cut sound"
        end
        if ipt.key("n") and not ipt.oldkey("n") then
            sound_tab.maximize()
            editor.tooltip = "max volume"
        end
        if ipt.key("m") and not ipt.oldkey("m") then
            sound_tab.silence()
            editor.tooltip = "min volume"
        end
    end

    -- Draw selected sound
    for x = 0, 15 do
        -- Sound data starts at second byte, sounds are 32 bytes long
        local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32 + 1
        local byte = sound_tab.memapi.peek(adr + x + sound_tab.scroll)
        local vol = bit.band(byte, 0x0F)
        local note = bit.rshift(bit.band(byte, 0xF0), 4)
        local halftile = tonumber("10010010", 2)
        local fulltile = tonumber("10011010", 2)

        -- Volume mode switch
        local val = note
        local val_colors = sound_tab.note_colors
        if vol_mode then
            val = vol
            val_colors = sound_tab.vol_colors
        end

        -- Draw values
        if vol ~= 0 then
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
    end

    -- Draw scrollbar
    draw.irect(0, 9, 16, 1, 0, 2)
    draw.char(sound_tab.scroll, 9, 6) -- char 6 is dot

    -- Draw note/volume toggle
    if vol_mode then
        draw.tile(0, 10, 30, highlight, 0)
    else
        draw.tile(0, 10, 29, highlight, 0)
    end

    -- Draw length
    draw.text(3, 10, "<" .. sound_tab.len + 1 .. ">", highlight)

    -- Draw base note
    draw.text(6, 10, "<" .. sound_tab.to_key(basenote) .. ">", highlight)

    for i, pos in ipairs{0, 3, 5, 6, 10} do
        if mx == pos and my == 10 then
            local fg, bg = draw.iget(mx, 10)
            draw.ink(mx, my, bg, fg)
        end
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
                if fg == 2 then fg = highlight end
                if bg == 2 then bg = highlight end
            end
            draw.text(x * 2, y + 11, str, fg, bg)
        end
    end

    -- Draw waveform selection
    for x = 0, 3 do
        draw.tile(x + 12, 10, x + 2, highlight, 0) -- num + 2 gets the waveform icon idx
        if x == sound_tab.waveform then
            draw.ink(x + 12, 10, 0, highlight)
        end
    end

    sound_tab.oldspace = sound_tab.space
    sound_tab.oldtab = sound_tab.tab
end


function sound_tab.update_bar(editor)
    local draw = sound_tab.drawing
    local ipt = sound_tab.input
    local mx, my = ipt.mouse.x, ipt.mouse.y

    -- Copy
    draw.char(8, 0, 24)
    if mx == 8 and my == 0 then
        draw.ink(8, 0, editor.bar_lit)
        editor.tooltip = "copy (CTRL+c)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.copy()
        end
    end

    -- Paste
    draw.char(9, 0, 25)
    if mx == 9 and my == 0 then
        draw.ink(9, 0, editor.bar_lit)
        editor.tooltip = "paste (CTRL+v)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.paste()
        end
    end

    -- Cut
    draw.char(10, 0, 26)
    if mx == 10 and my == 0 then
        draw.ink(10, 0, editor.bar_lit)
        editor.tooltip = "cut (CTRL+x)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.copy()
            sound_tab.paste("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0")
        end
    end

    -- Max volume
    draw.char(11, 0, tonumber("10011010", 2))
    if mx == 11 and my == 0 then
        draw.ink(11, 0, editor.bar_lit)
        editor.tooltip = "max vol (CTRL+n)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.maximize()
        end
    end

    -- Min volume
    draw.char(12, 0, tonumber("10010010", 2))
    if mx == 12 and my == 0 then
        draw.ink(12, 0, editor.bar_lit)
        editor.tooltip = "min vol (CTRL+m)"
        if ipt.lclick and not ipt.lheld then
            sound_tab.silence()
        end
    end
end


function sound_tab.to_key(note)
    local sequence = {"A ", "A#", "B ", "C ", "C#", "D ", "D#", "E ", "F ", "F#", "G ", "G#"}
    local octavenote = note % 12 + 1
    local octave = math.floor(note / 12)
    local key = sequence[octavenote] .. octave
    return tostring(key)
end


function sound_tab.up_base(value)
    local toadd = value
    local adr = sound_tab.memapi.map.sounds_start + sound_tab.selected * 32
    local byte = sound_tab.memapi.peek(adr)
    local base = byte % 128
    byte = bit.band(byte, tonumber("10000000", 2))
    local val = math.max(0, math.min(base + toadd, 92))
    byte = bit.bor(byte, val) -- range A0 to F7 base note
    sound_tab.memapi.poke(adr, byte)
    return val
end


function sound_tab.copy()
    sound_tab.stashed = ""
    local mem = sound_tab.memapi
    local adr = mem.map.sounds_start + (sound_tab.selected * 32)
    for i = 0, 31 do
        local byte = mem.peek(adr + i)
        sound_tab.stashed = sound_tab.stashed .. string.char(byte)
    end
end


function sound_tab.paste(sound)
    local topaste = sound or sound_tab.stashed
    local mem = sound_tab.memapi
    local adr = mem.map.sounds_start + (sound_tab.selected * 32)
    for i = 0, 31 do
        local byte = string.byte(topaste:sub(i + 1, i + 1))
        mem.poke(adr + i, byte)
    end
end


function sound_tab.maximize()
    local mem = sound_tab.memapi
    local adr = mem.map.sounds_start + (sound_tab.selected * 32)
    for i = 1, 31 do
        local byte = mem.peek(adr + i)
        byte = bit.bor(byte, 0x0F) -- maximize volume
        mem.poke(adr + i, byte)
    end
end


function sound_tab.silence()
    local mem = sound_tab.memapi
    local adr = mem.map.sounds_start + (sound_tab.selected * 32)
    for i = 1, 31 do
        local byte = mem.peek(adr + i)
        byte = bit.band(byte, 0xF0) -- minimize volume
        mem.poke(adr + i, byte)
    end
end


-- Export the module as a table
return sound_tab