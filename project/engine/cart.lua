-- Prepare a table for the module
local cart = {}

cart.sandbox = require("engine.sandbox")


function cart.init(memo)
    print("Creating cart sandbox")
    cart.name = "New cart"
    cart.code = {}
    cart.font = ""
    cart.sfx = ""
    cart.memo = memo
    cart.memapi = memo.memapi
    cart.running = false
    cart.cli = memo.editor.console
    cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.editor.console)
end


function cart.load(path, hardtxt)
    print("Loading built-in cart")
    cart.name = "Built-in cart"
    if hardtxt then
        local lines = {}
        local line = ""
        for i = 1, #hardtxt do
            local char = string.sub(hardtxt, i, i)
            if char == "\n" then
                table.insert(lines, line)
                line = ""
            elseif char ~= "\r" then
                line = line .. char
            end
        end
        cart.load_lines(lines)
        return true
    end

    print("Loading " .. path)
    cart.name = "Loaded cart"
    local fileinfo = love.filesystem.getInfo(path, "file")
    if fileinfo ~= nil then
        local globalpath = love.filesystem.getSaveDirectory() .. "/" .. path
        local file = io.open(globalpath, "r")

        if not file then return end
        local lines = {}
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
        cart.load_lines(lines)
        return true
    end
    return false
end


function cart.load_lines(lines)
    cart.code = {}
    cart.font = ""
    cart.sfx = ""

    local next_flag = ""
    local flag = ""

    for k, line in ipairs(lines) do
        -- Keep track of special flags
        flag = next_flag
        if line:sub(1, 4) == "--!:" or (line:sub(1, 2) == "(!" and line:sub(-2, -1) == "!)") then
            next_flag = line
        else
            next_flag = ""
        end

        -- Load font to memory
        if cart.tag("font", flag) then
            local fontstr = line:sub(3)
            if cart.use_mimosa then fontstr = line:sub(2, -2) end
            local success = cart.memapi.load_font(fontstr)
            if not success then
                cart.cli.error("Bad font")
                return false
            end

        -- Set name
        elseif cart.tag("name", flag) then
            cart.name = line:sub(3)
            if cart.use_mimosa then cart.name = line:sub(2, -2) end
            love.window.setTitle("Memosaic - " .. cart.name)
            table.insert(cart.code, line)

        -- Add line to code (exclude font or sfx flags and data)
        elseif not cart.tag("font", next_flag) and not cart.tag("sfx", next_flag) then
            table.insert(cart.code, line)
        end
    end
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


function cart.tag(txt, tag)
    if cart.use_mimosa and "(!" .. txt ..  "!)" == tag then
        return true
    elseif "--!:" .. txt == tag then
        return true
    end
    return false
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