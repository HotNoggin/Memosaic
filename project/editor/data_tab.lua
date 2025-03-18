-- Prepare a table for the module
local data_tab = {}


function data_tab.init(memo)
    data_tab.memo = memo
    data_tab.memapi = memo.memapi
    data_tab.cart = memo.cart
    data_tab.input = memo.input
    data_tab.drawing = memo.drawing
end


function data_tab.update(editor)
    local draw = data_tab.drawing
    local ipt = data_tab.input
    local mem = data_tab.memapi

    -- Editor tab colors
    editor.bar_bg = 1
    editor.bar_fg = 12
    editor.bar_lit = 13

    draw.clrs()
end


-- Export the module as a table
return data_tab