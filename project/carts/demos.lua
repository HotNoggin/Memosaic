local demos = {}
local paths = {"beep", "poke", "scroll", "snek", "spincube"}


for i, name in ipairs(paths) do
	demos[name .. ".memo"] = require("carts.demos." .. name)
end


demos["new_cart.memo"] =
[[
--!:name
--New cart
--!:font
--
]]


demos["splash.memo"] =
[[
--!:name
--Booting

--- INIT ---
i = -10
sqrnote = 40
trinote = 40
sawnote = 40
sqridx = 0
tridx = 2
sawidx = 4
scale = {
0, 2, 4, 7, 9,
12, 14, 16, 19, 21,
24,
}
lastnote = trinote + 12 * 3

--- MAIN ---
function boot()
 clrs()
end

function tick()
 if i < 40 then
  swipe()
  color()
  static(7)
  song()
 elseif i < 80 then
  swipe()
  fill(41)
  color()
  static((i)%7)
  song()
 elseif i < 100 then
  wordmark()
 elseif i < 121 then
  plink(7-(i - 100)/3)
 elseif i < 180 then
  wordmark()
 else
  stop()
  return
 end
 i = i + 1
end


--- AUDIO ---
function static(vol)
 blip(3, 0, vol, 0)
end

function plink(vol)
 blip(1, lastnote, vol)
end

function song()
 local note = flr(i/8) + 1
 if note < 1 then return end
 if scale[note + sawidx] == nil then return end
 blip(0, sqrnote + scale[note + sqridx], 7)
 blip(1, trinote + scale[note + tridx], 7)
 blip(2, sawnote + scale[note + sawidx], 7)
end


--- GRAPHICS ---
function wordmark()
 text(4, 12, "memosaic", 13, 0)
end

function fill(start)
 -- Fill a diagonal canvas section solid
 for x = 0, 15 do for y = 0, 15 do
  if x + y < i - start then
   etch(x, y, 0xff)
  end
 end end
end

function swipe()
 -- Randomly fill a diagonal canvas section
 for x = 0, 15 do for y = 0, 15 do
  if x + y == i or
  (x + y < i and i % 5 == 0) then
   local c = rnd(0x21, 0xff)
   -- Do not use blank dithers
   if c > 0x7f and c % 8 == 0 then
    c = c % 7 + 1
   end
   etch(x, y, c)
  end
 end end
end

function color()
 -- BG colors
 irect(0, 0, 8, 8, 13, 0)
 irect(8, 0, 8, 8, 14, 0)
 irect(0, 8, 8, 8, 11, 0)
 irect(8, 8, 8, 8, 8, 0)

 -- Top arch
 crect(2, 2, 12, 3, " ")
 crect(2, 2, 3, 8, " ")
 crect(11, 2, 3, 8, " ")

 -- Middle square
 crect(6, 6, 4, 4, " ")
 
 -- Bottom bar
 crect(2, 11, 12, 3, " ")
end
]]

-- Export the demos
return demos