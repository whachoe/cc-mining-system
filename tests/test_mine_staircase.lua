-- Regression test for mine_staircase.lua treating a storage block in its
-- path as bedrock and aborting the whole run after a single step.
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

-- scanning isn't what this test is about; skip it so it doesn't consume
-- from the inspect() sequence set up below for the staircase itself
Config.scanRadius = 0
Config.webhookUrl = ""

-- a chest permanently sits in front of the turtle: every forward attempt is
-- physically blocked and every inspect() sees the chest
turtle.forward = function()
  return false
end
turtle.inspect = function()
  return true, { name = "minecraft:chest" }
end

-- straight down is clear for 6 blocks, then bedrock (a permanent,
-- non-storage obstruction) -- caps the loop so the test terminates
local downCalls = 0
turtle.down = function()
  downCalls = downCalls + 1
  return downCalls <= 6
end

local chunk = assert(loadfile("src/programs/mine_staircase.lua"))
chunk("1", "1")

-- 6 successful downs while mining, plus 6 ups on the way back to start
Harness.equal(Movement.moveCount, 12, "the turtle dug down all 6 times before hitting bedrock")
-- 6 successful down() calls, then a 7th invocation that retries (and digs)
-- the full MAX_MOVE_ATTEMPTS (20) times against true bedrock before giving up
Harness.equal(downCalls, 26, "down kept retrying against real bedrock -- that's what stopped the run")
Harness.equal(turtle._digCalls, 20, "only digDown (bedrock retries) dug -- the chest ahead was never dug")
Harness.equal(Movement.pos.x, 0, "returned to its start x after finishing")
Harness.equal(Movement.pos.y, 0, "returned to its start y after finishing")
Harness.equal(Movement.pos.z, 0, "returned to its start z after finishing")
Harness.equal(Movement.facing, 0, "returned to its start facing after finishing")

Harness.finish()
