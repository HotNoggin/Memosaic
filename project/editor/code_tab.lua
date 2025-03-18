-- Prepare a table for the module
local code_tab = {}


function code_tab.init(memo)
    code_tab.memo = memo
    code_tab.memapi = memo.memapi
    code_tab.cart = memo.cart
    code_tab.input = memo.input
    code_tab.drawing = memo.drawing
end


function code_tab.update(editor)
    local draw = code_tab.drawing
    local ipt = code_tab.input
    local mem = code_tab.memapi

    -- Editor tab colors
    editor.bar_bg = 9
    editor.bar_fg = 8
    editor.bar_lit = 7

    draw.clrs()
end


-- Export the module as a table
return code_tab