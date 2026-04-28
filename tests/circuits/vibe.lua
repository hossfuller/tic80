-- Electronics Simulator for TIC-80
-- by Claude

-- Constants
local GRID_SIZE = 8
local GRID_W = 30
local GRID_H = 17
local TOOLBAR_Y = 0
local GRID_Y = 10

-- Component types
local COMP = {
    NONE = 0,
    WIRE = 1,
    POWER = 2,
    GROUND = 3,
    LED = 4,
    SWITCH = 5,
    AND_GATE = 6,
    OR_GATE = 7,
    NOT_GATE = 8,
    NAND_GATE = 9,
    NOR_GATE = 10,
    XOR_GATE = 11,
    BUTTON = 12,
    RESISTOR = 13,
    CAPACITOR = 14,
    CROSSWIRE = 15
}

local COMP_NAMES = {
    [COMP.NONE] = "Erase",
    [COMP.WIRE] = "Wire",
    [COMP.POWER] = "Power",
    [COMP.GROUND] = "Ground",
    [COMP.LED] = "LED",
    [COMP.SWITCH] = "Switch",
    [COMP.AND_GATE] = "AND",
    [COMP.OR_GATE] = "OR",
    [COMP.NOT_GATE] = "NOT",
    [COMP.NAND_GATE] = "NAND",
    [COMP.NOR_GATE] = "NOR",
    [COMP.XOR_GATE] = "XOR",
    [COMP.BUTTON] = "Button",
    [COMP.RESISTOR] = "Resistor",
    [COMP.CAPACITOR] = "Capacitor",
    [COMP.CROSSWIRE] = "Cross"
}

-- Colors
local COL = {
    BG = 0,
    GRID = 1,
    WIRE_OFF = 2,
    WIRE_ON = 11,
    POWER = 6,
    GROUND = 8,
    LED_OFF = 2,
    LED_ON = 11,
    GATE = 12,
    SWITCH_OFF = 2,
    SWITCH_ON = 11,
    TEXT = 12,
    TOOLBAR = 15,
    SELECT = 6,
    RESISTOR = 4,
    CAPACITOR = 9
}

-- Grid data
local grid = {}
local powered = {}
local selected = COMP.WIRE
local mx, my = 0, 0
local prevMx, prevMy = -1, -1
local mouseDown = false
local prevMouseDown = false
local tick = 0
local simSpeed = 1
local buttonHeld = {}

-- Initialize grid
function initGrid()
    for x = 0, GRID_W - 1 do
        grid[x] = {}
        powered[x] = {}
        buttonHeld[x] = {}
        for y = 0, GRID_H - 1 do
            grid[x][y] = {
                type = COMP.NONE,
                state = false,    -- for switches
                rotation = 0,     -- 0,1,2,3 = N,E,S,W
                hPowered = false, -- horizontal power for crosswire
                vPowered = false  -- vertical power for crosswire
            }
            powered[x][y] = false
            buttonHeld[x][y] = false
        end
    end
end

-- Check if position is in grid bounds
function inBounds(x, y)
    return x >= 0 and x < GRID_W and y >= 0 and y < GRID_H
end

-- Get component at grid position
function getComp(x, y)
    if inBounds(x, y) then
        return grid[x][y]
    end
    return nil
end

-- Set component at grid position
function setComp(x, y, compType)
    if inBounds(x, y) then
        grid[x][y].type = compType
        grid[x][y].state = false
        grid[x][y].rotation = 0
    end
end

-- Check if a cell is powered (propagation)
function isPowered(x, y)
    if not inBounds(x, y) then return false end
    return powered[x][y]
end

