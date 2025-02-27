-- Prepare a table for the module
local console = {}


function console.init(memo)
    console.cmd = require("editor.commands")
    console.cmd.init(memo)
    console.cart = memo.cart
    console.draw = memo.drawing
    console.input = memo.input
    console.editor = memo.editor

    console.workdir = {}
    console.lastdir = ""
    if not love.filesystem.getInfo("memo", "directory") then
        love.filesystem.createDirectory("memo")
    end
    if not love.filesystem.getInfo("memo/carts", "directory") then
        love.filesystem.createDirectory("memo/carts")
    end
    console.cartfile = ""

    console.entries = {}
    console.fgc = {}
    console.bgc = {}
    console.wrap = true

    -- Cursor x and y
    console.cx = 0
    console.cy = 0
    -- Scroll y
    console.sx = 0
    console.sy = 0
    -- Scroll frames (elapsed scroll time)
    console.sf = 0
    -- Last scroll direction
    console.sd = 0
    -- Input
    console.enter_down = false
    console.scroll_time = 0
    console.back_time = 0
    console.back_lim_a = 15
    console.back_lim_b = 60

    console.autoscroll = false
end


function console.reset()
    console.clear()
    console.print("\1 \1 Memosaic \1 \1", 11)
    console.print("Try HELP for the")
    console.print("command list, or")
    console.print("EDIT to switch  ")
    console.print("to edit mode.   ")
end


function console.clear()
    console.sx = 0
    console.sy = 0
    console.entries = {}
    console.fgc = {}
    console.bgc = {}
    console.take_input()
end


