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
function lib.btn()
    local code = lib.mint.pop()
    if code ~= nil then
        if lib.badtype(code, "number", " btn") then return end
        lib.mint.push(lib.memo.input.btn(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnp()
    local code = lib.mint.pop()
    if code ~= nil then
        if lib.badtype(code, "number", " btnp") then return end
        lib.mint.push(lib.memo.input.btn(code) and not lib.memo.input.old(code))
    else
        lib.mint.err(" btn", "missing operand")
    end
end


function lib.btnr()
    local code = lib.mint.pop()
    if code ~= nil then
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
    if char ~= nil and colr ~= nil then
        for idx = 0, 0xFF do
            if not m.ok then return end
            lib.tile(nil, idx, char, colr)
        end
    else
        m.err(" fill", "missing operand")
    end
end


function lib.text()
    local m = lib.mint
    local width, from, str, colr = m.pop(), m.pop(), m.pop(), m.pop()
    if from ~= nil and str ~= nil and colr ~= nil and width ~= nil then
        if lib.badtype(width, "number", " text:width") then return end
        if lib.badtype(from, "number", " text:pos") then return end
        if lib.badtype(colr, "number", " text:color") then return end

        str = tostring(str)
        local y, x = lib.split(from)
        local bg, fg = lib.split(colr)
        lib.draw.text(x, y, str, fg, bg, width, false)
    else
        m.err(" text", "missing operand")
    end
end


function lib.tile(val, pidx, pchar, pcolr)
    local m = lib.mint

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

    -- Becomes stack-based if no params provided
    local idx, char = pidx, pchar
    if idx == nil then idx = m.pop() end
    if char == nil then char = m.pop() end

    char = lib.tobyte(char, " etch")

    if char ~= nil and idx ~= nil then
        if lib.badtype(idx, "number", " etch:idx") then return end
        local y, x = lib.split(idx)
        lib.draw.char(x, y, char)
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

    if colr ~= nil and idx ~= nil then
        if lib.badtype(idx, "number", " ink:idx") then return end
        if lib.badtype(colr, "number", " ink:color") then return end

        local y, x = lib.split(idx)
        local bg, fg = lib.split(colr)
        lib.draw.ink(x, y, fg, bg)
    else
       m.err(" ink", "missing operand")
    end
end


function lib.cget()

end


function lib.iget()
    local m = lib.mint
    local idx = m.pop()
    if m ~= nil then
        else
    end
end


function lib.rect(val, pfrom, pto, pchar, pcolr)
    local m = lib.mint
    local to = pfrom or m.pop()
    local from = pto or m.pop()
    local char = pchar or m.pop()
    local colr = pcolr or m.pop()
    char = lib.tobyte(char, " crect:char")
    if to ~= nil and from ~= nil and colr ~= nil and char ~= nil then
        if lib.badtype(to, "number", " rect:to") then return end
        if lib.badtype(from, "number", " rect:from") then return end
        if lib.badtype(colr, "number", " rect:color") then return end

        local y, x = lib.split(from)
        local b, a = lib.split(to)
        local bg, fg = lib.split(colr)
        local w, h = a - x + 1, b - y + 1
        return lib.draw.rect(x, y, w, h, char, fg, bg)
    else
        m.err(" irect", "missing operand")
    end
end


function lib.crect(val, pfrom, pto, pchar)
    local m = lib.mint
    local to = pfrom or m.pop()
    local from = pto or m.pop()
    local char = pchar or m.pop()
    char = lib.tobyte(char, " crect:char")
    if to ~= nil and from ~= nil and char ~= nil then
        if lib.badtype(to, "number", " crect:to") then return end
        if lib.badtype(from, "number", " crect:from") then return end

        local y, x = lib.split(from)
        local b, a = lib.split(to)
        local w, h = a - x + 1, b - y + 1
        return lib.draw.crect(x, y, w, h, char)
    else
        m.err(" crect", "missing operand")
    end
end


function lib.irect(val, pfrom, pto, pcolr)
    local m = lib.mint
    local to = pfrom or m.pop()
    local from = pto or m.pop()
    local colr = pcolr or m.pop()
    if to ~= nil and from ~= nil and colr ~= nil then
        if lib.badtype(to, "number", " irect:to") then return end
        if lib.badtype(from, "number", " irect:from") then return end
        if lib.badtype(colr, "number", " irect:color") then return end

        local y, x = lib.split(from)
        local b, a = lib.split(to)
        local bg, fg = lib.split(colr)
        local w, h = a - x + 1, b - y + 1
        return lib.draw.irect(x, y, w, h, fg, bg)
    else
        m.err(" irect", "missing operand")
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
    if wav ~= nil and note ~= nil and vol ~= nil and at ~= nil then
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

-- Takes a value in the format #AB and returns A, B
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
            return string.byte(char)
        elseif #char > 1 then
            lib.mint.err(wherestr, "cannot convert multi-char string to byte (int)")
            return nil
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
    local toerr = should_err
    if toerr == nil then toerr = true end
    if type(val) ~= ty then
        if toerr then
            lib.mint.err(wherestr, "expected " .. ty .. ", got " .. type(val))
        end
        return true
    end
    return false
end


return lib