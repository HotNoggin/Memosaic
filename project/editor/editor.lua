-- Prepare a table for the module
local editor = {}

editor.font_tab = require("project.editor.font_tab")
editor.console = require("project.editor.console")

function editor.init(memo)
    editor.window = memo.window
    editor.input = memo.input
    editor.memapi = memo.memapi
    editor.drawing = memo.drawing
    editor.canvas = memo.canvas
    editor.cart = memo.cart
    editor.tab = 0
    editor.console.editor = editor

    editor.console.init(memo)
    editor.font_tab.init(memo)
end


function editor.update()
    if editor.tab == 0 then editor.console.update() end
    if editor.tab == 1 then editor.font_tab.update() end

    local ipt = editor.input

    -- Cart saving
    if ipt.ctrl and (ipt.key("s") and not ipt.oldkey("s")) then
        local cdata = ""
        cdata = cdata .. editor.cart.get_script() .. "\n"
        cdata = cdata .. "--!:font\n--" .. editor.font_tab.get_font(editor)
        print(cdata)
     end
end


-- Export the module as a table
return editor