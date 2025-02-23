--Mimosa interpreter
local mimosa = {
    scanner = require("mimosa.scanner"),
    parser = require("mimosa.parser"),
    had_err = false
}


function mimosa.init(memo)
    mimosa.cli = memo.editor.console
    mimosa.scanner.err = mimosa.error
end


function mimosa.run(code)
    mimosa.had_err = false
    local tokens = mimosa.scanner.scan(code)
    if mimosa.had_err then return end
    local tree = mimosa.parser.maketree(tokens)
    mimosa.cli.print(mimosa.branchtostring(tree), 12)
end


function mimosa.branchtostring(tree)
    local str = "("
    for k, branch in pairs(tree) do
        if type(branch) == "table" then
            str = str .. mimosa.branchtostring(branch)
        else
            str = str .. tostring(branch) .. ";"
        end
    end
    return str .. ")"
end


function mimosa.error(line, where, message)
    mimosa.cli.error("[line " .. line .. "]" .. where .. ":")
    mimosa.cli.error(message)
    mimosa.had_err = true
end


return mimosa