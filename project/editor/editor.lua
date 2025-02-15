-- Prepare a table for the module
local editor = {}

editor.font_tab = require("project.editor.font_tab")


function editor.init(window, input, memapi, drawing, canvas, cart)
    editor.window = window
    editor.input = input
    editor.memapi = memapi
    editor.drawing = drawing
    editor.canvas = canvas
    editor.cart = cart
    editor.tab = 0
end


function editor.update()
    if editor.tab == 0 then editor.font_tab.update(editor) end

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