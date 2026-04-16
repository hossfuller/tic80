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

    print("Key Test Project", ox, oy, 12)
    print("We doin' this", ox, oy-15, 12)

    printBtnLabels(ox - 30, oy + 15, "Btn")
    printInputState(ox + 20, oy + 15, "1P", 0)
    printInputState(ox + 50, oy + 15, "2P", 8)
    printInputState(ox + 80, oy + 15, "3P", 16)
    printInputState(ox + 110, oy + 15, "4P", 24)
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
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

