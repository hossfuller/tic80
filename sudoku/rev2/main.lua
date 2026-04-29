-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.sudoku_grid"
include "src.sudoku_logic"
include "src.input"
include "src.update"
include "src.draw"


-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

function INIT()
    -- Initialize the cells
    initializeCells()

    -- Get a valid solution into the cells' 'value' settings.
    generateSolution()

    -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
    finalizePuzzle('random')
end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()
    print("Rethink notes grid", EDGE_X_RIGHT - 80, EDGE_Y_BOTTOM - 10, WHITE)
end
