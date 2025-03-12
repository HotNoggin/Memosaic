local mimosa = {
    lexer = require("mimosa.lexer"),
    parser = require("mimosa.parser"),
    interpreter = require("mimosa.interpreter"),
    library = require("mimosa.library"),
    had_err = false,
}


function mimosa.init(memo)
    mimosa.lexer.err = mimosa.err
    mimosa.parser.err = mimosa.err
    mimosa.interpreter.baseerr = mimosa.err
    mimosa.interpreter.memo = memo
    mimosa.interpreter.lib = mimosa.library
    mimosa.cart_instructions = {}
    mimosa.memo = memo
    mimosa.interpreter.init()
    mimosa.library.init(memo, mimosa.interpreter)
end


function mimosa.run(script, stack, pile)
    mimosa.had_err = false
    local tokens = mimosa.lexer.scan(script)
    if mimosa.had_err then return false end
    local instructions, tags = mimosa.parser.get_instructions(tokens)
    if mimosa.had_err then return false end
    mimosa.interpreter.interpret(instructions, stack, pile, tags, 1)
    if not mimosa.interpreter.ok then return false end
    return true
end


function mimosa.err(line, where, msg)
    mimosa.had_err = true
    mimosa.memo.editor.console.error("[line " .. line .. "]" .. where .. ": " .. msg)
end

return mimosa