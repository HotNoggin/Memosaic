local parser = {
    tokens = {},
    tree = {}
}


function parser.maketree(tokens)
    parser.tokens = tokens
    parser.tree = {type = "script", body = {}}
    -- Number of parameters for built-in functions
    parser.tree.funcs = {
        out = 1,
    }
    if not (#parser.tokens > 0) then return {} end
    parser.tree.body = parser.resolvebody(1, parser.tree)
    return parser.tree
end


function parser.resolvebody(start, pparent)
    print("resolving body at " .. start)
    local p = parser
    local body = p.branch("body", p.tokens[start].line, pparent)
    body.expressions = {}
    local i = start
    local expression = {}
    while i <= #p.tokens do
        local t = p.tokens[i]
        if t.type == "}" or t.type == "?" or t.type == ":" then
            print("body resolved")
            return body, i + 1
        end
        expression, i = p.resolveexpression(i, body)
        table.insert(body.expressions, expression)
    end
    print("body resolved")
    return body, i + 1
end


-- Returns the expression branch and the end token idx of it
function parser.resolveexpression(start, pparent)
    local p = parser
    local expression = {type = "UNRESOLVED", parent = pparent}
    local t = p.tokens[start]
    print("resolving expression (" .. t.type .. ") at " .. start)
    local i = start
    while i <= #p.tokens do
        t = p.tokens[i]

        if t.type == "(" then
            print("+-subexpression-+")
            expression, i = p.resolveexpression(start + 1, pparent)
        elseif t.type == ")" then
            print("+_______________+")
            return expression, i + 1
        elseif t.type == "{" then
            return p.resolveblock(i + 1, pparent)
        elseif t.type == "}" then
            return expression, i
        elseif t.type == ":" or t.type == "?" then
            return expression, i + 1

        elseif p.isliteral(t) then
            expression, i = p.resolveliteral(i)
        elseif t.type == "identifier" then
            expression, i = p.resolveidentifier(i)
        elseif t.type == "command" then
            expression, i = p.resolvecommand(i, pparent)
        elseif t.type == "." then
            expression, i = p.resolvecall(i + 1, pparent)

        elseif p.isbinop(t) then
            if p.canbeunary(t) and expression.type == "UNRESOLVED" then
                expression, i = p.resolveunary(i, pparent)
            elseif expression.type == "UNRESOLVED" then
                p.err(t.line, " expr", "missing left operand for " .. t.type)
                return expression, i + 1
            else
                expression, i = p.resolvebinop(i, expression, pparent)
            end

        elseif p.isunary(t) then
            if expression.type == "UNRESOLVED" then
                expression, i = p.resolveunary(i)
            else
                p.err(t.line, " expr", "unexpected " .. t.type)
                return expression, i + 1
            end

        else
            p.err(t.line, " expr", "unexpected " .. t.type)
            return expression, i + 1
        end

        if expression.type ~= "UNRESOLVED" then
            print("expression resolved")
            local nxt = p.tokens[i]
            if nxt ~= nil and not p.isbinop(nxt) then return expression, i end
        end
    end

    return expression, i + 1
end


function parser.resolveblock(start, pparent)
    print("Resolving block at " .. start)
    local t = parser.tokens[start]
    local block, i = parser.branch("UNRESOLVED", t.line, pparent), start
    if t.type == ":" then
        print("body is iteration")
        block, i = parser.resolvefor(start + 1, pparent)
    else
        local firstexpr = {}
        firstexpr, i = parser.resolveexpression(start, pparent)
        local nxt = parser.tokens[i]
        print("next token in block is " .. nxt.type)
        if nxt.type == "?" then
            print("body is conditional")
            block, i = parser.resolveif(i + 1, firstexpr, start, pparent)
        elseif nxt.type == ":" then
            print("body is function")
            block, i = parser.resolvefunc(i + 1, firstexpr, pparent)
        else
            print("body is expression")
            block, i = firstexpr, i
        end
    end
    return block, i
end


function parser.resolveidentifier(start)
    local t = parser.tokens[start]
    print("terminal identifier " .. t.value)
    return {type = "identifier", name = t.value, line = t.line}, start + 1
end


function parser.resolvecommand(start, pparent)
    local t = parser.tokens[start]
    local cmd = t.value
    local nums = {X = 0, Y = 1, Z = 2, W = 3}
    if string.byte(cmd) >= string.byte("W") then
        print("terminal parameter " .. cmd)
        return {type = "parameter", number = nums[cmd], line = t.line}, start + 1
    else
        print("terminal command " .. cmd)
        local command = {type = "command", letter = cmd, line = t.line, parent = pparent}
        return command, start + 1
    end
end


function parser.resolvecall(start, pparent)
    local t = parser.tokens[start]
    local call = {type="call", line = t.line, parent = pparent}
    if t.type == "identifier" then -- Function call
        print("terminal call " .. t.value .. " at " .. start)
        call.name = t.value
        call.parameters = {}
        local pcount = parser.getparamcount(call.name, pparent, call.line)
        local stop = start + 1
        for i = 1, pcount do
            local expr = {}
            expr, stop = parser.resolveexpression(stop, pparent)
            table.insert(call.parameters, expr)
        end
        return call, stop
    elseif t.type == "int" then -- Parameter reference
        print("terminal parameter " .. t.value .. " at " .. start)
        call.type = "parameter"
        call.number = t.value
        return call, start + 1
    end
end


function parser.resolveliteral(start)
    local t = parser.tokens[start]
    print("terminal literal " .. t.value)
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


function parser.resolvebinop(start, parsedhalf, pparent)
    local t = parser.tokens[start]
    print("resolving binop: " .. t.type)
    local binop = {type = t.type, line = t.line, left = parsedhalf, right = {}, parent = pparent}
    local r, stop = parser.resolveexpression(start + 1, pparent)
    -- Combine neighboring pairs of binary operations
    if parser.isbinop(r) and not parser.associatesright(binop) then
        if r and parser.istighter(r.type, binop.type) then
            -- Keep as-is, right-associative
            binop.right = r
        else
            -- Perform a swap to become left-associative
            binop.right = r.left
            r.left = binop
            binop = r
        end
    else
        -- Keep as-is, right-associative
        binop.right = r
    end

    return binop, stop
end


function parser.resolveunary(start, pparent)
    local t = parser.tokens[start]
    print("resolving unary: " .. t.type)
    local unary = {type = t.type, line = t.line, value = {}, parent = pparent}
    if unary.type == "-" then
        unary.type = "negate"
    end
    local v, stop = parser.resolveexpression(start + 1, pparent)
    if parser.isbinop(v) then
        if parser.istighter(v.type, unary.type) then
            unary.value = v
        else
            unary.value = v.left
            v.left = unary
            unary = v
        end
    else
        unary.value = v
    end

    return unary, stop
end


function parser.resolveif(start, condit, prestart, pparent)
    print("Resolving conditional at " .. prestart)
    local t = parser.tokens[start]
    local i = start
    local ifblock = {type = "if", condition = condit, line = prestart, parent = pparent}
    ifblock.subconditions = {}
    ifblock.bodies = {}
    local canelse = false
    while i <= #parser.tokens do
        local body = {type = "UNRESOLVED"}
        body, i = parser.resolvebody(i, ifblock)
        local nxt = parser.tokens[i - 1]
        print("next token in if body is " .. nxt.type)
        if nxt.type == "?" then
            table.insert(ifblock.subconditions, body)
        elseif nxt.type == ":" then
            table.insert(ifblock.bodies, body)
        elseif nxt.type == "}" then
            return ifblock, i
        else
            parser.err(nxt.line, " in conditional", "expected : or ? or }, found " .. nxt.type)
            return ifblock, i
        end
    end
    return ifblock, i
end


function parser.resolvefor(start, pparent)
    print("Resovling iteration at " .. start)
    local t = parser.tokens[start]
    local ident, i = {}, start
    local forloop = {type = "for", line = t.line, parent = pparent}
    if t.type == "identifier" then
        ident, i = parser.resolveidentifier(i)
        forloop.iterator = ident
    else
        parser.err(t.line, " iteration", "missing identifier for iterator")
        return forloop, start + 1
    end
    forloop.iterable, i = parser.resolveexpression(i, forloop)
    t = parser.tokens[i]
    if t.type == ":" then
        forloop.body, i = parser.resolvebody(i + 1, forloop)
    else
        parser.err(t.line, " iteration", "missing colon (:)")
        return forloop, i + 1
    end
    return forloop, i
end


function parser.branch(ptype, pline, pparent)
    local branch = {type = "", line = 0, parent = pparent}
    if ptype then branch.type = ptype end
    if pline then branch.line = pline end
    return branch
end


---------- HELPERS ----------
function parser.getparamcount(funcname, parent, line)
    if parent == nil then
        parser.err(line, "", funcname .. " not defined")
        return 0
    end
    if parent.funcs == nil then parent.funcs = {} end
    if parent.funcs[funcname] == nil then
        parent.funcs[funcname] = parser.getparamcount(funcname, parent.parent, line)
    end
    return parent.funcs[funcname]
end


function parser.isliteral(t)
    return t.type == "hex" or t.type == "decimal"
    or t.type == "string" or t.type == "char"
end

function parser.isbinop(t)
    local p = parser
    return p.isadd(t) or p.ismult(t) or t.type == "**"
    or p.isbitop(t) or p.iscomparison(t)
    and not p.isunary(t)
end

function parser.isbitop(t)
    return t.type == "^^" or t.type == "|" or t.type == "&"
end

-- IMPORTATNT: This uses "negate" for negation, not "-"
-- To check if a token is negation, use canbeunary
function parser.isunary(t)
    return t.type == "!" or t.type == "~" or t.type == "negate"
end

function parser.canbeunary(t)
    return t.type == "!" or t.type == "~" or t.type == "-"
    or t.type == "negate"
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

-- Only for binops, as ALL unaries associate right
function parser.associatesright(t)
    return t.type == "**"
end

-- Returns true if a groups tighter than b
function parser.istighter(a, b)
    local strength = {
        -- logical / bitwise negations
        ["!"] = 11, ["~"] = 11,
        -- exponent
        ["**"] = 10,
        -- multiplication
        ["negate"] = 9, ["*"] = 9, ["/"] = 9, ["\\"] = 9,
        -- addition
        ["+"] = 8, ["-"] = 8,
        -- bitwise operators
        ["<<"] = 7, [">>"] = 7,
        ["&"] = 6,
        ["^^"] = 5,
        ["|"] = 4,
        -- relations
        ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3,
        -- equality
        ["!="] = 2, ["=="] = 2,
        -- logical
        ["&&"] = 1,
        ["||"] = 0,
    }
    return strength[a] > strength[b]
end
-----------------------------


return parser