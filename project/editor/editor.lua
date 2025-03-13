-- Prepare a table for the module
local editor = {}

editor.console = require("editor.console")
editor.font_tab = require("editor.font_tab")
editor.code_tab = require("editor.code_tab")


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
    editor.ranfrom = 0
    editor.console.editor = editor
    editor.tooltip = ""

    editor.hotreload = false
    editor.save_at_unfocus = ""

    editor.console.init(memo)
    editor.font_tab.init(memo)
    editor.code_tab.init(memo)
    editor.escdown = false
end


function editor.update()
    if editor.hotreload then
        editor.update_reload()
        return
    end

    if editor.tab == 0 then editor.console.update()
    elseif editor.tab == 1 then editor.font_tab.update(editor)
    elseif editor.tab == 2 then editor.code_tab.update(editor)
    end

    local ipt = editor.input
    local isesc = love.keyboard.isDown("escape")

    if ipt.ctrl and (ipt.key("r") and not ipt.oldkey("r")) then
        if ipt.shift then
            editor.sendcmd("reload")
        else
            editor.ranfrom = editor.tab
            editor.sendcmd("run")
            return
        end
    end

    if ipt.ctrl and (ipt.key("s") and not ipt.oldkey("s")) then
        editor.sendcmd("save")
    end

    -- CLI-Editor switching
    if isesc and not editor.escdown then
        editor.tooltip = "\1"
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
    local mx = editor.input.mouse.x
    local my = editor.input.mouse.y
    local click = editor.input.lclick
    local held = editor.input.lheld

    local tabicons = {">", 7, 1}
    local tabnames = {"cmd (ESC)", "font", "code"}

    if my == 0 and mx < #tabicons and click and not held then
        editor.tab = mx
        if editor.tab > 0 then
            editor.lasttab = editor.tab
        end
    end

    -- Draw top bar and bottom bar
    for x = 0, 15 do
        draw.tile(x, 0, "_", 12, 0) -- x y c gray black
        if editor.tab == x then
            draw.ink(x, 0, 11, 0) -- x y teal black
        end
        draw.tile(x, 15, " ", 10, 0) -- x y c blue black
    end

    -- Draw tabs
    for i, c in ipairs(tabicons) do
        local x = i - 1
        draw.char(x, 0, c)
        if mx == x and my == 0 then
            draw.ink(x, 0, 0, 11) -- x y black teal
            editor.tooltip = "tab: " .. tabnames[i]
        end
    end

    draw.text(0, 15, editor.tooltip) -- x y string
end


function editor.update_reload()
end


function editor.get_save()
    local cdata = ""
    cdata = cdata .. editor.cart.get_script()
    local font = editor.font_tab.get_font(editor)
    if editor.cart.use_mimosa then
        cdata = cdata .. "(!font!)\n(" .. font .. ")"
    else
        cdata = cdata .. "--!:font\n--" .. font
    end
    return cdata
end


function editor.sendcmd(command)
    editor.console.cmd.command(command)
    if #editor.console.entries > 1 then
        editor.tooltip = editor.console.entries[#editor.console.entries - 1]
    end
end


-- Export the module as a table
return editor