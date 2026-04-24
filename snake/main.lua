-- title:   Snake Clone
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


-- ==========================================
-- INCLUDES
-- ==========================================
include "src.constants"
include "src.helpers"

include "src.state_machine"
include "src.input"
include "src.update"
include "src.draw"


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