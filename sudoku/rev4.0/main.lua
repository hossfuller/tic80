-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev3
-- script:  lua
-- input: mouse

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"
include "src.sudoku.grid"
include "src.sudoku.buttons"
include "src.sudoku.logic"
include "src.sudoku.undo"
include "src.state_machine.game_state"
include "src.input"
include "src.update"
include "src.draw"


-- ==========================================
-- INITIALIZATION FUNCTIONS
-- ==========================================

function INIT()
    -- -- Initialize the cells
    -- initializeCells()

    -- -- Update sudoku.END_Y to reflect actual grid dimensions
    -- sudoku.END_Y = sudoku.cells[sudoku.DIM_X][sudoku.DIM_Y].y_bottom + 1

    -- -- Get a valid solution into the cells' 'value' settings.
    -- generateSolution()
    -- generatePuzzleByTier(SELECTED_DIFFICULTY)
end -- INIT()

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

INIT()

-- function TIC()
--     INPUT()
--     UPDATE()
--     DRAW()
-- end
function TIC()
    updateInput()
    
    local currentState = states[game.state]
    if currentState then
        currentState.update()
        currentState.draw()
    end
end