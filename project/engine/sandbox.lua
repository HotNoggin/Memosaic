-- Prepare a table for the module
local sandbox = {}


function sandbox.run(code)
    print("load lua function")
    local result, error = load(code, "Cart", "t", sandbox.env)
    if result then
        sandbox.func = result
        local ok, err = pcall(result)
        return ok, err
    else
        return false, error
    end
end


function sandbox.init(cart, input, memapi, drawing, console)
    print("Populating sandbox API")
    
    sandbox.func = function () end

    -- The Memosaic API (safe lua default functions and custom functions)
    sandbox.env = {
        -- Standard
        type = type,
        pcall = pcall,
        num = tonumber,
        str = tostring,
       -- time = os.clock()

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
        etch = drawing.char,
        ink = drawing.ink,
        rect = drawing.rect,
        crect = drawing.crect,
        irect = drawing.irect,
        text = drawing.text,

        -- Console
        echo = console.print,
        print = console.print,
        say = console.print,
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
        rnd = love.math.random,

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
        slct = select,
    }

    function sandbox.env.istr(str, i)
        return string.sub(str, i, i)
    end

    function sandbox.btnp(i)
        return input.btn(i) and not input.old(i)
    end

    function sandbox.btnup(i)
        return input.old(i) and not input.btn(i)
    end
    

    setfenv(sandbox.env.boot, sandbox.env)
    setfenv(sandbox.env.tick, sandbox.env)
end

-- select - SAFE
-- unpack - SAFE
-- xpcall - SAFE

-- Export the module as a table
return sandbox