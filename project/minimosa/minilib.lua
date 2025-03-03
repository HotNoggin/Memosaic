local mosa = {
    callstack = {}
}


function mosa.init(memo)
    mosa.cli = memo.editor.console
end


function mosa.out(intdict)
    local txt = ""
    for i, v in ipairs(intdict) do
        if type(v) == "number" then
            txt = txt .. string.char(v)
        else
            txt = txt .. "?"
        end
    end
end


function mosa.err(txt)
    mosa.cli.error(txt)
    for i = 1, #mosa.callstack do
        local entry = mosa.callstack[i]
        mosa.cli.error("line " .. entry.line .. " in " .. entry.funcname)
    end
end


return mosa