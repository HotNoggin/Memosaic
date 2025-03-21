-- Prepare a table for the api module and memory
local memapi = {
    bytes = {},
    stash = {},
}

local jjrle = require("engine.jjrle")

memapi.default_font = "007E464A52627E007733770077577500005E42425E505000004C42424C505000007E424242427E00005850585E585C0000003C3C3C3C0000003C765E5E763C001C147F7F7F1C1C001C1C7F7F7F141C001C1C7F7D7F1C1C001C1C7F5F7F1C1C003E7F6B776B7F3E003E7F636B637F3E001C147F5D7F141C00007E3E1E3E766200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005E5E000000000E0E000E0E0000247E7E247E7E2400005C5CD6D6747400006676381C6E660000347E4A763048000000000E0E00000000003C7E420000000000427E3C00000000041C0E1C0400000018187E7E181800000040606000000000181818181818000000006060000000006070381C0E0600003C7E524A7E3C000040447E7E404000006476725A5E4C00002466424A7E3400001E1E10107E7E00002E6E4A4A7A3200003C7E4A4A7A3000000606727A0E060000347E4A4A7E3400000C5E52527E3C000000006C6C0000000000406C6C0000000000183C664200000024242424242400000042663C180000000406525A1E0C00007C82BAAAB23C00007C7E0A0A7E7C00007E7E4A4A7E3400003C7E4242662400007E7E42427E3C00007E7E4A4A424200007E7E0A0A020200003C7E424A7A3800007E7E08087E7E000042427E7E42420000307040427E3E00007E7E181C766200007E7E40406060007E7E060C067E7E00007E7E0C187E7E00003C7E42427E3C00007E7E12121E0C00003C7E4262FEBC00007E7E0A0A7E7400002C4E5A5A7234000002027E7E020200003E7E40407E3E00001E3E70603E1E003E7E6030607E3E0000767E08087E760000060E7C780E0600004262725A4E460000007E7E4242000000060E1C38706000000042427E7E000000080C06060C080000404040404040000000060E0C00000000387C44443C7C00007F7F44447C380000387C44446C280000387C44447F7F0000387C54545C180000087E7F090B02000098BCA4A4FCF800007F7F04047C78000044447D7D404000008080FDFD000000007F7F081C7662000040417F7F404000787C0C180C7C7800007C7C08047C780000387C44447C380000FCFC48447C380000387C4448FCFC80007C7C08041C180000585C545474300000043E7E44440000003C7C40407C7C00001C3C70603C1C003C7C6030607C3C00006C7C10107C6C00009CBCA0A0FCFC00006474745C5C4C000000087E764200000000007E7E000000000042767E0800000010081818100800007E5A66665A7E00"
memapi.editor_font  = "007E464A52627E007733770077577500005E42425E505000004C42424C505000005048445E484400005850585E585C0000003C3C3C3C0000003C765E5E763C001C147F7F7F1C1C001C1C7F7F7F141C001C1C7F7D7F1C1C001C1C7F5F7F1C1C003E7F6B776B7F3E003E7F636B637F3E001C147F5D7F141C00007E3E1E3E766200007E5A42667E7E00007E426A6A427E00007E6A6A7A6A7E00007E464E42467E00007E6A566A567E0000405858585840000040606060604000007E484A484E7C00001E5E1E5E00540000787A787A002A00040C6F5E78141C0000000000000000000000000000000000007E424242427E00007E425A5A427E00000000000000000000000000000000000000005E5E000000000E0E000E0E0000247E7E247E7E2400005C5CD6D6747400006676381C6E660000347E4A763048000000000E0E00000000003C7E420000000000427E3C00000000041C0E1C0400000018187E7E181800000040606000000000181818181818000000006060000000006070381C0E0600003C7E524A7E3C000040447E7E404000006476725A5E4C00002466424A7E3400001E1E10107E7E00002E6E4A4A7A3200003C7E4A4A7A3000000606727A0E060000347E4A4A7E3400000C5E52527E3C000000006C6C0000000000406C6C0000000000183C664200000024242424242400000042663C180000000406525A1E0C00007C82BAAAB23C00007C7E0A0A7E7C00007E7E4A4A7E3400003C7E4242662400007E7E42427E3C00007E7E4A4A424200007E7E0A0A020200003C7E424A7A3800007E7E08087E7E000042427E7E42420000307040427E3E00007E7E181C766200007E7E40406060007E7E060C067E7E00007E7E0C187E7E00003C7E42427E3C00007E7E12121E0C00003C7E4262FEBC00007E7E0A0A7E7400002C4E5A5A7234000002027E7E020200003E7E40407E3E00001E3E70603E1E003E7E6030607E3E0000767E08087E760000060E7C780E0600004262725A4E460000007E7E4242000000060E1C38706000000042427E7E000000080C06060C080000404040404040000000060E0C00000000387C44443C7C00007F7F44447C380000387C44446C280000387C44447F7F0000387C54545C180000087E7F090B02000098BCA4A4FCF800007F7F04047C78000044447D7D404000008080FDFD000000007F7F081C7662000040417F7F404000787C0C180C7C7800007C7C08047C780000387C44447C380000FCFC48447C380000387C4448FCFC80007C7C08041C180000585C545474300000043E7E44440000003C7C40407C7C00001C3C70603C1C003C7C6030607C3C00006C7C10107C6C00009CBCA0A0FCFC00006474745C5C4C000000087E764200000000007E7E000000000042767E0800000010081818100800007E5A66665A7E00"

