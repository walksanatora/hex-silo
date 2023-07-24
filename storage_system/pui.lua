local expect = require "cc.expect".expect

local PrimeUI = {}
do
    local coros = {}
    local restoreCursor

    --- Adds a task to run in the main loop.
    ---@param func function The function to run, usually an `os.pullEvent` loop
    function PrimeUI.addTask(func)
        expect(1, func, "function")
        coros[#coros + 1] = { coro = coroutine.create(func) }
    end

    --- Sends the provided arguments to the run loop, where they will be returned.
    ---@param ... any The parameters to send
    function PrimeUI.resolve(...)
        coroutine.yield(coros, ...)
    end

    --- Clears the screen and resets all components. Do not use any previously
    --- created components after calling this function.
    function PrimeUI.clear()
        -- Reset the screen.
        term.setCursorPos(1, 1)
        term.setCursorBlink(false)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        -- Reset the task list and cursor restore function.
        coros = {}
        restoreCursor = nil
    end

    --- Sets or clears the window that holds where the cursor should be.
    ---@param win window|nil The window to set as the active window
    function PrimeUI.setCursorWindow(win)
        expect(1, win, "table", "nil")
        restoreCursor = win and win.restoreCursor
    end

    --- Gets the absolute position of a coordinate relative to a window.
    ---@param win window The window to check
    ---@param x number The relative X position of the point
    ---@param y number The relative Y position of the point
    ---@return number x The absolute X position of the window
    ---@return number y The absolute Y position of the window
    function PrimeUI.getWindowPos(win, x, y)
        if win == term then return x, y end
        while win ~= term.native() and win ~= term.current() do
            if not win.getPosition then return x, y end
            local wx, wy = win.getPosition()
            x, y = x + wx - 1, y + wy - 1
            _, win = debug.getupvalue(win.isColor, 1) -- gets the parent window through an upvalue
        end
        return x, y
    end

    --- Runs the main loop, returning information on an action.
    ---@return any ... The result of the coroutine that exited
    function PrimeUI.run()
        while true do
            -- Restore the cursor and wait for the next event.
            if restoreCursor then restoreCursor() end
            local ev = table.pack(os.pullEvent())
            -- Run all coroutines.
            for _, v in ipairs(coros) do
                if v.filter == nil or v.filter == ev[1] then
                    -- Resume the coroutine, passing the current event.
                    local res = table.pack(coroutine.resume(v.coro, table.unpack(ev, 1, ev.n)))
                    -- If the call failed, bail out. Coroutines should never exit.
                    if not res[1] then error(res[2], 2) end
                    -- If the coroutine resolved, return its values.
                    if res[2] == coros then return table.unpack(res, 3, res.n) end
                    -- Set the next event filter.
                    v.filter = res[2]
                end
            end
        end
    end
end

--- Draws a line of text at a position.
---@param win window The window to draw on
---@param x number The X position of the left side of the line
---@param y number The Y position of the line
---@param text string The text to draw
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.label(win, x, y, text, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, text, "string")
    fgColor = expect(5, fgColor, "number", "nil") or colors.white
    bgColor = expect(6, bgColor, "number", "nil") or colors.black
    win.setCursorPos(x, y)
    win.setTextColor(fgColor)
    win.setBackgroundColor(bgColor)
    win.write(text)
end

--- Creates a list of entries that can each be selected.
---@param win window The window to draw on
---@param x number The X coordinate of the inside of the box
---@param y number The Y coordinate of the inside of the box
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param entries string[] A list of entries to show, where the value is whether the item is pre-selected (or `"R"` for required/forced selected)
---@param action function|string A function or `run` event that's called when a selection is made
---@param selectChangeAction function|string|nil A function or `run` event that's called when the current selection is changed
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.selectionBox(win, x, y, width, height, entries, action, selectChangeAction, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, entries, "table")
    expect(7, action, "function", "string")
    expect(8, selectChangeAction, "function", "string", "nil")
    fgColor = expect(9, fgColor, "number", "nil") or colors.white
    bgColor = expect(10, bgColor, "number", "nil") or colors.black
    -- Create container window.
    local entrywin = window.create(win, x, y, width - 1, height)
    local selection, scroll = 1, 1
    -- Create a function to redraw the entries on screen.
    local function drawEntries()
        -- Clear and set invisible for performance.
        entrywin.setVisible(false)
        entrywin.setBackgroundColor(bgColor)
        entrywin.clear()
        -- Draw each entry in the scrolled region.
        for i = scroll, scroll + height - 1 do
            -- Get the entry; stop if there's no more.
            local e = entries[i]
            if not e then break end
            -- Set the colors: invert if selected.
            entrywin.setCursorPos(2, i - scroll + 1)
            if i == selection then
                entrywin.setBackgroundColor(fgColor)
                entrywin.setTextColor(bgColor)
            else
                entrywin.setBackgroundColor(bgColor)
                entrywin.setTextColor(fgColor)
            end
            -- Draw the selection.
            entrywin.clearLine()
            entrywin.write(#e > width - 1 and e:sub(1, width - 4) .. "..." or e)
        end
        -- Draw scroll arrows.
        entrywin.setCursorPos(width, 1)
        entrywin.write(scroll > 1 and "\30" or " ")
        entrywin.setCursorPos(width, height)
        entrywin.write(scroll < #entries - height + 1 and "\31" or " ")
        -- Send updates to the screen.
        entrywin.setVisible(true)
    end
    -- Draw first screen.
    drawEntries()
    -- Add a task for selection keys.
    PrimeUI.addTask(function()
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.down and selection < #entries then
                -- Move selection down.
                selection = selection + 1
                if selection > scroll + height - 1 then scroll = scroll + 1 end
                -- Send action if necessary.
                if type(selectChangeAction) == "string" then
                    PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                elseif selectChangeAction then
                    selectChangeAction(selection)
                end
                -- Redraw screen.
                drawEntries()
            elseif key == keys.up and selection > 1 then
                -- Move selection up.
                selection = selection - 1
                if selection < scroll then scroll = scroll - 1 end
                -- Send action if necessary.
                if type(selectChangeAction) == "string" then
                    PrimeUI.resolve("selectionBox", selectChangeAction, selection)
                elseif selectChangeAction then
                    selectChangeAction(selection)
                end
                -- Redraw screen.
                drawEntries()
            elseif key == keys.enter then
                -- Select the entry: send the action.
                if type(action) == "string" then
                    PrimeUI.resolve("selectionBox", action, entries[selection])
                else
                    action(entries[selection])
                end
            end
        end
    end)
end

--- Creates a text box that wraps text and can have its text modified later.
---@param win window The parent window of the text box
---@param x number The X position of the box
---@param y number The Y position of the box
---@param width number The width of the box
---@param height number The height of the box
---@param text string The initial text to draw
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@return function redraw A function to redraw the window with new contents
function PrimeUI.textBox(win, x, y, width, height, text, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    expect(6, text, "string")
    fgColor = expect(7, fgColor, "number", "nil") or colors.white
    bgColor = expect(8, bgColor, "number", "nil") or colors.black
    -- Create the box window.
    local box = window.create(win, x, y, width, height)
    -- Override box.getSize to make print not scroll.
    function box.getSize()
        return width, math.huge
    end

    -- Define a function to redraw with.
    local function redraw(_text)
        expect(1, _text, "string")
        -- Set window parameters.
        box.setBackgroundColor(bgColor)
        box.setTextColor(fgColor)
        box.clear()
        box.setCursorPos(1, 1)
        -- Redirect and draw with `print`.
        local old = term.redirect(box)
        print(_text)
        term.redirect(old)
    end
    redraw(text)
    return redraw
end

--- Draws a thin border around a screen region.
---@param win window The window to draw on
---@param x number The X coordinate of the inside of the box
---@param y number The Y coordinate of the inside of the box
---@param width number The width of the inner box
---@param height number The height of the inner box
---@param fgColor color|nil The color of the border (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.borderBox(win, x, y, width, height, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, height, "number")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    -- Draw the top-left corner & top border.
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    win.setCursorPos(x - 1, y - 1)
    win.write("\x9C" .. ("\x8C"):rep(width))
    -- Draw the top-right corner.
    win.setBackgroundColor(fgColor)
    win.setTextColor(bgColor)
    win.write("\x93")
    -- Draw the right border.
    for i = 1, height do
        win.setCursorPos(win.getCursorPos() - 1, y + i - 1)
        win.write("\x95")
    end
    -- Draw the left border.
    win.setBackgroundColor(bgColor)
    win.setTextColor(fgColor)
    for i = 1, height do
        win.setCursorPos(x - 1, y + i - 1)
        win.write("\x95")
    end
    -- Draw the bottom border and corners.
    win.setCursorPos(x - 1, y + height)
    win.write("\x8D" .. ("\x8C"):rep(width) .. "\x8E")
end

--- Draws a horizontal line at a position with the specified width.
---@param win window The window to draw on
---@param x number The X position of the left side of the line
---@param y number The Y position of the line
---@param width number The width/length of the line
---@param fgColor color|nil The color of the line (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
function PrimeUI.horizontalLine(win, x, y, width, fgColor, bgColor)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    fgColor = expect(5, fgColor, "number", "nil") or colors.white
    bgColor = expect(6, bgColor, "number", "nil") or colors.black
    -- Use drawing characters to draw a thin line.
    win.setCursorPos(x, y)
    win.setTextColor(fgColor)
    win.setBackgroundColor(bgColor)
    win.write(("\x8C"):rep(width))
end

--- Creates a text input box.
---@param win window The window to draw on
---@param x number The X position of the left side of the box
---@param y number The Y position of the box
---@param width number The width/length of the box
---@param action function|string A function or `run` event to call when the enter key is pressed
---@param fgColor color|nil The color of the text (defaults to white)
---@param bgColor color|nil The color of the background (defaults to black)
---@param replacement string|nil A character to replace typed characters with
---@param history string[]|nil A list of previous entries to provide
---@param completion function|nil A function to call to provide completion
---@param default string|nil A string to return if the box is empty
function PrimeUI.inputBox(win, x, y, width, action, fgColor, bgColor, replacement, history, completion, default)
    expect(1, win, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, width, "number")
    expect(5, action, "function", "string")
    fgColor = expect(6, fgColor, "number", "nil") or colors.white
    bgColor = expect(7, bgColor, "number", "nil") or colors.black
    expect(8, replacement, "string", "nil")
    expect(9, history, "table", "nil")
    expect(10, completion, "function", "nil")
    expect(11, default, "string", "nil")
    -- Create a window to draw the input in.
    local box = window.create(win, x, y, width, 1)
    box.setTextColor(fgColor)
    box.setBackgroundColor(bgColor)
    box.clear()
    -- Call read() in a new coroutine.
    PrimeUI.addTask(function()
        -- We need a child coroutine to be able to redirect back to the window.
        local coro = coroutine.create(read)
        -- Run the function for the first time, redirecting to the window.
        local old = term.redirect(box)
        local ok, res = coroutine.resume(coro, replacement, history, completion, default)
        term.redirect(old)
        -- Run the coroutine until it finishes.
        while coroutine.status(coro) ~= "dead" do
            -- Get the next event.
            local ev = table.pack(os.pullEvent())
            -- Redirect and resume.
            old = term.redirect(box)
            ok, res = coroutine.resume(coro, table.unpack(ev, 1, ev.n))
            term.redirect(old)
            -- Pass any errors along.
            if not ok then error(res) end
        end
        -- Send the result to the receiver.
        if type(action) == "string" then
            PrimeUI.resolve("inputBox", action, res)
        else
            action(res)
        end
        -- Spin forever, because tasks cannot exit.
        while true do os.pullEvent() end
    end)
end

return PrimeUI
