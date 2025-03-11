local lib = {
    memo = {},
    mint = {},
    mem = {},
    draw = {},
    cart = {}
}


function lib.init(memo, mint)
    lib.memo = memo
    lib.mint = mint
    lib.mem = memo.memapi
    lib.ipt = memo.input
    lib.draw = memo.drawing
    lib.cart = memo.cart
end


function lib.stat(offset)
    lib.mint.say("stat")
    local code = lib.mint.pop()
    if code ~= nil then
        lib.mint.push(lib.memo.stat(code + offset))
    else
        lib.mint.err(" stat", "missing operand")
    end
end


function lib.btn()
    lib.mint.say("btn")
    local code = lib.mint.pop()
    if code ~= nil then
        lib.mint.push(lib.memo.input.btn(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnp()
    lib.mint.say("btnp")
    local code = lib.mint.pop()
    if code ~= nil then
        lib.mint.push(lib.memo.input.btn(code) and not lib.memo.input.old(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnr()
    lib.mint.say("btnr")
    local code = lib.mint.pop()
    if code ~= nil then
        lib.mint.push(lib.memo.input.old(code) and not lib.memo.input.btn(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.fill()
    local m = lib.mint
    m.say("fill")
    local char, colr = m.pop(), m.pop()
    if char ~= nil and colr ~= nil then
        for idx = 0, 0xFF do
            if not m.ok then return end
            lib.tile(nil, idx, char, colr)
        end
    end
end


function lib.tile(val, pidx, pchar, pcolr)
    local m = lib.mint
    m.say("tile")

    local idx, char, colr = pidx, pchar, pcolr
    if idx == nil then idx = m.pop() end
    if char == nil then char = m.pop() end
    if colr == nil then colr = m.pop() end

    if char ~= nil and idx ~= nil and colr ~= nil then
        lib.etch(nil, idx, char)
        if m.ok then lib.ink(nil, idx, colr) end
    else
        m.err(" tile", "missing operand")
    end
end


function lib.etch(val, pidx, pchar)
    local m = lib.mint
    m.say("etch")

    -- Becomes stack-based if no params provided
    local idx, char = pidx, pchar
    if idx == nil then idx = m.pop() end
    if char == nil then char = m.pop() end

    if char ~= nil and idx ~= nil then
        if type(char) == "string" then
            char = lib.tobyte(char, " etch")
        elseif type(char) ~= "number" then
            m.err(" etch", "expected int or byte for color, got " .. type(char))
            return
        end
        if type(idx) ~= "number" then
            m.err(" etch", "expected int for idx, got " .. type(idx))
            return
        end

        if m.ok then
            local y, x = lib.split(idx)
            lib.draw.char(x % 16, y % 16, char)
        end
    else
       m.err(" etch", "missing operand")
    end
end


function lib.ink(val, pidx, pcolr)
    local m = lib.mint
    m.say("ink")

    -- Becomes stack-based if no params provided
    local idx, colr = pidx, pcolr
    if idx == nil then idx = m.pop() end
    if colr == nil then colr = m.pop() end

    if colr ~= nil and idx ~= nil then
        if type(colr) ~= "number" then
            m.err(" ink", "expected int for color, got " .. type(colr))
            return
        end
        if type(idx) ~= "number" then
            m.err(" ink", "expected int for idx, got " .. type(idx))
            return
        end
        local y, x = lib.split(idx)
        local bg, fg = lib.split(colr)
        lib.draw.ink(x % 16, y % 16, fg % 16, bg % 16)
    else
       m.err(" ink", "missing operand")
    end
end


-- Takes a value in the format 0xAB and returns A, B
function lib.split(idx)
    return math.floor(idx / 16), idx % 16
end


function lib.tobyte(char, where)
    local wherestr = ""
    if where then wherestr = where end
    if type(char) == "number" then
        return char % 0xFF
    elseif type(char) == "string" then
        if #char == 1 then
            return string.byte(string.sub(char, 1, 1))
        else
            lib.mint.err(wherestr, "cannot convert empty string to byte (int)")
            return nil
        end
    else
        lib.mint.err(wherestr, " cannot convert " .. type(char) .. " to byte (int)")
        return nil
    end
end


return lib