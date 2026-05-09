-- title:   Sudoku for TIC-80
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: rev5.0
-- script:  lua
-- input:   mouse

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"
include "src.timer"

game_timer = TimerObj.new()

include "src.sudoku.grid"
include "src.sudoku.buttons"
include "src.sudoku.logic"
include "src.sudoku.undo"

include "src.game_state"
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