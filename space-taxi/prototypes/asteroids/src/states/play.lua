-- ==========================================
-- STATE: PLAY
-- ==========================================

local function inputPlay()
    if btnp(BTN_P1_SELECT) and btnp(BTN_P1_START) then
        changeState(STATE.GAMEOVER)
    end
end

local function updatePlay()

end

local function drawPlay()
    cls(PURPLE)




end
