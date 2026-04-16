--Key Test Project
--By Rain_Effect,pixelbath
local ox = 70
local oy = 15
local btnLabel = { "Up", "Down", "Left", "Right", "Btn A", "Btn B", "Btn X", "Btn Y" }

function printBtnLabels(x, y, headingText)
    print(headingText, x, y, 8)
    for i = 1, 8 do
        print(btnLabel[i], x, y + i * 10, 12)
    end
end

function printInputState(x, y, headingText, startIdx)
    print(headingText, x, y, 8)
    for i = 1, 8 do
        if btn(i - 1 + startIdx) then
            print("On", x, y + i * 10, 6)
        else
            print("Off", x - 3, y + i * 10, 1)
        end
    end
end

function TIC()
    cls(10)

    -- print("Key Test Project", 0, 0, 12)
    print("Key Test Project", ox, oy, 12)

    printBtnLabels(ox - 30, oy + 15, "Btn")
    printInputState(ox + 20, oy + 15, "1P", 0)
    printInputState(ox + 50, oy + 15, "2P", 8)
    printInputState(ox + 80, oy + 15, "3P", 16)
    printInputState(ox + 110, oy + 15, "4P", 24)
end


