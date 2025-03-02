local mimosa = {
    lexer = require("mimosa.lexer"),
    parser = require("mimosa.parser"),
    interpreter = require("mimosa.interpreter"),
    had_err = false,
}

function mimosa.init(memo)
    mimosa.lexer.err = mimosa.err
    mimosa.parser.err = mimosa.err
    mimosa.interpreter.baseerr = mimosa.err
    mimosa.memo = memo
end


function mimosa.run(script)
    local tokens = mimosa.lexer.scan(script)
    if mimosa.had_err then return end
    local instructions = mimosa.parser.get_instructions(tokens)
    if mimosa.had_err then return end
    mimosa.interpreter.interpret(instructions)
end


function mimosa.err(line, where, msg)
    mimosa.had_err = true
    mimosa.memo.editor.console.error("[line " .. line .. "]" .. where .. ": " .. msg)
end

return mimosa