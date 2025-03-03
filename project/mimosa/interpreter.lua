-- short for mimosa interpreter
local mint = {
    ok = true,
    memo = {},
    stack = {},
    heap = {},
    line = 1,
    idx = 1,
    sp = 0,
    verbose = true,
    outcolor = 12,
}


function mint.interpret(instructions, stack, heap)
    mint.ok = true
    mint.line = 1
    mint.idx = 1
    mint.sp = 0

    mint.say("interpreting")
    if stack then mint.stack = stack end
    if heap then mint.heap = heap end

    while mint.idx <= #instructions do
        local i = mint.idx
        local inst = instructions[i]
        mint.line = inst.line
        local func = mint.operations[inst.type]
        if func == nil then
            mint.err("", "bad operation (" .. inst.type .. ")")
            return
        end

        func(inst.value)

        if mint.errored then break end
        mint.idx = i + 1
    end
end


function mint.set(v)
    local name, val = mint.pop(), mint.pop()
    if name and val then
        if type(name) == "string" then
            mint.heap[name] = val
        else
            mint.err(" set", "expected identifier for name")
        end
        mint.say("set " .. name .. " to " .. tostring(val))
    else
        mint.err(" set", "missing operand")
    end
end


function mint.get(v)
    local name = mint.pop()
    if name then
        if type(name) == "string" then
            local val = mint.heap[name]
            if val ~= nil then
                mint.say("get " .. name)
                mint.push(val)
            else
                mint.err(" get", name .. " is undefined")
            end
        else
            mint.err(" get", "expected identifier for name")
        end
    else
        mint.err(" get", "missing operand")
    end
end


function mint.out()
    local txt = mint.pop()
    if txt then
        mint.memo.editor.console.print(txt, mint.outcolor)
    else
        mint.err(" out", "missing operand")
    end
end


function mint.add(v)
    local b, a = mint.pop(), mint.pop()
    if a and b then
        print("add " .. tostring(a) .." to " .. tostring(b))
        if type(a) == "number" and type(b) == "number" then
            mint.push(a + b)
        elseif type(a) == "string" or type(b) == "string" then
            mint.push(tostring(a) .. tostring(b))
        else
            mint.err(" add", "cannot add " .. type(a) .. " to " .. type(b))
        end
    else
        mint.err(" add", " missing operand")
    end
end


function mint.sub(v)
    mint.say("sub isn't done")
end


function mint.mult(v)
    mint.say("mult isn't done")
end


function mint.div(v)
    mint.say("div isn't done")
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
    mint.say("pop " .. value)
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


mint.operations = {
    string = mint.push,
    identifier = mint.push,
    out = mint.out,
    ["="] = mint.set,
    ["."] = mint.get,
    ["+"] = mint.add,
    ["-"] = mint.sub,
    ["*"] = mint.mult,
    ["/"] = mint.div,
    ["--"] = mint.negate,
    ["!"] = mint.isnot,
    ["~"] = mint.binot,
}


return mint