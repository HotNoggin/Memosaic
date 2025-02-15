-- Prepare a table for the module
local sandbox = {}


function sandbox.run(code)
    local result, error = load( code, "Cart", "t", sandbox.env)
    if result then
        local ok, err = pcall(result)
        return ok, err
    else
        return false, error
    end
end


function sandbox.init(cart, input, memapi, drawing, console)
    -- The Memosaic API (safe lua default functions and custom functions)
    sandbox.env = {
        -- Standard
        type = type,
        pcall = pcall,
        num = tonumber,
        str = tostring,

        -- Callbacks
        boot = function() end,
        tick = function() end,

        -- Memory
        peek = memapi.peek,
        poke = memapi.poke,

        -- Input
        btn = input.btn,

        -- Graphics
        clrs = drawing.clrs,
        tile = drawing.tile,
        ink = drawing.ink,

        -- Console
        echo = console.print,
        print = console.print,
        err = console.err,

        -- Math
        abs = math.abs,
        ciel = math.ceil,
        cos = math.cos,
        deg = math.deg,
        flr = math.floor,
        fmod = math.fmod,
        log = math.log,
        max = math.max,
        min = math.min,
        rad = math.rad,
        sin =  math.sin,
        sqrt = math.sqrt,
        rand = love.math.random,

        -- String
        sub = string.sub,
        format = string.format,
        char = string.char,
        byte = string.byte,
        len = string.len,
        hex = memapi.hex,

        -- Table
        next = next,
        pairs = pairs,
        insert = table.insert,
        rmv = table.remove,
        sort = table.sort,

        -- Metatable
        setmeta = setmetatable,
        getmeta = getmetatable,
        requal = rawequal,
        rget = rawget,
        rset = rawset,
        rlen = rawlen,
        slct = select,
    }
end

-- print - SAFE (assuming output to stdout is ok)
-- select - SAFE
-- type - SAFE
-- unpack - SAFE
-- _VERSION - SAFE
-- xpcall - SAFE

-- Export the module as a table
return sandbox