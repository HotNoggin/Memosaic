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
                print("encountered binop")
                if p.isbinop(expression.type) then -- both are binops! handle precedence
                    print("both new and current are binops")
                    if p.istighter(t, expression.type) then
                        -- Only evaluate binops that are tighter than the current one
                        print("new binop is tighter")
                        expression, i = p.resolvebinop(i, parent, expression)
                    else
                        print("new binop is not tighter")
                        return expression, i + 1
                    end
                else
                    print("current is not a binop")
                    expression, i = p.resolvebinop(i, parent, expression)
                end
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


function parser.resolvebinop(start, parent, l)
    local t = parser.tokens[start]
    local binop = {type = t.type, line = t.line, left = l, right = {}}
    local r, stop = parser.resolveexpression(start + 1, binop)
    -- Combine neighboring pairs of binary operations
    if parser.isbinop(r.type) then
        -- If the right binop is tighter, nest it inside of this one
        if parser.istighter(r.type, binop.type) then
            print("nesting r in binop")
            binop.right = r
        -- Nest this binop in the right one otherwise
        else
            print("nesting binop in r")
            r.left = binop
            binop = r
        end
    else
        print("right is not a binop")
        binop.right = r
    end
    print("binary operator " .. t.type)
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