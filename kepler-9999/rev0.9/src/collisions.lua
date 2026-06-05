-- ==========================================
-- COLLISION SYSTEM
-- ==========================================

function objectIsOffMap(obj)
    if not obj or not obj.position then
        return true
    end

    return
        obj.position.x < 0 or
        obj.position.y < 0 or
        obj.position.x >= MAP_PIXELS_W or
        obj.position.y >= MAP_PIXELS_H
end

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

    if objectsAreHarpoonLinked(a, b) then
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
        applyCollisionDamage(obj, star)
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
        applyCollisionDamage(obj, planet)
        return
    end

    if planet.moons then
        for _, moon in ipairs(planet.moons) do
            if objectsCollide(obj, moon) then
                applyCollisionDamage(obj, moon)
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

    for _, station in ipairs(game.play.space_stations or {}) do
        checkObjectAgainstPlanet(obj, station)
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

    -- Calculate damage before deflection changes velocity.
    local damage_to_b = 0
    local damage_to_a = 0

    if a.induceDamage then
        damage_to_b = a:induceDamage(b)
    end

    if b.induceDamage then
        damage_to_a = b:induceDamage(a)
    end

    -- Bounce/separate surviving dynamic objects.
    deflectCollisionPair(a, b)

    -- Apply damage after deflection so killed objects can still use the
    -- pre-collision damage values.
    if b.takeDamage then
        b:takeDamage(damage_to_b, a)
    end

    if a.takeDamage then
        a:takeDamage(damage_to_a, b)
    end
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

function applyCollisionDamage(a, b)
    if not a or not b then
        return
    end

    if a.dead or b.dead then
        return
    end

    local damage_to_b = 0
    local damage_to_a = 0

    if a.induceDamage then
        damage_to_b = a:induceDamage(b)
    end

    if b.induceDamage then
        damage_to_a = b:induceDamage(a)
    end

    if b.takeDamage then
        b:takeDamage(damage_to_b, a)
    end

    if a.takeDamage then
        a:takeDamage(damage_to_a, b)
    end
end

-- ==========================================
-- HARPOON FUNCTIONS
-- ==========================================
-- These are ~kinda~ part of the collision system.

function objectsAreHarpoonLinked(a, b)
    if not a or not b then
        return false
    end

    if a.harpoon and a.harpoon.attached and a.harpoon.target == b then
        return true
    end

    if b.harpoon and b.harpoon.attached and b.harpoon.target == a then
        return true
    end

    return false
end

function distancePointToSegmentSquared(px, py, ax, ay, bx, by)
    local abx = bx - ax
    local aby = by - ay

    local apx = px - ax
    local apy = py - ay

    local ab_len_sq = abx * abx + aby * aby

    if ab_len_sq <= 0 then
        return distanceSquared(px, py, ax, ay)
    end

    local t = (apx * abx + apy * aby) / ab_len_sq
    t = clamp(t, 0, 1)

    local closest_x = ax + abx * t
    local closest_y = ay + aby * t

    return distanceSquared(px, py, closest_x, closest_y)
end

function segmentIntersectsCircle(ax, ay, bx, by, cx, cy, radius)
    local dist_sq = distancePointToSegmentSquared(cx, cy, ax, ay, bx, by)
    return dist_sq <= radius * radius
end
