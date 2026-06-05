-- title:   Kepler-9999
-- author:  Hoss Fuller
-- version: rev0.9
-- script:  lua
-- input:   mouse
-- saveid:  kepler_9999

-- ==========================================
-- INCLUDES
-- ==========================================

include "src.constants_system"
include "src.constants_game"

include "src.generators.backgroundmap"
include "src.generators.ships"
include "src.generators.stars"
include "src.generators.planets"
include "src.generators.moons"
include "src.generators.comets"
include "src.generators.asteroids"
include "src.camera"
include "src.collisions"
include "src.gravity"
include "src.polygons"
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

include "src.classes.KeplerObj"
include "src.classes.SpaceShip"
include "src.classes.Star"
include "src.classes.Planet"
include "src.classes.Moon"
include "src.classes.Comet"
include "src.classes.Asteroid"

-- ==========================================
-- MAIN TIC FUNCTION
-- ==========================================

function BOOT()
    math.randomseed(tstamp() + time())

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
