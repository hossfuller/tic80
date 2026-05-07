-- ==========================================
-- STATE: NEWPUZZLE
-- ==========================================

-- This state is just for switching from the current puzzle to a new puzzle.

local function updateNewPuzzle()
    changeState(STATE.PUZZLE)
end

local function drawNewPuzzle()
    cls(BLACK)
end