function console.update()
    local c = console
    local draw = c.draw

    -- Enter and backspace
    local enter = c.input.enter
    local back
    if c.input.back then
        if c.back_time == 0 then back = true
        elseif c.back_time >= c.back_lim_b then back = true
        elseif c.back_time >= c.back_lim_a then back = c.back_time % 2 == 0 end
        c.back_time = c.back_time + 1
    else
        c.back_time = 0
        back = false
    end

    -- Add typed input text
    local text = c.input.poptext()
    if text ~= "" then
        c.entries[#c.entries] = c.entries[#c.entries] .. text
        c.autoscroll = true
    end

    -- Remove char with backspace
    if back then
        c.entries[#c.entries] = c.entries[#c.entries]:sub(1, -2)
    end

    -- Take command and add new input line on enter
    if enter and not c.enter_down then
        local txt = c.entries[#c.entries]
        local commands = c.cmd.split(txt, ";")
        for i, command in ipairs(commands) do
            c.cmd.command(command)
        end
        c.fgc[#c.entries] = 8
        c.autoscroll = true
    end

    c.enter_down = enter

    -- Don't let the amount of entries exceed the maximum limit
    while #c.entries > 128 do
        table.remove(c.entries, 1)
        table.remove(c.fgc, 1)
        table.remove(c.bgc, 1)
    end

    -- Prepare to write and color the text to the console
    local to_write = {}
    local to_fgc = {}
    local to_bgc = {}

    -- Generate preformated text to use for writing
    if c.wrap then
        for index, txt in ipairs(c.entries) do
            if index == #c.entries then
                txt = ">" .. txt
            end
            local split = c.splitstr(txt, 16)
            if split then
                for stri = 1, #split do
                    table.insert(to_write, split[stri])
                    table.insert(to_fgc, c.fgc[index])
                    table.insert(to_bgc, c.bgc[index])
                end
            else
                table.insert(to_write, "")
                table.insert(to_fgc, c.fgc[index])
                table.insert(to_fgc, c.bgc[index])
            end
        end

    -- Send unformatted text to use for writing
    else
        for index, text in ipairs(c.entries) do
            table.insert(to_write, text)
        end
        if #to_write > 0 then
            to_write[#to_write] = ">" .. to_write[#to_write]
        end
        to_fgc = c.fgc
        to_bgc = c.bgc
    end

    -- Autoscrolling
    c.cy = #to_write
    if c.autoscroll and c.cy - 16 > c.sy then
        console.sy = c.cy - 16
    end

    -- Scroll with the mousewheel
    if love.keyboard.isDown("up") then
        if c.scroll_time % 2 == 0 then
            c.sy = c.sy - 1
        end
        c.scroll_time = c.scroll_time + 1
    elseif love.keyboard.isDown("down") then
        if c.scroll_time % 2 == 0 then
            c.sy = c.sy + 1
        end
        c.scroll_time = c.scroll_time + 1
    end

    
    c.sy = math.max(0, math.min(c.sy, #to_write - 1))

    -- Display the formatted text to the console
    draw.clrs()

    for i = 0, 15 do
        if #to_write > i + c.sy then
            local idx = i + 1 + c.sy
            draw.text(0, i, to_write[idx], to_fgc[idx], to_bgc[idx])
        end
    end

    console.autoscroll = false
end


function console.changedir(path)
    local folders = console.cmd.split(path, "/")
    local newdir = {}

    for i, v in ipairs(console.workdir) do
        table.insert(newdir, v)
    end

    if #folders <= 0 then return end

    -- to last
    if folders[1] == "-" then
        newdir = console.cmd.split(console.lastdir, "/")
    -- to root
    elseif folders[1] == "~" then
        newdir = {}
        table.remove(folders, 1)
    else
        for i, folder in ipairs(folders) do
            if folder == ".." then
                if #newdir > 0 then table.remove(newdir, #newdir) end
            else
                table.insert(newdir, folder)
            end
        end
    end

    local dirpath = console.getworkdir(newdir)
    local formatted = "\1" .. string.sub(dirpath, 5, -1)
    if love.filesystem.getInfo(dirpath) == nil then
        console.print(formatted , console.cmd.pink)
        console.print(" does not exist", console.cmd.pink)
        return
    end

    console.lastdir = console.getworkdir():sub(6, -1) -- remove memo/
    console.workdir = newdir
    console.print(formatted, console.cmd.blue)
end


-- The workdir formatted with the memo mini logo
function console.getminidir(str)
    local rstr = "\1" .. string.sub(str, 5)
    if #rstr >= 5 then
        local extension = str:sub(#str -4, #str)
        if extension == ".memo" then
            rstr = string.sub(rstr, 1, #rstr - 4) .. "\1"
        end
    end
    return rstr
end


function console.getworkdir(t)
    local dir = "memo/"
    local workdir = console.workdir
    if t then workdir = t end
    for i, value in ipairs(workdir) do
        dir = dir .. value .. "/"
    end
    return dir
end



function console.take_input()
    table.insert(console.entries, "")
    table.insert(console.fgc, 8)
    table.insert(console.bgc, 0)
    console.autoscroll = true
end


function console.print(text, fg, bg)
    local fore = 13
    local back = 0
    if not console.bad_type(fg, "number", "print") and fg > 0 then fore = fg % 16 end
    if not console.bad_type(bg, "number", "print") and fg > 0 then back = bg % 16 end
    if text then print("memo>" .. tostring(text)) end
    console.entries[#console.entries] = tostring(text)
    console.fgc[#console.fgc] = fore
    console.bgc[#console.bgc] = back
    console.take_input()
end


function console.error(text)
    local t = ""
    if type(text) == "string" then
        console.print(text, 14)
    elseif type(text == "table") then
        for line in ipairs(text) do
            console.print(text[line], 14)
        end
    end
    if console.editor.cart.running then
        console.editor.cart.stop()
    end
end


function console.splitstr(text, chunkSize)
    local tbl = {}
    local str = ""
    for i = 1, #text do
        str = str .. text:sub(i, i)
        if #str >= chunkSize or i >= #text then
            table.insert(tbl, str)
            str = ""
        end
    end
    return tbl
end


function console.bad_type(val, t, fname)
    if not val then return true end
    if type(t) == "string" then
        if type(val) ~= t then
            console.error({
                fname,
                "expected type:", t,
                "but got type:", type(val)})
            return true
        end
    elseif type(t) == "table" then
        for i, v in ipairs(t) do
            if type(val) ~= t[v] then
                console.error({
                    fname,
                    "expected type:", t,
                    "but got type:", type(val)})
                return true
            end
        end
    end
    return false
end


-- Use for line in getlines(str)
function console.getlines(str)
    local pos = 1;
    return function()
        if pos < 0 then return nil end
        local  p1, p2 = string.find( str, "\r?\n", pos )
        local line
        if p1 then
            line = str:sub( pos, p1 - 1 )
            pos = p2 + 1
        else
            line = str:sub( pos )
            pos = -1
        end
        return line
    end
end


-- Export the module as a a table
return console