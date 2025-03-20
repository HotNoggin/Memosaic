-- This library replaces bit on web (which uses Lua 5.1 instead of LuaJIT)
-- Tnere is no need for any conditionals
-- LuaJIT implicitly prioritizes it's own bit.* library over this one
-- Lua 5.1 doesn't have LuaJIT's bit.* library, and so uses this one
print("Using web bit library.")
return require("libs.numberlua").bit