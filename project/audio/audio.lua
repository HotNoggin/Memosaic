local audio = {
    channels = {},
    idx = 0,
    inote = 0,
}

audio.denver = require("audio.denver")


function audio.init(memo)
    audio.sqr = audio.denver.get({waveform='square', frequency=27.5})
    audio.tri = audio.denver.get({waveform='triangle', frequency=27.5})
    audio.saw = audio.denver.get({waveform='sawtooth', frequency=27.5})
    audio.noz = audio.denver.get({waveform='pinknoise', frequency=27.5, length = 10})
    audio.sqr:setLooping(true)
    audio.tri:setLooping(true)
    audio.saw:setLooping(true)
    audio.noz:setLooping(true)

    audio.channels = {
        [0] = audio.new_channel("sqr", audio.sqr),
        [1] = audio.new_channel("tri", audio.tri),
        [2] = audio.new_channel("saw", audio.saw),
        [3] = audio.new_channel("pnk", audio.noz),
    }
end


function audio.start()
    -- love.audio.play(
    --     audio.tri
    -- )
end


function audio.tick()
    audio.idx = (audio.idx + 1) % 10
    if audio.idx == 0 then
        audio.inote = (audio.inote + 1) % 88 -- 88 piano keys from A#0 to C#8
    end
    audio.note(0, audio.inote)
    audio.note(1, audio.inote)
    audio.note(2, audio.inote)
    audio.note(3, audio.inote)
end


function audio.new_channel(waveform, love_sound)
    return {pitch = 1, name = waveform, sound = love_sound}
end


function audio.pitch(idx, pitch)
    if pitch <= 0 then return end
    local chan = audio.channels[idx]
    chan.pitch = pitch
    chan.sound:setPitch(chan.pitch)
end


function audio.note(idx, note)
    audio.pitch(idx, audio.to_pitch(note))
end


-- Returns the pitch of the given note
-- note: number of semitones above the base pitch 0 the note is
-- return: number that is doubled from 1 for every octave increased
function audio.to_pitch(note)
    return 2^(note/12 - 1)
end


return audio