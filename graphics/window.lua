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


-- Export the module as a table
return window