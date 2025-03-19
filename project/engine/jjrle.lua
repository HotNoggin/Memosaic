local jjrle = {}

jjrle.firstcode = string.byte("G")
jjrle.lastcode = string.byte("Z")
jjrle.minrun = 3
jjrle.maxrun = jjrle.lastcode - jjrle.firstcode + jjrle.minrun


function jjrle.pack(raw)
    local packed = ""
    local run = 1
    local pre = ""
    for i = 1, #raw + 1 do
        local c = raw:sub(i, i)
        if pre ~= "" and not jjrle.ishex(pre) then
            return error("JJRLE ERROR: non-hexadecimal character found in string")
        end

        if c ~= pre and pre ~= "" or i >= #raw then -- new character found or reached end
            if run < jjrle.minrun then
                local str = ""
                for j = 1, run  do
                    str = str .. pre
                end
                packed = packed .. str
            else
                local code = jjrle.getcode(run - jjrle.minrun)
                packed = packed .. pre .. code
            end
            run = 1
        elseif pre ~= "" then -- identical char found
            if run >= jjrle.maxrun then -- add max encoding if reached maximum
                packed = packed .. c .. "Z"
                run = 0
            end
            run = run + 1 -- increase run length
        end
        pre = c
    end

    return packed
end


function jjrle.unpack(packed)
    local raw = ""
    for i = 1, #packed do
        local pre = packed:sub(i, i)
        local c = packed:sub(i + 1, i + 1)
        -- check the current character for code
        if c ~= "" and jjrle.isbetween(c, "G", "Z") then
            local index = jjrle.getval(c)
            local runlen = index + jjrle.minrun
            -- add the previously read character n times
            for count = 1, runlen do
                raw = raw .. pre
            end
        elseif pre ~= "" and jjrle.ishex(pre) then
            -- add the previously read character one time
            raw = raw .. pre
        else
            --return error("JJRLE ERROR: character is not code or hexadecimal")
        end
    end

    return raw
end


-- Returns the value of a char code, where G is 0
function jjrle.getval(c)
    return string.byte(c) - jjrle.firstcode
end


-- Returns the char code of a value, where 0 is G
function jjrle.getcode(num)
    return string.char(num + jjrle.firstcode)
end


function jjrle.ishex(c)
    return jjrle.isbetween(c, "0", "9") or jjrle.isbetween(c, "A", "F")
    or jjrle.isbetween(c, "a", "f")
end

function jjrle.isbetween(c, a, b)
    return c:byte() >= a:byte() and c:byte() <= b:byte()
end

return jjrle