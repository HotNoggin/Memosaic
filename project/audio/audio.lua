local audio = {
    channels = {},
    memo = {},
    chansize = 0,
    idx = 0,
}

audio.denver = require("audio.denver")


function audio.init(memo)
    -- A0 is 27.5, A1 is 55, A2 is 110
    local freq = 27.5
    audio.sqr = audio.denver.get({waveform='square', frequency=freq})
    audio.tri = audio.denver.get({waveform='triangle', frequency=freq})
    audio.saw = audio.denver.get({waveform='sawtooth', frequency=freq})
    audio.noz = audio.denver.get({waveform='pinknoise', frequency=freq, length = 10})
    audio.sqr:setLooping(true)
    audio.tri:setLooping(true)
    audio.saw:setLooping(true)
    audio.noz:setLooping(true)

    local map = memo.memapi.map
    audio.memo = memo
    audio.console = memo.editor.console

    audio.channels = {
        [0] = audio.new_channel("sqr", audio.sqr, map.sqrwav_start, 0.2),
        [1] = audio.new_channel("tri", audio.tri, map.triwav_start, 1),
        [2] = audio.new_channel("saw", audio.saw, map.sawwav_start, 0.3),
        [3] = audio.new_channel("noz", audio.noz, map.nozwav_start, 0.7),
    }

    audio.chansize = map.sqrwav_stop - map.sqrwav_start + 1
end


function audio.start()
    audio.vol(0, 0, 1)
    audio.vol(1, 0, 1)
    audio.vol(2, 0, 1)
    audio.vol(3, 0, 1)

    love.audio.play(
        audio.sqr,
        audio.tri,
        audio.saw,
        audio.noz
    )

    local a = audio
    local map = audio.memo.memapi.map
end


function audio.tick()
    local a = audio
    -- Each audio buffer
    for i = 0, 3 do
        -- Get the instructions
        local channel = audio.channels[i]
        local adr = a.idx + channel.ptr
        local lbyte = a.memo.memapi.peek(adr)
        local rbyte = a.memo.memapi.peek(adr + 1)
        local vol = lbyte % 0x10
        local note = rbyte % 0x80

        -- Play the sound
        audio.vol(i, vol, channel.basevol)
        audio.note(i, note)

        -- Erase the instructions
        a.memo.memapi.poke(adr, 0)
        a.memo.memapi.poke(adr + 1, 0)
    end

    a.idx = (a.idx + 2) % math.floor(a.chansize)
end


function audio.pitch(idx, pitch)
    if pitch <= 0 then return end
    local chan = audio.channels[idx]
    chan.pitch = pitch
    chan.sound:setPitch(chan.pitch)
end


function audio.vol(idx, vol, base)
    local chan = audio.channels[idx]
    -- Given volume in range 0-15, remap to 0-base
    chan.volume = math.floor(vol) / 15 * base
    chan.sound:setVolume(chan.volume)
end


function audio.note(idx, note)
    audio.pitch(idx, audio.to_pitch(note))
end


function audio.chirp(sound, wav, base, len, at)
    local con = audio.console
    if con.bad_type(sound, "number", "beep:sound") or con.bad_type(wav, "number", "beep:wave")
    then return false end

    local toadd = base or 0
    local offset = at or 0
    local length = len or 0
    length = math.max(0, math.min(length, 7))

    local mem = audio.memo.memapi
    local start = sound * 32 + mem.map.sounds_start
    local head_a = mem.peek(start)
    local head_b = mem.peek(start + 1)
    local basenote = head_a % 128

    for idx = 0, 29 do
        local byte = mem.peek(start + 1 + idx) -- Header is 1 byte long
        local vol = bit.band(byte, 0x0F)
        local note = bit.rshift(bit.band(byte, 0xF0), 4)
        for i = 0, length do -- mini beep for each note
            audio.blip(wav, basenote + toadd + note, vol, idx * (length + 1) + offset + i)
        end
    end
    return true
end


function audio.beep(wav, note, vol, len, at)
    local con = audio.console

    if con.bad_type(wav, "number", "beep:wave") or con.bad_type(note, "number", "beep:note")
    or con.bad_type(vol, "number", "beep:volume") or con.bad_type(len, "number", "beep:length")
    then return false end

    local offset = at or 0

    for idx = 0, len - 1 do
        local success = audio.blip(wav, note, vol, idx + offset)
        if not success then return false end
    end
    return true
end


function audio.blip(wav, note, vol, at)
    local con = audio.console
    local a = audio
    if con.bad_type(wav, "number", "blip:wave") or con.bad_type(note, "number", "blip:note")
    or con.bad_type(vol, "number", "blip:volume")
    then return false end

    if math.floor(wav) > 3 or math.floor(wav) < 0 then
        con.error("invalid audio channel index (" .. wav .. ")")
        return false
    end

    local where = at or 0

    local chan = a.channels[math.floor(wav)]
    local adr = (a.idx + (where * 2)) % a.chansize

    if where > 0 then -- ignore negatives
        if vol > 0 then -- ignore silence
            audio.memo.memapi.poke(adr + chan.ptr, vol)
        end
        audio.memo.memapi.poke(adr + chan.ptr + 1, note)
    end
    return true
end


function audio.new_channel(waveform, love_sound, start, basevolume)
    return {pitch = 1, volume = 1,
    name = waveform, sound = love_sound,
    ptr = start, basevol = basevolume}
end


-- Returns the pitch of the given note
-- note: number of semitones above the base pitch 0 the note is
-- return: number that is doubled from 1 for every octave increased
-- Accepts notes from 0 to 127 and clamps outliers
function audio.to_pitch(note)
    return 2^ ( math.max( 0, math.min(note, 127) ) /12 - 1)
end


return audio