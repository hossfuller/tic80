--
-- Bundle file
-- Code changes will be overwritten
--

-- title:   Snake Clone
-- author:  Adam Fuller <the.adam.fuller@gmail.com>
-- version: 0.1
-- script:  lua


--[[ INCLUDES ]]--
-- [TQ-Bundler: src.constants]



-- [/TQ-Bundler: src.constants]

-- [TQ-Bundler: src.helpers]



-- [/TQ-Bundler: src.helpers]

-- include "src.classes.SpongObj"
-- include "src.classes.SpaddleObj"
-- include "src.classes.SballObj"

-- [TQ-Bundler: src.screens.start]



-- [/TQ-Bundler: src.screens.start]

-- [TQ-Bundler: src.screens.menu]



-- [/TQ-Bundler: src.screens.menu]

-- [TQ-Bundler: src.screens.high_scores]



-- [/TQ-Bundler: src.screens.high_scores]

-- [TQ-Bundler: src.state_machine]



-- [/TQ-Bundler: src.state_machine]

-- [TQ-Bundler: src.input]



-- [/TQ-Bundler: src.input]

-- [TQ-Bundler: src.update]



-- [/TQ-Bundler: src.update]

-- [TQ-Bundler: src.draw]



-- [/TQ-Bundler: src.draw]

--[[ INITIALIZATION ]]--


function BOOT()
end

function INIT()
end

INIT()


--[[ GAME LOOP ]]--

function TIC()
    cls(BLACK)

    -- if current_state == STATE.START then
    --     --[[ START SCREEN ]] --
    --     state_start_update()

    -- elseif current_state == STATE.OPTIONS then
    --     --[[ USER CAN CONFIGURE CONSTANTS ]] --
    --     state_options_update()

    -- elseif current_state == STATE.READY then
    --     state_ready_update()
    --     state_ready_draw()

    -- elseif current_state == STATE.PLAY then
    --     state_play_update()
    --     state_play_draw()

    -- elseif current_state == STATE.GAMEOVER then
    --     state_gameover_update()
    --     state_gameover_draw()
    -- end
end

-- <TILES>
-- 001:00dddd000d0000d0d00dd00dd0d0000dd0d0000dd00dd00d0d0000d000dddd00
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

