-- ==========================================
-- GENERATORS
-- ==========================================

function generateStarMap()
    -- Clear whole TIC-80 map.
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            mset(x, y, TILE_EMPTY)
        end
    end

    -- Fill the visible screen area with sparse random stars.
    for y = 0, SCREEN_TILES_H - 1 do
        for x = 0, SCREEN_TILES_W - 1 do
            local roll = math.random(1, 100)

            if roll <= 4 then
                -- 4% chance of a star in this tile.

                local star_roll = math.random(1, 100)

                if star_roll <= 70 then
                    mset(x, y, TILE_STAR_DIM)
                elseif star_roll <= 95 then
                    mset(x, y, TILE_STAR_MED)
                else
                    mset(x, y, TILE_STAR_BRIGHT)
                end
            else
                mset(x, y, TILE_EMPTY)
            end
        end
    end
end
