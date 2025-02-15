-- Prepare a table for the module
local cart = {}

cart.sandbox = require("engine.sandbox")


function cart.init(input, memapi, drawing, console)
    print("Creating cart sandbox")
    cart.code = {}
    cart.font = ""
    cart.sfx = ""
    cart.memapi = memapi
    cart.running = false
    cart.sandbox.init(cart, input, memapi, drawing, console)
end


function cart.load(path)
    print("Loading " .. path)
    cart.code = {}
    cart.font = ""
    cart.sfx = ""

    local file = io.open(path, "r")
    if file then
        local next_flag = ""
        local flag = ""

        for line in file:lines() do
            -- Keep track of special flags
            flag = next_flag
            if string.sub(line, 1, 4) == "--!:" then
                next_flag = line
            else
                next_flag = ""
            end

            -- Load font to memory
            if flag == "--!:font" then
                cart.memapi.load_font(string.sub(line, 3, -1))
            -- Add line to code (exclude font or sfx flags and data)
            elseif next_flag ~= "--!:font" and next_flag ~= "--!:sfx" then
                table.insert(cart.code, line)
            end
        end

        file:close()
    end
end


function cart.run()
    print("Starting cart")
    cart.running = true
    local ok, err = cart.sandbox.run(cart.get_script())
    if not ok then
        print(err)
        cart.stop()
    else
        print("Cart is booting \n")
        cart.boot()
    end
end


function cart.stop()
    print("Cart stopped\n")
    cart.running = false
end


function cart.boot()
    local ok, err = pcall(cart.sandbox.env.boot)
    if not ok then
        print(err)
        cart.stop()
    end
end


function cart.tick()
    local ok, err = pcall(cart.sandbox.env.tick)
    if not ok then
        print(err)
        cart.stop()
    end
end


function cart.get_script()
    local script = ""
    for line = 1, #cart.code do
        script = script .. cart.code[line] .. '\n'
    end
    return script
end


-- Export the module as a table
return cart