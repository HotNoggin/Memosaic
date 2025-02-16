-- Prepare a table for the module
local console = {}


function console.init(memo)
    print("\tConsole")
    console.cmd = require("editor.commands")
    console.cmd.init(memo)
    console.cart = memo.cart
    console.draw = memo.drawing
    console.input = memo.input
    console.editor = memo.editor

    console.working_dir = love.filesystem.getWorkingDirectory()
    console.cartfile = "hello_world"

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
    console.working_dir = love.filesystem.getWorkingDirectory()
    console.take_input()
end


function console.update()
    local c = console
    local draw = c.draw

    local autoscroll = false

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
        autoscroll = true
    end

    -- Remove char with backspace
    if back then
        c.entries[#c.entries] = c.entries[#c.entries]:sub(1, -2)
    end

    -- Take command and add new input line on enter
    if enter and not c.enter_down then
        c.cmd.command(c.entries[#c.entries])
        c.fgc[#c.entries] = 9
        c.take_input()
        autoscroll = true
    end

    c.enter_down = enter

    -- Don't let the amount of entries exceed the maximum limit
    while #c.entries > 128 do
        table.remove(c.entries, 1)
    end

    -- Prepare to write and color the text to the console
    local to_write = {}
    local to_fgc = {}
    local to_bgc = {}

    -- Generate preformated text to use for writing
    if c.wrap then
        for entry = 1, #c.entries do
            local txt = c.entries[entry]
            if entry == #c.entries then txt = ">" .. txt end
            local split = c.splitstr(txt, 16)
            if split then
                for stri = 1, #split do
                    table.insert(to_write, split[stri])
                    table.insert(to_fgc, c.fgc[entry])
                    table.insert(to_bgc, c.bgc[entry])
                end
            end
        end

    -- Send unformatted text to use for writing
    else
        to_write = c.entries
        to_fgc = c.fgc
        to_bgc = c.bgc
    end

    -- Autoscrolling
    c.cy = #to_write
    if autoscroll and c.cy - 16 > c.sy then
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
end


function console.command(cmd)
    console.error(cmd)
end


function console.take_input()
    table.insert(console.entries, "")
    table.insert(console.fgc, 8)
    table.insert(console.bgc, 0)
end


function console.print(text, fg, bg)
    local fore = 13
    local back = 0
    if not console.bad_type(fg, "number", "print") and fg > 0 then fore = fg % 16 end
    if not console.bad_type(bg, "number", "print") and fg > 0 then back = bg % 16 end
    print(text)
    console.entries[#console.entries] = tostring(text)
    console.fgc[#console.fgc] = fore
    console.bgc[#console.bgc] = back
    console.take_input()
end


function console.error(text)
    console.print("ERROR:", 14)

    local t = ""
    if type(text) == "string" then
        console.print(text, 14)
    elseif type(text == "table") then
        for line in ipairs(text) do
            console.print(text[line], 14)
        end
    end

    console.editor.cart.stop()
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