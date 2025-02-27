--Mimosa interpreter
local mimosa = {
    scanner = require("mimosa.scanner"),
    parser = require("mimosa.parser"),
    evaluator = require("mimosa.evaluator"),
    had_err = false,
}

mimosa.mosalib = mimosa.evaluator.mosalib

function mimosa.init(memo)
    mimosa.cli = memo.editor.console
    mimosa.scanner.err = mimosa.error
    mimosa.parser.err = mimosa.error
    mimosa.evaluator.err = mimosa.error
    mimosa.mosalib.callstack = mimosa.evaluator.callstack
    mimosa.mosalib.init(memo)
end


function mimosa.run(code)
    mimosa.had_err = false
    local tokens = mimosa.scanner.scan(code)
    if mimosa.had_err then return end
    local tree = mimosa.parser.maketree(tokens)
    if mimosa.had_err then return end
    mimosa.evaluator.evaluate(tree, {})
end


function mimosa.branchtostring(tree)
    local str = "("
    for k, branch in pairs(tree) do
        if type(branch) == "table" then
            if k ~= "parent" and k ~= "funcs" then
                    str = str .. mimosa.branchtostring(branch)
            end
        elseif k ~= "line" then
            str = str .. tostring(branch) .. ";"
        end
    end
    return str .. ")"
end


function mimosa.asttoindented(ast)
    local text = ""
    local tabbage = ""
    local word = ""
    for i = 1, #ast do        
        local char = string.sub(ast, i, i)
        if char == "(" then tabbage = tabbage .. " "
        elseif char == ")" then tabbage = string.sub(tabbage, 1, -2)
        elseif char == ";" then
            text = text .. tabbage .. word .. "\n"
            word = ""
        else word = word .. char
        end
    end
    return text
end


function mimosa.error(line, where, message)
    mimosa.cli.error("[line " .. line .. "]" .. where .. ":")
    mimosa.cli.error(message)
    mimosa.had_err = true
end


return mimosa