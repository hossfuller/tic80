-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev2.2
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.sudoku_grid"
include "src.sudoku_buttons"
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
    
    -- Update sudoku.END_Y to reflect actual grid dimensions
    sudoku.END_Y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom + 1

    -- Get a valid solution into the cells' 'value' settings.
    generateSolution()

    -- What is the difficulty? Copy the appropriate number of 'value' fields to 'guess' fields and lock those fields.
    setPuzzleDifficulty('random')
end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

function TIC()
    INPUT()
    UPDATE()
    DRAW()
end
