-- ==========================================
-- STATE MACHINE
-- ==========================================

local states = {
    [STATE.TITLE] = {
        update = updateTitle,
        draw = drawTitle,
    },
    [STATE.OPTIONS] = {
        update = updateOptions,
        draw = drawOptions,
    },
    [STATE.HISCORES] = {
        update = updateHiscores,
        draw = drawHiscores,
    },
    [STATE.PUZZLE] = {
        update = updatePuzzle,
        draw = drawPuzzle,
    },
}
