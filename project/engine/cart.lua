-- Prepare a table for the module
local cart = {}

cart.sandbox = require("engine.sandbox")


function cart.init(memo)
    print("Creating cart sandbox")
    cart.name = "New cart"
    cart.code = {}
    cart.size = 0
    cart.font = ""
    cart.sfx = ""
    cart.memo = memo
    cart.memapi = memo.memapi

    cart.running = false
    cart.use_mimosa = false
    cart.cli = memo.editor.console
    cart.errstack = ""

    cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.audio, memo.editor.console)
end


function cart.load(path, hardtxt)
    if hardtxt then
        print("Loading built-in cart")
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
        cart.name = "Built-in cart"
        cart.load_lines(lines)
        return true
    end

    print("Loading " .. path)
    local fileinfo = love.filesystem.getInfo(path, "file")
    if fileinfo ~= nil then
        local globalpath = love.filesystem.getSaveDirectory() .. "/" .. path
        local file = io.open(globalpath, "r")

        if not file then return false end

        if cart.getfilesize(file) > 0x8000 then --32KiB
            cart.cli.print("Cart is " .. cart.getfilesize(file) - 0x8000 .. " bytes too big!")
            return false
        end

        cart.use_mimosa = false
        if #path > 4 and string.sub(path, -5, -1) == ".mosa" then
            cart.use_mimosa = true
        elseif #path > 3 and string.sub(path, -4, -1) == ".lua" then
            cart.use_mimosa = false
        end

        local lines = {}
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
        cart.name = "Loaded cart"
        cart.load_lines(lines)
        return true
    end
    return false
end



function cart.load_lines(lines)
    cart.code = {}
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

        -- Set code mode
        if k == 1 then
            if flag == "--!:lua" then
                cart.use_mimosa = false
            elseif flag == "(!mimosa!)" then
                cart.use_mimosa = true
            end

        -- Load font to memory
        elseif cart.tag("font", flag) then
            local fontstr = line:sub(3)
            if cart.use_mimosa then fontstr = line:sub(2, -2) end
            local success = cart.memapi.load_font(fontstr)
            if not success then
                cart.cli.error("Bad font")
                return false
            else
                cart.font = fontstr
            end

        -- Add line to code (exclude font or sfx flags and data)
        -- Ensure flags that should be added to the cart are BELOW this
        elseif cart.tag("font", next_flag) or cart.tag("sfx", next_flag) then
            goto continue
        end

        table.insert(cart.code, line)

        if cart.tag("name", flag) then
            cart.name = line:sub(3)
            if cart.use_mimosa then cart.name = line:sub(2, -2) end
            love.window.setTitle("Memosaic - " .. cart.name)
        end

        if cart.tag("defaultfont", flag) then
            cart.memapi.load_font(cart.memapi.default_font)
        end

        ::continue::
    end
end


function cart.run()
    local memo = cart.memo
    print("Starting cart")
    love.window.setTitle("Memosaic - " .. cart.name)
    cart.running = true

    local ok, err
    if cart.use_mimosa then
        ok = xpcall(cart.memo.mimosa.run, cart.handle_err, cart.get_script(), {}, {})
    else
        cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.audio, memo.editor.console)
        ok, err = cart.sandbox.run(cart.get_script(), cart.name)
    end

    if not ok then
        if err then cart.cli.error(err) end
        cart.stop()
    else
        print("Cart is booting \n")
        cart.boot()
    end
end


function cart.tag(txt, tag)
    if cart.use_mimosa and "(!" .. txt ..  "!)" == tag then
        return true
    elseif not cart.use_mimosa and "--!:" .. txt == tag then
        return true
    end
    return false
end


function cart.stop()
    print("Cart stopped\n")
    cart.memo.drawing.setoffset(0, 0)
    -- Reset individual line scroll
    for i = 0, 15 do
        cart.memapi.poke(cart.memapi.map.scroll_start + i, 0)
    end
    cart.running = false
end


function cart.boot()
    if cart.use_mimosa then
        local mint = cart.memo.mimosa.interpreter
        local idx = mint.tags["boot"]
        if idx ~= nil then
            -- Interpret the boot region, using the old stack, pile, and tags
            local ok, err = xpcall(mint.interpret, cart.handle_err,
            mint.instructions, nil, nil, nil, idx + 1)
            if not ok then
                if err then cart.cli.error(err) end
                cart.stop()
            end
        end
    else
        local ok, err = xpcall(cart.sandbox.env.boot, cart.handle_err)
        if not ok then
            if err then cart.cli.error(err) end
            cart.stop()
        end
    end
end


function cart.tick()
    if cart.use_mimosa then
        local mint = cart.memo.mimosa.interpreter
        local idx = mint.tags["tick"]
        if idx ~= nil then
            -- Interpret the tick region, using the old stack, pile, and tags
            local ok, err = xpcall(mint.interpret, cart.handle_err,
            mint.instructions, nil, nil, nil, idx + 1)
            if not ok then
                if err then cart.cli.error(err) end
                cart.stop()
            end
        end
    else
        local ok, err = xpcall(cart.sandbox.env.tick, cart.handle_err)
        if not ok then
            if err then cart.cli.error(err) end
            cart.stop()
        end
    end
end


function cart.get_script()
    local script = ""
    for line = 1, #cart.code do
        script = script .. cart.code[line] .. '\n'
    end
    return script
end


function cart.getfilesize(file)
    local current = file:seek()
    local size = file:seek("end")
    file:seek("set", current)
    return size
end


function cart.handle_err(err)
    cart.errstack = debug.traceback(err)
    return err
end


-- Export the module as a table
return cart