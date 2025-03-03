-- Prepare a table for the module
local editor = {}

editor.font_tab = require("project.editor.font_tab")
editor.console = require("project.editor.console")

function editor.init(memo)
    print("Initializing editor")
    editor.window = memo.window
    editor.input = memo.input
    editor.memapi = memo.memapi
    editor.drawing = memo.drawing
    editor.canvas = memo.canvas
    editor.cart = memo.cart
    editor.tab = 0
    editor.lasttab = 1
    editor.console.editor = editor

    editor.console.init(memo)
    editor.font_tab.init(memo)
    editor.escdown = false
end


function editor.update()
    if editor.tab == 0 then editor.console.update() end
    if editor.tab == 1 then editor.font_tab.update() end

    local ipt = editor.input
    local isesc = love.keyboard.isDown("escape")

    -- Cart saving
    if ipt.ctrl and (ipt.key("s") and not ipt.oldkey("s")) then
        editor.console.cmd.command("save")
    end

    -- CLI-Editor switching
    if isesc and not editor.escdown then
        if editor.tab > 0 then
            editor.lasttab = editor.tab
            editor.tab = 0
        else
            editor.tab = editor.lasttab
            if editor.lasttab <= 0 then
                editor.lasttab = 1
            end
        end
    end
    editor.escdown = isesc
end


function editor.get_save()
    local cdata = ""
    cdata = cdata .. editor.cart.get_script() .. "\n"
    cdata = cdata .. "--!:font\n--" .. editor.font_tab.get_font(editor)
    return cdata
end

-- Export the module as a table
return editor