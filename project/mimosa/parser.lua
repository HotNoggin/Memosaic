local parser = {}

parser.reserved = {"out", "O", "push", "pop", "true", "false", "goto", "do", "end",}


function parser.get_instructions(tokens)
    local unclosedskips = {}
    local instructions = {}
    local tags = {}
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

        -- CONDITIONAL BLOCKS --
        elseif inst.type == "{" then
            table.insert(unclosedskips, i)
        elseif inst.type == "}" then
            if #unclosedskips <= 0 then
                parser.err(token.line, "", "unmatched '}'")
            else
                local idx = unclosedskips[#unclosedskips]
                if instructions[idx].type == "{" then
                    instructions[idx] = {line = instructions[idx].line, type = "{", value = i}
                    table.remove(unclosedskips, #unclosedskips)
                else
                    parser.err(token.line, "", "unmatched '}'")
                end
            end

        -- TAG BLOCKS --
        elseif inst.type == "tag" then
            if inst.value == "" then
                inst.type = "end"
                if #unclosedskips <= 0 then
                    parser.err(token.line, "", "unmatched '##'")
                else
                    local idx = unclosedskips[#unclosedskips]
                    local oldinst = instructions[idx]
                    if oldinst.type == "tag" then
                        instructions[idx] = {
                            line = oldinst.line, type = "tag", value = i, name = oldinst.value}
                        table.remove(unclosedskips, #unclosedskips)
                    else
                        parser.err(token.line, "", "unmatched '##'")
                    end
                end
            else
                table.insert(unclosedskips, i)
                tags[inst.value] = i
            end
        end

        table.insert(instructions, inst)
    end

    for i, idx in ipairs(unclosedskips) do
        local inst = instructions[idx]
        parser.err(inst.line, "", "unclosed '" .. inst.type .. "'")
    end

    return instructions, tags
end


return parser