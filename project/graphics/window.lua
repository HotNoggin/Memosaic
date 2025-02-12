-- Prepare a table for the module
local window = {}

window.WIDTH = 128
window.HEIGHT = 128

-- Set the screen size, title, and icon
function window.init(scale, use_vsync)
    local success = love.window.setMode(128 * scale, 128 * scale,
        {resizable = true, vsync = use_vsync,
        minwidth = window.WIDTH, minheight = window.HEIGHT} )
    if not success then return false end

    love.window.setTitle("Memosaic - New Project")

    local small_logo = love.image.newImageData("images/logo.png")
    local large_logo = love.image.newImageData("images/logo_big.png")

    success = love.window.setIcon(large_logo)
    if not success then
        love.window.setIcon(small_logo)
    end

    return true
end


function window.get_integer_scale()
    local int_width, int_height = love.graphics.getDimensions()
    int_width = math.floor(int_width / window.WIDTH)
    int_height = math.floor(int_height / window.HEIGHT)
    return math.max(1, math.min(int_width, int_height))
end


function window.display_canvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    local screen_width, screen_height = love.graphics.getDimensions()
    local scale = window.get_integer_scale()
    local scaled_width = window.WIDTH * scale
    local scaled_height = window.HEIGHT * scale
    love.graphics.draw(canvas.image,
        (screen_width / 2) - (scaled_width / 2),
        (screen_height / 2) - (scaled_height / 2),
        0, scale, scale)
end


-- Export the module as a table
return window