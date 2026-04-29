-- ==========================================
-- INPUT FUNCTIONS
-- ==========================================

-- State variable to make sure a single click doesn't repeatedly toggle a cell.
local prev_left_click = false
local clicked_cell = {
    i = nil,
    j = nil
}

local function clearAllCellClicks()
    for i = 1, 9 do
        for j = 1, 9 do
            sudoku.cells[i][j].clicked = false
        end
    end
    clicked_cell.i = nil
    clicked_cell.j = nil
end

local function checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y)
    local just_pressed = left_click and not prev_left_click
    prev_left_click = left_click

    for i = 1, 9 do
        for j = 1, 9 do
            local cell = sudoku.cells[i][j]

            -- Is this a mouseover event?
            cell.mouseover =
                (cell.x_left <= mouse_x and mouse_x <= cell.x_right) and
                (cell.y_top <= mouse_y and mouse_y <= cell.y_bottom)

            -- Did the user click on this cell?
            if cell.mouseover and just_pressed then
                if not cell.clicked then
                    clearAllCellClicks()
                    cell.clicked = true
                    clicked_cell.i = i
                    clicked_cell.j = j
                else
                    cell.clicked = false
                end
            end

            -- Is the user trying to change the number?
            if cell.clicked and scroll_y > 0 then
                if cell.guess == nil or cell.guess >= 9 then
                    cell.guess = 1
                else
                    cell.guess = cell.guess + 1
                end
            elseif cell.clicked and scroll_y < 0 then
                if cell.guess == nil or cell.guess <= 1 then
                    cell.guess = 9
                else
                    cell.guess = cell.guess - 1
                end
            end

            sudoku.cells[i][j] = cell
        end
    end
end

function INPUT()
    local mouse_x, mouse_y, left_click, middle_click, right_click, scroll_x, scroll_y = mouse()

    checkInputOnPuzzleGrid(mouse_x, mouse_y, left_click, scroll_y)
end
