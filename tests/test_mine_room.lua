-- Regression test for mine_room.lua drifting out of the room's footprint
-- when a storage block cuts one row short: the old row/layer transitions
-- were blind relative steps that assumed the previous leg always reached
-- its full length, so a shortfall carried into every row/layer after it.
local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

turtle = MockCC.newTurtle()
MockCC.installOs(1)
textutils = MockCC.newTextutils()
http = MockCC.newHttp()

dofile("src/lib/01_config.lua")
dofile("src/lib/02_inventory.lua")
dofile("src/lib/03_movement.lua")
dofile("src/lib/04_world_position.lua")
dofile("src/lib/05_scan.lua")
dofile("src/lib/06_storage.lua")
dofile("src/lib/07_webhook.lua")
dofile("src/lib/08_bootstrap.lua")

Config.scanRadius = 0
Config.webhookUrl = ""

-- a chest sits at local-frame (0,0,2) -- the far cell of row 1's 2x3 room
-- sweep (row 1 runs from z=0 to z=2) -- permanently blocking that one cell,
-- never anywhere else
local DIRS = {
  [0] = { x = 0, z = 1 },
  [1] = { x = 1, z = 0 },
  [2] = { x = 0, z = -1 },
  [3] = { x = -1, z = 0 },
}
local CHEST = { x = 0, y = 0, z = 2 }

local function isChestAhead()
  local dir = DIRS[Movement.facing]
  local x, y, z = Movement.pos.x + dir.x, Movement.pos.y, Movement.pos.z + dir.z
  return x == CHEST.x and y == CHEST.y and z == CHEST.z
end

turtle.forward = function()
  return not isChestAhead()
end
turtle.inspect = function()
  if isChestAhead() then
    return true, { name = "minecraft:chest" }
  end
  return false
end

local minX, maxX, minZ, maxZ = 0, 0, 0, 0
Movement.addMoveHook(function()
  minX, maxX = math.min(minX, Movement.pos.x), math.max(maxX, Movement.pos.x)
  minZ, maxZ = math.min(minZ, Movement.pos.z), math.max(maxZ, Movement.pos.z)
end)

local chunk = assert(loadfile("src/programs/mine_room.lua"))
chunk("2", "3", "1")

Harness.equal(turtle._digCalls, 0, "the chest is never dug, even after row 1 is cut short")
Harness.equal(minZ, 0, "row 2 never drifts below the room's z=0 edge")
Harness.equal(maxZ, 2, "row 2 still reaches the room's far z=2 edge despite row 1 stopping short")
Harness.equal(minX, 0, "the sweep never drifts below the room's x=0 edge")
Harness.equal(maxX, 1, "the sweep never drifts past the room's x=1 edge")
Harness.equal(Movement.moveCount, 6, "row 2 starts from the correct corner instead of chaining off row 1's shortfall")
Harness.equal(Movement.pos.x, 0, "returned to its start x after finishing")
Harness.equal(Movement.pos.y, 0, "returned to its start y after finishing")
Harness.equal(Movement.pos.z, 0, "returned to its start z after finishing")
Harness.equal(Movement.facing, 0, "returned to its start facing after finishing")

Harness.finish()
