-- title:   General Game Skeleton
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- desc:    General game state machine skeleton for TIC-80
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.game_state"
include "src.helpers"

include "src.states.start"
include "src.states.options"
include "src.states.hiscores"
include "src.states.ready"
include "src.states.play"
include "src.states.pause"
include "src.states.gameover"

include "src.state_machine"

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function TIC()
    updateInput()
    
    local currentState = states[game.state]
    if currentState then
        currentState.update()
        currentState.draw()
    end
end