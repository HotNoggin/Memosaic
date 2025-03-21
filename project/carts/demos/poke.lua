return
[[
--!:lua
--!:name
--Poke poke!
--!:author
--jjgame.dev

function tick()
    -- Draw a random tile at a random position with random colors
    tile(
        rnd(0, 15), rnd(0, 15), -- Random position
        char(rnd(0x00, 0xff)),   -- Random char
        rnd(0, 15), rnd(0, 15)) -- Random colors
end

--!:font
--
]]