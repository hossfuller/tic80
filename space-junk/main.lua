-- title:   Space Junk
-- author:  Hoss Fuller
-- desc:    Travel the universe, cleaning up space junk.
-- version: 0.1
-- script:  lua
-- saveid:  space_junk

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"

include "src.game_state"
include "src.states.start"
include "src.states.play"
include "src.states.gameover"
include "src.states.highscores"
include "src.state_machine"

include "src.classes.SpaceShip"

-- ==========================================
-- MAIN GAME LOOP
-- ==========================================

-- DELETE THIS LINE ONCE THIS CODE HAS BEEN INCORPORATED:
-- https://bytesnbits.co.uk/wp-content/uploads/2020/01/Asteroids-1.txt

function TIC()
    local currentState = states[game.state]
    if currentState then
        currentState.input()
        currentState.update()
        currentState.draw()
    end
end