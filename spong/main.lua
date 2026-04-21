-- title:   SPong (Son of Pong)
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.2
-- script:  lua


--[[ INCLUDES ]]--
include "src.constants"
include "src.classes.SpongObj"
include "src.classes.SpaddleObj"
include "src.classes.SballObj"

include "src.input"
include "src.update"
include "src.draw"
include "src.check"



--[[ INITIALIZATION ]]--

-- Create objects
paddle1 = SpaddleObj:new({player = 1})
paddle2 = SpaddleObj:new({player = 2})
ball    = SballObj:new()

-- TODO: How do I automatically change the keymapping upon loading?
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
    --[[ CHECK FOR USER INPUT ]]--
    INPUT()

    --[[ UPDATE GAME DATA ]]--
    UPDATE()

    --[[ DRAW GAME GRAPHICS ]]--
    DRAW()

    --[[ CHECK FOR GAME STOPPAGES ]]--
    CHECK()
end --TIC