-- Simulate the circuit
function simulate()
    -- Reset powered state
    local newPowered = {}
    for x = 0, GRID_W - 1 do
        newPowered[x] = {}
        for y = 0, GRID_H - 1 do
            newPowered[x][y] = false
            grid[x][y].hPowered = false
            grid[x][y].vPowered = false
        end
    end

    -- Find all power sources and propagate
    local toVisit = {}

    -- Add power sources
    for x = 0, GRID_W - 1 do
        for y = 0, GRID_H - 1 do
            local comp = grid[x][y]
            if comp.type == COMP.POWER then
                table.insert(toVisit, { x = x, y = y })
                newPowered[x][y] = true
            elseif comp.type == COMP.SWITCH and comp.state then
                table.insert(toVisit, { x = x, y = y })
                newPowered[x][y] = true
            elseif comp.type == COMP.BUTTON and buttonHeld[x][y] then
                table.insert(toVisit, { x = x, y = y })
                newPowered[x][y] = true
            end
        end
    end

    -- Process gates first
    for x = 0, GRID_W - 1 do
        for y = 0, GRID_H - 1 do
            local comp = grid[x][y]
            if comp.type >= COMP.AND_GATE and comp.type <= COMP.XOR_GATE then
                local inputs = getGateInputs(x, y, comp.rotation)
                local output = evaluateGate(comp.type, inputs)
                if output then
                    newPowered[x][y] = true
                    table.insert(toVisit, { x = x, y = y })
                end
            end
        end
    end

    -- Flood fill power through wires
    local visited = {}
    for x = 0, GRID_W - 1 do
        visited[x] = {}
        for y = 0, GRID_H - 1 do
            visited[x][y] = false
        end
    end

    while #toVisit > 0 do
        local current = table.remove(toVisit, 1)
        local cx, cy = current.x, current.y

        if not visited[cx][cy] then
            visited[cx][cy] = true
            newPowered[cx][cy] = true

            local comp = grid[cx][cy]

            -- Propagate to neighbors
            local dirs = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
            for _, d in ipairs(dirs) do
                local nx, ny = cx + d[1], cy + d[2]
                if inBounds(nx, ny) and not visited[nx][ny] then
                    local ncomp = grid[nx][ny]
                    if canPropagate(comp.type, ncomp.type) then
                        -- Handle crosswire specially
                        if ncomp.type == COMP.CROSSWIRE then
                            if d[1] ~= 0 then -- horizontal
                                grid[nx][ny].hPowered = true
                            else              -- vertical
                                grid[nx][ny].vPowered = true
                            end
                            -- Continue in same direction
                            local nnx, nny = nx + d[1], ny + d[2]
                            if inBounds(nnx, nny) and not visited[nnx][nny] then
                                local nncomp = grid[nnx][nny]
                                if canPropagate(COMP.WIRE, nncomp.type) then
                                    table.insert(toVisit, { x = nnx, y = nny })
                                end
                            end
                        else
                            table.insert(toVisit, { x = nx, y = ny })
                        end
                    end
                end
            end
        end
    end

    powered = newPowered
end

-- Check if power can propagate between component types
function canPropagate(fromType, toType)
    if toType == COMP.NONE or toType == COMP.GROUND then
        return false
    end
    if toType >= COMP.AND_GATE and toType <= COMP.XOR_GATE then
        return false -- Gates don't receive power directly
    end
    return true
end

-- Get inputs for a logic gate
function getGateInputs(x, y, rotation)
    local inputs = { false, false }
    local dirs = {
        [0] = { { -1, 0 }, { 1, 0 } }, -- North: inputs from left/right
        [1] = { { 0, -1 }, { 0, 1 } }, -- East: inputs from top/bottom
        [2] = { { -1, 0 }, { 1, 0 } }, -- South: inputs from left/right
        [3] = { { 0, -1 }, { 0, 1 } } -- West: inputs from top/bottom
    }

    local d = dirs[rotation] or dirs[0]
    for i, dir in ipairs(d) do
        local nx, ny = x + dir[1], y + dir[2]
        if inBounds(nx, ny) then
            inputs[i] = powered[nx][ny]
        end
    end
    return inputs
end

-- Evaluate logic gate
function evaluateGate(gateType, inputs)
    local a, b = inputs[1], inputs[2]

    if gateType == COMP.AND_GATE then
        return a and b
    elseif gateType == COMP.OR_GATE then
        return a or b
    elseif gateType == COMP.NOT_GATE then
        return not a
    elseif gateType == COMP.NAND_GATE then
        return not (a and b)
    elseif gateType == COMP.NOR_GATE then
        return not (a or b)
    elseif gateType == COMP.XOR_GATE then
        return (a or b) and not (a and b)
    end
    return false
end

-- Draw toolbar
function drawToolbar()
    rect(0, 0, 240, GRID_Y, COL.TOOLBAR)

    local items = {
        COMP.NONE, COMP.WIRE, COMP.POWER, COMP.GROUND,
        COMP.LED, COMP.SWITCH, COMP.BUTTON, COMP.AND_GATE,
        COMP.OR_GATE, COMP.NOT_GATE, COMP.XOR_GATE, COMP.CROSSWIRE
    }

    for i, comp in ipairs(items) do
        local tx = (i - 1) * 20
        local ty = 1

        if selected == comp then
            rect(tx, ty, 18, 8, COL.SELECT)
        end

        -- Draw mini icon
        drawMiniComp(tx + 9, ty + 4, comp, true)
    end

    -- Draw selected name
    print(COMP_NAMES[selected] or "?", 1, 136 - 6, COL.TEXT, false, 1, true)
end

