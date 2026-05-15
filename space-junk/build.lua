--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Space Junk
-- author:  Hoss Fuller
-- desc:    Travel the universe, cleaning up space junk.
-- version: 0.1
-- script:  lua
-- saveid:  space_junk

-- ==========================================
-- INCLUDES
-- ==========================================

-- [TQ-Bundler: src.constants]

-- ==========================================
-- CONSTANTS
-- ==========================================

-- Colors
local BLACK      = 0
local PURPLE     = 1
local RED        = 2
local ORANGE     = 3
local YELLOW     = 4
local GREEN_LITE = 5
local GREEN_MED  = 6
local GREEN_DARK = 7
local BLUE_DARK  = 8
local BLUE_MED   = 9
local BLUE_LITE  = 10
local CYAN       = 11
local WHITE      = 12
local GRAY_LITE  = 13
local GRAY_MED   = 14
local GRAY_DARK  = 15

-- Button mappings
local BTN_P1_UP     = 0
local BTN_P1_DOWN   = 1
local BTN_P1_LEFT   = 2
local BTN_P1_RIGHT  = 3
local BTN_P1_A      = 4         -- Primary action / Select
local BTN_P1_B      = 5         -- Secondary action / Back / Pause
local BTN_P1_X      = 6
local BTN_P1_Y      = 7
local BTN_P1_SELECT = BTN_P1_X
local BTN_P1_START  = BTN_P1_Y

-- Screen dimensions
local EDGE_X_LEFT   = 0
local EDGE_X_RIGHT  = 240
local EDGE_Y_TOP    = 0
local EDGE_Y_BOTTOM = 136

-- Character dimensions (these scale linearly)
local FIXED_CHAR_WIDTH  = 6
local FIXED_CHAR_HEIGHT = 6
local X_PADDING         = FIXED_CHAR_WIDTH + 2
local Y_PADDING         = FIXED_CHAR_HEIGHT + 2

local DEBUG = true

-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]

-- ==========================================
-- HELPERS
-- ==========================================




-- ==========================================
-- DRAWING HELPERS
-- ==========================================

function drawCenteredText(text, y, color, fixed, scale, smallfont, shadow_color)
    if fixed == nil then
        fixed = false
    end
    if scale == nil then
        scale = 1
    end
    if smallfont == nil then
        smallfont = false
    end
    if shadow_color == nil then
        shadow_color = -1
    end
    local width = print(text, 0, -50, color, fixed, scale, smallfont)

    if shadow_color >= 0 then
        print(text, (EDGE_X_RIGHT - width) / 2 + 1, y + 1, shadow_color, fixed, scale, smallfont)
    end
    print(text, (EDGE_X_RIGHT - width) / 2, y, color, fixed, scale, smallfont)
end


-- [/TQ-Bundler: src.helpers]

-- [TQ-Bundler: src.game_state]

-- ==========================================
-- GAME STATE
-- ==========================================

STATE = {
    START    = "START",
    PLAY     = "PLAY",
    GAMEOVER = "GAMEOVER",
}

game = {
    state = STATE.START,
    prevState = nil,

    -- Gameplay state
    play = {
        player = {},
        score  = 0,
    },
}


-- ==========================================
-- STATE CHANGE
-- ==========================================

function changeState(newState)
    game.prevState = game.state
    game.state = newState

    -- State entry logic
    if newState == STATE.PLAY then
        -- Reset game state for new game
        game.play.player = SpaceShip.new()
        game.play.score  = 0
    end
end


-- [/TQ-Bundler: src.game_state]

-- [TQ-Bundler: src.states.start]

-- ==========================================
-- STATE: START (Main Menu)
-- ==========================================

function inputStart()
    if btnp(BTN_P1_A) or btnp(BTN_P1_START) then
        changeState(STATE.PLAY)
    end
end

function updateStart()

end

