--main lua program for controlling execution

--hard coded things
local js = [==[
    [
  { angles: 'qwaeawqaeaqa', startDir: 'NORTH_WEST' },
  { angles: 'ewdqdwe', startDir: 'SOUTH_WEST' },
  { angles: 'eaqwqae', startDir: 'SOUTH_WEST' },
  { angles: 'qqqqqed', startDir: 'NORTH_WEST' },
  { angles: 'qqqqqed', startDir: 'NORTH_WEST' },
  { angles: 'waaw', startDir: 'NORTH_EAST' },
  { angles: 'waaw', startDir: 'NORTH_EAST' },
  { angles: 'qqqqqdaqa', startDir: 'SOUTH_EAST' },
  { angles: 'wdwewewewewew', startDir: 'EAST' }
]
]==]
local append = textutils.unserializeJSON(js)

textutils.pagedPrint(js)
textutils.pagedPrint(textutils.serialise(append))

local fp = peripheral.find("focal_port")
local imp = peripheral.find("cleric_impetus")
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
    imp.activateCircle()
    local ev, mishap, periph = os.pullEvent("circle_stopped")
    return fp.readIota()
end

local file = ...
if file == nil then error("Argument expected: file path") end


textutils.pagedPrint(
    textutils.serialise(
        executeHex(file, true)
    )
)
