--main lua program for controlling execution

--hard coded things
local read = "top"
local write = "back"
local append = textutils.unserializeJSON(
    '[{"angles":"qwaeawqaeaqa","startDir":"NORTH_WEST"},{"angles":"ewdqdwe","startDir":"SOUTH_WEST"},{"angles":"eaqwqae","startDir":"SOUTH_WEST"},{"angles":"qqqqqea","startDir":"NORTH_WEST"},{"angles":"waaw","startDir":"NORTH_EAST"},{"angles":"wdwewewewewew","startDir":"EAST"}]'
)


local fp = peripheral.find("focal_port")
local completion = require "cc.shell.completion"

shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
    completion.file
))



local function executeHex(hex, get_output)
    fp.writeIota(nil)
    redstone.setOutput(write, true)
    sleep(1)
    redstone.setOutput(write, false)
    local code
    -- get code from file
    if type(hex) == "string" then
        if not fs.exists(hex) then error("File path is invalid, does not exist") end
        if fs.isDir(hex) then error("File path is meant to point to a json file") end
        local f = fs.open(hex, "r")
        local d = f.readAll()
        f.close()
        code = textutils.unserializeJSON(d)
        if type(code) ~= "table" then error("Invalid json data") end
    elseif type(hex) == "table" then
        code = hex
    else
        error("Expected file path or table, got" .. type(hex))
    end

    --inject callback if we need the output
    if get_output then
        print("injecting callback")
        for _, v in ipairs(append) do
            table.insert(code, v)
        end
    end

    fp.writeIota(code)
    local c = 0
    print("await completion")
    while redstone.getInput(read) do sleep(1) end
    if get_output then return fp.readIota() end
end

local file = ...
if file == nil then error("Argument expected: file path") end

--term.clear()
--term.setCursorPos(1, 1)
--textutils.pagedPrint(
--textutils.serialise(
executeHex(file, true)
--)
--)
