-- Prepare a table for the module
local editor = {}
local jjrle = require("engine.jjrle")

editor.console = require("editor.console")
editor.font_tab = require("editor.font_tab")
editor.code_tab = require("editor.code_tab")
editor.sound_tab = require("editor.sound_tab")
editor.data_tab = require("editor.data_tab")

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
    editor.remember_reload_choice = false
    editor.saved_reload_choice = 0
    editor.cart_at_save = ""

    editor.console.init(memo)
    editor.font_tab.init(memo)
    editor.code_tab.init(memo)
    editor.sound_tab.init(memo)
    editor.data_tab.init(memo)
    editor.escdown = false
    editor.opened()

    editor.bar_bg = 0
    editor.bar_fg = 0
    editor.bar_lit = 0
end


function editor.opened()
    -- Retrieve editor memory from backup
    editor.memapi.retrieve()
end


function editor.update()
    local map = editor.memapi.map
    local ipt = editor.input
    local isesc = love.keyboard.isDown("escape")

    -- Reset all flags, set efont flag to true
    for i = map.rflags_start, map.rflags_end do
        editor.memapi.poke(i, 0x01)
    end

    if editor.hotreload then
        editor.update_reload()
        return
    end

    -- Hotkey nav
    for i = 0, 4 do
        if ipt.ctrl and love.keyboard.isDown(tostring(i)) then
            editor.tab = i
            if editor.tab > 0 then
                editor.lasttab = editor.tab
            end
        end
    end

    if editor.tab == 0 then editor.console.update()
    elseif editor.tab == 1 then editor.font_tab.update(editor)
    elseif editor.tab == 2 then editor.code_tab.update(editor)
    elseif editor.tab == 3 then editor.sound_tab.update(editor)
    elseif editor.tab == 4 then editor.data_tab.update(editor)
    end

    -- Hotkeys
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
       if editor.tab == 1 then editor.font_tab.update_bar(editor)
       elseif editor.tab == 3 then editor.sound_tab.update_bar(editor) end
    end
end


function editor.update_bar()
    local draw = editor.drawing
    local mx = editor.input.mouse.x
    local my = editor.input.mouse.y
    local click = editor.input.lclick
    local held = editor.input.lheld

    local tabicons = {16, 17, 18, 19, 20}
    local tabnames = {"cmd (ESC)", "font", "code", "sounds", "data"}

    if my == 0 and mx < #tabicons and click and not held then
        editor.tab = mx
        if editor.tab > 0 then
            editor.lasttab = editor.tab
        end
    end

    -- Draw top bar and bottom bar
    for x = 0, 15 do
        draw.tile(x, 0, " ", editor.bar_fg, editor.bar_bg)
        draw.tile(x, 15, " ", editor.bar_fg, editor.bar_bg)
    end

    -- Draw tabs
    for i, c in ipairs(tabicons) do
        local x = i - 1
        draw.char(x, 0, c)
        if mx == x and my == 0 then
            draw.ink(x, 0, editor.bar_lit, editor.bar_bg)
            editor.tooltip = "tab: " .. tabnames[i]
        end
        if editor.tab == x then
            draw.ink(x, 0, editor.bar_bg, editor.bar_lit)
        end
    end

    -- Run
    draw.char(14, 0, 21)
    if mx == 14 and my == 0 then
        draw.tile(14, 0, 22, editor.bar_lit)
        if not click then
            editor.tooltip = "run (CTRL+r)"
        end
        if click and not held then
            editor.ranfrom = editor.tab
            editor.sendcmd("run")
            return
        end
    end

    -- Save
    draw.char(15, 0, 23)
    if mx == 15 and my == 0 then
        draw.ink(15, 0, editor.bar_lit)
        if not click then
            editor.tooltip = "save (CTRL+s)"
        end
        if click and not held then
            editor.sendcmd("save")
        end
    end

    draw.text(0, 15, editor.tooltip) -- x y string
end


