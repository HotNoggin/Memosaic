-- Prepare a table for the module
local drawing = {}

local b = require("bit")

drawing.TILE_WIDTH = 16
drawing.TILE_HEIGHT = 16

drawing.palette = {
    -- KIBI 16 (by me, made for KIBIBOY)
    {r = 0.035, g = 0.008, b = 0.133}, -- black
    {r = 0.227, g = 0.208, b = 0.196}, -- silver
    {r = 0.290, g = 0.020, b = 0.302}, -- purple
    {r = 0.447, g = 0.106, b = 0.188}, -- red
    {r = 0.490, g = 0.200, b = 0.024}, -- brown
    {r = 0.976, g = 0.588, b = 0.086}, -- orange
    {r = 0.965, g = 0.753, b = 0.471}, -- peach
    {r = 1.000, g = 0.855, b = 0.078}, -- yellow
    {r = 0.659, g = 1.000, b = 0.318}, -- lime
    {r = 0.090, g = 0.318, b = 0.145}, -- green
    {r = 0.267, g = 0.259, b = 0.745}, -- blue
    {r = 0.141, g = 0.698, b = 0.729}, -- teal
    {r = 0.647, g = 0.816, b = 0.824}, -- gray
    {r = 0.965, g = 0.953, b = 0.816}, -- white
    {r = 0.973, g = 0.420, b = 0.537}, -- pink
    {r = 0.663, g = 0.204, b = 0.678}, -- magenta
}


function drawing.init(canvas, memapi, width, height)
    print("Connecting drawing api")
    drawing.canvas = canvas
    drawing.memapi = memapi
end


function drawing.char(c, x, y, c_color, t_color)
    if x < 0 or x >= drawing.TILE_WIDTH then return end
    if y < 0 or y >= drawing.TILE_HEIGHT then return end
    -- Convert char to byte and poke the ascii buffer byte
    local idx = y * drawing.TILE_WIDTH + x
    drawing.memapi.poke(idx + drawing.memapi.map.ascii_start, string.byte(c))
    -- Poke the color buffer byte as well
    local color_byte = drawing.memapi.peek(idx + drawing.memapi.map.color_start)
    if c_color > 0 then
        color_byte = b.band(color_byte, 0x0f) -- Erase char color
        color_byte = b.bor(color_byte, b.lshift(c_color, 4)) -- Set char color
        drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
    if t_color > 0 then
       color_byte = b.band(color_byte, 0xf0) -- Erase tile color
       color_byte = b.bor(color_byte, t_color) -- Set tile color
       drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
end


function drawing.draw_buffer()
    for tx = 0, drawing.TILE_WIDTH - 1 do
        for ty = 0, drawing.TILE_HEIGHT - 1 do
            local idx = ty * drawing.TILE_WIDTH + tx 
            local char = drawing.memapi.peek(idx + drawing.memapi.map.ascii_start)
            local color = drawing.memapi.peek(idx + drawing.memapi.map.color_start)
            local c_color = b.rshift(b.band(color, 0xf0), 4) -- Get left color
            local t_color = b.band(color, 0x0f) -- Get right color
            -- Draw the character
            for px = 0, 7 do
                for py = 0, 7 do
                    -- ! Using color only currently, ignoring char
                    if px % 2 == 0 and py % 2 == 0 then
                        drawing.pixel(tx * 8 + px, ty * 8 + py, c_color)
                    else
                        drawing.pixel(tx * 8 + px, ty * 8 + py, t_color)
                    end
                end
            end
        end
    end
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