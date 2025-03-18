-- Prepare a table for the module
local sound_tab = {}


function sound_tab.init(memo)
    sound_tab.memo = memo
    sound_tab.memapi = memo.memapi
    sound_tab.cart = memo.cart
    sound_tab.input = memo.input
    sound_tab.drawing = memo.drawing
end


function sound_tab.update(editor)
    local draw = sound_tab.drawing
    local ipt = sound_tab.input
    local mem = sound_tab.memapi

    -- Editor tab colors
    editor.bar_bg = 2
    editor.bar_fg = 15
    editor.bar_lit = 14

    draw.clrs()
end


-- Export the module as a table
return sound_tab