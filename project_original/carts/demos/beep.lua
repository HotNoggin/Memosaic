return
[[
--!:lua
--!:name
--Beep
--!:author
--jjgame.dev

i = 0
wav = 0
note = 50

function tick()
 local t = false
 if btn(0) then wav = 0 t = true end
 if btn(1) then wav = 1 t = true end
 if btn(2) then wav = 2 t = true end
 if btn(3) then wav = 3 t = true end
 if btn(4) then note = note - 1 end
 if btn(5) then note = note + 1 end
 -- wave note vol
 if t then blip(wav, note, 7) end
 i=(i+1)%32
end

--!:font
--
]]