-- title:   Sussudioku!! (Sudoku for TIC-80)
-- author:  Hoss Fuller
-- version: 1.0
-- script:  lua
-- input:   mouse
-- saveid:  sussudioku_bang_bang

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"
include "src.timer"

include "src.sudoku.grid"
include "src.sudoku.buttons"
include "src.sudoku.logic"

include "src.game_state"

include "src.sudoku.undo"

include "src.states.title"
include "src.states.options"
include "src.states.statistics"
include "src.states.puzzle"
include "src.states.newpuzzle"
include "src.state_machine"

include "src.input"


-- ==========================================
-- MAIN GAME LOOP
-- ==========================================


function TIC()
    updateInput()

    local currentState = states[game.state]
    if currentState then
        currentState.update()
        currentState.draw()
    end
end