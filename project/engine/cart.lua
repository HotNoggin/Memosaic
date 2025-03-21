-- Prepare a table for the module
local cart = {
    running_splash = false,
    ended_splash = false,
}

cart.sandbox = require("engine.sandbox")


function cart.init(memo)
    print("Creating cart sandbox")
    cart.name = "New cart"
    cart.path = "memo/"
    cart.code = ""
    cart.size = 0
    cart.font = ""
    cart.sfx = ""
    cart.memo = memo
    cart.memapi = memo.memapi

    cart.is_export = false
    cart.running = false
    cart.use_mimosa = false
    cart.cli = memo.editor.console
    cart.errstack = ""

    cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.audio, memo.editor.console)
end


function cart.load(path, hardtxt, is_export)
    cart.is_export = is_export
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
        cart.load_lines(lines, is_export)
        return true
    end

    print("Attempting to load " .. path)
    local fileinfo = love.filesystem.getInfo(path, "file")
    if fileinfo ~= nil then
        local globalpath = love.filesystem.getSaveDirectory() .. "/" .. path
        local file = io.open(globalpath, "r")

        if not file then return false end

        if cart.getfilesize(file) > 0x8000 then --32KiB
            cart.cli.print("Cart is " .. cart.getfilesize(file) - 0x8000 .. " bytes too big!", 14)
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
        table.insert(lines, "") -- required newline at end of file
        cart.load_lines(lines, is_export)
        cart.path = path
        return true
    end
    return false
end



function cart.load_lines(lines, is_export)
    cart.code = ""
    local sfxcount = 0

    local next_flag = ""
    local flag = ""
    local split = "\n"

    for k, line in ipairs(lines) do
        if k == #lines then split = "" end

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
        end

        -- Load font to memory
        if cart.tag("font", flag) then
            local fontstr = line:sub(3)
            if cart.use_mimosa then fontstr = line:sub(2, -2) end
            local success = cart.memapi.load_font(fontstr)
            if not success then
                cart.cli.error("Bad font")
                return false
            else
                cart.font = fontstr
            end

        -- Load sound to memory
        elseif cart.tag("sfx", flag) then
            local soundstr = line:sub(3)
            if cart.use_mimosa then soundstr = line:sub(2, -2) end
            local success = cart.memapi.load_sound(sfxcount, soundstr)
            if not success then
                cart.cli.error("Bad sound (#" .. sfxcount .. ")")
            end
            sfxcount = sfxcount + 1

        elseif cart.tag("name", flag) then
            cart.name = line:sub(3)
            if cart.use_mimosa then cart.name = line:sub(2, -2) end
            if is_export then
                love.window.setTitle(cart.name)
            else
                love.window.setTitle("Memosaic - " .. cart.name)
            end
            cart.code = cart.code .. line .. split

        -- Add line to code (exclude font or sfx flags and data)
        elseif not cart.tag("font", next_flag) and not cart.tag("sfx", next_flag) then
            cart.code = cart.code .. line .. split
        end
    end

    cart.memo.editor.cart_at_save = cart.memo.editor.get_save()
end


function cart.get_combined(script, scriptpath)
    local combined = ""
    local line = ""
    local c = ""
    local queue_include = false
    for i = 1, #script do
        c = script:sub(i, i)
        if c == "\n" or i == #script then
            if i == #script then line = line .. c end -- include last char
            if queue_include then
                local code = cart.include(line, scriptpath)
                combined = combined .. code .. "\n"
                queue_include = false
            else
                combined = combined .. line .. "\n"
            end
            line = ""
        else
            line = line .. c
        end
        if line == "#include " then
            queue_include = true
            line = ""
        end
    end
    print(combined)
    return combined
end


function cart.include(relativepath, fromfile)
    local filedata = ""
    print("Include " .. relativepath)
    local frompath = fromfile:match("(.*[/\\])")
    local includepath = frompath .. relativepath
    filedata = love.filesystem.read(includepath)
    return filedata or ""
end


function cart.run()
    local script = cart.get_combined(cart.get_script(), cart.path)
    if #script >= 0x8000 then
        cart.cli.print("Cart is " .. #script - 0x8000 .. " bytes too big!", 14)
    end
    if not cart.memo.editor.check_save() then return end
    local memo = cart.memo
    print("Starting cart")
    if cart.is_export then
        love.window.setTitle(cart.name)
    else
        love.window.setTitle("Memosaic - " .. cart.name)
    end
    cart.running = true

    -- Backup editor memory for retrieval
    cart.memapi.backup()

    -- Reset all row flags
    for i = cart.memapi.map.rflags_start, cart.memapi.map.rflags_end do
        cart.memapi.poke(i, 0x00)
    end

    local ok, err
    if cart.use_mimosa then
        cart.memo.mimosa.script = script
        cart.memo.mimosa.stack = {}
        cart.memo.mimosa.pile = {}
        ok = xpcall(cart.memo.mimosa.run, cart.handle_err)
    else
        cart.sandbox.init(cart, memo.input, memo.memapi, memo.drawing, memo.audio, memo.editor.console)
        ok, err = cart.sandbox.run(script, cart.name)
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
    cart.memapi.retrieve()
    cart.running = false
    if cart.running_splash then
        cart.running_splash = false
        cart.ended_splash = true
    end
end


function cart.boot()
    if cart.use_mimosa then
        local mint = cart.memo.mimosa.interpreter
        local idx = mint.tags["boot"]
        if idx ~= nil then
            -- Interpret the boot region, using the old stack, pile, and tags
            mint.idx = idx + 1
            local ok, err = xpcall(mint.interpret, cart.handle_err)
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
            mint.idx = idx + 1
            local ok, err = xpcall(mint.interpret, cart.handle_err)
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
    return cart.code
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