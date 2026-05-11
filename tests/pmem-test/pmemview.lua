-- title:  Persistent Memory Viewer / Modifier
-- author: StinkerB06
-- desc:   Created with the assistance of NesBox
-- saveid: sussudioku_bang_bang

-- Change saveid tag to choose game
-- to read persistent memory data from.

screen_color = 5
border_color = 6
text_notes_color = 15

index = 0
value = pmem(index)
function TIC()
    cls(screen_color)
    poke(0x3FF8, border_color)
    if btnp(0, 45, 6) then index = index + 1 end
    if btnp(1, 45, 6) then index = index - 1 end
    if btnp(0, 45, 6) or btnp(1, 45, 6) then value = pmem(index % 256) end
    if btnp(2, 45, 6) then value = value - 1 end
    if btnp(3, 45, 6) then value = value + 1 end
    if btn(4) then value = 0 end
    print("Current index: " .. index % 256, 1, 1, text_notes_color)
    print("Index value (S32): " .. pmem(index % 256), 1, 8, text_notes_color)
    pmem(index % 256, value)
end

-- StinkerB06 owns privledges to this
-- cartridge. If anyone tries to copy
-- any of my carts, then they will be
-- told on NesBox if without permission.
