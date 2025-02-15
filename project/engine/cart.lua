-- Prepare a table for the module
local cart = {}

cart.sandbox = require("engine.sandbox")


function cart.init(input, memapi, drawing, console)
    print("Creating cart sandbox")
    cart.memapi = memapi
    cart.running = false
    cart.sandbox.init(cart, input, memapi, drawing, console)
end


function cart.load(path)
    print("Loading " .. path)
    cart.code = ""
    cart.font = ""
    cart.sfx = ""

    local file = io.open(path, "r")
    if file then
        cart.code = file:read("*a") -- *a = read all contents
        file:close()
    end
end


function cart.run()
    print("Starting cart")
    cart.running = true
    local ok, err = cart.sandbox.run(cart.code)
    if not ok then
        print(err)
        cart.stop()
    else
        print("Cart is booting")
        cart.boot()
    end
end


function cart.stop()
    print("Cart stopped")
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


-- Export the module as a table
return cart