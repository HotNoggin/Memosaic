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
    -- exit
    -- config
    -- keyconfig

    if cmd.is(c, "info", terms, 1) then cmd.info()
    elseif cmd.is(c, "ls", terms, 1) then cmd.listdir()
    elseif cmd.is(c, "dir", terms, 1) then cmd.listdir()
    else cmd.cli.error("Not a command or executable lua") end
end


function cmd.info()
    print("info")
    local out = cmd.cli.print
    out("\1 Memosaic")
    out("  ".. cmd.memo.info.version)
    out("  ".. cmd.memo.cart.name)
    out("  ".. cmd.cli.working_dir .. "/")
    out("  ".. cmd.cli.cartfile)
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