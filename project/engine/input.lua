-- Prepare a table for the module
local input = {}


function input.init(window)
    print("Initializing input")
    input.window = window
    -- 0:up 1:left 2:down 3:right 4:x/j 5:c/k
    input.buttons = {false, false, false, false, false, false}

    -- Ranges from 0 to 15 on the x and y axis (corresponding to the grid)
    input.mouse = {x = 0, y = 0}
    input.lclick = false
    input.rclick = false
end


function input.update()
    input.buttons[1] = love.keyboard.isScancodeDown("w") or love.keyboard.isScancodeDown("up")
    input.buttons[2] = love.keyboard.isScancodeDown("a") or love.keyboard.isScancodeDown("left")
    input.buttons[3] = love.keyboard.isScancodeDown("s") or love.keyboard.isScancodeDown("down")
    input.buttons[4] = love.keyboard.isScancodeDown("d") or love.keyboard.isScancodeDown("right")
    input.buttons[5] = love.keyboard.isScancodeDown("x") or love.keyboard.isScancodeDown("j")
    input.buttons[6] = love.keyboard.isScancodeDown("c") or love.keyboard.isScancodeDown("k")
    input.lclick = love.mouse.isDown(1)
    input.rclick = love.mouse.isDown(2)

    -- C++ implementation
    -- int windowWidth = 0;
    -- int windowHeight = 0;
    -- SDL_GetWindowSize(window, &windowWidth, &windowHeight);
    -- int scale = Canvas::getScale(windowWidth, windowHeight);

    -- int offsetX = (windowWidth - (Canvas::WIDTH * scale)) / 2;
    -- int offsetY = (windowHeight - (Canvas::HEIGHT * scale)) / 2;
    
    -- mouseX = (event.motion.x - offsetX) / scale;
    -- mouseY = (event.motion.y - offsetY) / scale;

    local win_width, win_height = love.graphics.getDimensions()
    local scale = input.window.get_integer_scale()

    local offset_x = (win_width / 2) - (input.window.WIDTH * scale / 2)
    local offset_y = (win_height / 2) - (input.window.HEIGHT * scale / 2)

    local mouse_x = (love.mouse.getX() - offset_x) / scale
    local mouse_y = (love.mouse.getY() - offset_y) / scale

    input.mouse.x = math.max(0, math.min(math.floor(mouse_x / 8), 15))
    input.mouse.y = math.max(0, math.min(math.floor(mouse_y / 8), 15))
end


function input.btn(num)
    if num < 0 or num > 5 then return false end
    return input.buttons[num + 1]
end


function input.num(b)
    if b then return 1 else return 0 end
end


-- Export the module as a table
return input