-- Draw mini component for toolbar
function drawMiniComp(x, y, compType, on)
    if compType == COMP.NONE then
        print("X", x - 2, y - 2, 8)
    elseif compType == COMP.WIRE then
        line(x - 3, y, x + 3, y, on and COL.WIRE_ON or COL.WIRE_OFF)
    elseif compType == COMP.POWER then
        print("+", x - 2, y - 2, COL.POWER)
    elseif compType == COMP.GROUND then
        print("-", x - 2, y - 2, COL.GROUND)
    elseif compType == COMP.LED then
        circ(x, y, 2, on and COL.LED_ON or COL.LED_OFF)
    elseif compType == COMP.SWITCH then
        rect(x - 2, y - 2, 5, 5, on and COL.SWITCH_ON or COL.SWITCH_OFF)
    elseif compType == COMP.BUTTON then
        rectb(x - 2, y - 2, 5, 5, COL.SWITCH_OFF)
    elseif compType == COMP.AND_GATE then
        print("&", x - 2, y - 2, COL.GATE)
    elseif compType == COMP.OR_GATE then
        print("|", x - 2, y - 2, COL.GATE)
    elseif compType == COMP.NOT_GATE then
        print("!", x - 2, y - 2, COL.GATE)
    elseif compType == COMP.XOR_GATE then
        print("^", x - 2, y - 2, COL.GATE)
    elseif compType == COMP.CROSSWIRE then
        line(x - 2, y, x + 2, y, COL.WIRE_OFF)
        line(x, y - 2, x, y + 2, COL.WIRE_OFF)
    end
end

-- Draw grid
function drawGrid()
    -- Draw grid lines
    for x = 0, GRID_W do
        local px = x * GRID_SIZE
        line(px, GRID_Y, px, 136, COL.GRID)
    end
    for y = 0, GRID_H do
        local py = y * GRID_SIZE + GRID_Y
        line(0, py, 240, py, COL.GRID)
    end

    -- Draw components
    for x = 0, GRID_W - 1 do
        for y = 0, GRID_H - 1 do
            local comp = grid[x][y]
            if comp.type ~= COMP.NONE then
                local px = x * GRID_SIZE + GRID_SIZE // 2
                local py = y * GRID_SIZE + GRID_Y + GRID_SIZE // 2
                local on = powered[x][y]

                drawComponent(px, py, comp, on)
            end
        end
    end
end

