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


----------- SYSTEM -----------

function lib.stat(offset)
    local code = lib.mint.pop()
    if code then
        if lib.badtype(code, "number", " stat") then return end
        lib.mint.push(lib.memo.stat(code + offset))
    else
        lib.mint.err(" stat", "missing operand")
    end
end


function lib.btn()
    local code = lib.mint.pop()
    if code then
        if lib.badtype(code, "number", " btn") then return end
        lib.mint.push(lib.memo.input.btn(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnp()
    local code = lib.mint.pop()
    if code then
        if lib.badtype(code, "number", " btnp") then return end
        lib.mint.push(lib.memo.input.btn(code) and not lib.memo.input.old(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnr()
    local code = lib.mint.pop()
    if code then
        if lib.badtype(code, "number", " btnr") then return end
        lib.mint.push(lib.memo.input.old(code) and not lib.memo.input.btn(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


----------- DRAWING -----------

function lib.fill()
    local m = lib.mint
    local char, colr = m.pop(), m.pop()
    if char and colr then
        for idx = 0, 0xFF do
            if not m.ok then return end
            lib.tile(nil, idx, char, colr)
        end
    end
end


function lib.tile(val, pidx, pchar, pcolr)
    local m = lib.mint

    local idx, char, colr = pidx, pchar, pcolr
    if idx == nil then idx = m.pop() end
    if char == nil then char = m.pop() end
    if colr == nil then colr = m.pop() end

    if char and idx and colr then
        lib.etch(nil, idx, char)
        if m.ok then lib.ink(nil, idx, colr) end
    else
        m.err(" tile", "missing operand")
    end
end


function lib.etch(val, pidx, pchar)
    local m = lib.mint

    -- Becomes stack-based if no params provided
    local idx, char = pidx, pchar
    if idx == nil then idx = m.pop() end
    if char == nil then char = m.pop() end

    if char and idx then
        if lib.badtype(idx, "number", " etch:idx") then return end

        if type(char) == "string" then
            char = lib.tobyte(char, " etch")
        elseif lib.badtype(char, "number", " etch:char") then
            return
        end

        if m.ok then
            local y, x = lib.split(idx)
            lib.draw.char(x, y, char)
        end
    else
       m.err(" etch", "missing operand")
    end
end


function lib.ink(val, pidx, pcolr)
    local m = lib.mint

    -- Becomes stack-based if no params provided
    local idx, colr = pidx, pcolr
    if idx == nil then idx = m.pop() end
    if colr == nil then colr = m.pop() end

    if colr and idx then
        if lib.badtype(idx, "number", " ink:idx") then return end
        if lib.badtype(colr, "number", " ink:color") then return end

        local y, x = lib.split(idx)
        local bg, fg = lib.split(colr)
        lib.draw.ink(x, y, fg, bg)
    else
       m.err(" ink", "missing operand")
    end
end


function lib.rect()
    print("rect")
    local m = lib.mint
    local to, from, char, colr = m.pop(), m.pop(), m.pop(), m.pop()
    if to and from and char and colr then
        lib.crect(nil, from, to, char)
        lib.irect(nil, from, to, colr)
    else
        m.err(" rect", "missing operand")
    end
end


function lib.crect(val, pfrom, pto, pchar)
    local m = lib.mint
    local to = pfrom or m.pop()
    local from = pto or m.pop()
    local char = pchar or m.pop()
    if to and from and char then
        if lib.badtype(to, "number", "crect:to") then return end
        if lib.badtype(from, "number", "crect:from") then return end

        local y, x = lib.split(from)
        local b, a = lib.split(to)
        local w, h = a - x + 1, b - y + 1
        print(" crect " .. x .. " " .. y .. " " .. w .. " " .. h .. " " .. char)
        return lib.draw.crect(x, y, w, h, char)
    else
        m.err(" crect", "missing operand")
    end
end


----------- AUDIO -----------
function lib.blip(val, pwav, pnote, pvol)
    local m = lib.mint
    local wav = pwav or m.pop()
    local note = pnote() or m.pop()
    local vol = pvol or m.pop()
    local ok = lib.blipat(val, wav, note, vol, 0)
    if not ok then
        lib.mint.err(" blip", "could not blip")
    end
    return ok
end


function lib.blipat(val, pwav, pnote, pvol, pat)
    local m = lib.mint
    local wav = pwav or m.pop()
    local note = pnote() or m.pop()
    local vol = pvol or m.pop()
    local at = pat or m.pop()
    if wav and note and vol and at then
        if lib.badtype(wav, "number", " blipat:wave") then return end
        if lib.badtype(note, "number", " blipat:note") then return end
        if lib.badtype(vol, "number", " blipat:volume") then return end
        if lib.badtype(at, "number", " blipat:at") then return end

        local ok = lib.memo.audio.blipat(wav, note, vol, at)
        if not ok then
            lib.mint.err(" blipat", "could not blip")
        end
        return ok
    else
        m.err(" blipat", "missing operand")
    end
end



----------- HELPERS -----------

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
        lib.mint.err(wherestr, "cannot convert " .. type(char) .. " to byte (int)")
        return nil
    end
end


function lib.badtype(val, ty, wherestr, should_err)
    local toerr = should_err or true
    if type(val) == ty then
        return false
    elseif should_err then
        lib.mint.err(wherestr, "expected " .. ty .. ", got " .. type(val))
    end
    return true
end


return lib