-- short for mimosa interpreter
local mint = {
    ok = true,
    memo = {},
    lib = {},

    stack = {},
    truestack = {},
    lists = {},
    callstack = {},
    skipstack = {},
    pile = {},
    tags = {}, -- In name:idx pairs
    instructions = {}, -- last PASSED instructions from mint.interpret

    line = 1,
    idx = 1,
    outcolor = 12,
}

mint.truestack = mint.stack
local bit = require("bit")


function mint.interpret(instructions, stack, pile, tags, from)
    mint.ok = true
    mint.line = 1
    mint.idx = from or mint.idx
    mint.instructions = instructions or mint.instructions
    mint.callstack = {}
    mint.skipstack = {}

    if stack then mint.stack = stack end
    if pile then mint.pile = pile end
    if tags then mint.tags = tags end
    if from then mint.idx = from end

    mint.truestack = mint.stack
    mint.lists = {}

    while mint.idx <= #mint.instructions do
        local inst = mint.instructions[mint.idx]
        mint.line = inst.line

        local func = mint.operations[inst.type]
        if func == nil then
            mint.err(" interpret", "bad operation (" .. inst.type .. ")")
            return
        end
        func(inst.value)

        if not mint.ok then break end
        mint.idx = mint.idx + 1
    end
end


function mint.skip(skipstop)
    local bool = mint.pop()
    if bool ~= nil then
        if mint.truth(bool) then
            table.insert(mint.skipstack, mint.idx)
        else
            mint.idx = skipstop
        end
    else
        mint.err(" skip ({)", "missing operand")
    end
end


function mint.endskip()
    table.remove(mint.skipstack)
end


