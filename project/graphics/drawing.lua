-- Prepare a table for the module
local drawing = {}

local b = require("bit")

-- The width and height of THE CANVAS in tiles
-- NOT the width and height of a tile!
drawing.TILE_WIDTH = 16
drawing.TILE_HEIGHT = 16

-- Ranges from 0 to 15, allows smooth scrolling + other effects
drawing.offset = {x = 0, y = 0}

drawing.palette = {
    -- KIBI 16 (by me, made for KIBIBOY)
    -- {r = 0.035, g = 0.008, b = 0.133}, -- 0 black
    -- {r = 0.227, g = 0.208, b = 0.196}, -- 1 silver
    -- {r = 0.290, g = 0.020, b = 0.302}, -- 2 purple
    -- {r = 0.447, g = 0.106, b = 0.188}, -- 3 red
    -- {r = 0.490, g = 0.200, b = 0.024}, -- 4 brown
    -- {r = 0.976, g = 0.588, b = 0.086}, -- 5 orange
    -- {r = 0.965, g = 0.753, b = 0.471}, -- 6 peach
    -- {r = 1.000, g = 0.855, b = 0.078}, -- 7 yellow
    -- {r = 0.659, g = 1.000, b = 0.318}, -- 8 lime
    -- {r = 0.090, g = 0.318, b = 0.145}, -- 9 green
    -- {r = 0.267, g = 0.259, b = 0.745}, -- a/10 blue
    -- {r = 0.141, g = 0.698, b = 0.729}, -- b/11 teal
    -- {r = 0.647, g = 0.816, b = 0.824}, -- c/12 gray
    -- {r = 0.965, g = 0.953, b = 0.816}, -- d/13 white
    -- {r = 0.973, g = 0.420, b = 0.537}, -- e/14 pink
    -- {r = 0.663, g = 0.204, b = 0.678}, -- f/15 magenta
}


function drawing.init(memo)
    print("Connecting drawing api")
    drawing.canvas = memo.canvas
    drawing.memapi = memo.memapi
    drawing.console = memo.editor.console
    local img = love.image.newImageData("img/memo_16.png")
    for i = 0, 15 do
        local pr, pg, pb = img:getPixel(i, 0)
        drawing.palette[i + 1] = {r = pr, g = pg, b = pb}
    end
end


-- Set every tile's char, fg color, and bg color.
function drawing.clrs(c, fg, bg)
    local char = " "
    local fore = 13
    local back = 0
    if c then char = c end
    if fg then fore = fg end
    if bg then back = bg end
    drawing.rect(0, 0, 16, 16, char, fore, back)
end


-- Set the char, fg color, and bg color of a rectangle of tiles.
function drawing.rect(x, y, w, h, c, fg, bg)
    for tx = x, x + (w - 1) do
        for ty = y, y + (h - 1) do
            drawing.tile(tx, ty, c, fg, bg)
        end
    end
end


-- Set the 
function drawing.crect(x, y, w, h, c)
    for tx = x, x + (w - 1) do
        for ty = y, y + (h - 1) do
            drawing.char(tx, ty, c)
        end
    end
end


function drawing.irect(x, y, w, h, fg, bg)
    for tx = x, x + (w - 1) do
        for ty = y, y + (h - 1) do
            drawing.ink(tx, ty, fg, bg)
        end
    end
end


-- Fill ASCII the buffer with the given string
function drawing.fill(str)
    if not str:len() > 0 then return end
    for i = 1, drawing.memapi.ascii_end - drawing.memapi.map.ascii_start + 1 do
        if str:len() >= i then
            drawing.char(i % 16, math.floor(i / 16))
        end
    end
end


-- Draw a line of text onto the screen
-- If w > 1, this wraps to keep width w
function drawing.text(x, y, str, fg, bg, w)
    local c = drawing.console
    if c.bad_type(x, "number", "text:x") then return end
    if c.bad_type(y, "number", "text:y") then return end
    local dx = x
    local dy = y
    local width = 0
    local s = tostring(str)
    if w then width = w end
    if c.bad_type(width, "number", "text:width") then return end
    local dowrap = width > 0
    for i = 1, #s do
        local char = s:sub(i, i)
        if dowrap and dx >= x + width then
            dx = x
            dy = dy + 1
        end
        drawing.tile(dx, dy, char, fg, bg)
        dx = dx + 1
    end
end


function drawing.tile(x, y, c, fg, bg)
    drawing.char(x, y, c)
    drawing.ink(x, y, fg, bg)
end


function drawing.cget(tx, ty)
    local con = drawing.console
    if con.bad_type(tx, "number", "cget:x") or con.bad_type(ty, "number", "cget:y") then
        return
    end
    local idx = drawing.memapi.ascii_start + ((tx + ty*16) % 0x100)
    return drawing.memapi.peek(idx)
end


function drawing.iget(tx,ty)
    local con = drawing.console
    if con.bad_type(tx, "number", "iget:x") or con.bad_type(ty, "number", "iget:y") then
        return
    end
    local idx = drawing.memapi.ascii_start + ((tx + ty*16) % 0x100)
    local byte = drawing.memapi.peek(idx)
    local fg = math.floor(byte / 16)
    local bg = math.floor(byte) % 16
    return fg, bg
