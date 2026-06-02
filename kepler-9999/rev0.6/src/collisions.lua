-- ==========================================
-- COLLISION SYSTEM
-- ==========================================

local COLLISION_DAMAGE_SCALE = 1

function getCollisionRadius(obj)
    if not obj then
        return 0
    end

    return obj.collision_radius or obj.radius or 0
end

function objectsCollide(a, b)
    if not a or not b then
        return false
    end

    if a.dead or b.dead then
        return false
    end

    if not a.position or not b.position then
        return false
    end

    local ar = getCollisionRadius(a)
    local br = getCollisionRadius(b)

    return objectsTooClose(
        a.position.x,
        a.position.y,
        ar,
        b.position.x,
        b.position.y,
        br,
        0
    )
end

function getCollisionNormal(a, b)
    local dx = a.position.x - b.position.x
    local dy = a.position.y - b.position.y

    if dx == 0 and dy == 0 then
        local angle = randomFloat(0, math.pi * 2)
        return math.cos(angle), math.sin(angle)
    end

    local dist = math.sqrt(dx * dx + dy * dy)

    return dx / dist, dy / dist
end

function separateCollisionObjects(a, b)
    if not a or not b then
        return
    end

    if not a.position or not b.position then
        return
    end

    local ar = getCollisionRadius(a)
    local br = getCollisionRadius(b)

    local dx = a.position.x - b.position.x
    local dy = a.position.y - b.position.y
    local dist_sq = dx * dx + dy * dy

    if dist_sq <= 0 then
        local angle = randomFloat(0, math.pi * 2)
        dx = math.cos(angle)
        dy = math.sin(angle)
        dist_sq = 1
    end

    local dist = math.sqrt(dist_sq)
    local min_dist = ar + br

    if dist >= min_dist then
        return
    end

    local overlap = min_dist - dist
    local nx = dx / dist
    local ny = dy / dist

    -- If both are movable, split the push.
    a.position.x = a.position.x + nx * overlap * 0.5
    a.position.y = a.position.y + ny * overlap * 0.5

    b.position.x = b.position.x - nx * overlap * 0.5
    b.position.y = b.position.y - ny * overlap * 0.5
end

function deflectObject(obj, normal_x, normal_y)
    if not obj or obj.dead then
        return
    end

    if not obj.velocity then
        return
    end

    local speed = obj.velocity.speed or 0

    -- If object is stationary, give it a tiny bump away from the collision.
    if speed <= 0 then
        obj.velocity.speed = 0.1
        obj.velocity.direction = math.atan(normal_y, normal_x)
        return
    end

    local vx = math.cos(obj.velocity.direction) * speed
    local vy = math.sin(obj.velocity.direction) * speed

    -- Reflect velocity across collision normal.
    local dot = vx * normal_x + vy * normal_y

    local reflected_x = vx - 2 * dot * normal_x
    local reflected_y = vy - 2 * dot * normal_y

    local elasticity = obj.elasticity or 0.75

    reflected_x = reflected_x * elasticity
    reflected_y = reflected_y * elasticity

    local new_speed = math.sqrt(reflected_x * reflected_x + reflected_y * reflected_y)

    obj.velocity.speed = new_speed
    obj.velocity.direction = math.atan(reflected_y, reflected_x)
end

function deflectCollisionPair(a, b)
    separateCollisionObjects(a, b)

    local nx, ny = getCollisionNormal(a, b)

    -- a gets pushed along the normal.
    deflectObject(a, nx, ny)

    -- b gets pushed opposite the normal.
    deflectObject(b, -nx, -ny)
end

--[[
    Asteroids are a special case here because they break up into smaller
    asteroids when they're "destroyed". So we need a lot of code to detect when
    this is happening and then properly handle it.
--]]
function isAsteroid(obj)
    return obj and getmetatable(obj) == Asteroid
end

