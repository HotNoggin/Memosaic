-- Prepare a table for the module
local console = {}

console.entries = {}


function console.update(e)
    
end


function console.print(text, color)
    print(text)
    table.insert(console.entries, {c = color, t = text})
end


function console.error(text, color)
    print("ERR: " .. text)
    table.insert(console.entries {c = color, t = "ERROR: " .. text})
end


-- Export the module as a a table
return console