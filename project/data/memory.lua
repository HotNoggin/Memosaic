-- Prepare a table for the api module and memory
local memapi = {}

local ffi = require("ffi")

memapi.default_font = "007e464a52627e007733770077577500005e42425e505000004c42424c5050000044424448504800005850585e585c0000003c3c3c3c0000003c765e5e763c001c1c7f7d7f1c1c001c147f7f7f1c1c001c1c7f5f7f1c1c001c1c7f7f7f141c003e7f6b776b7f3e003e7f636b637f3e001c147f5d7f141c00007e3e1e3e766200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5e000000000e0e000e0e0000247e7e247e7e2400005c5cd6d6747400006676381c6e660000347e4a763048000000000e0e00000000003c7e420000000000427e3c00000000041c0e1c0400000018187e7e181800000040606000000000181818181818000000006060000000006070381c0e0600003c7e524a7e3c000040447e7e404000006476725a5e4c00002466424a7e3400001e1e10107e7e00002e6e4a4a7a3200003c7e4a4a7a3000000606727a0e060000347e4a4a7e3400000c5e52527e3c000000006c6c0000000000406c6c0000000000183c664200000024242424242400000042663c180000000406525a1e0c00007c82baaab23c00007c7e0a0a7e7c00007e7e4a4a7e3400003c7e4242662400007e7e42427e3c00007e7e4a4a424200007e7e0a0a020200003c7e424a7a3800007e7e08087e7e000042427e7e42420000307040427e3e00007e7e181c766200007e7e40406060007e7e060c067e7e00007e7e0c187e7e00003c7e42427e3c00007e7e12121e0c00003c7e4262febc00007e7e0a0a7e7400002c4e5a5a7234000002027e7e020200003e7e40407e3e00001e3e70603e1e003e7e6030607e3e0000767e08087e760000060e7c780e0600004262725a4e460000007e7e4242000000060e1c38706000000042427e7e000000080c06060c080000404040404040000000060e0c00000000387c44443c7c00007f7f44447c380000387c44446c280000387c44447f7f0000387c54545c180000087e7f090b02000098bca4a4fcf800007f7f04047c78000044447d7d404000008080fdfd000000007f7f081c7662000040417f7f404000787c0c180c7c7800007c7c08047c780000387c44447c380000fcfc48447c380000387c4448fcfc80007c7c08041c180000585c545474300000043e7e44440000003c7c40407c7c00001c3c70603c1c003c7c6030607c3c00006c7c10107c6c00009cbca0a0fcfc00006474745c5c4c000000087e764200000000007e7e000000000042767e0800000010081818100800007e5a66665a7e00"


-- The addresses of specific areas of memory
memapi.map = {
    memory_start = 0x000, memory_end = 0xfff, -- The entirety of the memory
    write_start  = 0x000, write_end  = 0xfff, -- The writable memory block
    font_start   = 0x000, font_end   = 0x3ff, -- 1024 (1.0 kibi) bytes for 128 8-byte chars
    sounds_start = 0x400, sounds_end = 0x9ff, -- 1536 (1.5 kibi) bytes for 32 to 48 32-byte sounds
    audio_start  = 0xa00, audio_stop = 0xaff, -- 256 bytes for audio buffer of 128 instructions
    audio_middle = 0xb00, audio_end  = 0xbff, -- 256 bytes for second audio buffer
    ascii_start  = 0xc00, ascii_end  = 0xcff, -- 256 bytes for ascii char grid of 256 chars
    color_start  = 0xd00, color_end  = 0xdff, -- 256 bytes for 4-bit color grid of 512 colors
    bonus_start  = 0xe00, bonus_end  = 0xfff, -- 512 bytes for multiple uses, including saving
}


-- Create a new, 4Kib memory buffer
function memapi.init()
    print("Creating memory buffer")
    memapi.bytes = love.data.newByteData(0x1000) -- New 4Kib buffer
    memapi.ptr = ffi.cast('uint8_t*', memapi.bytes:getFFIPointer()) -- Byte pointer
    memapi.load_font(memapi.default_font)
end


-- Loads font from a hexadecimal string
function memapi.load_font(font)
    print("Loading font")
    local font_size = memapi.map.font_end - memapi.map.font_start
    for i = 0, font_size do
        if #font < 2*i then return false end
        local byte = tonumber(string.sub(font, 2*i + 1, 2*i + 2), 16)
        memapi.poke(i + memapi.map.font_start, byte)
    end
    return true
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


function memapi.hex(str)
    return tonumber(str, 16)
end


function memapi.hexchar(num)
    return string.format("%x", num)
end


-- Export the modele as a table
return memapi