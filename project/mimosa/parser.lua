local parser = {}

parser.reserved = {
    -- Console
    "out", "O", "err", "outcolr",
    -- Stack and literals
    "push", "P", "pop",
    "true", "false",
    -- Control flow
    "do", "jump", "end",
    -- Input
    "stat", "btn", "btnp", "btnr",
    -- Drawing
    "fill", "tile", "T", "etch", "E", "ink", "I",
    "rect", "R", "crect", "irect", "text"
}


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

        -- TAGS and REGIONS --
        elseif inst.type == "tag" then
            if inst.value ~= "" then
                tags[inst.value] = i
            else
                parser.err(token.line, " tag", "no name")
            end
        elseif inst.type == "region" then
            if inst.value == "" then
                inst.type = "end"
                if #unclosedskips <= 0 then
                    parser.err(token.line, "", "unmatched '##'")
                else
                    local idx = unclosedskips[#unclosedskips]
                    local oldinst = instructions[idx]
                    if oldinst.type == "region" then
                        instructions[idx] = {
                            line = oldinst.line, type = "region", value = i, name = oldinst.value}
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