-- The addresses of specific areas of memory
memapi.map = {
    memory_start = 0x0000, memory_end = 0x1fff, -- The entirety of the memory
    write_start  = 0x0000, write_end  = 0x1fff, -- The writable memory block
    font_start   = 0x0000, font_end   = 0x03ff, -- 1024 (1 kibi) bytes for 128 8-byte cart chars
    sounds_start = 0x0400, sounds_end = 0x07ff, -- 1024 (1 kibi) bytes for 32 to 48 32-byte sounds

    sqrwav_start = 0x0800, sqrwav_stop = 0x09ff, -- Channel 0: square, 512 bytes of instruction
    triwav_start = 0x0a00, triwav_stop = 0x0bff, -- Channel 1: triangle, 512 bytes of instruction

    ascii_start  = 0x0c00, ascii_end  = 0x0cff, -- 256 bytes for ascii char grid of 256 chars
    color_start  = 0x0d00, color_end  = 0x0dff, -- 256 bytes for 4-bit color grid of 512 colors

    scroll_start = 0x0e00, scroll_end = 0x0e0f, -- 16 bytes for 128 pixels of scroll per tile line
    pan_x        = 0x0e10, pan_y      = 0x0e11, -- 2 bytes for the tile grid pan x and y
    rflags_start = 0x0e20, rflags_end = 0x0e2f, -- 16 bytes for tile row flags of 8 flags per row

    efont_start  = 0x1000, efont_end  = 0x13ff, -- 1024 (1 kibi) bytes for 128 8-byte editor chars 

    sawwav_start = 0x1800, sawwav_stop = 0x19ff, -- Channel 2: sawtooth, 512 bytes of instruction
    nozwav_start = 0x1a00, nozwav_stop = 0x1bff, -- Channel 3: noise, 512 bytes of instruction
}


-- Create a new, 4Kib memory buffer
function memapi.init(memo)
    print("Creating memory buffer")

    -- FFI is not supported on web, so byte-dependent features must be replaced
    local success, ffi = pcall(require, "ffi")
    memapi.is_ffi = success
    if memapi.is_ffi then
        memapi.bytes = love.data.newByteData(0x2000) -- New 8Kib buffer
        memapi.stash = love.data.newByteData(0x2000) -- Duplicate buffer for editor stash
        memapi.ffi = ffi
    else
        memapi.poke = memapi.web_poke -- slightly slower because of % 256
        memapi.backup = memapi.web_backup -- uses table instead of bytes
        memapi.retrieve = memapi.web_retrieve -- uses table instead of bytes
        memapi.bytes = {}
        memapi.stash = {}
        for i = 1, 0x2000 do
            memapi.bytes[i] = 0
            memapi.stash[i] = 0
        end
    end

    memapi.ptr = memapi.get_ptr()
    memapi.load_font(memapi.default_font)
    memapi.load_font(memapi.editor_font, true)
    memapi.backup()
    memapi.memo = memo
