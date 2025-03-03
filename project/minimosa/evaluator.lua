local evaluator = {
    err = function(line, where, msg) end,
    variables = {},
    callstack = {},
    minilib = require("minimosa.minilib"),
    verbose = true
}

evaluator.builtins = {
    out = evaluator.minilib.out;
}


function evaluator.evaluate(expr, variables)
    local ev = evaluator
    local vars = ev.duplicate(variables)
    ev.out("evaluating branch of type " .. expr.type)
    if expr.type == "body" then
        evaluator.evaluatebody(expr, vars)
    end
end


function evaluator.evaluatebody(body, variables)
    local ev = evaluator
    local vars = ev.duplicate(variables)
end


---------- HELPERS ----------
-- Make a copy of a vars table (shallow)
-- Always duplicate between expressions!
function evaluator.duplicate(vars)
    local newvars = {}
    for name, variable in pairs(vars) do
        newvars[name] = variable
    end
    return newvars
end

-- Use a "variable" objects (tables, passed by reference) for values
-- That way, deeper-scope changes to vars affect outer-scope values
-- To change a variable value, use vars[name].value = newvalue
-- That change will affect the variable value everywhere it is defined
function evaluator.newvar(val)
    return {value = val}
end

function evaluator.out(str)
    if evaluator.verbose then print(str) end
end
-----------------------------


return evaluator