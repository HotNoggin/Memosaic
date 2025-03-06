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

    if editor.tab > 0 then
       editor.update_bar()
    end
end


function editor.update_bar()
    local draw = editor.drawing
    local tooltip = ""
    local mx = editor.input.mouse.x
    local my = editor.input.mouse.y
    local click = editor.input.lclick
    local held = editor.input.lheld

    local tabicons = {">", 7,}
    local tabnames = {"command", "font"}

    if my == 0 and mx < #tabicons - 1 and click and not held then
        editor.tab = mx
        if editor.tab > 0 then
            editor.lasttab = editor.tab
        end
    end

    -- Draw top bar and bottom bar
    for x = 0, 15 do
        draw.tile(x, 0, "_", 12, 0) -- x y c blue black
        if editor.tab == x then
            draw.ink(x, 0, 11, 0) -- x y teal black
        end
        draw.tile(x, 15, " ", 12, 10) -- x y c gray blue
    end

    -- Draw tabs
    for i, c in ipairs(tabicons) do
        local x = i - 1
        draw.char(x, 0, c)
        if mx == x and my == 0 then
            draw.ink(x, 0, 0, 11) -- x y black teal
            tooltip = tabnames[i]
        end
    end

    draw.text(0, 15, tooltip) -- x y string
end


function editor.get_save()
    local cdata = ""
    cdata = cdata .. editor.cart.get_script() .. "\n"
    cdata = cdata .. "--!:font\n--" .. editor.font_tab.get_font(editor)
    return cdata
end

-- Export the module as a table
return editor