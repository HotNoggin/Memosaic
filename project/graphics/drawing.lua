-- Prepare a table for the module
local drawing = {}

local b = require("bit")

-- The width and height of THE CANVAS in tiles
-- NOT the width and height of a tile!
drawing.TILE_WIDTH = 16
drawing.TILE_HEIGHT = 16

drawing.palette = {
    -- KIBI 16 (by me, made for KIBIBOY)
    {r = 0.035, g = 0.008, b = 0.133}, -- 0 black
    {r = 0.227, g = 0.208, b = 0.196}, -- 1 silver
    {r = 0.290, g = 0.020, b = 0.302}, -- 2 purple
    {r = 0.447, g = 0.106, b = 0.188}, -- 3 red
    {r = 0.490, g = 0.200, b = 0.024}, -- 4 brown
    {r = 0.976, g = 0.588, b = 0.086}, -- 5 orange
    {r = 0.965, g = 0.753, b = 0.471}, -- 6 peach
    {r = 1.000, g = 0.855, b = 0.078}, -- 7 yellow
    {r = 0.659, g = 1.000, b = 0.318}, -- 8 lime
    {r = 0.090, g = 0.318, b = 0.145}, -- 9 green
    {r = 0.267, g = 0.259, b = 0.745}, -- a/10 blue
    {r = 0.141, g = 0.698, b = 0.729}, -- b/11 teal
    {r = 0.647, g = 0.816, b = 0.824}, -- c/12 gray
    {r = 0.965, g = 0.953, b = 0.816}, -- d/13 white
    {r = 0.973, g = 0.420, b = 0.537}, -- e/14 pink
    {r = 0.663, g = 0.204, b = 0.678}, -- f/15 magenta
}


function drawing.init(canvas, memapi)
    print("Connecting drawing api")
    drawing.canvas = canvas
    drawing.memapi = memapi
    drawing.clrs()
end


-- Set every tile's char, fg color, and bg color.
function drawing.clrs(c, fg, bg)
    local char = " "
    local fore = 13
    local back = 0
    if c then char = c end
    if fg then fore = fg end
    if bg then back = bg end
    drawing.rect(0, 0, 15, 15, char, fore, back)
end


-- Set the char, fg color, and bg color of a rectangle of tiles.
function drawing.rect(x, y, w, h, c, fg, bg)
    for tx = x, x + w do
        for ty = y, y + h do
            drawing.tile(tx, ty, c, fg, bg)
        end
    end
end


-- Set the 
function drawing.crect(x, y, w, h, c)
    for tx = x, x + w do
        for ty = y, y + h do
            drawing.char(tx, ty, c)
        end
    end
end


function drawing.irect(x, y, w, h, fg, bg)
    for tx = x, x + w do
        for ty = y, y + h do
            drawing.ink(tx, ty, fg, bg)
        end
    end
end


-- Draw a line of text onto the screen
function drawing.text(x, y, str, fg, bg)
    for i = 1, string.len(str) do
        drawing.tile(x + i - 1, y, string.sub(str, i, i), fg, bg)
    end
end


function drawing.tile(x, y, c, fg, bg)
    drawing.char(x, y, c)
    drawing.ink(x, y, fg, bg)
end


function drawing.char(x, y, c)
    if x < 0 or x >= drawing.TILE_WIDTH then return end
    if y < 0 or y >= drawing.TILE_HEIGHT then return end

    -- Convert char to byte and poke the ascii buffer byte
    local idx = y * drawing.TILE_WIDTH + x
    local char = c
    if type(char) == "string" then char = string.byte(c) end
    drawing.memapi.poke(idx + drawing.memapi.map.ascii_start, char)
end


function drawing.ink(x, y, fg, bg)
    if x < 0 or x >= drawing.TILE_WIDTH then return end
    if y < 0 or y >= drawing.TILE_HEIGHT then return end

    -- Poke the color buffer nibbles separately
    local idx = y * drawing.TILE_WIDTH + x
    local color_byte = drawing.memapi.peek(idx + drawing.memapi.map.color_start)
    if fg >= 0 then
        color_byte = b.band(color_byte, 0x0f) -- Erase char color
        color_byte = b.bor(color_byte, b.lshift(fg, 4)) -- Set char color
        drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
    if bg >= 0 then
       color_byte = b.band(color_byte, 0xf0) -- Erase tile color
       color_byte = b.bor(color_byte, bg) -- Set tile color
       drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
end


-- ## Canvas pixel drawing methods ## --

function drawing.draw_buffer()
    for tx = 0, drawing.TILE_WIDTH - 1 do
        for ty = 0, drawing.TILE_HEIGHT - 1 do
            local tile = ty * drawing.TILE_WIDTH + tx -- which tile this is
            local char = drawing.memapi.peek(tile + drawing.memapi.map.ascii_start)
            local color = drawing.memapi.peek(tile + drawing.memapi.map.color_start)
            local fg = b.rshift(b.band(color, 0xf0), 4) -- Get left color
            local bg = b.band(color, 0x0f) -- Get right color
            -- Draw the character
            for px = 0, 7 do
                for py = 0, 7 do
                    if drawing.font_pixel(px, py, char) then
                        drawing.pixel(tx * 8 + px, ty * 8 + py, fg)
                    else
                        drawing.pixel(tx * 8 + px, ty * 8 + py, bg)
                    end
                end
            end
        end
    end
end


function drawing.font_pixel(px, py, idx)
    local byte = drawing.memapi.peek(idx * 8 + px + drawing.memapi.map.font_start)
    local pixel = bit.rshift(bit.band(byte, bit.lshift(1, py)), py)
    return pixel == 1
end


function drawing.pixel(x, y, color)
    local col = drawing.palette[(color % 16) + 1]
    drawing.canvas.data:setPixel(x, y, col.r, col.g, col.b)
end


function drawing.clear(color)
    for x = 0, drawing.canvas.width - 1 do
        for y = 0, drawing.canvas.height - 1 do
            drawing.pixel(x, y, color)
        end
    end
end

-- Export the module as a table
return drawing
