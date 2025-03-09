-- short for mimosa interpreter
local mint = {
    ok = true,
    memo = {},
    stack = {},
    pile = {},

    line = 1,
    idx = 1,
    sp = 0,

    verbose = true,
    outcolor = 12,
}


function mint.interpret(instructions, stack, pile)
    mint.ok = true
    mint.line = 1
    mint.idx = 1
    mint.sp = 0

    mint.say("interpreting")
    if stack then mint.stack = stack end
    if pile then mint.pile = pile end

    while mint.idx <= #instructions do
        local inst = instructions[mint.idx]
        mint.line = inst.line
        local func = mint.operations[inst.type]
        if func == nil then
            mint.err("", "bad operation (" .. inst.type .. ")")
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
        if bool then
            mint.say("no skip")
        else
            mint.say("skip to " .. skipstop)
            mint.idx = skipstop
        end
    else
        mint.err(" skip ({)", "missing operand")
    end
end


function mint.set()
    local name, val = mint.pop(), mint.pop()
    if name ~= nil and val ~= nil then
        if type(name) == "string" then
            mint.pile[name] = val
        elseif type(name) == "number" then
            mint.ok = mint.memo.memapi.poke(name, val)
        else
            mint.err(" set", "expected identifier or address")
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
            end
        else
            mint.err(" get", "expected identifier or address")
        end
    else
        mint.err(" get", "missing operand")
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
            mint.err(" subtract", "cannot suntract " .. type(b) .. " from " .. type(a))
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


function mint.pop()
    if mint.sp <= 0 then
        mint.err("", "stack underflow")
        return
    end
    local value = table.remove(mint.stack, mint.sp)
    mint.sp = mint.sp - 1
    mint.say("pop " .. tostring(value))
    return value
end


function mint.err(where, msg)
    mint.ok = false
    mint.baseerr(mint.line, where, msg)
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
        return mint.int(value) > 0
    elseif type(value) == "string" or type(value) == "table" then
        return #value > 0
    end
    return false
end


-- Todo: list ([]), char, ink, tile, fill, txt, buff, comparison
mint.operations = {
    string = mint.push,
    int = function (value) mint.push(mint.int(value)) end,
    identifier = mint.push,
    pop = mint.pop,
    out = mint.out,
    O = mint.out,
    ["true"] = mint.bool,
    ["false"] = mint.bool,
    ["="] = mint.set,
    ["."] = mint.get,
    ["+"] = mint.add,
    ["-"] = mint.sub,
    ["*"] = mint.mult,
    ["/"] = mint.div,
    ["**"] = mint.pow,
    ["\\"] = mint.mod,
    ["--"] = mint.negate,
    ["!"] = mint.isnot,
    ["~"] = mint.binot,
    ["{"] = mint.skip,
    ["}"] = function () end,
}


return mint