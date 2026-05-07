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
    [STATE.STATISTICS] = {
        update = updateStatistics,
        draw = drawStatistics,
    },
    [STATE.PUZZLE] = {
        update = updatePuzzle,
        draw = drawPuzzle,
    },
    [STATE.NEWPUZZLE] = {
        update = updateNewPuzzle,
        draw = drawNewPuzzle,
    },
}
