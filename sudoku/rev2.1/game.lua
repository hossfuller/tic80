--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2.1
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

-- include "src.constants"
-- include "src.sudoku_grid"
-- include "src.sudoku_logic"
-- include "src.input"
-- include "src.update"
-- include "src.draw"


-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

-- function INIT()
--     -- Initialize the cells
--     initializeCells()

--     -- Get a valid solution into the cells' 'value' settings.
--     generateSolution()

--     -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
--     finalizePuzzle('random')
-- end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

-- INIT()

function TIC()
    cls(0)
    -- INPUT()
    -- UPDATE()
    -- DRAW()
    -- print("Rethink notes grid", EDGE_X_RIGHT - 80, EDGE_Y_BOTTOM - 10, WHITE)
end

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

