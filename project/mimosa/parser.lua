local parser = {
    tokens = {},
    tree = {}
}


function parser.maketree(tokens)
    parser.tokens = tokens
    parser.tree = {}
    local tree = parser.resolvebody(1)
    return tree
end


function parser.resolvebody(start, parent)
    local p = parser
    local branch = p.branch("body", p.tokens[start].line, p.tree)
    branch.expressions = {}
    local i = start
    local expression = {}
    while i <= #p.tokens do
        local t = p.tokens[i]
        if t.type == "}" then
            return branch, i + 1
        end
        expression, i = p.resolveexpression(i, branch)
        table.insert(branch.expressions, expression)
    end
    return branch, i + 1
end


-- Returns the expression branch and the end token idx of it
function parser.resolveexpression(start, parent)
    local p = parser
    local expression = {}
    local i = start
        while i <= #p.tokens do
            local t = p.tokens[i]
            if t.type == ")" then
                return expression, i + 1
            elseif p.isliteral(t) then
                expression, i = p.resolveliteral(i)
            elseif t.type == "identifier" then
                expression, i = p.resolveidentifier(i)
            elseif p.isbinop(t) then
                expression, i = p.resolvebinop(i, expression)
            else
                p.err(t.line, " expr", "unexpected " .. t.type)
                return expression, i + 1
            end
        end
    return expression, i + 1
end


function parser.resolveidentifier(start)
    local t = parser.tokens[start]
    return {type = "identifier", value = t.value, line = t.line}, start + 1
end


function parser.resolveliteral(start)
    local t = parser.tokens[start]
    local val
    local littype = "int"
    if t.type == "hex" then
        val = tonumber(t.value, 16)
    elseif t.type == "decimal" then
        val = tonumber(t.value, 10)
    elseif t.type == "char" then
        val = string.byte(t.value)
    elseif t.type == "string" then
        val = {}
        for c = 1, #t.value do
            table.insert(val, string.byte(string.sub(t.value, c, c)))
            littype = "dict"
        end
    end

    return {type = littype, value = val, line = t.line}, start + 1
end


function parser.resolvebinop(start, parsedhalf)
    local t = parser.tokens[start]
    local binop = {type = t.type, line = t.line, left = {}, right = {}}
    local r, stop = parser.resolveexpression(start + 1, binop)
    -- Combine neighboring pairs of binary operations
    print("binop: " .. binop.type)
    if parser.isbinop(binop) and parser.isbinop(r) then
        if parser.istighter(r.type, binop.type) then
            -- Nest the new in the old
            print("old is the outside")
            binop.left = parsedhalf
            binop.right = r
        else
            -- Nest the old in the new
            print("new is the outside")
            r.left = binop
            r.right = parsedhalf
            binop = r
        end
    else
        print("not both binops")
        binop.left = parsedhalf
        binop.right = r
    end
    return binop, stop
end


function parser.branch(ptype, pline, pparent)
    local branch = {type = "", line = 0, parent = pparent}
    if ptype then branch.type = ptype end
    if pline then branch.line = pline end
    return branch
end


---------- HELPERS ----------
function parser.isliteral(t)
    return t.type == "hex" or t.type == "decimal"
    or t.type == "string" or t.type == "char"
end

function parser.isbinop(t)
    local p = parser
    return p.isadd(t) or p.ismult(t) or p.isbitop(t)
    or p.iscomparison(t) and not p.isunary(t)
end

function parser.isbitop(t)
    return t.type == "^^" or t.type == "|" or t.type == "&"
end

function parser.isunary(t)
    return t.type == "!" or t.type == "~"
end

function parser.iscomparison(t)
    return t.type == ">" or t.type == "<"
    or t.type == ">=" or t.type == ">="
    or t.type == "==" or t.type == "!="
end

function parser.ismult(t)
    return t.type == "*" or t.type == "/" or t.type == "\\"
end

function parser.isadd(t)
    return t.type == "+" or t.type == "-"
end

-- Returns true if a groups tighter than b
function parser.istighter(a, b)
    local strength = {
        ["!"] = 9, ["negate"] = 9,
        ["*"] = 8, ["/"] = 8, ["\\"] = 8,
        ["+"] = 7, ["-"] = 7,
        ["<<"] = 6, [">>"] = 6,
        ["&"] = 5,
        ["^^"] = 4,
        ["|"] = 3,
        ["!="] = 2, ["=="] = 2, ["<"] = 2, [">"] = 2, ["<="] = 2, [">="] = 2,
        ["&&"] = 1,
        ["||"] = 0,
    }
    return strength[a] > strength[b]
end
-----------------------------


return parser