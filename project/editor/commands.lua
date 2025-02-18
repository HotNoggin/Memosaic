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

    -- help
    -- demos
    -- skim (ui for carts)
    -- copy
    -- cd [dirpath]
    -- folder
    -- load
    -- file (get name)
    -- mkdir
    -- dirname
    -- save [filename]
    cmd.cli.print(str, cmd.green)

    cmd.found_command = false

    if cmd.is(c, "info", terms, 1) then cmd.info()
    elseif cmd.is(c, "cd", terms, 2) then cmd.changedir(terms[2])
    elseif cmd.is(c, "ls", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "dir", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "shutdown", terms, 1) then cmd.shutdown()
    elseif cmd.is(c, "load", terms, 2) then cmd.load(terms[2])
    elseif cmd.is(c, "run", terms, 1) then cmd.run()
    elseif cmd.is(c, "demos", terms, 1) then cmd.demos()
    elseif cmd.is(c, "wrap", terms, 1) then cmd.wrap()
    end

    if not cmd.found_command then
        cmd.cli.print("Not a command or a lua function", cmd.pink)
    end
end


function cmd.info()
    local out = cmd.cli.print
    out("\1", cmd.teal)
    out("Memosaic", cmd.gray)
    out(cmd.memo.info.version, cmd.blue)
    out(cmd.memo.cart.name, cmd.teal)
    out("Bytes: " .. math.ceil(#cmd.memo.editor.get_save() / 8 ), cmd.blue)
    out("\1" .. cmd.cli.getworkdir():sub(5, -1), cmd.blue)
end


function cmd.wrap()
    cmd.cli.wrap = not cmd.cli.wrap
end


function cmd.changedir(path)
    cmd.cli.changedir(path)
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
                local extension = path:sub(#path -4, #path)
                print(extension)
                if extension == ".memo" then
                    cmd.cli.print(" " .. name:sub(1, -5) .. "\1")
                    found_something = true
                else extension = path:sub(#path -3, #path)
                    if extension == ".lua" then
                        cmd.cli.print(" " .. name)
                        found_something = true
                    end
                end
            elseif info.type == "directory" then
                cmd.cli.print(" " .. name .. "/")
                found_something = true
            end
        end
    end

    if not found_something then cmd.cli.print(" nothing", cmd.purple) end
end


function cmd.shutdown()
    love.event.quit()
end


function cmd.load(file)
    local folder = cmd.cli.getworkdir()

    local testpaths = {
        -- Check local paths before global paths, 
        -- No extension before with extension
        folder .. file .. ".memo",
        folder .. file .. ".lua",
        folder .. file,
        "memo/" .. file .. ".memo",
        "memo/" .. file .. ".lua",
        "memo/" .. file,
    }

    for i, path in ipairs(testpaths) do
        local success = cmd.memo.cart.load(path)
        if success then
            cmd.cli.print("Loaded " .. path)
            cmd.cli.cartfile = path
            return
        end
    end

    cmd.cli.print("Couldn't load", 14)
end


function cmd.demos()
    if lfs.getInfo("memo/carts/demos", "directory") == nil then
        local success = lfs.createDirectory("memo/carts/demos")
        if not success then
            cmd.cli.print("Couldn't install demos", cmd.pink)
            cmd.cli.print("Couldn't create folder", cmd.red)
            return
        end
    end
    for name, cart in pairs(cmd.memo.demos) do
        local success, msg = lfs.write("memo/carts/demos/" .. name, cart)
        if not success then
            cmd.cli.print("Couldn't install demos", cmd.pink)
            cmd.cli.print(msg, cmd.red)
            return
        end
    end
    cmd.cli.print("Saved demos to")
    cmd.cli.print("\1/carts/demos/")
end


function cmd.run()
    cmd.cli.print("Running " .. cmd.cli.cartfile)
    cmd.memo.cart.run()
end


function cmd.is(command, name, t, count)
    if name ~= command then
        return false
    end
    cmd.found_command = true
    if #t == count then return true else
        if count - 1 == 1 then
            cmd.cli.print(name .. " needs 1 arg b but was given " .. #t - 1, 14)
        else
            cmd.cli.print(name .. " needs " .. count - 1 .. " args but was given " .. #t - 1, 14)
        end
        return false
    end
end


function cmd.split(str, c, s)
    local space = false
    if s then space = true end
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