function drawStart()
    cls(0)

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("SPACE JUNK", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z to start", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.start]

-- [TQ-Bundler: src.states.play]

-- ==========================================
-- STATE: PLAY
-- ==========================================

function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end

    game.play.player:input()
end

function updatePlay()

end

function drawPlay()
    cls(PURPLE)

    game.play.player:draw()

    if DEBUG == true then
        local pos = game.play.player:getPosition()
        local rot = game.play.player:getRotation()

        print("X: " .. tostring(pos.x) .. "; Y: " .. tostring(pos.y), EDGE_X_LEFT, EDGE_Y_TOP, WHITE)
        print("Radians: " .. tostring(rot.rotation) .. "; Speed: " .. tostring(rot.speed), EDGE_X_LEFT, EDGE_Y_TOP + Y_PADDING, WHITE)
    end

end


-- [/TQ-Bundler: src.states.play]

-- [TQ-Bundler: src.states.gameover]

-- ==========================================
-- STATE: GAMEOVER
-- ==========================================

function inputGameover()
    if btnp(BTN_P1_A) or btnp(BTN_P1_B) then
        changeState(STATE.START)
    end
end

function updateGameover()

end

function drawGameover()
    drawPlay()

    local title_y_pos = math.floor(EDGE_Y_BOTTOM / 2) - 3 * Y_PADDING
    drawCenteredText("GAME OVER", title_y_pos, ORANGE, nil, 3, nil, YELLOW)
    drawCenteredText("Press Z or X to return to start screen", title_y_pos + 3 * Y_PADDING, WHITE, false, 1, false, GRAY_DARK)
end


-- [/TQ-Bundler: src.states.gameover]

-- [TQ-Bundler: src.state_machine]

-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.START] = {
        input  = inputStart,
        update = updateStart,
        draw   = drawStart,
    },
    [STATE.PLAY] = {
        input  = inputPlay,
        update = updatePlay,
        draw   = drawPlay,
    },
    [STATE.GAMEOVER] = {
        input  = inputGameover,
        update = updateGameover,
        draw   = drawGameover,
    },
}


-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.classes.SpaceShip]

-- ==========================================
-- SPACESHIP OBJECT
-- ==========================================

SpaceShip = {}
SpaceShip.__index = SpaceShip

-- Creates a new SpaceShip instance
function SpaceShip.new(params)
    params             = params or {}
    local self         = setmetatable({}, SpaceShip)

    self.color    = params.color or BLUE_MED
    self.position = {
        x = params.x or math.floor(EDGE_X_RIGHT / 2),
        y = params.y or math.floor(EDGE_Y_BOTTOM / 2)

    }
    self.rotation      = params.rotation or 5
    self.rotationSpeed = params.rotationSpeed or 0.07
    self.shape         = params.shape or {
        {x=8, y=0},
        {x=-8, y=6},
        {x=-4, y=0},
        {x=-8, y=-6},
        {x=8, y=0}
	}
    return self
end

-- ==========================================
-- SPACESHIP HELPERS
-- ==========================================

function SpaceShip:getPosition()
    return self.position
end

function SpaceShip:getRotation()
    return {
        rotation = self.rotation,
        speed    = self.rotationSpeed
    }
end


-- ==========================================
-- SPACESHIP INPUT
-- ==========================================

function SpaceShip:input()
    if btn(BTN_P1_LEFT) then
        self.rotation = self.rotation - self.rotationSpeed
    end
    if btn(BTN_P1_RIGHT) then
        self.rotation = self.rotation + self.rotationSpeed
    end

    self.rotation = self:keepAngleInRange(self.rotation)
end

-- ==========================================
-- SPACESHIP UPDATE
-- ==========================================

function SpaceShip:keepAngleInRange(angle)
    if angle < 0 then
        while angle < 0 do
            angle = angle + (2 * math.pi)
        end
    end
    if angle > (2 * math.pi) then
        while angle > (2 * math.pi) do
            angle = angle - (2 * math.pi)
        end
    end
    return angle
end

function SpaceShip:rotatePoint(point, rotation)
    local rotated_x = (point.x * math.cos(rotation)) - (point.y * math.sin(rotation))
    local rotated_y = (point.y * math.cos(rotation)) + (point.x * math.sin(rotation))
    return { x = rotated_x, y = rotated_y }
end

-- ==========================================
-- SPACESHIP DRAW
-- ==========================================

-- Draw the spaceship.
function SpaceShip:draw()
    local first_point = true
    local last_point = 0
    local rotated_point = 0
    for index, point in ipairs(self.shape) do
        rotated_point = self:rotatePoint(point, self.rotation)

        if first_point then
            last_point = rotated_point
            first_point = false
        else
            line(
                last_point.x + self.position.x,
                last_point.y + self.position.y,
                rotated_point.x + self.position.x,
                rotated_point.y + self.position.y,
                self.color
            )
            last_point = rotated_point
        end
    end
end


-- [/TQ-Bundler: src.classes.SpaceShip]

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

-- DELETE THIS LINE ONCE THIS CODE HAS BEEN INCORPORATED:
-- https://bytesnbits.co.uk/wp-content/uploads/2020/01/Asteroids-1.txt

function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end