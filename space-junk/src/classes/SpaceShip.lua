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

-- 'rotation' parameter is in radians.
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
