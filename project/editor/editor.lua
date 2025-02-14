-- Prepare a table for the module
local editor = {}

editor.font_tab = require("project.editor.font_tab")


function editor.init(window, input, memapi, drawing, canvas)
    editor.window = window
    editor.input = input
    editor.memapi = memapi
    editor.drawing = drawing
    editor.canvas = canvas
    editor.tab = 0
    editor.active = true
end


function editor.update()
    if editor.tab == 0 then editor.font_tab.update(editor) end
end


-- Export the module as a table
return editor