-- Draw a component
function drawComponent(x, y, comp, on)
    local t = comp.type
    local s = GRID_SIZE // 2 - 1

    if t == COMP.WIRE then
        -- Draw wire connections
        local col = on and COL.WIRE_ON or COL.WIRE_OFF
        circ(x, y, 2, col)
        -- Connect to neighbors
        local gx = (x - GRID_SIZE // 2) // GRID_SIZE
        local gy = (y - GRID_Y - GRID_SIZE // 2) // GRID_SIZE
        local dirs = { { 0, -1, 0, -s }, { 1, 0, s, 0 }, { 0, 1, 0, s }, { -1, 0, -s, 0 } }
        for _, d in ipairs(dirs) do
            local nx, ny = gx + d[1], gy + d[2]
            if inBounds(nx, ny) and grid[nx][ny].type ~= COMP.NONE then
                line(x, y, x + d[3], y + d[4], col)
            end
        end
    elseif t == COMP.POWER then
        local col = COL.POWER
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("+", x - 2, y - 2, 0)
    elseif t == COMP.GROUND then
        local col = COL.GROUND
        line(x - s, y, x + s, y, col)
        line(x - s + 1, y + 1, x + s - 1, y + 1, col)
        line(x - s + 2, y + 2, x + s - 2, y + 2, col)
    elseif t == COMP.LED then
        local col = on and COL.LED_ON or COL.LED_OFF
        circ(x, y, s, col)
        if on then
            circb(x, y, s + 1, COL.LED_ON)
        end
    elseif t == COMP.SWITCH then
        local col = comp.state and COL.SWITCH_ON or COL.SWITCH_OFF
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        rectb(x - s, y - s, s * 2 + 1, s * 2 + 1, 12)
        if comp.state then
            print("1", x - 2, y - 2, 0)
        else
            print("0", x - 2, y - 2, 12)
        end
    elseif t == COMP.BUTTON then
        local gx = (x - GRID_SIZE // 2) // GRID_SIZE
        local gy = (y - GRID_Y - GRID_SIZE // 2) // GRID_SIZE
        local held = buttonHeld[gx][gy]
        local col = held and COL.SWITCH_ON or COL.SWITCH_OFF
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        rectb(x - s, y - s, s * 2 + 1, s * 2 + 1, 12)
        print("B", x - 2, y - 2, held and 0 or 12)
    elseif t == COMP.AND_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("&", x - 2, y - 2, 0)
    elseif t == COMP.OR_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("|", x - 2, y - 2, 0)
    elseif t == COMP.NOT_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("!", x - 2, y - 2, 0)
    elseif t == COMP.NAND_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("N", x - 2, y - 2, 0)
    elseif t == COMP.NOR_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("n", x - 2, y - 2, 0)
    elseif t == COMP.XOR_GATE then
        local col = on and COL.WIRE_ON or COL.GATE
        rect(x - s, y - s, s * 2 + 1, s * 2 + 1, col)
        print("^", x - 2, y - 2, 0)
    elseif t == COMP.RESISTOR then
        local col = COL.RESISTOR
        rect(x - s, y - 1, s * 2 + 1, 3, col)
    elseif t == COMP.CAPACITOR then
        local col = COL.CAPACITOR
        line(x - 1, y - s, x - 1, y + s, col)
        line(x + 1, y - s, x + 1, y + s, col)
    elseif t == COMP.CROSSWIRE then
        local gx = (x - GRID_SIZE // 2) // GRID_SIZE
        local gy = (y - GRID_Y - GRID_SIZE // 2) // GRID_SIZE
        local hcol = grid[gx][gy].hPowered and COL.WIRE_ON or COL.WIRE_OFF
        local vcol = grid[gx][gy].vPowered and COL.WIRE_ON or COL.WIRE_OFF
        line(x - s, y, x + s, y, hcol)
        line(x, y - s, x, y + s, vcol)
        -- Gap in middle
        pix(x, y, COL.BG)
    end
end

-- Handle mouse input
function handleInput()
    mx, my, mouseDown = mouse()

    -- Toolbar selection
    if mouseDown and my < GRID_Y then
        local items = {
            COMP.NONE, COMP.WIRE, COMP.POWER, COMP.GROUND,
            COMP.LED, COMP.SWITCH, COMP.BUTTON, COMP.AND_GATE,
            COMP.OR_GATE, COMP.NOT_GATE, COMP.XOR_GATE, COMP.CROSSWIRE
        }
        local idx = mx // 20 + 1
        if idx >= 1 and idx <= #items then
            selected = items[idx]
        end
    end

    -- Grid interaction
    if my >= GRID_Y then
        local gx = mx // GRID_SIZE
        local gy = (my - GRID_Y) // GRID_SIZE

        if inBounds(gx, gy) then
            -- Reset all button holds
            for bx = 0, GRID_W - 1 do
                for by = 0, GRID_H - 1 do
                    buttonHeld[bx][by] = false
                end
            end

            if mouseDown then
                local comp = grid[gx][gy]

                -- Handle button hold
                if comp.type == COMP.BUTTON then
                    buttonHeld[gx][gy] = true
                    -- Toggle switch on click
                elseif comp.type == COMP.SWITCH and not prevMouseDown then
                    comp.state = not comp.state
                    -- Place component
                elseif selected ~= nil then
                    if gx ~= prevMx or gy ~= prevMy or not prevMouseDown then
                        setComp(gx, gy, selected)
                    end
                end

                prevMx, prevMy = gx, gy
            end
        end
    end

    -- Keyboard shortcuts
    if keyp(48) then initGrid() end -- C to clear
    if keyp(49) then                -- R to rotate selected component
        local gx = mx // GRID_SIZE
        local gy = (my - GRID_Y) // GRID_SIZE
        if inBounds(gx, gy) then
            grid[gx][gy].rotation = (grid[gx][gy].rotation + 1) % 4
        end
    end

    -- Number keys for quick select
    if keyp(2) then selected = COMP.WIRE end
    if keyp(3) then selected = COMP.POWER end
    if keyp(4) then selected = COMP.GROUND end
    if keyp(5) then selected = COMP.LED end
    if keyp(6) then selected = COMP.SWITCH end

    prevMouseDown = mouseDown
end

-- Draw cursor
function drawCursor()
    local gx = mx // GRID_SIZE
    local gy = (my - GRID_Y) // GRID_SIZE

    if inBounds(gx, gy) and my >= GRID_Y then
        local px = gx * GRID_SIZE
        local py = gy * GRID_SIZE + GRID_Y
        rectb(px, py, GRID_SIZE + 1, GRID_SIZE + 1, 12)
    end
end

-- Draw help
function drawHelp()
    print("1-5:Select C:Clear R:Rotate", 60, 136 - 6, COL.GRID, false, 1, true)
end

-- Main initialization
initGrid()

-- TIC main loop
function TIC()
    tick = tick + 1

    handleInput()

    -- Simulate every frame
    simulate()

    -- Draw
    cls(COL.BG)
    drawGrid()
    drawToolbar()
    drawCursor()
    drawHelp()
end
