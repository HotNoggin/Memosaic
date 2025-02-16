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
    -- info
    -- demos
    -- skim (ui for carts)
    -- copy
    -- cd [dirpath]
    -- folder
    -- load
    -- file (get name)
    -- ls (aka dir)
    -- mkdir
    -- dirname
    -- save [filename]
    -- run

    cmd.cli.print(str, 10) --blue

    if cmd.is(c, "info", terms, 1) then cmd.info()
    elseif cmd.is(c, "ls", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "dir", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "shutdown", terms, 1) then cmd.shutdown()
    elseif cmd.is(c, "load", terms, 2) then cmd.load(terms[2])
    elseif cmd.is(c, "run", terms, 1) then cmd.run()
    else cmd.cli.error("Not a command or a lua function") end
end


function cmd.info()
    print("info")
    local out = cmd.cli.print
    local clra = 11 -- teal
    local clrb = 12 -- gray
    out("\1", clra)
    out("Memosaic", clrb)
    out(cmd.memo.info.version, clra)
    out(cmd.memo.cart.name, clrb)
    out(cmd.cli.working_dir .. "/", clra)
    out(cmd.cli.cartfile, clrb)
end


function cmd.listdir()
    local folder = cmd.cli.working_dir
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
                end
            elseif info.type == "directory" then
                print("is dir")
                cmd.cli.print(name .. "/")
            end
        end
    end
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
    if success then cmd.cli.print("Loaded " .. file) end
end


function cmd.is(command, name, t, count)
    if #t >= count then return name == command else
        cmd.cli.error(name .. " needs " .. count .. " args but was given " .. #t)
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