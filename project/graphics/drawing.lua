-- Prepare a table for the module
local drawing = {}

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


function drawing.init(p_canvas)
    print("Initializing drawing api")
    drawing.canvas = p_canvas
end


function drawing.pixel(x, y, color)
    local col = drawing.palette[(color % 16) + 1]
    print(col.r .. " " .. col.b .. " " .. col.g)
    print(type(col.b))
    drawing.canvas.data.setPixel(x, y, col.r, col.g, col.b)
end


function drawing.clear(color)
    for x = 0, drawing.canvas.width do
        for y = 0, drawing.canvas.height do
            drawing.pixel(x, y, color)
        end
    end
end

-- Export the module as a table
return drawing