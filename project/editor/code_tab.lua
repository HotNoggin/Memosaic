-- Prepare a table for the module
local code_tab = {}


function code_tab.init(memo)
    code_tab.memo = memo
    code_tab.cart = memo.cart
    code_tab.input = memo.input
    code_tab.drawing = memo.drawing
end


function code_tab.update(editor)
    local draw = code_tab.drawing
    draw.clrs()
end


-- Export the module as a table
return code_tab