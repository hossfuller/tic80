-- title:   Asteroids
-- author:  Hoss Fuller
-- desc:    Travel the universe, cleaning up space junk.
-- version: 0.1
-- script:  lua
-- saveid:  asteroids_bang_bang

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants"
include "src.helpers"

include "src.game_state"
include "src.states.start"
include "src.states.options"
include "src.states.play"
include "src.states.gameover"
include "src.states.highscores"
include "src.state_machine"

include "src.classes.SpaceObj"
include "src.classes.Ship"
include "src.classes.Asteroid"

-- ==========================================
-- MAIN GAME LOOP
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