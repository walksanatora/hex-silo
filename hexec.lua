--main lua program for controlling execution
local fp = peripheral.find("focal_port")
local read = "top"
local write = "back"

local completion = require "cc.shell.completion"

shell.setCompletionFunction(shell.getRunningProgram(),completion.build(
    completion.file
))

local function executeHex(hex)
    fp.writeIota(nil)
    redstone.setAnalogOutput(write,15)
    sleep(1)
    redstone.setAnalogOutput(write,0)
    local code
    if type(hex) == "string" then
        if not fs.exists(hex) then error("File path is invalid, does not exist") end
        if fs.isDir(hex) then error("File path is meant to point to a json file") end
        local f = fs.open(hex,"r")
        local d = f.readAll()
        f.close()
        code = textutils.unserializeJSON(d)
        if type(code) ~="table" then error("Invalid json data") end
    elseif type(hex) == "table" then
        code = hex
    else
        error("Expected file path or table, got"..type(hex))
    end
    fp.writeIota(code)
    local c = 0
    while redstone.getAnalogInput(read) ~= 0 do sleep() end
    return fp.readIota()
end

local file = ...
if file == nil then error("Argument expected: file path") end

print(textutils.pagedTabulate(executeHex(...)))