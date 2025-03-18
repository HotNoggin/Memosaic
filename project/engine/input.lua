-- Prepare a table for the module
local input = {}


function input.init(memo)
    print("Initializing input")
    input.window = memo.window

    input.alpha_keys = {
        "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h",
        "j", "k", "l", "z", "x", "c", "v", "b", "n", "m", "0", "1", "2", "3", "4", "5",
        "6", "7", "8", "9",
    }

    input.buttons = {false, false, false, false, false, false}
    input.old_buttons =  {false, false, false, false, false, false}

    input.alpha = {}
    input.old_alpha = {}

    -- Ranges from 0 to 15 on the x and y axis (corresponding to the grid)
    input.mouse = {x = 0, y = 0}
    input.wheel = 0
    input.lclick = false
    input.rclick = false
    input.lheld = false
    input.rheld = false

    input.text = ""
    input.ctrl = false
    input.shift = false
    input.enter = false
    input.back = false
    input.del = false
end


function input.update()
    input.ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    input.shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    input.enter = love.keyboard.isDown("return")
    input.back = love.keyboard.isDown("backspace")
    input.del = love.keyboard.isDown("delete")

    input.old_buttons = {
        input.buttons[1], input.buttons[2], input.buttons[3], input.buttons[4],
        input.buttons[5], input.buttons[6], input.buttons[7], input.buttons[8]
    }

    input.buttons[1] = love.keyboard.isScancodeDown("a") or love.keyboard.isScancodeDown("left")
    input.buttons[2] = love.keyboard.isScancodeDown("d") or love.keyboard.isScancodeDown("right")
    input.buttons[3] = love.keyboard.isScancodeDown("w") or love.keyboard.isScancodeDown("up")
    input.buttons[4] = love.keyboard.isScancodeDown("s") or love.keyboard.isScancodeDown("down")
    input.buttons[5] = love.keyboard.isScancodeDown("x") or love.keyboard.isScancodeDown("j")
    input.buttons[6] = love.keyboard.isScancodeDown("c") or love.keyboard.isScancodeDown("k")
    input.buttons[7] = input.enter
    input.buttons[8] = input.shift

    input.lheld = input.lclick
    input.rheld = input.rheld
    input.lclick = love.mouse.isDown(1)
    input.rclick = love.mouse.isDown(2)

    input.old_alpha = {}
    for i = 1, #input.alpha_keys do
       input.old_alpha[input.alpha_keys[i]] = input.alpha[input.alpha_keys[i]]
    end
    input.alpha = {}
    for i = 1, #input.alpha_keys do
        input.alpha[input.alpha_keys[i]] = love.keyboard.isDown(input.alpha_keys[i])
    end

    local win_width, win_height = love.graphics.getDimensions()
    local scale = input.window.get_integer_scale()

    local offset_x = (win_width / 2) - (input.window.WIDTH * scale / 2)
    local offset_y = (win_height / 2) - (input.window.HEIGHT * scale / 2)

    local mouse_x = (love.mouse.getX() - offset_x) / scale
    local mouse_y = (love.mouse.getY() - offset_y) / scale

    input.mouse.px = math.max(0, math.min(math.floor(mouse_x), 127))
    input.mouse.py = math.max(0, math.min(math.floor(mouse_y), 127))

    input.mouse.x = math.max(0, math.min(math.floor(mouse_x / 8), 15))
    input.mouse.y = math.max(0, math.min(math.floor(mouse_y / 8), 15))
end


function input.lclick_in(x, y, a, b)
    if input.lclick then
        if input.mouse.x >= x and input.mouse.x <= a and
            input.mouse.y >= y and input.mouse.y <= b then
            return true
        end
    end
    return false
end


function input.rclick_in(x, y, a, b)
    if input.rclick then
        if input.mouse.x >= x and input.mouse.x <= a and
            input.mouse.y >= y and input.mouse.y <= b then
            return true
        end
    end
    return false
end


function input.btn(num)
    if num < 0 or num > 7 then return false end
    return input.buttons[num + 1]
end


function input.btnp(num)
    return input.btn(num) and not input.old(num)
end


function input.key(key)
    if input.alpha[key] then return true else return false end
end


function input.oldkey(key)
    if input.old_alpha[key] then return true else return false end
end


function input.poptext()
    local txt = input.text
    input.text = ""
    return txt
end

function input.old(num)
    if num < 0 or num > 7 then return false end
    return input.old_buttons[num + 1]
end


function input.num(b)
    if b then return 1 else return 0 end
end


-- Export the module as a table
return input