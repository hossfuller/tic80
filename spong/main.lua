-- title:   SPong (Son of Pong)
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.2
-- script:  lua


--[[ INCLUDES ]]--
include "src.constants"
include "src.classes.SpongObj"
include "src.classes.SpaddleObj"
include "src.classes.SballObj"

include "src.screen_start"
include "src.screen_menu"
include "src.input"
include "src.update"
include "src.draw"
include "src.check"



--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({player = 1})
paddle2 = SpaddleObj:new({player = 2})
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

    if CURRENT_GAME_MODE == 'start' then
        --[[ START SCREEN ]]--
        start_screen()

    elseif CURRENT_GAME_MODE == 'menu' then
        --[[ USER CAN CONFIGURE CONSTANTS ]]--
        menu_screen()

    elseif CURRENT_GAME_MODE == 'game' or CURRENT_GAME_MODE == 'over' then
        --[[ CHECK FOR USER INPUT ]] --
        INPUT()

        --[[ UPDATE GAME DATA ]] --
        UPDATE()

        --[[ DRAW GAME GRAPHICS ]] --
        DRAW()

        --[[ CHECK FOR GAME STOPPAGES ]] --
        CHECK()
      end
end --TIC
