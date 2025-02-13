-- Prepare a table for the api module and memory
local memapi = {}

local ffi = require("ffi")

-- The addresses of specific areas of memory
memapi.map = {
    memory_start = 0x000, memory_end = 0xfff, -- The entirety of the memory
    write_start  = 0x000, write_end  = 0xfff, -- The writable memory block
    font_start   = 0x000, font_end   = 0x7ff, -- 2048 bytes for 256 8-byte chars
    sounds_start = 0x800, sounds_end = 0x9ff, -- 512 bytes for 32-byte sounds
    audio_start  = 0xa00, audio_end  = 0xbff, -- 512 bytes for audio buffer
    ascii_start  = 0xc00, ascii_end  = 0xcff, -- 256 bytes for ascii char grid
    color_start  = 0xd00, color_end  = 0xdff, -- 256 bytes for 4-bit color gridd
    bonus_start  = 0xe00, bonus_end  = 0xfff, -- 512 byets for multiple uses
}


-- Return a new, 4Kib memory buffer
function memapi.init()
    print("Creating memory buffer")
    memapi.bytes = love.data.newByteData(0x1000) -- New 4Kib buffer
    memapi.ptr = ffi.cast('uint8_t*', memapi.bytes:getFFIPointer()) -- Byte pointer
end


-- Get the byte at the specified address
function memapi.peek(address)
    if not type(address) == "number" then return end
    if address < memapi.map.memory_start or address > memapi.map.memory_end then
        error("Attempted to access out of bounds memory at " .. address)
    end

    return memapi.ptr[address]
end


-- Set the byte at the specified address
function memapi.poke(address, value)
    if not type(address) == "number" then return end
    if not type(value) == "number" then return end

    if address < memapi.map.write_start and address > memapi.map.write_end then
        error("Attempted to write to read only memory at " .. address)
    end

    memapi.ptr[address] = value
end


function memapi.get_hex(num, len)
    local hex = string.format("%x", num)
    while string.len(hex) < len do
        hex = "0" .. hex
    end
    return hex
end

-- Export the modele as a table
return memapi