-- Prepare a table for the module
local canvas = {}


function canvas.init(width, height)
    print("Preparing virtual display")
    canvas.data = love.image.newImageData(width, height)
    canvas.image = love.graphics.newImage(canvas.data)
    canvas.data.mapPixel(canvas.data, canvas._clear_image_map)
    canvas.update()
end


function canvas._clear_image_map(x, y, r, g, b, a)
    return 1, 1, 1, 1
end


function canvas.update()
    canvas.image.replacePixels(canvas.image, canvas.data)
end


-- Export the module as a table
return canvas