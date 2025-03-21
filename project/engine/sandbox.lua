-- Prepare a table for the module
local sandbox = {}


function sandbox.run(code, name)
    local env = sandbox.env
    local result, error = load(code, name, "t", env)
    if result then
        setfenv(sandbox.env.boot, env)
        setfenv(sandbox.env.tick, env)
        sandbox.func = result
        local ok, err = xpcall(result, sandbox.cart.handle_err)
        return ok, err
    else
        return false, error
    end
end


function sandbox.init(cart, input, memapi, drawing, audio, console)
    print("Populating sandbox API")
    sandbox.func = function () end
    sandbox.cart = cart

    local bit = require("bit")

    -- The Memosaic API (safe lua default functions and custom functions)
    sandbox.env = {
        -- Standard
        type = type,
        pcall = pcall,
        num = tonumber,
        str = tostring,
        trace = debug.traceback,

        -- Callbacks
        boot = function() end,
        tick = function() end,

        -- Memory
        peek = memapi.peek,
        poke = memapi.poke,

        -- System
        stat = cart.memo.stat,
        btn = input.btn,
        stop = cart.stop,

        -- Graphics
        clrs = drawing.clrs,
        tile = drawing.tile,
        etch = drawing.char,
        ink = drawing.ink,
        rect = drawing.rect,
        crect = drawing.crect,
        irect = drawing.irect,
        cget = drawing.cget,
        iget = drawing.iget,
        text = drawing.text,
        pan = drawing.setoffset,

        -- Audio
        blip = audio.blip,
        beep = audio.beep,
        chirp = audio.chirp,

        -- Console
        echo = console.print,
        print = console.print,
        say = console.print,
        err = console.err,

        -- Math
        abs = math.abs,
        ceil = math.ceil,
        cos = math.cos,
        deg = math.deg,
        floor = math.floor,
        flr = math.floor,
        fmod = math.fmod,
        log = math.log,
        max = math.max,
        min = math.min,
        rad = math.rad,
        sin =  math.sin,
        sqrt = math.sqrt,
        random = love.math.random,
        rand = love.math.random,
        rnd = love.math.random,

        -- Bitops
        band = bit.band,
        bor = bit.bor,
        bnot = bit.bnot,
        lshift = bit.lshift,
        rshift = bit.rshift,

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
        ipairs = ipairs,
        insert = table.insert,
        remove = table.remove,
        rmv = table.remove,
        sort = table.sort,
        unpack = unpack,

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

    function sandbox.btnr(i)
        return input.old(i) and not input.btn(i)
    end

    setfenv(sandbox.env.boot, sandbox.env)
    setfenv(sandbox.env.tick, sandbox.env)
end


-- select - SAFE
-- xpcall - SAFE

-- Export the module as a table
return sandbox