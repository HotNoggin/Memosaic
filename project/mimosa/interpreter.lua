-- short for mimosa interpreter
local mint = {
    ok = true,
    memo = {},
    lib = {},

    stack = {},
    callstack = {},
    skipstack = {},
    pile = {},
    tags = {}, -- In name:idx pairs
    instructions = {}, -- last PASSED instructions from mint.interpret

    line = 1,
    idx = 1,
    sp = 0,

    verbose = false,
    outcolor = 12,
}


function mint.interpret(instructions, stack, pile, tags, from)
    mint.ok = true
    mint.line = 1
    mint.idx = 1
    mint.sp = 0
    mint.callstack = {}
    mint.skipstack = {}
    mint.instructions = instructions

    mint.say("interpreting")
    if stack then mint.stack = stack end
    if pile then mint.pile = pile end
    if tags then mint.tags = tags end
    if from then mint.idx = from end

    while mint.idx <= #instructions do
        local inst = instructions[mint.idx]
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
            mint.say("no skip")
            table.insert(mint.skipstack, mint.idx)
        else
            mint.say("skip to " .. skipstop)
            mint.idx = skipstop
        end
    else
        mint.err(" skip ({)", "missing operand")
    end
end


function mint.endskip()
    mint.say("skip complete")
    table.remove(mint.skipstack, #mint.skipstack)
end


function mint.hop()
    local bool = mint.pop()
    if bool ~= nil then
        if mint.truth(bool) then
            if #mint.skipstack > 0 then
                mint.say("hop back up to " .. mint.skipstack[#mint.skipstack])
                mint.idx = mint.skipstack[#mint.skipstack]
            else
                mint.err(" hop (^)", "not inside of skip")
            end
        else
            mint.say("no hop")
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
                mint.say("jumping to " .. funcname .. " at " .. pos)
                if canreturn then
                    mint.say("can return to " .. mint.idx)
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
        local origin = table.remove(mint.callstack, #mint.callstack)
        mint.idx = origin.from
        mint.say("return to " .. origin.name)
    else
        mint.say("go to end")
        mint.idx = #mint.instructions
    end
end


function mint.skipregion(skipstop)
    mint.say("skip over tag to " .. skipstop)
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
        mint.say("set " .. name .. " to " .. tostring(val))
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
                mint.say("get " .. name)
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
        else
            mint.err(" get", "expected identifier or address, got " .. type(name))
        end
    else
        mint.err(" get", "missing operand")
    end
end


function mint.increment(amount)
    local name = mint.pop()
    local toadd = 1
    if amount then toadd = amount end
    if name ~= nil then
        mint.say("incrementing " .. name)
        if type(name) == "string" then
            if mint.pile[name] ~= nil then
                mint.pile[name] = mint.int(mint.pile[name] + amount)
            else
                mint.err(" increment", name .. " is undefined")
            end
        elseif type(name) == "number" then
            local val = mint.memo.memapi.peek(name)
            if val ~= nil then
                mint.ok = mint.memo.memapi.poke((val+toadd)%0xFF)
                if not mint.ok then
                    mint.err(" increment", "could not write memory")
                end
            else
                mint.err(" increment", "could not read memory")
            end
        else
            mint.err(" increment", "expected identifier or address, got ".. type(name))
        end
    end
end


function mint.out()
    local txt = mint.pop()
    if txt ~= nil then
        mint.say("out")
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


function mint.add()
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        mint.say("add " .. tostring(a) .." to " .. tostring(b))
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
        mint.say("subtract " .. tostring(b) .." from " .. tostring(a))
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
        mint.say("multiply " .. tostring(a) .." by " .. tostring(b))
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
        mint.say("divide " .. tostring(a) .." by " .. tostring(b))
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
        mint.say("pow " .. tostring(a) .." to " .. tostring(b))
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
        mint.say("mod " .. tostring(a) .." by " .. tostring(b))
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


function mint.compare(mode)
    local b, a = mint.pop(), mint.pop()
    if a ~= nil and b ~= nil then
        mint.say("compare " .. tostring(a) .. " " .. mode .. " " .. tostring(b))
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
        mint.say("logic " .. tostring(a) .. " " .. mode .. " " .. tostring(b))
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
            mint.say("numerical negate " .. tostring(value))
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
        mint.say("logical negate " .. tostring(value))
        mint.push(not mint.truth(value))
    else
        mint.err(" not (!)", "missing operand")
    end
end


function mint.binot()
    local value = mint.pop()
    if value ~= nil then
        if type(value) == "number" then
            mint.say("binot " .. value)
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


function mint.push(value)
    mint.say("push " .. tostring(value))
    mint.sp = mint.sp + 1
    mint.stack[mint.sp] = value
end


function mint.snap()
    mint.say("snap")
    mint.sp = 1
    mint.stack = {}
end


function mint.crackle()
    local stack = mint.stack
    -- mint.push(stack)
    mint.err(" crackle", "not yet implemented")
    return
end


function mint.pop()
    if mint.sp > 0 then
        local value = table.remove(mint.stack, mint.sp)
        mint.sp = mint.sp - 1
        mint.say("pop " .. tostring(value))
        if value == nil then
            mint.err(" pop", "fatal: is nil")
        end
        return value
    else
        mint.err("", "stack underflow")
    end
end


function mint.del()
    mint.say("del")
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
    mint.say("peeking")
    local val = mint.pop()
    if val ~= nil then
        mint.push(val)
        mint.push(val)
    else
        mint.err("push", "missing operand")
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


function mint.say(txt)
    if mint.verbose then
        print(txt)
    end
end


function mint.int(num)
    local x = math.floor(num)
    return (x + 0x8000) % (0x7FFF + 0x8000 + 1) + -0x8000
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
        int = function (value) mint.push(mint.int(value)) end,
        identifier = mint.push,
        ["true"] = mint.bool,
        ["false"] = mint.bool,

        -- Stack and pile
        snap = mint.snap,
        crackle = mint.crackle,
        pop = mint.pop,
        push = mint.pushpop,
        P = mint.pushpop,
        del = mint.del,
        ["="] = mint.set,
        ["."] = mint.get,

        -- Code flow
        hop = mint.hop,
        ["^"] = mint.hop,
        ["{"] = mint.skip,
        jump = mint.jump,
        ["do"] = mint.godo,
        ["$"] = mint.godo,
        ["end"] = mint.goend,
        region = mint.skipregion,
        ["}"] = mint.endskip,
        tag = function (value) mint.say("Passed tag " .. value) end,

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

        -- Input
        ["?"] = mint.lib.stat,
        stat = mint.lib.stat,
        btn = mint.lib.btn,
        btnp = mint.lib.btnp,
        btnr = mint.lib.btnr,

        -- Drawing
        fill = mint.lib.fill,
        tile = mint.lib.tile,
        T = mint.lib.tile,
        etch = mint.lib.etch,
        E = mint.lib.etch,
        ink = mint.lib.ink,
        I = mint.lib.ink,
        rect = mint.lib.rect,
        R = mint.lib.rect,
        crect = mint.lib.crect,
        irect = mint.lib.irect,
        text = mint.lib.text,

        -- Audio
        blipat = mint.lib.blipat,
        blip = mint.lib.blip,
        beepat = mint.lib.beepat,
        beep = mint.lib.beep,
    }
end


return mint