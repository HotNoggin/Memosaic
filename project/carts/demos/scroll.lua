return
[[
--!:lua
--!:name
--Scroll
--!:author
--jjgame.dev

function boot()
 i = 0
end


function tick()
 i = i + 1

 if i % 4 == 0 then
  for r = 0, 15 do

   local newv = peek(0xe00 + r) + r
   if r % 2 == 0 then
    newv = peek(0xe00 + r) - r
   end

   poke(0xe00 + r, newv)
  end
 end

 pan(i % 128, i % 128)
end

--!:defaultfont
]]