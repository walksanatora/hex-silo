--main lua program for controlling execution

--hard coded things
local read = "front"
local write = "top"
local append = textutils.unserializeJSON(
    '[{"angles":"qwaeawqaeaqa","startDir":"NORTH_WEST"},{"angles":"ewdqdwe","startDir":"SOUTH_WEST"},{"angles":"eaqwqae","startDir":"SOUTH_WEST"},{"angles":"eeeeeqd","startDir":"SOUTH_WEST"},{"angles":"waaw","startDir":"NORTH_EAST"},{"angles":"qqqqqdaqa","startDir":"SOUTH_EAST"},{"angles":"aawdd","startDir":"EAST"},{"angles":"wdwewewewewew","startDir":"EAST"}]'
)


local fp = peripheral.find("focal_port")
local completion = require "cc.shell.completion"

shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
    completion.file
))


--[[
    takes a file path or a table and hexcasting executes it and waits for output
    if get_output is true then it will return the output of the hex
    if get_output is false then it will return the hex executed
]]
local function executeHex(hex, get_output)
    fp.writeIota(nil)
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
    print("start circle")
    redstone.setOutput(write, true)
    sleep(1)
    redstone.setOutput(write, false)
    print("await completion")
    while redstone.getInput(read) do sleep(.1) end
    return fp.readIota()
end

local file = ...
if file == nil then error("Argument expected: file path") end

term.clear()
term.setCursorPos(1, 1)
textutils.pagedPrint(
    textutils.serialise(
        executeHex(file, true)
    )
)
