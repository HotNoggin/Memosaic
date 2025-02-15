-- Prepare a table for the module
local console = {}

console.entries = {
    -----------------"
    "\1 \1 Memosaic \1 \1",
    "Try HELP for the",
    "command list, or",
    "EDIT to switch  ",
    "to edit mode.   ",
}
console.fgc = {11, 13, 13, 13, 13}
console.bgc = {0, 0, 0, 0, 0}
console.wrap = true

-- Scroll y
console.sy = 0
-- Scroll frames (elapsed scroll time)
local sf = 0
-- Last scroll direction
local sd = 0


function console.update(e)
    local draw = e.drawing
    local c = console

    local to_write = {}
    local to_fgc = {}
    local to_bgc = {}


    -- Don't let the amount of entries exceed the maximum limit
    while #c.entries > 128 do
        table.remove(c.entries, 1)
    end

    -- If wrapping is enabled, generate the formatted text
    if c.wrap then
        for entry = 1, #c.entries do
            local split = c.splitstr(c.entries[entry], 16)
            if split then
                for stri = 1, #split do
                    table.insert(to_write, split[stri])
                    table.insert(to_fgc, c.fgc[entry])
                    table.insert(to_bgc, c.bgc[entry])
                end
            end
        end
    -- If it's not enabled, just send the text over as-is
    else
        to_write = c.entries
        to_fgc = c.fgc
        to_bgc = c.bgc
    end

    -- Scroll with the mousewheel
    if e.input.wheel ~= sd then
        c.sy = c.sy - e.input.wheel
    else
        sf = 0
    end
    sd = e.input.wheel
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


function console.print(text, fg, bg)
    print(text)
    table.insert(console.entries, text)
end


function console.error(text, fg, bg)
    print("ERR: " .. text)
    table.insert(console.entries, "ERROR: " .. text)
end


function console.splitstr(text, chunkSize)
    local s = {}
    for i = 1, #text, chunkSize do
        s[#s + 1] = text:sub(i, i + chunkSize - 1)
    end
    return s
end


-- Export the module as a a table
return console