function mint.hop()
    local bool = mint.pop()
    if bool ~= nil then
        if mint.truth(bool) then
            if #mint.skipstack > 0 then
                mint.idx = mint.skipstack[#mint.skipstack]
            else
                mint.err(" hop (^)", "not inside of skip")
            end
        end
    else
        mint.err(" hop (^)", "missing operand")
    end
end


function mint.godo()
    mint.jump(true)
end


function mint.jump(canreturn)
    local where = " jump"
    if canreturn then where = " do ($)" end
    local funcname = mint.pop()
    if funcname ~= nil then
        if type(funcname) == "string" then
            local pos = mint.tags[funcname]
            if pos ~= nil then
                if canreturn then
                    table.insert(mint.callstack,
                    {name = funcname, from = mint.idx, line = mint.line})
                    if #mint.callstack > 0xFFFF then
                        mint.err(where, "callstack overflow from " .. funcname)
                    end
                end
                mint.idx = pos
            else
                mint.err(where, "##" .. funcname .. " does not exist")
            end
        else
            mint.err(where, "expected string, got " .. type(funcname))
        end
    else
        mint.err(where, "missing operand")
    end
end


function mint.goend()
    if #mint.callstack > 0 then
        local origin = table.remove(mint.callstack)
        mint.idx = origin.from
    else
        mint.idx = #mint.instructions
    end
end


function mint.skipregion(skipstop)
    mint.idx = skipstop
end


function mint.set()
    local name, val = mint.pop(), mint.pop()
    if name ~= nil and val ~= nil then
        if type(name) == "string" then
            mint.pile[name] = val
        elseif type(name) == "number" then
            if type(val) == "number" then
                mint.ok = mint.memo.memapi.poke(name, val)
                if not mint.ok then
                    mint.err(" poke", "could not write memory")
                end
            else
                mint.err(" poke", "cannot poke " .. type(val))
            end
        else
            mint.err(" set", "expected identifier or address, got " .. type(name))
        end
    else
        mint.err(" set", "missing operand")
    end
end


function mint.get()
    local name = mint.pop()
    if name ~= nil then
        if type(name) == "string" then
            local val = mint.pile[name]
            if val ~= nil then
                mint.push(val)
            else
                mint.err(" get", name .. " is undefined")
            end
        elseif type(name) == "number" then
            local val = mint.memo.memapi.peek(name)
            if val ~= nil then
                mint.push(val)
            else
                mint.err(" peek", "could not read memory")
            end
        elseif type(name) == "table" then
            local copy = {}
            for i, v in ipairs(name) do
                copy[i] = v
            end
            mint.push(copy)
        else
            mint.err(" get", "expected identifier or address, got " .. type(name))
        end
    else
        mint.err(" get", "missing operand")
    end
end


function mint.increment(amount)
    local name = mint.pop()
    local toadd = amount or 1
    if name ~= nil then
        if type(name) == "string" then
            if mint.pile[name] ~= nil then
                mint.pile[name] = mint.int(mint.pile[name] + amount)
            else
                mint.err(" increment", name .. " is undefined")
            end
        elseif type(name) == "number" then
            local val = mint.memo.memapi.peek(name)
            if val ~= nil then
                mint.ok = mint.memo.memapi.poke(name, (val + toadd) % 0xFF)
                if not mint.ok then
                    mint.err(" increment", "could not write memory")
                end
            else
                mint.err(" increment", "could not read memory")
            end
        else
            mint.err(" increment", "expected identifier or address, got ".. type(name))
        end
    else
        mint.err(" increment", "missing operand")
    end
end


function mint.out()
    local txt = mint.pop()
    if txt ~= nil then
        mint.memo.editor.console.print(txt, mint.outcolor)
    else
        mint.err(" out", "missing operand")
    end
end


function mint.outcolr()
    local colr = mint.pop()
    if colr ~= nil then
        if type(colr) == "number" then
            if colr >= 0 and colr < 16 then
                mint.outcolor = colr
            else
                mint.err(" outcolr", "color must be 0 to 15, but is " .. tostring(colr))
            end
        else
            mint.err(" outcolr", "expected int, got " .. type(colr))
        end
    else
        mint.err(" outcolr", "missing operand")
    end
end


function mint.apierr()
    local txt = mint.pop()
    if txt ~= nil then
        mint.err("", tostring(txt))
    else
        mint.err(" err", "missing operand")
    end
end


function mint.add()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            mint.push(mint.int(a + b))
        elseif type(a) == "string" or type(b) == "string" then
            mint.push(tostring(a) .. tostring(b))
        else
            mint.err(" add", "cannot add " .. type(a) .. " to " .. type(b))
        end
    else
        mint.err(" add", " missing operand")
    end
end


function mint.sub()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            mint.push(mint.int(a - b))
        else
            mint.err(" subtract", "cannot subtract " .. type(b) .. " from " .. type(a))
        end
    else
        mint.err(" subtract", " missing operand")
    end
end


function mint.mult()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            mint.push(mint.int(a * b))
        else
            mint.err(" multiply", "cannot multiply " .. type(a) .. " by " .. type(b))
        end
    else
        mint.err(" multiply", " missing operand")
    end
end


function mint.div()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            if b == 0 then
                mint.err(" divide", "division by 0")
                return
            end
            mint.push(mint.int(a / b))
        else
            mint.err(" divide", "cannot add " .. type(a) .. " to " .. type(b))
        end
    else
        mint.err(" divide", " missing operand")
    end
end


function mint.pow()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            mint.push(mint.int(a ^ b))
        else
            mint.err(" power", "cannot raise " .. type(a) .. " to " .. type(b))
        end
    else
        mint.err(" power", " missing operand")
    end
end


function mint.mod()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            if b == 0 then
                mint.err(" modulo", "division by 0")
                return
            end
            mint.push(mint.int(a % b))
        else
            mint.err(" modulo", "cannot divide " .. type(a) .. " by " .. type(b))
        end
    else
        mint.err(" modulo", "missing operand")
    end
end


function mint.merge()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if type(a) == "number" and type(b) == "number" then
            mint.push(mint.int(bit.lshift(a % 16, 4) + b % 16))
        else
            mint.err(" merge (:)", "cannot merge " .. type(a) .. " and " .. type(b))
        end
    else
        mint.err(" merge (:)", "missing operand")
    end
end


function mint.compare(mode)
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        if mode == "equals" then
            mint.push(a == b)
        elseif (type(a) == type(b)) then
            if mode == "more" then
                mint.push(a > b)
            elseif mode == "less" then
                mint.push(a < b)
            elseif mode == "no less" then
                mint.push(a >= b)
            elseif mode == "no more" then
                mint.push(a <= b)
            end
        else
            mint.err(" " .. mode, "cannot compare " .. type(a) .. " and " .. type(b))
        end
    else
        mint.err(" " .. mode, "missing operand")
    end
end


function mint.logic(mode)
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        a, b = mint.truth(a), mint.truth(b)
        if mode == "and" then
            mint.push(a and b)
        elseif mode == "or" then
            mint.push(a or b)
        end
    else
        mint.err(" " .. mode, "missing operand")
    end
end


function mint.negate()
    local value = mint.pop()
    if value ~= nil then
        if type(value) == "number" then
            mint.push(mint.int(-value))
        else
            mint.err(" negate", "cannot negate " .. type(value))
        end
    else
        mint.err(" negate", "missing operand")
    end
end


function mint.isnot()
    local value = mint.pop()
    if value ~= nil then
        mint.push(not mint.truth(value))
    else
        mint.err(" not (!)", "missing operand")
    end
end


function mint.binot()
    local value = mint.pop()
    if value ~= nil then
        if type(value) == "number" then
            mint.push(bit.bnot(value))
        else
            mint.err(" not (~)", "cannot negate " .. type(value))
        end
    else
        mint.err(" not (~)", "missing operand")
    end
end


function mint.bool(value)
    if value == "true" then mint.push(true)
    else mint.push(false) end
end


function mint.tochar()
    local char = mint.pop()
    if char ~= nil then
        if type(char) == "string" then
            if #char == 1 then
                mint.push(string.byte(char))
            else
                mint.err(" char(')", "invalid character (" .. char .. ")")
            end
        elseif type(char) == "number" then
            mint.push(char % 0x100)
        else
            mint.err(" char (')", "cannot convert " .. type(char) .. " to byte (int)")
        end
    else
        mint.err(" char (')", "missing operand")
    end
end


function mint.listget()
    local list, index = mint.pop(), mint.pop()
    if list ~= nil and index ~= nil then
        if type(index) == "number" then
            index = mint.luaidx(index, list)
            if type(list) == "table" then
                if index > #list then
                    mint.err(" index (@)", index .. " is out of bounds")
                    return
                end
                mint.push(list[index])
            elseif type(list) == "string" then
                if index > #list then
                    mint.err(" index (@)", index .. " is out of bounds")
                    return
                end
                mint.push(string.sub(list, index, index))
            else
                mint.err(" index (@)", "cannot index " .. type(list))
            end
        else
            mint.err(" index (@)", "index cannot be " .. type(index))
        end
    else
        mint.err(" index (@)", "missing operand")
    end
end


function mint.listset()
    local list, index, value = mint.pop(), mint.pop(), mint.pop()
    if list ~= nil and index ~= nil and value ~= nil then
        if type(index) == "number" then
            if type(list) == "table" then
                index = mint.luaidx(index, list)
                if index > #list then
                    mint.err(" mutate (@=)", index .. " is out of bounds")
                    return
                end
                list[index] = value
            else
                mint.err(" mutate (@=)", "cannot mutate " .. type(list))
            end
        else
            mint.err(" mutate (@=)", "index cannot be " .. type(index))
        end
    else
        mint.err(" mutate (@=)", "missing operand")
    end
end


function mint.listinsert()
    local list, index, value = mint.pop(), mint.pop(), mint.pop()
    if list ~= nil and index ~= nil and value ~= nil then
        if type(index) == "number" then
            if type(list) == "table" then
                index = mint.luaidx(index, list)
                if index > #list then
                    mint.err(" insert (@+)", index .. " is out of bounds")
                    return
                end
                table.insert(list, index, value)
            else
                mint.err(" insert (@+)", "cannot mutate " .. type(list))
            end
        else
            mint.err(" insert (@+)", "index cannot be " .. type(index))
        end
    else
        mint.err(" insert (@+)", "missing operand")
    end
end


function mint.listremove()
    local list, index = mint.pop(), mint.pop()
    if list ~= nil and index ~= nil then
        if type(index) == "number" then
            if type(list) == "table" then
                index = mint.luaidx(index, list)
                if index > #list then
                    mint.err(" remove (@-)", index .. " is out of bounds")
                    return
                end
                table.remove(list, index)
            else
                mint.err(" remove (@-)", "cannot mutate " .. type(list))
            end
        else
            mint.err(" remove (@-)", "index cannot be " .. type(index))
        end
    else
        mint.err(" remove (@-)", "missing operand")
    end
end


function mint.listpush()
    local list, value = mint.pop(), mint.pop()
    if list ~= nil and value ~= nil then
        if type(list) == "table" then
            table.insert(list, value)
        else
            mint.err(" list push (@<)", "cannot mutate " .. type(list))
        end
    else
        mint.err(" list push (@<)", "missing operand")
    end
end


function mint.listpop()
    local list = mint.pop()
    if list ~= nil then
        if type(list) == "table" then
            if #list > 0 then
                mint.push(table.remove(list))
            else
                mint.err(" list pop (@>)", "list underflow")
            end
        else
            mint.err(" list pop (@>)", "cannot mutate " .. type(list))
        end
    else
        mint.err(" list pop (@>)", "missing operand")
    end
end


function mint.listlen()
    local item = mint.pop()
    if item ~= nil then
        if type(item) == "string" or type(item) == "table" then
            mint.push(#item)
        else
            mint.err(" length (@#)", "cannot get length of " .. type(item))
        end
    else
        mint.err(" length (@#)", "missing operand")
    end
end


function mint.openlist()
    local list = {}
    table.insert(mint.lists, list)
    mint.stack = list
end


function mint.closelist()
    -- Remove and push the last list
    local list = mint.stack
    -- Set stack to previous list or true stack if none
    if #mint.lists > 0 then
        mint.stack = mint.lists[#mint.lists]
    else
        mint.stack = mint.truestack
    end
    mint.push(list)
    table.remove(mint.lists, #mint.lists)
end


function mint.type()
    local val = mint.pop()
    if val ~= nil then
        mint.push(mint.mosatype(type(val)))
    else
        mint.err(" type", "missing operand")
    end
end


function mint.mosatype(ty)
    local types = {
        ["number"] = "int",
        ["string"] = "str",
        ["table"] = "list",
        ["boolean"] = "bool",
    }
    return types[ty]
end


function mint.tostr()
    local val = mint.pop()
    if val ~= nil then
        mint.push(tostring(val))
    else
        mint.err(" str", "missing operand")
    end
end


function mint.toint()
    local val = mint.pop()
    if val ~= nil then
        if type(val) == "boolean" then
            if val then mint.push(1) else mint.push(0) end
        elseif type(val) == "string" then
            mint.push(mint.int(tonumber(val)))
        elseif type(val) == "number" then
            mint.push(mint.int(val))
        else
            mint.err(" int", "cannot convert " .. type(val) .. " to int")
        end
    else
        mint.err(" int", "missing operand")
    end
end


function mint.push(value)
    table.insert(mint.stack, value)
end


function mint.snap()
    mint.stack = {}
end


function mint.crackle()
    mint.push(mint.stack)
end


function mint.pop()
    if #mint.stack > 0 then
        local value = table.remove(mint.stack)
        if value == nil then
            mint.err(" pop", "fatal: is nil")
        end
        return value
    else
        mint.err("", "stack underflow")
    end
end


function mint.stat(offset)
    local code = mint.pop()
    if code ~= nil then
        if type(code) == "number" then
            mint.push(mint.memo.stat(code + offset))
        elseif type(code) == "string" then
            mint.push(mint.pile[code] ~= nil)
        else
            mint.err(" stat (?)", "expected identifier or address, got " .. type(code))
        end
    else
        mint.err(" stat (?)", "missing operand")
    end
end


function mint.del()
    local name = mint.pop()
    if name ~= nil then
        if type(name) == "string" then
            mint.pile[name] = nil
        else
            mint.err(" del", "expected identifier, got " .. type(name))
        end
    else
        mint.err(" del", "missing operand")
    end
end


function mint.pushpop()
    local val = mint.pop()
    if val ~= nil then
        mint.push(val)
        mint.push(val)
    else
        mint.err(" push", "missing operand")
    end
end


function mint.err(where, msg)
    mint.ok = false
    mint.baseerr(mint.line, where, msg)
end


function mint.error()
    local msg = mint.pop()
    if msg ~= nil then
        mint.err("", tostring(msg))
    else
        mint.err(" err", "missing operand")
    end
end


function mint.int(x)
    return (math.floor(x) + 0x8000) % (0x7FFF + 0x8000 + 1) - 0x8000
end


function mint.luaidx(num, list)
    if num >= 0 then
        return num + 1
    else
        if type(list) == "string" or type(list) == "table" then
            return #list + num + 1
        else
            return 1
        end
    end
end


function mint.truth(value)
    if type(value) == "boolean" then
        return value
    elseif type(value) == "number" then
        return mint.int(value) ~= 0
    elseif type(value) == "string" or type(value) == "table" then
        return #value > 0
    end
    return false
end


function mint.init()
    mint.operations = {
        -- Literals
        string = mint.push,
        integer = function (value) mint.push(mint.int(value)) end,
        identifier = mint.push,
        ["true"] = mint.bool,
        ["false"] = mint.bool,
        ["'"] = mint.tochar,

        -- Stack and pile
        snap = mint.snap,
        crackle = mint.crackle,
        pop = mint.pop,
        push = mint.pushpop,
        P = mint.pushpop,
        stack = mint.crackle,
        del = mint.del,
        ["="] = mint.set,
        ["."] = mint.get,

        -- Lists
        ["["] = mint.openlist;
        ["]"] = mint.closelist;
        ["@"] = mint.listget;
        ["@="] = mint.listset;
        ["@+"] = mint.listinsert;
        ["@-"] = mint.listremove;
        ["@<"] = mint.listpush;
        ["@>"] = mint.listpop;
        ["@#"] = mint.listlen;

        -- Control flow
        ["^"] = mint.hop,
        ["{"] = mint.skip,
        ["$"] = mint.jump,
        hop = mint.hop,
        jump = mint.jump,
        ["do"] = mint.godo,
        ["#"] = mint.godo,
        ["end"] = mint.goend,
        region = mint.skipregion,
        ["}"] = mint.endskip,
        tag = function () end,

        -- Logical binops
        [">"] = function () mint.compare("more") end,
        ["<"] = function () mint.compare("less") end,
        [">="] = function () mint.compare("no less") end,
        ["<="] = function () mint.compare("no more") end,
        ["=="] = function () mint.compare("equals") end,
        ["&&"] = function () mint.logic("and") end,
        ["||"] = function () mint.logic("or") end,

        -- Mathematical binops
        ["+"] = mint.add,
        ["-"] = mint.sub,
        ["*"] = mint.mult,
        ["/"] = mint.div,
        ["**"] = mint.pow,
        ["\\"] = mint.mod,
        [":"] = mint.merge,

        -- Unary operations
        ["!"] = mint.isnot,
        ["~~"] = mint.binot,
        ["~"] = mint.negate,
        ["++"] = function () mint.increment(1) end,
        ["--"] = function () mint.increment(-1) end,

        -- Console
        out = mint.out,
        O = mint.out,
        err = mint.error,
        outcolr = mint.outcolr,

        -- Types
        ["type"] = mint.type,
        str = mint.tostr,
        int = mint.toint,

        -- System
        ["?"] = mint.stat,
        stat = mint.stat,
        btn = mint.lib.btn,
        btnp = mint.lib.btnp,
        btnr = mint.lib.btnr,
        stop = mint.memo.cart.stop,

        -- Drawing
        fill = mint.lib.fill,
        tile = mint.lib.tile,
        T = mint.lib.tile,
        etch = mint.lib.etch,
        E = mint.lib.etch,
        ink = mint.lib.ink,
        I = mint.lib.ink,
        cget = mint.lib.cget,
        iget = mint.lib.iget,
        rect = mint.lib.rect,
        R = mint.lib.rect,
        crect = mint.lib.crect,
        irect = mint.lib.irect,
        text = mint.lib.text,
        write = mint.lib.write,
        pan = mint.lib.pan,

        -- Audio
        blip = mint.lib.blip,
        beep = mint.lib.beep,
        chirp = mint.lib.chirp,
        sfxset = mint.lib.sfxset,

        -- Math
        abs = mint.lib.abs,
        cos = mint.lib.cos,
        sin = mint.lib.sin,
        min = mint.lib.min,
        max = mint.lib.max,
        rnd = mint.lib.rnd,
    }
end


return mint