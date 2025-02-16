-- Prepare a table for the module
local cmd = {}


function cmd.init(memo)
    print("\tCLI")
    cmd.memo = memo
    cmd.cli = memo.editor.console
end


function cmd.command(str)
    local terms = cmd.words(str)
    -- Empty command means no command
    if not terms or terms == nil or #terms <= 0 then return end

    local c = terms[1]

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

    cmd.cli.print(str, 10) --blue

    if cmd.is(c, "info", terms, 1) then cmd.info()
    elseif cmd.is(c, "wrap", terms, 1) then cmd.wrap()
    elseif cmd.is(c, "ls", terms, 1) then cmd.listdir() -- BROKEN (No contents)
    elseif cmd.is(c, "dir", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "shutdown", terms, 1) then cmd.shutdown()
    elseif cmd.is(c, "load", terms, 2) then cmd.load(terms[2])
    elseif cmd.is(c, "run", terms, 1) then cmd.run()
    else cmd.cli.print("Not a command or a lua function", 14) end
end


function cmd.info()
    local out = cmd.cli.print
    local blue = 10 -- blue
    local teal = 11 -- teal
    local gray = 12 -- gray
    out("\1", teal)
    out("Memosaic", gray)
    out(cmd.memo.info.version, blue)
    out(cmd.memo.cart.name, teal)
    out("Bytes: " .. math.ceil(#cmd.memo.editor.get_save() / 8 ),blue)
end


function cmd.wrap()
    cmd.cli.wrap = not cmd.cli.wrap
end


function cmd.listdir()
    local folder = cmd.cli.working_dir
    local found_something = false
    cmd.cli.print(folder)
    cmd.cli.print("Contents: ")
    local files = love.filesystem.getDirectoryItems(cmd.cli.working_dir)
    print("found " .. #files .. " files")
    for i, name in ipairs(files) do
        local path = folder .. "/ ".. name
        local info = love.filesystem.getInfo(path)
        print("checking " .. name)
        if info then
            print("file or dir exists")
            if info.type == "file" then
                print("is file")
                local extension = path:sub(1, -5)
                if extension == ".memo" then
                    cmd.cli.print(name)
                    found_something = true
                end
            elseif info.type == "directory" then
                print("is dir")
                cmd.cli.print(name .. "/")
                found_something = true
            end
        end
    end
    if not found_something then cmd.cli.print("Nothing") end
end


function cmd.shutdown()
    love.event.quit()
end


function cmd.load(file)
    local success = cmd.memo.cart.load(cmd.cli.working_dir .. "/" .. file .. ".memo")
    if not success then
        success = cmd.memo.cart.load(cmd.cli.working_dir .. "/" .. file .. ".lua")
    end
    if not success then
        success = cmd.memo.cart.load(cmd.cli.working_dir .. "/" .. file)
    end
    if not success then
        success = cmd.memo.cart.load(file .. ".memo")
    end
    if not success then
        success = cmd.memo.cart.load(file .. ".lua")
    end
    if not success then
        success = cmd.memo.cart.load(file)
    end
    if success then cmd.cli.print("Loaded " .. file) else
        cmd.cli.print("Couldn't load.", 14)
    end
end


function cmd.run()
    cmd.memo.cart.run()
end


function cmd.is(command, name, t, count)
    if name ~= command then
        return false
    end 
    if #t >= count then return true else
        cmd.cli.print(name .. " needs " .. count .. " args but was given " .. #t, 14)
        return false
    end
end


function cmd.words(str)
    local words = {}
    local word = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        if cmd.isspace(char) then
            table.insert(words, word)
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


function cmd.isspace(str)
	return str:match("%s") ~= nil
end

-- Export the module as a table
return cmd