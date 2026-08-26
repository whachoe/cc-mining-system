local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

turtle = MockCC.newTurtle()
dofile("src/lib/01_config.lua")
dofile("src/lib/02_inventory.lua")

Harness.equal(Inventory.freeSlotCount(), 15, "all 15 usable slots start empty")
Harness.equal(Inventory.isNearlyFull(), false, "not nearly full when empty")

-- fill slots 2..15 (14 of the 15 usable slots), leaving exactly the
-- configured threshold (2) of usable slots... minus one, to cross it
for slot = 2, 15 do
  turtle._slots[slot] = { name = "minecraft:stone", count = 64 }
end
Harness.equal(Inventory.freeSlotCount(), 1, "one usable slot left free")
Harness.equal(Inventory.isNearlyFull(), true, "nearly full once free slots <= threshold")

-- fuel consolidation moves a mined fuel item out of its slot into slot 1
turtle = MockCC.newTurtle()
dofile("src/lib/01_config.lua")
dofile("src/lib/02_inventory.lua")

turtle._slots[5] = { name = "minecraft:coal", count = 10 }
Inventory.consolidateFuel()
Harness.equal(turtle._slots[5], nil, "coal removed from its original slot")
Harness.equal(turtle._slots[1] and turtle._slots[1].count, 10, "coal moved into the fuel slot")

-- non-fuel items are left where they are
turtle._slots[6] = { name = "minecraft:stone", count = 5 }
Inventory.consolidateFuel()
Harness.equal(turtle._slots[6] and turtle._slots[6].count, 5, "stone is not swept into the fuel slot")

-- topUpFuel consumes fuel-slot items one at a time up to the target level
turtle._fuelLevel = 0
Inventory.topUpFuel(5)
Harness.equal(turtle._fuelLevel, 5, "fuel topped up to the requested target level")
Harness.equal(turtle._slots[1].count, 5, "5 fuel items consumed from the fuel slot")

-- if mined loot ended up in the fuel slot (it's just slot 1, once fuel's
-- been burned out of it), consolidateFuel relocates it instead of leaving
-- it stuck blocking fuel from ever landing there again
turtle = MockCC.newTurtle()
dofile("src/lib/01_config.lua")
dofile("src/lib/02_inventory.lua")

turtle._slots[1] = { name = "minecraft:cobblestone", count = 32 }
turtle._slots[4] = { name = "minecraft:coal", count = 10 }
Inventory.consolidateFuel()
Harness.equal(turtle._slots[1] and turtle._slots[1].name, "minecraft:coal", "the fuel slot ends up holding fuel")
Harness.equal(turtle._slots[1].count, 10, "all 10 coal made it into the fuel slot")

local relocatedSlot = nil
for slot = 2, 16 do
  if turtle._slots[slot] and turtle._slots[slot].name == "minecraft:cobblestone" then
    relocatedSlot = slot
  end
end
Harness.check(relocatedSlot ~= nil, "the cobblestone that was in the fuel slot got moved elsewhere, not dropped")
Harness.equal(turtle._slots[relocatedSlot].count, 32, "the relocated cobblestone kept its full count")

Harness.finish()
