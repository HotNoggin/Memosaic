-- Prepare a table for the module
local cmd = {}

local lfs = require("love.filesystem")

function cmd.init(memo)
    print("\tCLI")
    cmd.memo = memo
    cmd.cli = memo.editor.console
    cmd.purple = 2
    cmd.red = 3
    cmd.lime = 8
    cmd.green = 9
    cmd.blue = 10
    cmd.teal = 11
    cmd.gray = 12
    cmd.pink = 14
end


function cmd.command(str)
    local terms = cmd.words(str)
    -- Empty command means no command
    if not terms or terms == nil or #terms <= 0 then return end

    local c = string.lower(terms[1])

    -- Still need:
    -- help
    -- skim (ui for carts)
    -- copy
    -- mkdir

    cmd.cli.print(str, cmd.green)

    cmd.found_command = false

    if cmd.is(c, "info", terms, 1) then cmd.info()
    elseif cmd.is(c, "cd", terms, 2) then cmd.cli.changedir(terms[2])
    elseif cmd.is(c, "ls", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "dir", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "shutdown", terms, 1) then love.event.quit()
    elseif cmd.is(c, "quit", terms, 1) then love.event.quit()
    elseif cmd.is(c, "reboot", terms, 1) then love.event.quit("restart")
    elseif cmd.is(c, "new", terms, 1) then cmd.new()
    elseif cmd.is(c, "save", terms, 1) then cmd.save(terms)
    elseif cmd.is(c, "load", terms, 2) then cmd.load(terms[2])
    elseif cmd.is(c, "reload", terms, 1) then cmd.load(cmd.cli.cartfile)
    elseif cmd.is(c, "run", terms, 1) then cmd.run()
    elseif cmd.is(c, "edit", terms, 1) then cmd.edit()
    elseif cmd.is(c, "folder", terms, 1) then cmd.folder()
    elseif cmd.is(c, "demos", terms, 1) then cmd.demos()
    elseif cmd.is(c, "clear", terms, 1) then cmd.cli.clear()
    elseif cmd.is(c, "welcome", terms, 1) then cmd.cli.reset()
    elseif cmd.is(c, "font", terms, 1) then cmd.font(0x00, 0xFF)
    elseif cmd.is(c, "chars", terms, 1) then cmd.font(0x00, 0x7F)
    elseif cmd.is(c, "dithers", terms, 1) then cmd.font(0x80, 0xFF)
    elseif cmd.is(c, "wrap", terms, 1) then cmd.cli.wrap = not cmd.cli.wrap
    elseif cmd.is(c, "mimosa", terms, 1) then cmd.setmimosa(true)
    elseif cmd.is(c, "lua", terms, 1) then cmd.setmimosa(false)
    end

    if cmd.found_command then return end

    if cmd.cli.usemimosa then
        local mimosa = cmd.memo.mimosa
        mimosa.had_err = false
        local tokens = mimosa.lexer.scan(str)
        if mimosa.had_err then
            cmd.cli.print("Not a command or valid mimosa", cmd.pink)
            return
        end
        mimosa.parser.get_instructions(tokens)
        if mimosa.had_err then
            cmd.cli.print("Not a command or valid mimosa", cmd.pink)
            return
        end
        mimosa.run(str)
        return
    end

    local result, error = load(str, "CMD", "t", cmd.memo.cart.sandbox.env)
    if result == nil then
        cmd.cli.print("Not a command or valid lua", cmd.pink)
    else
        local ok, err = pcall(result)
        if not ok then
            cmd.cli.print(err, cmd.pink)
        end
    end
end


function cmd.info()
    local out = cmd.cli.print
    out("\1", cmd.teal)
    out("Memosaic", cmd.gray)
    out(cmd.memo.info.version, cmd.blue)
    out(" for " .. cmd.memo.info.version_name, cmd.blue)
    out(cmd.memo.cart.name, cmd.teal)
    local cartsize, sizecolr = #cmd.memo.editor.get_save(), cmd.blue
    if cartsize > 0x8000 then sizecolr = cmd.pink end
    out("Size: " .. cartsize, sizecolr)
    out(" /" .. 0x8000, sizecolr)
    out("\1" .. cmd.cli.getworkdir():sub(5, -1), cmd.blue)
end


function cmd.edit()
    cmd.cli.editor.tab = cmd.cli.editor.lasttab
end


function cmd.folder()
    love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/memo")
end


function cmd.setmimosa(ison)
    cmd.cli.usemimosa = ison
    local mode = "lua"
    if ison then mode = "mimosa" end
    cmd.cli.print("CLI language set to " .. mode)
end


