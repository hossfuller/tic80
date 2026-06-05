-- ==========================================
-- GRAVITY SYSTEM
-- ==========================================

function getGravitySources()
    local sources = {}

    local function addSource(obj)
        if obj and
            not obj.dead and
            obj.exerts_gravity ~= false and
            obj.position and
            obj.mass and
            obj.mass > 0 then
            table.insert(sources, obj)
        end
    end

    addSource(game.play.star)

    for _, planet in ipairs(game.play.planets or {}) do
        addSource(planet)

        if planet.moons then
            for _, moon in ipairs(planet.moons) do
                addSource(moon)
            end
        end
    end

    for _, station in ipairs(game.play.space_stations or {}) do
        addSource(station)
    end

    if game.play.player then
        addSource(game.play.player)
    end

    for _, comet in ipairs(game.play.comets or {}) do
        addSource(comet)
    end

    for _, asteroid in ipairs(game.play.asteroids or {}) do
        addSource(asteroid)
    end

    return sources
end

function getGravityAffectedObjects()
    local affected = {}

    local function addAffected(obj)
        if obj and
            not obj.dead and
            obj.affected_by_gravity ~= false and
            obj.position and
            obj.velocity then
            table.insert(affected, obj)
        end
    end

    addAffected(game.play.player)

    for _, comet in ipairs(game.play.comets or {}) do
        addAffected(comet)
    end

    for _, asteroid in ipairs(game.play.asteroids or {}) do
        addAffected(asteroid)
    end

    return affected
end

function applyGravityToObject(obj, sources)
    if not obj or obj.dead or not obj.position or not obj.velocity then
        return
    end

    local total_ax = 0
    local total_ay = 0

    for _, source in ipairs(sources) do
        if source ~= obj and
            source and
            not source.dead and
            source.position and
            source.mass and
            source.mass > 0 then
            local dx = source.position.x - obj.position.x
            local dy = source.position.y - obj.position.y

            local dist_sq = dx * dx + dy * dy

            if dist_sq > 0 then
                local dist = math.sqrt(dist_sq)

                -- Avoid absurd gravity spikes when objects overlap or nearly touch.
                local min_dist = getCollisionRadius(obj) + getCollisionRadius(source)

                if dist < min_dist then
                    dist = min_dist
                    dist_sq = dist * dist
                end

                -- Newtonian-style acceleration:
                -- F = G * m1 * m2 / r^2
                -- a = F / m1
                -- a = G * m2 / r^2
                local acceleration = GRAVITATIONAL_CONSTANT * source.mass / dist_sq

                local nx = dx / dist
                local ny = dy / dist

                total_ax = total_ax + nx * acceleration
                total_ay = total_ay + ny * acceleration
            end
        end
    end

    if total_ax ~= 0 or total_ay ~= 0 then
        local gravity_vector = obj:compToVector(total_ax, total_ay)
        obj.velocity = obj:addVectors(obj.velocity, gravity_vector)
        clampGravityVelocity(obj)
    end
end

function clampGravityVelocity(obj)
    if not obj or not obj.velocity or not obj.max_speed then
        return
    end

    local max_speed = obj.gravity_max_speed or obj.max_speed * 3

    if obj.velocity.speed > max_speed then
        obj.velocity.speed = max_speed
    end
end

function updateGravity()
    local sources = getGravitySources()
    local affected = getGravityAffectedObjects()

    for _, obj in ipairs(affected) do
        applyGravityToObject(obj, sources)
    end
end

