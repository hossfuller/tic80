-- title:   Kepler-9999
-- author:  Hoss Fuller
-- version: rev0.1
-- script:  lua
-- input:   mouse
-- saveid:  kepler_9999

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants_tic80"
include "src.constants_game"

include "src.generators"
include "src.game_state"
include "src.helpers"

include "src.states.start"
include "src.states.options"
include "src.states.highscores"
include "src.states.ready"
include "src.states.play"
include "src.states.pause"
include "src.states.gameover"

include "src.state_machine"

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function BOOT()
    applyAllOptions()
    changeState(STATE.START)
end


function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end
