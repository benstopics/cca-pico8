local lualzw = require("lualzw")

-- see if the file exists
function FILE_EXISTS(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function LINES_FROM(file)
    if not FILE_EXISTS(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

-- tests the functions above
TEXT_DATA = table.concat(LINES_FROM('formatted-cca.dat'), "|")

local input = TEXT_DATA
local compressed = assert(lualzw.compress(input))
local decompressed = assert(lualzw.decompress(compressed))

local function PrintHex(data)
    for i = 1, #data do
        local char = string.sub(data, i, i)
        return string.format("%02x", string.byte(char)) .. " "
    end
end

-- https://gist.github.com/yi/01e3ab762838d567e65d
function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

local hex = string.lower(string.tohex(compressed))
local p8_hex = '__gfx__\n'

local rows = 0
local col = 0
local total_bytes = 0
local total_sfx_bytes = 0

for i = 1,#hex,2 do
    total_bytes = total_bytes + 1
    col = col + 2
    if rows < 128 then
        p8_hex = p8_hex .. hex:sub(i+1,i+1)
        p8_hex = p8_hex .. hex:sub(i,i)
        if col == 128 then
            p8_hex = p8_hex .. '\n'
            col = 0
            rows = rows + 1
            if rows == 128 then p8_hex = p8_hex .. '__map__\n' end
        end
    elseif rows < 160 then
        p8_hex = p8_hex .. hex:sub(i,i)
        p8_hex = p8_hex .. hex:sub(i+1,i+1)
        if col == 256 then
            p8_hex = p8_hex .. '\n'
            col = 0
            rows = rows + 1
            if rows == 160 then p8_hex = p8_hex .. '__sfx__\n' end
        end
    elseif rows >= 160 then
        p8_hex = p8_hex .. hex:sub(i+1,i+1)
        p8_hex = p8_hex .. hex:sub(i,i)
        total_sfx_bytes = total_sfx_bytes + 1
        if col == 128 then
            p8_hex = p8_hex .. '\n'
            col = 0
        end
    end
end

return