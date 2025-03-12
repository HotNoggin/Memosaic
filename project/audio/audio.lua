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


function audio.beepat(wav, note, vol, len, at)
    for idx = audio.idx + at, audio.idx + at + (len - 1) do
         audio.blipat(wav, note, vol, idx)
    end
end

function audio.beep(wav, note, vol, len)
    audio.beepat(wav, note, vol, len, 0)
end


function audio.blipat(wav, note, vol, at)
    local con = audio.console
    local a = audio
    if con.bad_type(wav, "number", "blipat") or con.bad_type(note, "number", "blipat")
    or con.bad_type(vol, "number", "blipat") or con.bad_type(at, "number", "blipat")
    then return end

    if math.floor(wav) > 3 or math.floor(wav) < 0 then
        con.error("invalid audio channel index (" .. wav .. ")")
        return
    end

    local chan = a.channels[math.floor(wav)]
    local adr = (a.idx + (at * 2)) % a.chansize
    print(adr + chan.ptr < chan.ptr)

    audio.memo.memapi.poke(adr + chan.ptr, vol)
    audio.memo.memapi.poke(adr + chan.ptr + 1, note)
end

function audio.blip(wav, note, vol)
    audio.blipat(wav, note, vol, 0)
end


function audio.new_channel(waveform, love_sound, start, basevolume)
    return {pitch = 1, volume = 1,
    name = waveform, sound = love_sound,
    ptr = start, basevol = basevolume}
end


-- Returns the pitch of the given note
-- note: number of semitones above the base pitch 0 the note is
-- return: number that is doubled from 1 for every octave increased
function audio.to_pitch(note)
    return 2^(note/12 - 1)
end


return audio