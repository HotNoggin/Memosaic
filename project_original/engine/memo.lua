-- Prepare a table for the module
local memo = {
    info = {version = "0.2.1-alpha", version_name = "Cookie", is_win = package.config:sub(1, 1) == "\\"},

    window = require("graphics.window"),
    input = require("engine.input"),
    memapi = require("engine.memapi"),
    tick = require("engine.tick"),
    canvas = require("graphics.canvas"),
    drawing = require("graphics.drawing"),
    audio = require("audio.audio"),
    mimosa = require("mimosa.mimosa"),
    cart = require("engine.cart"),
    editor = require("editor.editor"),
    demos = require("carts.demos")
}


function memo.init(options)
    print("======== MEMOSAIC ========")
    print("Booting Memosaic modules")
    memo.window.init(options.win_scale, options.vsync)
    memo.memapi.init(memo)
    memo.input.init(memo)
    memo.drawing.init(memo)
    memo.audio.init(memo)
    memo.canvas.init(memo.window.WIDTH, memo.window.HEIGHT, memo)
    memo.mimosa.init(memo)
    memo.cart.init(memo)
    memo.editor.init(memo)

    print("Initializing module states")
    memo.drawing.clear(0)
    memo.drawing.clrs()
    memo.canvas.update()
    memo.editor.console.reset()
    print("Memosaic is ready\n========\n")
end


function memo.stat(code)
    if code >= 0x00 and code <= 0x05 then
        return memo.input.btn(code)
    elseif code >= 0x08 and code <= 0x0F then
        return memo.input.btn(code - 0x08) and not memo.input.old(code - 0x08)
    elseif code == 0x20 then
        return memo.input.lclick
    elseif code == 0x21 then
        return memo.input.rclick
    elseif code == 0x22 then
        return memo.input.wheel == 1
    elseif code == 0x23 then
        return memo.input.wheel == -1
    elseif code == 0x24 then
        return memo.input.lclick and not memo.input.lheld
    elseif code == 0x25 then
        return memo.input.rclick and not memo.input.rheld
    elseif code == 0x26 then
        return memo.input.mouse.x
    elseif code == 0x27 then
        return memo.input.mouse.y
    elseif code == 0x28 then
        return memo.input.mouse.px
    elseif code == 0x29 then
        return memo.input.mouse.py
    else
        return false
    end
end


-- Export the module as a table
return memo