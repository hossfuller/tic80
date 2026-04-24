-- title:   SPong (Son of Pong)
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.3
-- script:  lua


--[[ INCLUDES ]]--
include "src.constants"
include "src.helpers"

include "src.classes.SpongObj"
include "src.classes.SpaddleObj"
include "src.classes.SballObj"

include "src.screen_start"
include "src.screen_menu"
include "src.input"
include "src.update"
include "src.draw"
include "src.state_machine"

--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({ player = 1 })
paddle2 = SpaddleObj:new({ player = 2 })
ball    = SballObj:new()


function BOOT()
end

function INIT()
    paddle1:reset()
    paddle2:reset()
    ball:reset()

    paddle1:resetScore()
    paddle2:resetScore()
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    cls(BLACK)

    if current_state == STATE.START then
        --[[ START SCREEN ]] --
        state_start_update()

    elseif current_state == STATE.OPTIONS then
        --[[ USER CAN CONFIGURE CONSTANTS ]] --
        state_options_update()

    elseif current_state == STATE.READY then
        state_ready_update()
        state_ready_draw()

    elseif current_state == STATE.PLAY then
        state_play_update()
        state_play_draw()

    elseif current_state == STATE.GAMEOVER then
        state_gameover_update()
        state_gameover_draw()
    end
end
