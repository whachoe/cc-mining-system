local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

local function loadMovementLibs()
  dofile("src/lib/01_config.lua")
  dofile("src/lib/02_inventory.lua")
  dofile("src/lib/03_movement.lua")
end

-- odometry: forward/turn/up/down update pos and facing correctly
turtle = MockCC.newTurtle()
loadMovementLibs()

Harness.equal(Movement.pos.x, 0, "start position x")
Harness.equal(Movement.pos.z, 0, "start position z")

Movement.forward()
Harness.equal(Movement.pos.z, 1, "facing 0: forward increases z")

Movement.turnRight()
Harness.equal(Movement.facing, 1, "turnRight increments facing")

Movement.forward()
Harness.equal(Movement.pos.x, 1, "facing 1: forward increases x")

Movement.up()
Harness.equal(Movement.pos.y, 1, "up increases y")
Movement.down()
Harness.equal(Movement.pos.y, 0, "down decreases y")

Harness.equal(Movement.moveCount, 4, "moveCount counts forward/up/down but not turns")

-- goTo/returnToStart navigate back using the odometry
Movement.returnToStart()
Harness.equal(Movement.pos.x, 0, "returnToStart brings x back to 0")
Harness.equal(Movement.pos.z, 0, "returnToStart brings z back to 0")
Harness.equal(Movement.facing, 0, "returnToStart faces the original direction")

-- a permanent obstruction (e.g. bedrock) makes forward give up and report
-- failure, retrying (and digging) up to the full attempt budget
turtle = MockCC.newTurtle()
turtle._forwardBlocked = math.huge
loadMovementLibs()

local ok = Movement.forward()
Harness.equal(ok, false, "permanently blocked forward gives up")
Harness.equal(Movement.pos.z, 0, "position unchanged after a failed forward")
Harness.check(turtle._digCalls > 0, "a non-storage obstruction is dug at least once")

-- a transient obstruction (e.g. a mob) clears within the retry budget
turtle = MockCC.newTurtle()
turtle._forwardBlocked = 3
loadMovementLibs()

local ok2 = Movement.forward()
Harness.equal(ok2, true, "forward succeeds once a transient obstruction clears")
Harness.equal(Movement.pos.z, 1, "position updates once the obstruction clears")

-- a storage block (chest/barrel/...) in front is never dug, even though it
-- blocks the move just like any other obstruction would
turtle = MockCC.newTurtle()
turtle._forwardBlocked = math.huge
turtle._inspectSequence = { { true, { name = "minecraft:chest" } } }
loadMovementLibs()

local ok3 = Movement.forward()
Harness.equal(ok3, false, "forward blocked by a storage block reports failure")
Harness.equal(Movement.pos.z, 0, "position unchanged when blocked by a storage block")
Harness.equal(turtle._digCalls, 0, "a storage block is never dug by forward")

-- same guard applies to up/down (e.g. a chest sitting on the layer above)
turtle = MockCC.newTurtle()
turtle._upBlocked = math.huge
turtle._inspectUp = { true, { name = "minecraft:barrel" } }
loadMovementLibs()

local ok4 = Movement.up()
Harness.equal(ok4, false, "up blocked by a storage block reports failure")
Harness.equal(Movement.pos.y, 0, "position unchanged when up is blocked by a storage block")
Harness.equal(turtle._digCalls, 0, "a storage block is never dug by up")

turtle = MockCC.newTurtle()
turtle._downBlocked = math.huge
turtle._inspectDown = { true, { name = "minecraft:shulker_box" } }
loadMovementLibs()

local ok5 = Movement.down()
Harness.equal(ok5, false, "down blocked by a storage block reports failure")
Harness.equal(Movement.pos.y, 0, "position unchanged when down is blocked by a storage block")
Harness.equal(turtle._digCalls, 0, "a storage block is never dug by down")

Harness.finish()
