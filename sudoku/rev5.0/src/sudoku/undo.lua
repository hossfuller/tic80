-- ==========================================
-- UNDO FUNCTION
-- ==========================================

local checkAutoNote -- forward declaration, see src.states.puzzle

local undo_list = {}

local function register_action(x_pos, y_pos, new_value, prev_value)
    undo_list[#undo_list + 1] = {
        x    = x_pos,
        y    = y_pos,
        new  = new_value,
        prev = prev_value,
    }
end

local function undo_last_action()
    local last_action = table.remove(undo_list)
    if last_action ~= nil then
        if sudoku.cells[last_action.x][last_action.y].guess == last_action.new then
            sudoku.cells[last_action.x][last_action.y].guess = last_action.prev

            -- If the auto-note button has been pressed in the past, rerun the
            -- auto-note functionality without incrementing the auto-note counter.
            if auto_note_btn.NUM_CLICKED ~= nil and auto_note_btn.NUM_CLICKED > 0 then
                checkAutoNote()
            end
        end
    end
end