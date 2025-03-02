local scanner = {
    current = 1,
    line = 1,
    code = "",
    tokens = {}
}
-- Has scanner.err(line, where txt, message txt)


-- Scans a string of code and returns a table of tokens
function scanner.scan(code)
    scanner.code = code
    scanner.current = 1
    scanner.line = 1
    while not scanner.atend() do
        scanner.scantoken()
    end
    return scanner.tokens
end


-- Evaluates the next token and adds it to the list
function scanner.scantoken()
    local s = scanner
    local c = scanner.advance()

    local symbols = {".", ",", "%", "/", "\\", "{", "}", "(", ")", "+", "-", ":", "?"}

    if s.isin(c, symbols) then
        s.addtoken(c)
    elseif c == ";" then
        local comment = ""
        while not s.atend() and s.peek() ~= ";" do
            comment = comment .. s.advance()
        end
        s.advance()
    elseif c == "#" then
        if s.peek() == '"' then -- Raw string
            s.advance()
            local string = ""
            local last = ""
            while not s.atend() do
                last = s.advance()
                if last == '"' and s.peek() == "#" then
                    s.addtoken("string", string)
                    s.advance()
                    break
                end
                string = string .. last
            end
        elseif s.isdec(s.peek()) then -- Decimal int
            local int = ""
            local last = ""
            while not s.atend() and s.isdec(s.peek()) do
                last = s.advance()
                int = int .. last
            end
            s.addtoken("decimal", int)
        else
            s.addtoken("#")
        end
    elseif c == '"' then
        local string = ""
        local last = ""
        while not s.atend() and s.peek() ~= '"' do
            last = s.advance()
            -- String escape sequences
            if s.isin(last, {"\n", "\r", "\v", "\a", "\b", "\f"}) then
                s.advance()
            elseif last == "\\" then
                if s.match("\\") then string = string .. "\\"
                elseif s.match("n") then string = string .. "\n"
                elseif s.match("r") then string = string .. "\r"
                elseif s.match("t") then string = string .. "\t"
                elseif s.match("v") then string = string .. "\v"
                elseif s.match("a") then string = string .. "\a"
                elseif s.match("b") then string = string .. "\b"
                elseif s.match("f") then string = string .. "\f"
                elseif s.match('"') then string = string .. "\""
                else s.err(s.line,  " in string", "invalid escape char: " .. s.peek()) end
            else string = string .. last end
        end
        s.addtoken("string", string)
        s.advance()
    elseif c == "'" then
        local next = s.peek()
        if s.isbetween(next, "!", "~") then
            s.addtoken("char", next)
            s.advance()
        else s.err(s.line, " char", "invalid character")
        end
    elseif c == "`" then
        local word = ""
        while not s.atend() and s.islow(s.peek()) do
            word = word .. s.advance()
        end
        s.addtoken("string", word)
    elseif s.islow(c) then
        local identifier = c
        while not s.atend() and s.islow(s.peek()) do
            identifier = identifier .. s.advance()
        end
        s.addtoken("identifier", identifier)
    elseif s.ishex(c) then
        local int = c
        while not s.atend() and s.ishex(s.peek()) do
            int = int .. s.advance()
        end
        s.addtoken("hex", int)
    elseif s.iscaps(c) then -- This follows ishex() so hex is excluded
        s.addtoken("command", c)
    elseif c == "*" then
        if s.match("*") then s.addtoken("**")
        else s.addtoken("*")
        end
    elseif c == "<" then
        if s.match("=") then s.addtoken("<=")
        elseif s.match("<") then s.addtoken("<<")
        else s.addtoken("<")
        end
    elseif c == ">" then
        if s.match("=") then s.addtoken (">=")
        elseif s.match(">") then s.addtoken(">>")
        else s.addtoken(">")
        end
    elseif c == "=" then
        if s.match("=") then s.addtoken("==")
        else s.addtoken("=")
        end
    elseif c == "|" then
        if s.match("|") then s.addtoken("||")
        else s.addtoken("|")
        end
    elseif c == "&" then
        if s.match("&") then s.addtoken("&&")
        else s.addtoken("&")
        end
    elseif c == "!" then
        if s.match("=") then s.addtoken("!=")
        else s.addtoken("!")
        end
    elseif c == "^" then
        if s.match("^") then s.addtoken("^^")
        else s.addtoken("^")
        end
    elseif s.isin(c, {" ", "\t", "\r"}) then -- pass
    elseif c == "\n" then s.line = s.line + 1
    else s.err(s.line, "", "Invalid token: " .. c) end
end


-- Inserts a token into the token list
function scanner.addtoken(ptype, pval)
    local token = {type = ptype, value = "", line = scanner.line}
    if pval then token.value = pval end
    table.insert(scanner.tokens, token)
end


-- Returns the current character and moves to the next one
function scanner.advance()
    local char = scanner.charat(scanner.code, scanner.current)
    scanner.current = scanner.current + 1
    return char
end

-- Returns true and advances if the current token matches
function scanner.match(char)
    if scanner.peek() == char then
        scanner.advance()
        return true
    end
end

---------- HELPERS ----------
function scanner.charat(str, i)
    return string.sub(str, i, i)
end

function scanner.isin(c, chars)
    for i, char in ipairs(chars) do
        if c == char then
            return true
        end
    end
    return false
end

function scanner.islow(c)
    return scanner.isbetween(c, "a", "z")
end

function scanner.iscaps(c)
    return scanner.isbetween(c, "A", "Z")
end

function scanner.ishex(c)
    return scanner.isbetween(c, "0", "9") or scanner.isbetween(c, "A", "F")
end

function scanner.isdec(c)
    return scanner.isbetween(c, "0", "9")
end

function scanner.isbetween(c, a, b)
    return c:byte() >= a:byte() and c:byte() <= b:byte()
end

function scanner.peek()
    if scanner.atend() then return "" end
    return scanner.charat(scanner.code, scanner.current)
end

function scanner.atend()
    return scanner.current > #scanner.code
end
-----------------------------


return scanner