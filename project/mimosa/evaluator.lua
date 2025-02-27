local evaluator = {
    err = function(line, where, msg) end,
    variables = {},
    callstack = {},
    mosalib = require("mimosa.mosalib"),
    verbose = true
}

evaluator.builtins = {
    out = evaluator.mosalib.out;
}

function evaluator.evaluate(branch, vars)
    local ev = evaluator
    ev.out("evaluating")
end

---------- HELPERS ----------
function evaluator.duplicate(vars)
    local newvars = {}
    for key, value in pairs(vars) do
        newvars[key] = value
    end
    return newvars
end

function evaluator.out(str)
    if evaluator.verbose then print(str) end
end
-----------------------------


return evaluator