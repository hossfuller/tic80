-- ==========================================
-- POLYGON FUNCTIONS
-- ==========================================

function polygonSignedArea(points)
    local area = 0

    for i = 1, #points do
        local j = i + 1
        if j > #points then
            j = 1
        end

        area = area + points[i].x * points[j].y - points[j].x * points[i].y
    end

    return area / 2
end

function polygonIsClockwise(points)
    return polygonSignedArea(points) < 0
end

function pointInTriangle(p, a, b, c)
    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) -
            (p2.x - p3.x) * (p1.y - p3.y)
    end

    local d1 = sign(p, a, b)
    local d2 = sign(p, b, c)
    local d3 = sign(p, c, a)

    local has_neg = d1 < 0 or d2 < 0 or d3 < 0
    local has_pos = d1 > 0 or d2 > 0 or d3 > 0

    return not (has_neg and has_pos)
end

function polygonVertexIsConvex(prev, current, next, clockwise)
    local cross =
        (current.x - prev.x) * (next.y - current.y) -
        (current.y - prev.y) * (next.x - current.x)

    if clockwise then
        return cross < 0
    else
        return cross > 0
    end
end

function removeDuplicateClosingPoint(points)
    local result = {}

    for i, p in ipairs(points) do
        result[#result + 1] = {
            x = p.x,
            y = p.y,
        }
    end

    if #result >= 2 then
        local first = result[1]
        local last = result[#result]

        if first.x == last.x and first.y == last.y then
            table.remove(result, #result)
        end
    end

    return result
end

function triangulatePolygon(points)
    local polygon = removeDuplicateClosingPoint(points)
    local triangles = {}

    if #polygon < 3 then
        return triangles
    end

    if #polygon == 3 then
        triangles[#triangles + 1] = {
            polygon[1],
            polygon[2],
            polygon[3],
        }
        return triangles
    end

    local clockwise = polygonIsClockwise(polygon)

    -- Build index list so we can remove ears without destroying original points.
    local indices = {}

    for i = 1, #polygon do
        indices[#indices + 1] = i
    end

    local guard = 0
    local max_guard = #polygon * #polygon

    while #indices > 3 and guard < max_guard do
        guard = guard + 1

        local ear_found = false

        for i = 1, #indices do
            local prev_i = i - 1
            local next_i = i + 1

            if prev_i < 1 then
                prev_i = #indices
            end

            if next_i > #indices then
                next_i = 1
            end

            local prev_index = indices[prev_i]
            local curr_index = indices[i]
            local next_index = indices[next_i]

            local prev_point = polygon[prev_index]
            local curr_point = polygon[curr_index]
            local next_point = polygon[next_index]

            if polygonVertexIsConvex(prev_point, curr_point, next_point, clockwise) then
                local contains_point = false

                for j = 1, #indices do
                    local test_index = indices[j]

                    if test_index ~= prev_index and
                        test_index ~= curr_index and
                        test_index ~= next_index then
                        local test_point = polygon[test_index]

                        if pointInTriangle(test_point, prev_point, curr_point, next_point) then
                            contains_point = true
                            break
                        end
                    end
                end

                if not contains_point then
                    triangles[#triangles + 1] = {
                        prev_point,
                        curr_point,
                        next_point,
                    }

                    table.remove(indices, i)
                    ear_found = true
                    break
                end
            end
        end

        -- If no ear was found, the polygon may be self-intersecting,
        -- degenerate, or have duplicate/collinear points causing trouble.
        if not ear_found then
            break
        end
    end

    if #indices == 3 then
        triangles[#triangles + 1] = {
            polygon[indices[1]],
            polygon[indices[2]],
            polygon[indices[3]],
        }
    end

    return triangles
end

function drawFilledPolygon(points, color)
    local triangles = triangulatePolygon(points)

    for _, triangle in ipairs(triangles) do
        local a = triangle[1]
        local b = triangle[2]
        local c = triangle[3]

        tri(
            a.x, a.y,
            b.x, b.y,
            c.x, c.y,
            color
        )
    end
end

function drawPolygonOutline(points, color)
    if #points < 2 then
        return
    end

    for i = 2, #points do
        line(
            points[i - 1].x,
            points[i - 1].y,
            points[i].x,
            points[i].y,
            color
        )
    end

    local first = points[1]
    local last = points[#points]

    if first.x ~= last.x or first.y ~= last.y then
        line(
            last.x,
            last.y,
            first.x,
            first.y,
            color
        )
    end
end