-- Prepare a table for the api module and memory
local memapi = {}

-- The addresses of specific areas of memory
memapi.map = {
    memory_start = 0x000, memory_end = 0xfff,
    write_start = 0x000, write_end = 0xfff,
    font_start = 0x000, font_end = 0x7ff,
    sfx_start = 0x800, sfx_end = 0x9ff,
    audio_start = 0xa00, audio_end = 0xbff,
    grid_start = 0xc00, grid_end = 0xdff,
    save_start = 0xe00, save_end = 0xfff
}


-- Fill the mem buffer
function memapi.create_memory()
    local mem_table = {}
    print("Initializing memory buffer")
    for i = memapi.map.memory_start, memapi.map.memory_end do
        mem_table[i] = 0x00
    end
    return mem_table
end


-- Get the byte at the specified address
function memapi.peek(mem_table, address)
    if not type(address) == "number" then return end
    if address < memapi.map.memory_start or address > memapi.map.memory_end then
        error("Attempted to access out of bounds memory at " .. address)
    end

    return mem_table[address]
end


-- Set the byte at the specified address
function memapi.poke(mem_table, address, value)
    if not type(address) == "number" then return end
    if not type(value) == "number" then return end

    if address < memapi.map.write_start and address > memapi.map.write_end then
        error("Attempted to write to read only memory at " .. address)
    end

    mem_table[address] = value
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