function breakAsteroidFromCollision(asteroid, other)
    if not asteroid or asteroid.dead then
        return
    end

    local nx = 0
    local ny = 0

    if other and other.position and asteroid.position then
        nx, ny = getCollisionNormal(asteroid, other)
    else
        local direction = asteroid.velocity and asteroid.velocity.direction or randomFloat(0, math.pi * 2)
        nx = math.cos(direction)
        ny = math.sin(direction)
    end

    asteroid.break_normal = {
        x = nx,
        y = ny,
    }

    asteroid.break_other = other

    killAsteroidAndSpawnFragments(asteroid)
end

function killCollisionObject(obj, other)
    if not obj or obj.dead then
        return
    end

    if isAsteroid(obj) then
        breakAsteroidFromCollision(obj, other)
    else
        obj:kill()
    end
end

function destroyCollisionObject(obj)
    if not obj or obj.dead then
        return
    end

    obj:kill()
end

--[[
    Now we're checking against large bodies. If the moving object hits a star,
    planet, or moon, it's gone.
--]]
-- If the object hits a star, poof! it's gone.
function checkObjectAgainstStar(obj, star)
    if not obj or not star then
        return
    end

    if obj.dead then
        return
    end

    if objectsCollide(obj, star) then
        destroyCollisionObject(obj)
    end
end

function checkObjectAgainstPlanet(obj, planet)
    if not obj or not planet then
        return
    end

    if obj.dead then
        return
    end

    if objectsCollide(obj, planet) then
        destroyCollisionObject(obj)
        return
    end

    if planet.moons then
        for _, moon in ipairs(planet.moons) do
            if objectsCollide(obj, moon) then
                destroyCollisionObject(obj)
                return
            end
        end
    end
end

function checkObjectAgainstLargeBodies(obj)
    if not obj or obj.dead then
        return
    end

    checkObjectAgainstStar(obj, game.play.star)

    if obj.dead then
        return
    end

    for _, planet in ipairs(game.play.planets or {}) do
        checkObjectAgainstPlanet(obj, planet)

        if obj.dead then
            return
        end
    end
end

function getDynamicCollisionObjects()
    local objects = {}

    if game.play.player and not game.play.player.dead then
        table.insert(objects, game.play.player)
    end

    for _, comet in ipairs(game.play.comets or {}) do
        if comet and not comet.dead then
            table.insert(objects, comet)
        end
    end

    for _, asteroid in ipairs(game.play.asteroids or {}) do
        if asteroid and not asteroid.dead then
            table.insert(objects, asteroid)
        end
    end

    return objects
end

function handleDynamicCollision(a, b)
    if not a or not b then
        return
    end

    if a.dead or b.dead then
        return
    end

    if not objectsCollide(a, b) then
        return
    end

    local a_is_asteroid = isAsteroid(a)
    local b_is_asteroid = isAsteroid(b)

    if a_is_asteroid or b_is_asteroid then
        -- Push the non-asteroid away before the asteroid disappears.
        if a_is_asteroid and not b_is_asteroid then
            local nx, ny = getCollisionNormal(b, a)
            deflectObject(b, nx, ny)
        elseif b_is_asteroid and not a_is_asteroid then
            local nx, ny = getCollisionNormal(a, b)
            deflectObject(a, nx, ny)
        end

        if a_is_asteroid then
            killCollisionObject(a, b)
        end

        if b_is_asteroid then
            killCollisionObject(b, a)
        end

        return
    end

    -- Everything else just bounces.
    deflectCollisionPair(a, b)
end

function checkDynamicObjectCollisions(objects)
    local count = #objects

    for i = 1, count - 1 do
        local a = objects[i]

        if a and not a.dead then
            for j = i + 1, count do
                local b = objects[j]

                if b and not b.dead then
                    handleDynamicCollision(a, b)
                end
            end
        end
    end
end

function updateCollisions()
    local objects = getDynamicCollisionObjects()

    -- First: star/planet/moon collisions.
    for _, obj in ipairs(objects) do
        checkObjectAgainstLargeBodies(obj)
    end

    -- Second: dynamic object collisions.
    --
    -- Use the original snapshot so fragments spawned this frame do not also
    -- collide immediately in the same frame.
    checkDynamicObjectCollisions(objects)
end
