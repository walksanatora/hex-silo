-- simple utility script to load a hex into a focal port

local completion = require("cc.shell.completion")

shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
    { completion.choice, { "save", "load" } },
    completion.file
))

local args = { ... }

if #args < 2 then
    error("usage: hex <save/load> <file>")
end
local mode = args[1]
local file = args[2]
if (mode ~= "save") and (mode ~= "load") then
    error("mode must be either save or load (case sensitive), got: " .. mode)
end

local p = peripheral.find("focal_port")
if mode == "load" then
    if not fs.exists(file) then error("file must exist when loading") end
    local f = fs.open(file, "r")
    local d = f.readAll()
    f.close()
    local dat = textutils.unserializeJSON(d)
    print("succeded: " .. tostring(p.writeIota(dat)))
else
    local f = fs.open(file, "w")
    local d = p.readIota()
    f.write(textutils.serialiseJSON(d))
    f.flush()
    f.close()
    print("saved Iota to: " .. file)
end
