-- title:   Space Taxi
-- author:  Hoss Fuller
-- desc:    Travel the universe, delivering space passengers to their space destinations.
-- version: 0.1
-- script:  lua
-- saveid:  space_taxi

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"

include "src.game_state"
include "src.states.start"
-- include "src.states.options"
-- include "src.states.hiscores"
-- include "src.states.ready"
-- include "src.states.play"
-- include "src.states.pause"
-- include "src.states.gameover"

include "src.state_machine"


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