function cmd.listdir()
    local folder = cmd.cli.getworkdir()
    local found_something = false
    cmd.cli.print("\1" .. folder:sub(5, #folder), cmd.teal)

    local items = lfs.getDirectoryItems(folder)
    for i, name in ipairs(items) do
        local path = folder .. name
        local info = love.filesystem.getInfo(path)
        if info == nil then return end
        if info then
            if info.type == "file" then
                local split = cmd.split(path, ".")
                local extension = split[#split]
                if extension == "memo" then
                    cmd.cli.print(" " .. name:sub(1, -5) .. "\1")
                    found_something = true
                elseif extension == "lua" or extension == "mosa" then
                    cmd.cli.print(" " .. name)
                    found_something = true
                end
            elseif info.type == "directory" then
                cmd.cli.print(" " .. name .. "/")
                found_something = true
            end
        end
    end

    if not found_something then cmd.cli.print(" nothing", cmd.purple) end
end


function cmd.font(from, to)
    local txt = ""
    for i = from, to do
        txt = txt .. string.char(i)
    end
    cmd.cli.print(txt, cmd.gray)
    if to - from >= 0xEF then
        cmd.cli.print("scroll up!", cmd.blue)
    end
end


function cmd.save(terms)
    local path = ""
    if #terms > 1 then
        path = terms[2]
    else
        path = cmd.cli.cartfile
    end

    if cmd.split(path, "/")[1] ~= "memo" then
        path = cmd.cli.getworkdir() .. path
    end

    local mosa = cmd.memo.cart.use_mimosa
    local split = cmd.split(path, ".")
    local extension = split[#split]
    if extension == "mosa" then
        mosa = true
        cmd.memo.cart.use_mimosa = true
    end

    local success, message
    local savefile = cmd.memo.editor.get_save()
    local cartsize = #cmd.memo.editor.get_save()
    if cartsize > 0x8000 then
        cmd.cli.print("Cart is " .. cartsize - 0x8000 .. " bytes too big!")
        return
     end

    local minipath = cmd.cli.getminidir(path)
    if path == "" then
        cmd.cli.print("No path provided", cmd.pink)
        return
    end
    if string.sub(path, -1) == "/" then
        cmd.cli.print("No filename", cmd.pink)
        return
    end

    cmd.cli.cartfile = path

    if mosa and extension ~= "mosa" then
        success, message = love.filesystem.write(path .. ".mosa", savefile)
    elseif not mosa and extension ~= "memo" and extension ~= "lua" then
        success, message = love.filesystem.write(path .. ".memo", savefile)
        minipath = minipath .. ".\1"
    else
        success, message = love.filesystem.write(path, savefile)
    end

    if success then
        cmd.memo.cart.use_mimosa = mosa
        cmd.cli.print("Saved " .. cmd.memo.cart.name .. " to " .. minipath)
        return
    else
        cmd.cli.print("Couldn't save.", cmd.pink)
        cmd.cli.print(message, cmd.pink)
        return
    end
end


function cmd.load(file)
    local folder = cmd.cli.getworkdir()

    local testpaths = {
        -- Check local paths before global paths, 
        -- No extension before with extension
        folder .. file .. ".memo",
        folder .. file .. ".lua",
        folder .. file .. ".mosa",
        folder .. file,
        "memo/" .. file .. ".memo",
        "memo/" .. file .. ".lua",
        "memo/" .. file .. ".mosa",
        "memo/" .. file,
        file,
    }

    for i, path in ipairs(testpaths) do
        local success = cmd.memo.cart.load(path)
        if success then
            cmd.cli.print("Loaded " .. cmd.cli.getminidir(path))
            cmd.cli.cartfile = path
            return
        end
    end

    cmd.cli.print("Couldn't load", 14)
end


function cmd.demos(specific)
    if lfs.getInfo("memo/carts/demos", "directory") == nil then
        local success = lfs.createDirectory("memo/carts/demos")
        if not success then
            cmd.cli.print("Couldn't install demos", cmd.pink)
            cmd.cli.print("Couldn't create folder", cmd.red)
            return
        end
    end
    for name, cart in pairs(cmd.memo.demos) do
        local success, msg
        if specific == nil then
            success, msg = lfs.write("memo/carts/demos/" .. name, cart)
        elseif name == specific then
            success, msg = lfs.write("memo/carts/demos/" .. name, cart)
        end
        if not success then
            cmd.cli.print("Couldn't install demos", cmd.pink)
            cmd.cli.print(msg, cmd.red)
            return
        end
    end
    cmd.cli.print("Saved demos to")
    cmd.cli.print("\1/carts/demos/")
end


function cmd.new()
    cmd.memo.cart.load("", cmd.memo.demos["new_cart.memo"])
    cmd.memo.memapi.load_font(cmd.memo.memapi.default_font)
    cmd.cli.cartfile = ""
    cmd.cli.print("New cart loaded")
end


function cmd.run()
    if cmd.cli.cartfile == "" then
        cmd.cli.print("Save once first!", cmd.pink)
        return
    end
    cmd.cli.print("Running " .. cmd.cli.getminidir(cmd.cli.cartfile))
    cmd.memo.cart.run()
end


function cmd.is(command, name, t, count)
    if name ~= command then
        return false
    end
    cmd.found_command = true
    if #t >= count then return true else
        if count - 1 == 1 then
            cmd.cli.print(name .. " needs 1 arg but was given " .. #t - 1, 14)
        else
            cmd.cli.print(name .. " needs " .. count - 1 .. " args but was given " .. #t - 1, 14)
        end
        return false
    end
end


function cmd.split(str, c, usespace)
    local space = false
    if usespace then space = true end
    local words = {}
    local word = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == c or (cmd.isspace(char) and space) then
            if word ~= "" then table.insert(words, word) end
            word = ""
        elseif i == #str then
            word = word .. char
            table.insert(words, word)
            word = ""
        else
            word = word .. char
        end
        i = i + 1
    end
    return words
end


function cmd.words(str)
    return cmd.split(str, "", true)
end


function cmd.isspace(str)
	return (str:match("%s") ~= nil)
end


-- Export the module as a table
return cmd