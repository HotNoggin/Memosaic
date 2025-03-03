--minimosa interpreter
local minimosa = {
    scanner = require("minimosa.scanner"),
    parser = require("minimosa.parser"),
    evaluator = require("minimosa.evaluator"),
    had_err = false,
}

minimosa.minilib = minimosa.evaluator.minilib


function minimosa.init(memo)
    minimosa.cli = memo.editor.console
    minimosa.scanner.err = minimosa.error
    minimosa.parser.err = minimosa.error
    minimosa.evaluator.err = minimosa.error
    minimosa.minilib.callstack = minimosa.evaluator.callstack
    minimosa.minilib.init(memo)
end


function minimosa.run(code)
    minimosa.had_err = false
    local tokens = minimosa.scanner.scan(code)
    if minimosa.had_err then return end
    local tree = minimosa.parser.maketree(tokens)
    if minimosa.had_err then return end
    minimosa.evaluator.evaluate(tree.body, {})
end


function minimosa.branchtostring(tree)
    local str = "("
    for k, branch in pairs(tree) do
        if type(branch) == "table" then
            if k ~= "parent" and k ~= "funcs" then
                    str = str .. minimosa.branchtostring(branch)
            end
        elseif k ~= "line" then
            str = str .. tostring(branch) .. ";"
        end
    end
    return str .. ")"
end


function minimosa.asttoindented(ast)
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


function minimosa.error(line, where, message)
    minimosa.cli.error("[line " .. line .. "]" .. where .. ":")
    minimosa.cli.error(message)
    minimosa.had_err = true
end


return minimosa