end


function memapi.get_ptr()
    if memapi.is_ffi then
        return memapi.ffi.cast('uint8_t*', memapi.bytes:getFFIPointer()) -- Byte pointer
    else
        return memapi.bytes -- Plain ol' table
    end
end


function memapi.backup()
    memapi.stash = memapi.bytes:clone()
    print("Stashed editor memory")
end


function memapi.retrieve()
    memapi.bytes = memapi.stash:clone()
    memapi.ptr = memapi.get_ptr()
    print("Retrieved editor memory")
end


function memapi.web_backup()
    for i, v in ipairs(memapi.bytes) do
        memapi.stash[i] = v
    end
    print("Stashed editor memory")
end


function memapi.web_retrieve()
    for i, v in ipairs(memapi.stash) do
        memapi.bytes[i] = v
    end
    print("Retrieved editor memory")
end


-- Loads font from a hexadecimal string
function memapi.load_font(packedfont, editor)
    print("Loading font")
    local font
    if packedfont == "" then
        font = memapi.default_font
    else
        font = jjrle.unpack(packedfont)
    end
    local font_size = memapi.map.font_end - memapi.map.font_start
    local font_start = memapi.map.font_start
    if editor then font_start = memapi.map.efont_start end
    if not font then return false end
    for i = 0, font_size do
        if #font <= 2*i then return false end
        local byte = memapi.hex(string.sub(font, 2*i + 1, 2*i + 2))
        memapi.poke(i + font_start, byte)
    end
    return true
end


-- Loads a single sound from a hexadecimal string
-- The volumes come first, then the notes,
-- as that is the most space-saving for jjrle.
-- Do note that the header is also split like that!
function memapi.load_sound(idx, packedsound)
    local sound = jjrle.unpack(packedsound)
    if #sound < 64 then return false end
    for i = 0, 31 do
        local vol = sound:sub(i + 1, i + 1)
        local note = sound:sub(i + 33, i + 33)
        local byte = memapi.hex(note .. vol)
        memapi.poke(idx * 32 + i + memapi.map.sounds_start, byte)
    end
    return true
end


-- Get the byte at the specified address
function memapi.peek(address)
    if not type(address) == "number" then return end
    if address < memapi.map.memory_start or address > memapi.map.memory_end then
        memapi.error("Attempted to access out of bounds memory at " .. address)
        return
    end

    return memapi.ptr[address]
end


-- Set the byte at the specified address (mod 256)
function memapi.web_poke(address, value)
    if not type(address) == "number" then return end
    if not type(value) == "number" then return end

    if address < memapi.map.memory_start or address > memapi.map.memory_end then
        memapi.error("Attempted to access out of bounds memory at " .. address)
        return false
    elseif address < memapi.map.write_start or address > memapi.map.write_end then
        memapi.error("Attempted to write to read only memory at " .. address)
        return false
    end

    memapi.ptr[address] = value % 256
    return true
end


-- Set the byte at the specified address
function memapi.poke(address, value)
    if not type(address) == "number" then return end
    if not type(value) == "number" then return end

    if address < memapi.map.memory_start or address > memapi.map.memory_end then
        memapi.error("Attempted to access out of bounds memory at " .. address)
        return false
    elseif address < memapi.map.write_start or address > memapi.map.write_end then
        memapi.error("Attempted to write to read only memory at " .. address)
        return false
    end

    memapi.ptr[address] = value
    return true
end


function memapi.hex(str)
    return tonumber(str, 16)
end


function memapi.hexchar(num)
    return string.upper(string.format("%x", num))
end


function memapi.error(txt)
    memapi.memo.editor.console.error(txt)
end

-- Export the module as a table
return memapi