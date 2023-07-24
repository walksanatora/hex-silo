--main lua program for controlling execution

local pui = require("pui")

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--hard coded things
local js =
[=[ [{"angles":"qwaeawqaeaqa","startDir":"NORTH_WEST"},{"angles":"ewdqdwe","startDir":"SOUTH_WEST"},{"angles":"eaqwqae","startDir":"SOUTH_WEST"},{"angles":"qqq","startDir":"WEST"},{"x":0,"y":0,"z":2},{"angles":"eee","startDir":"EAST"},{"angles":"qwaeawq","startDir":"NORTH_WEST"},{"angles":"waaw","startDir":"NORTH_EAST"},{"angles":"qqqqqdaqa","startDir":"SOUTH_EAST"},{"angles":"aawdd","startDir":"EAST"},{"angles":"wdwewewewewew","startDir":"EAST"}] ]=]
local append = textutils.unserializeJSON(js)

local list_items = "list_items.json"
local pull_items = "pull_items.json"

local fp = peripheral.find("focal_port")
local imp_periph = peripheral.find("cleric_impetus", function(p)
    return table.contains(rs.getSides(), p)
end)
local imp = peripheral.getName(imp_periph)
local completion = require "cc.shell.completion"
local argv = { ... }

shell.setCompletionFunction(shell.getRunningProgram(), completion.build(
    completion.file
))

local flag

local function get_hex(hex)
    if not fs.exists(hex) then error("File path is invalid, does not exist") end
    if fs.isDir(hex) then error("File path is meant to point to a json file") end
    local f = fs.open(hex, "r")
    local d = f.readAll()
    f.close()
    hex = textutils.unserializeJSON(d)
    if type(hex) ~= "table" then error("Invalid json data") end
    return hex
end

--[[
    takes a file path or a table and hexcasting executes it and waits for output
    if get_output is true then it will return the output of the hex
    if get_output is false then it will return the hex executed
]]
local function executeHex(hex, get_output)
    while true do
        if not imp_periph.isCasting() then
            break
        end
        sleep(1)
    end
    fp.writeIota(nil)
    local code
    -- get code from file
    if type(hex) == "string" then
        code = get_hex(hex)
        if type(code) ~= "table" then error("Invalid json data") end
    elseif type(hex) == "table" then
        code = hex
    else
        error("Expected file path or table, got" .. type(hex))
    end

    --inject callback if we need the output
    if get_output then
        for _, v in ipairs(append) do
            table.insert(code, v)
        end
    end

    fp.writeIota(code)
    if type(imp) == "string" then
        redstone.setOutput(imp, true)
        sleep(1)
        redstone.setOutput(imp, false)
    else
        imp.activateCircle() --broken
    end
    local ev, mishap, periph = os.pullEvent("circle_stopped")
    return fp.readIota()
end

--[[
    replaces all of a specified pattern in the hex with iota
]]
local function surgeons(hex, pattern, iota)
    for idx, pat in ipairs(hex) do
        if (pat["startDir"] == pattern["startDir"]) and (pat["angles"] == pattern["angles"]) then
            hex[idx] = iota
        end
    end
end

local function reloadItems()
    local res = executeHex(list_items, true)
    local counts = {}
    local readable = {}
    for _, v in pairs(res[1]) do
        counts[v[2]["itemType"]] = v[3]
        readable[v[1]] = v[2]["itemType"]
    end
    return { counts = counts, read = readable }
end

local function exportItems(id, count)
    local hex = get_hex(pull_items)
    surgeons(hex, { ["startDir"] = 'EAST', ["angles"] = '' }, { ["isItem"] = true, ["itemType"] = id })
    surgeons(hex, { ["startDir"] = 'EAST', ["angles"] = 'w' }, tonumber(count))
    executeHex(hex, false)
end

--key is itemid
--value is count
local items = {}
local item_ids = {}
local item_names = {}
local item_names_to_ids = {}

parallel.waitForAny(
    function()
        while true do
            both = reloadItems() --refresh item list
            item_ids = {}
            item_names = {}
            items = both["counts"]
            for k, _ in pairs(both["counts"]) do
                table.insert(item_ids, k)
            end
            for k, _ in pairs(both["read"]) do
                table.insert(item_names, k)
            end
            item_names_to_ids = both["read"]
            table.sort(item_names)
            sleep(10) --once a minute
        end
    end,
    function()
        while true do
            if #item_ids ~= 0 then
                pui.clear()
                local count = pui.textBox(term.current(), 3, 18, 45, 1,
                    "stored: " .. tostring(items[item_names_to_ids[item_names[1]]]))
                pui.borderBox(term.current(), 4, 2, 45, 15)
                pui.selectionBox(term.current(), 4, 2, 45, 15, item_names, "done", function(opt)
                    count("stored: " .. tostring(items[item_names_to_ids[item_names[opt]]]))
                end)
                local _, _, itemname = pui.run()
                local itemid = item_names_to_ids[itemname]
                pui.clear()
                local title = "How many items max: " .. items[itemid]
                pui.label(term.current(), 3, 2, title)
                pui.horizontalLine(term.current(), 3, 3, #title + 2)
                pui.borderBox(term.current(), 4, 4, 40, 1)
                pui.inputBox(term.current(), 4, 4, 40, "result")
                local _, _, text = pui.run()
                exportItems(itemid, text)
            end
            sleep()
        end
    end
)

--[[
elseif #argv == 2 then
    local hex = get_hex(pull_items)
    surgeons(hex, { ["startDir"] = 'EAST', ["angles"] = '' }, { ["isItem"] = true, ["itemType"] = argv[1] })
    surgeons(hex, { ["startDir"] = 'EAST', ["angles"] = 'w' }, tonumber(argv[2]))
    executeHex(hex, false)
end
]]
