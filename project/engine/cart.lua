-- Prepare a table for the module
local cart = {}

cart.sandbox = require("engine.sandbox")


function cart.init(memo)
    print("Creating cart sandbox")
    cart.name = "New Cart"
    cart.code = {}
    cart.font = ""
    cart.sfx = ""
    cart.memo = memo
    cart.memapi = memo.memapi
    cart.running = false
    cart.cli = memo.editor.console
    cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.editor.console)
end


function cart.load(path)
    print("Loading " .. path)
    cart.name = path
    cart.code = {}
    cart.font = ""
    cart.sfx = ""

    local fileinfo =  love.filesystem.getInfo(path, "file")
    if fileinfo ~= nil then
        local globalpath = love.filesystem.getSaveDirectory() .. "/" .. path
        local file = io.open(globalpath, "r")
        local next_flag = ""
        local flag = ""

        if not file then return end
        print("Loading script")
        for line in file:lines() do
            -- Keep track of special flags
            flag = next_flag
            if line:sub(1, 4) == "--!:" then
                next_flag = line
            else
                next_flag = ""
            end

            -- Load font to memory
            if flag == "--!:font" then
                local success = cart.memapi.load_font(line:sub(3, -1))
                if not success then
                    cart.cli.error("Bad font")
                    return false
                end
            
            -- Set name
            elseif flag == "--!:name" then
                cart.name = line:sub(3, -1)
                love.window.setTitle("Memosaic - " .. cart.name)
                table.insert(cart.code, line)
            
            -- Add line to code (exclude font or sfx flags and data)
            elseif next_flag ~= "--!:font" and next_flag ~= "--!:sfx" then
                table.insert(cart.code, line)
            end
        end

        file:close()
        return true
    end
    return false
end


function cart.run()
    local memo = cart.memo
    print("Starting cart")
    love.window.setTitle("Memosaic - " .. cart.name)
    cart.running = true

    cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.editor.console)
    local ok, err = cart.sandbox.run(cart.get_script(), cart.name)

    if not ok then
        cart.cli.error(err)
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
        cart.cli.error(err)
        cart.stop()
    end
end


function cart.tick()
    local ok, err = pcall(cart.sandbox.env.tick)
    if not ok then
        cart.cli.error(err)
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