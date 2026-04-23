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
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    cls(BLACK)

    -- print_centered_text(message, height, color, shadow, fixed, scale)
    -- print_centered_text("current mode = " .. CURRENT_GAME_MODE, math.floor(EDGE_Y_BOTTOM * 0.80), BLUE_LITE, false, false, 1)
    -- print_centered_text("start_menu_ball.cur = " .. start_menu_ball.cur, math.floor(EDGE_Y_BOTTOM * 0.80) + 10, BLUE_LITE, false, false, 1)
    -- print_centered_text("start_menu_ball.sel = " .. start_menu_ball.sel, math.floor(EDGE_Y_BOTTOM * 0.80) + 20, BLUE_LITE, false, false, 1)
    print_centered_text("current mode = " .. CURRENT_GAME_MODE, math.floor(EDGE_Y_BOTTOM * 0.95), BLUE_LITE, false, false, 1)

    if CURRENT_GAME_MODE == 'start' then
        --[[ START SCREEN ]]--
        start_screen()

    elseif CURRENT_GAME_MODE == 'menu' then
        --[[ USER CAN CONFIGURE CONSTANTS ]]--
        menu_screen()

    elseif CURRENT_GAME_MODE == 'game' then
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
