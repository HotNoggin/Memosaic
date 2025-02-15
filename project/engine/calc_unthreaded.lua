local env = {
	main = {sin = math.sin, cos = math.cos, pi = math.pi},
	user = {}
}

setmetatable(env, {
	__newindex = function(t, k, v)
		--if t.main[k] then
		--	error("you may not redefine " .. k)
		--end

		t.user[k] = v
	end,

	__index = function(t, k)
		return t.main[k] or t.user[k]
	end
})

local load

local hook = function(...)
	if (debug.getinfo(2, "f").func ~= load) then
		error("timeout")
	end
end

load = function(s)
	local ret, ok = loadstring((s))
	if not ret then
		print("bad syntax:", ok)
		return
	end

	setfenv(ret, env)

	jit.off()
	debug.sethook(hook, "", 8192)
	
	ok, ret = pcall(ret)

	debug.sethook()
	jit.on()

	if not ok then
		print("bad code:", ret)
		return
	end
	return ret
end

local calc = function(s)
	return load("return " .. s)
end

load[[
	function add(a, b)
		return cos(a * pi * 0.2) + sin(b * pi * 0.2)
	end

	pi = 10
]]

print(load, calc)

print(calc"add(1, 1)")

print(calc"pi", calc"user.pi")

load("while true do end") -- timeout

load("(function() for i=1, 8181 do end end)()") -- timeout

load("(function() for i=1, 8180 do end end)()") -- ok


love.event.quit()