function editor.update_reload()
    local draw = editor.drawing
    local ipt = editor.input

    -- Conflict resolution options
    if ipt.key("1") and not ipt.oldkey("1") or
    editor.saved_reload_choice == 1 or
    ipt.lclick_in(0, 5, 15, 6) and not ipt.lheld then
        editor.sendcmd("reload")
        editor.sendcmd("save")
        print("Loaded external changes")
        editor.save_reload_choice(1)
        return
    elseif ipt.key("2") and not ipt.oldkey("2") or
    editor.saved_reload_choice == 2 or
    ipt.lclick_in(0, 8, 15, 9) and not ipt.lheld then
        editor.sendcmd("save")
        print("Saved editor changes")
        editor.save_reload_choice(2)
        return
    elseif ipt.key("3") and not ipt.oldkey("3") or
    editor.saved_reload_choice == 3 or
    ipt.lclick_in(0, 11, 15, 12) and not ipt.lheld then
        print("Ignored external changes")
        editor.save_reload_choice(3)
        return
    end

    -- Base popup text
    draw.clrs()
    draw.text(0, 0, "External change detected!", 5, 0, 16) -- orange
    draw.text(0, 2, "Which do you    want to save?", 3, 0, 16) -- brown
    local byte = 0xCC
    local str = ""
    for i=1,16 do
        str = str .. string.char(byte)
    end
    draw.text(0, 4, str, 3)
    draw.text(0, 5, "1:load external")
    draw.text(0, 6, " (lose editor's)")
    draw.text(0, 8, "2:save changes")
    draw.text(0, 9, " (lose external)")
    draw.text(0, 11, "3:overwrite none")
    draw.text(0, 12, " (do not save)")
    draw.text(0, 15, " don't ask again", 1) -- silver

    local mx, my = ipt.mouse.x, ipt.mouse.y

    for i = 5, 11, 3 do
        if my == i or my == i + 1 then
            draw.irect(0, i, 16, 2, 4) -- x y w h red
        else
            draw.irect(0, i, 16, 1, 5) -- x y w h orange
            draw.irect(0, i, 16, 1, 3) -- x y w h brown
        end
    end

    -- Remember choice toggle
    if mx == 0 and my == 15 and ipt.lclick and not ipt.lheld then
        editor.remember_reload_choice = not editor.remember_reload_choice
    end
    if editor.remember_reload_choice then
        draw.char(0, 15, 30)
        draw.irect(0, 15, 16, 1, 5) -- x y w h orange
    else
        draw.tile(0, 15, 29, 1, 0) -- x y c silver, black
    end
end


function editor.save_reload_choice(num)
    if editor.remember_reload_choice then
        editor.saved_reload_choice = num
    end
    editor.hotreload = false
end


function editor.get_save()
    local cdata = ""
    cdata = cdata .. editor.cart.get_script()
    local font = editor.font_tab.get_font(editor)
    local packedfont = jjrle.pack(font)
    if editor.cart.use_mimosa then
        cdata = cdata .. "(!font!)\n(" .. packedfont .. ")"
    else
        cdata = cdata .. "--!:font\n--" .. packedfont
    end
    return cdata
end


function editor.sendcmd(command)
    editor.console.cmd.command(command)
    if #editor.console.entries > 1 then
        editor.tooltip = editor.console.entries[#editor.console.entries - 1]
    end
end


-- Checks the saves and triggers a hot reload if needed
-- Returns true if the cart is ok to run (no conflicts)
function editor.check_save()
    local change = false
    local editorsave = editor.get_save()
    local path = love.filesystem.getSaveDirectory() .. "/" .. editor.console.cartfile
    if path[#path] == "/" then -- This is a folder
        return true
    end
    local diskfile = io.open(path, "r")

    if not diskfile then -- There is no file here
        return true
    end

    local disksave = diskfile:read("*a")

    if disksave ~= editorsave and disksave ~= editor.cart_at_save then
        print("External changes detected")
        -- Only handle conflict if the editor has its own unsaved changes
        -- Otherwise just load the changes from the disk
        if editor.get_save() ~= editor.cart_at_save then
            print("Queue conflict resolution")
            editor.hotreload = true
            return false
        else
            print("No local changes")
            editor.sendcmd("reload")
            return true
        end
    else
        print("No external changes")
        return true
    end
end


-- Export the module as a table
return editor