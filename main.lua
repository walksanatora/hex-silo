--main lua program for controlling execution
local fp = peripheral.find("focal_port")
local impetus = "bottom"


local function executeHex(hex)
    local code
    if type(hex) == "string" then
        local f = fs.open(hex,"r")
        local d = f.readAll()
        f.close()
        code = textutils.unserializeJSON(d)
    elseif type(hex) == "table" then
        code = hex
    else
        error("Expected file path or table, got"..type(hex))
    end
    fp.writeIota(code)
    redstone.setAnalogOutput(impetus,15)
    sleep(1)
    redstone.setAnalogOutput(impetus,0)
    while redstone.getAnalogInput(impetus) ~= 0 do sleep() end
end