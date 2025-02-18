-- Prepare a table for the module
local memo = {
    info = {version = "0.0.2-alpha", is_win = package.config:sub(1, 1) == "\\"},

    window = require("graphics.window"),
    input = require("engine.input"),
    memapi = require("data.memory"),
    tick = require("engine.tick"),
    canvas = require("graphics.canvas"),
    drawing = require("graphics.drawing"),
    cart = require("engine.cart"),
    editor = require("editor.editor"),
    demos = require("carts.demos")
}


function memo.init(options)
    print("======== MEMOSAIC ========")
    print("Booting Memosaic modules")
    memo.window.init(options.win_scale, options.vsync)
    memo.memapi.init()
    memo.input.init(memo)
    memo.drawing.init(memo)
    memo.canvas.init(memo.window.WIDTH, memo.window.HEIGHT, memo)
    memo.cart.init(memo)
    memo.editor.init(memo)

    print("Initializing module states")
    memo.drawing.clear(0)
    memo.drawing.clrs()
    memo.canvas.update()
    memo.editor.console.reset()
    print("Memosaic is ready\n========\n")
end

-- Export the module as a table
return memo