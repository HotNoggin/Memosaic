local lexer = {
    current = 1,
    line = 1,
    code = "",
    tokens = {}
}
-- Has lexer.err(line, where txt, message txt)


-- Scans a string of code and returns a table of tokens
function lexer.scan(code)
    lexer.code = code
    lexer.tokens = {}
    lexer.current = 1
    lexer.line = 1
    while not lexer.atend() do
        lexer.scantoken()
    end
    return lexer.tokens
end


-- Evaluates the next token and adds it to the list
function lexer.scantoken()
    local l = lexer
    local c = lexer.advance()

    local symbols = {".", ",", "%", "/", "\\", "{", "}", ":", "?", "@", "$",}

    if l.isin(c, symbols) then
        l.addtoken(c)
    elseif c == "(" then
        while not l.atend() and l.peek() ~= ")" do
            l.advance()
        end
        l.advance()
    elseif c == "#" then
        if l.peek() == '"' then -- Raw string
            l.advance()
            local string = ""
            local last = ""
            while not l.atend() do
                last = l.advance()
                if last == '"' and l.peek() == "#" then
                    l.addtoken("string", string)
                    l.advance()
                    break
                end
                string = string .. last
            end
        elseif l.peek() == "#" then -- Tag
            l.advance()
            local name = ""
            while l.islow(l.peek()) or l.iscaps(l.peek()) do
                name = name .. l.advance()
            end
            l.addtoken("tag", name)
        elseif l.ishex(l.peek()) then -- Hex int
            local int = ""
            while not l.atend() and l.ishex(l.peek()) do
                int = int .. l.advance()
            end
            l.addtoken("hex", int)
        else
            l.addtoken("#")
        end
    elseif c == '"' then
        local string = ""
        local last = ""
        while not l.atend() and l.peek() ~= '"' do
            last = l.advance()
            -- String escape sequences
            if l.isin(last, {"\n", "\r", "\v", "\a", "\b", "\f"}) then
                l.advance()
            elseif last == "\\" then
                if l.match("\\") then string = string .. "\\"
                elseif l.match("n") then string = string .. "\n"
                elseif l.match("r") then string = string .. "\r"
                elseif l.match("t") then string = string .. "\t"
                elseif l.match("v") then string = string .. "\v"
                elseif l.match("a") then string = string .. "\a"
                elseif l.match("b") then string = string .. "\b"
                elseif l.match("f") then string = string .. "\f"
                elseif l.match('"') then string = string .. "\""
                else l.err(l.line,  " in string", "invalid escape char: " .. l.peek()) end
            else string = string .. last end
        end
        l.addtoken("string", string)
        l.advance()
    elseif c == "'" then
        local next = l.peek()
        if l.isbetween(next, "!", "~") then
            l.addtoken("char", next)
            l.advance()
        else l.err(l.line, " char", "invalid character")
        end
    elseif l.islow(c) or l.iscaps(c) then
        local identifier = c
        while not l.atend() and (l.islow(l.peek()) or l.iscaps(l.peek())) do
            identifier = identifier .. l.advance()
        end
        l.addtoken("identifier", identifier)
    elseif l.isdec(c) then
        local num = c
        while not l.atend() and l.isdec(l.peek()) do
            num = num .. l.advance()
        end
        l.addtoken("int", num)
    elseif c == "*" then
        if l.match("*") then l.addtoken("**")
        else l.addtoken("*")
        end
    elseif c == "+" then
        if l.match("+") then l.addtoken("++")
        else l.addtoken("+")
        end
    elseif c == "-" then
        if l.match("-") then l.addtoken("--")
        else l.addtoken("-")
        end
    elseif c == "~" then
        if l.match("~") then l.addtoken("~~")
        else l.addtoken("~")
        end
    elseif c == "<" then
        if l.match("=") then l.addtoken("<=")
        elseif l.match("<") then l.addtoken("<<")
        else l.addtoken("<")
        end
    elseif c == ">" then
        if l.match("=") then l.addtoken (">=")
        elseif l.match(">") then l.addtoken(">>")
        else l.addtoken(">")
        end
    elseif c == "=" then
        if l.match("=") then l.addtoken("==")
        else l.addtoken("=")
        end
    elseif c == "|" then
        if l.match("|") then l.addtoken("||")
        else l.addtoken("|")
        end
    elseif c == "&" then
        if l.match("&") then l.addtoken("&&")
        else l.addtoken("&")
        end
    elseif c == "!" then
        if l.match("=") then l.addtoken("!=")
        else l.addtoken("!")
        end
    elseif c == "^" then
        if l.match("^") then l.addtoken("^^")
        else l.addtoken("^")
        end
    elseif l.isin(c, {" ", "\t", "\r"}) then -- pass
    elseif c == "\n" then l.line = l.line + 1
    else l.err(l.line, "", "Invalid token: " .. c) end
end


-- Inserts a token into the token list
function lexer.addtoken(ptype, pval)
    local token = {type = ptype, value = "", line = lexer.line}
    if pval then token.value = pval end
    table.insert(lexer.tokens, token)
end


-- Returns the current character and moves to the next one
function lexer.advance()
    local char = lexer.charat(lexer.code, lexer.current)
    lexer.current = lexer.current + 1
    return char
end

-- Returns true and advances if the current token matches
function lexer.match(char)
    if lexer.peek() == char then
        lexer.advance()
        return true
    end
end

---------- HELPERS ----------
function lexer.charat(str, i)
    return string.sub(str, i, i)
end

function lexer.isin(c, chars)
    for i, char in ipairs(chars) do
        if c == char then
            return true
        end
    end
    return false
end

function lexer.islow(c)
    return lexer.isbetween(c, "a", "z")
end

function lexer.iscaps(c)
    return lexer.isbetween(c, "A", "Z")
end

function lexer.ishex(c)
    return lexer.isbetween(c, "0", "9") or lexer.isbetween(c, "A", "F")
end

function lexer.isdec(c)
    return lexer.isbetween(c, "0", "9")
end

function lexer.isbetween(c, a, b)
    return c:byte() >= a:byte() and c:byte() <= b:byte()
end

function lexer.peek()
    if lexer.atend() then return "" end
    return lexer.charat(lexer.code, lexer.current)
end

function lexer.atend()
    return lexer.current > #lexer.code
end
-----------------------------


return lexer