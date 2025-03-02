local parser = {}

parser.reserved = {}


function parser.get_instructions(tokens)
    local unclosedskips = {}
    local instructions = {}
    for i, token in ipairs(tokens) do
        local inst = token

        -- KEYWORDS --
        if inst.type == "identifier" then
            for idx, reservedword in ipairs(parser.reserved) do
                if inst.value == reservedword then
                    inst.type = reservedword
                end
            end

        -- NUMBERS --
        elseif inst.type == "int" then
            local int = math.floor(tonumber(inst.value, 10))
            inst = {line = inst.line, type = "int", value = int}
        elseif inst.type == "hex" then
            local int = math.floor(tonumber(inst.value, 16))
            inst = {line = inst.line, type = "int", value = int}

        -- BLOCKS --
        elseif inst.type == "{" then
            table.insert(unclosedskips, i)
        elseif inst.type == "}" then
            if #unclosedskips <= 0 then
                parser.err(token.line, "", "unmatched '}'")
            end
            local idx = unclosedskips[-1]
            local toclose = instructions[idx]
            toclose.stop = i
            table.remove(unclosedskips, -1)
        end

        table.insert(instructions, inst)
    end

    for i, idx in ipairs(unclosedskips) do
        local inst = instructions[idx]
        parser.err(inst.line, "", "unclosed '{'")
    end

    return instructions
end


return parser