end


function drawing.char(x, y, c)
    -- if con.bad_type(x, "number") or con.bad_type(y, "number") or
    -- con.bad_type(c, {"number", "string"}) then return end

    if x < 0 or x >= drawing.TILE_WIDTH then return end
    if y < 0 or y >= drawing.TILE_HEIGHT then return end

    -- Convert char to byte and poke the ascii buffer byte
    local idx = math.floor(y) * drawing.TILE_WIDTH + math.floor(x)
    local char = c
    if type(char) == "string" then char = string.byte(c) end
    if type(char) ~= "number" then
        drawing.console.error("etch:char: expected char or number, got " .. type(char))
        return
    end
    if char > 0 then
        drawing.memapi.poke(idx + drawing.memapi.map.ascii_start, char)
    end
end


function drawing.ink(x, y, fg, bg)
    local con = drawing.console
    local fore = -1
    local back = -1
    if con.bad_type(x, "number", "ink:x") or con.bad_type(y, "number", "ink:y")
    then return end
    if fg then
        if con.bad_type(fore, "number", "ink") then return end
        fore = math.floor(fg)
    end
    if bg then
        if con.bad_type(back, "number", "ink") then return end
        back = math.floor(bg)
    end
    if x < 0 or x >= drawing.TILE_WIDTH then return end
    if y < 0 or y >= drawing.TILE_HEIGHT then return end

    -- Poke the color buffer nibbles separately
    local idx = math.floor(y) * drawing.TILE_WIDTH + math.floor(x)
    local color_byte = drawing.memapi.peek(idx + drawing.memapi.map.color_start)
    if fore >= 0 then
        color_byte = b.band(color_byte, 0x0f) -- Erase char color
        color_byte = b.bor(color_byte, b.lshift(fore, 4)) -- Set char color
        drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
    if back >= 0 then
       color_byte = b.band(color_byte, 0xf0) -- Erase tile color
       color_byte = b.bor(color_byte, back) -- Set tile color
       drawing.memapi.poke(idx + drawing.memapi.map.color_start, color_byte)
    end
end


function drawing.setoffset(px, py)
    if drawing.console.bad_type(px, "number", "offset") then return end
    if drawing.console.bad_type(py, "number", "offset") then return end
    drawing.memapi.poke(drawing.memapi.map.pan_x, math.floor(px) % 128)
    drawing.memapi.poke(drawing.memapi.map.pan_y, math.floor(py) % 128)
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
                    local draw_pixel
                    if char >= 0x80 then
                        draw_pixel = drawing.dither_pixel(px, py, char)
                    else
                        draw_pixel = drawing.font_pixel(px, py, char)
                    end
                    local off_x = drawing.memapi.peek(drawing.memapi.map.pan_x) % 128
                    local off_y = drawing.memapi.peek(drawing.memapi.map.pan_y) % 128
                    local row_x = drawing.memapi.peek(drawing.memapi.map.scroll_start + ty) % 128
                    local opx = (tx * 8 + px + off_x + row_x) % 128
                    local opy = (ty * 8 + py + off_y) % 128
                    if draw_pixel then
                        drawing.pixel(opx, opy, fg)
                    else
                        drawing.pixel(opx, opy, bg)
                    end
                end
            end
        end
    end
end


function drawing.dither_pixel(px, py, byte)
    local pattern = bit.band(bit.rshift(byte, 4), 0b0111)
    local quadidx = math.floor(py / 4) * 2 + math.floor(px / 4)
    local quadmask = bit.lshift(1, 3 - quadidx)
    local drawquad = bit.band(byte, quadmask) > 0
    if drawquad then
        if pattern == 0b000 then
            return px % 2 == 0 -- Vertical stripes
        elseif pattern == 0b001 then
            return py % 2 == 0 -- Horizontal stripes
        elseif pattern == 0b010 then
            return px % 2 == 0 or py % 2 == 0 -- Grid
        elseif pattern == 0b011 then
            return not(px % 2 == 1 or py % 2 == 1) -- Dots
        elseif pattern == 0b100 then
            return (px + py) % 2 == 0 -- Checkerboard
        elseif pattern == 0b101 then
            return (px + py) % 4 == 0 -- Upward slope diagonals
        elseif pattern == 0b110 then
            return (px - py) % 4 == 0 -- Downward slope diagonals
        else -- 0b111
            return drawquad -- Fill
        end
    else
        return false
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


-- Takes a hex color #AABBCC and returns a, b, c
-- Where all values are between 0 and 1
function drawing.colr(color)
    local clr = math.floor(color)
    local ba = bit.rshift(bit.band(clr, 0xFF0000), 16) / 0xFF
    local bb = bit.rshift(bit.band(clr, 0x00FF00), 8) / 0xFF
    local bc = bit.band(clr, 0xFF) / 0xFF
end

-- Export the module as a table
return drawing
