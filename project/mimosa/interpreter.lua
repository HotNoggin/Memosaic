local interpreter = {
    errored = false,
    stack = {},
    heap = {},
    line = 1,
    idx = 1,
}


function interpreter.interpret(instructions, stack, heap)
    print("interpreting")
    if stack then interpreter.stack = stack end
    if heap then interpreter.heap = heap end

    while interpreter.idx <= #instructions do
        local i = interpreter.idx
        local inst = instructions[i]
        interpreter.line = inst.line
        local func = interpreter.operations[inst.type]
        if func == nil then
            interpreter.err("", "bad operation (" .. inst.type .. ")")
            return
        end

        if interpreter.errored then break end
        interpreter.idx = i + 1
    end
end


function interpreter.err(where, msg)
    interpreter.errored = true
    interpreter.baseerr(interpreter.line, where, msg)
end


interpreter.operations = {

}


return interpreter