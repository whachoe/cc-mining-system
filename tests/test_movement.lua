local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

-- odometry: forward/turn/up/down update pos and facing correctly
turtle = MockCC.newTurtle()
dofile("src/lib/03_movement.lua")

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

-- a permanent obstruction (e.g. bedrock) makes forward give up and report failure
turtle = MockCC.newTurtle()
turtle._forwardBlocked = math.huge
dofile("src/lib/03_movement.lua")

local ok = Movement.forward()
Harness.equal(ok, false, "permanently blocked forward gives up")
Harness.equal(Movement.pos.z, 0, "position unchanged after a failed forward")

-- a transient obstruction (e.g. a mob) clears within the retry budget
turtle = MockCC.newTurtle()
turtle._forwardBlocked = 3
dofile("src/lib/03_movement.lua")

local ok2 = Movement.forward()
Harness.equal(ok2, true, "forward succeeds once a transient obstruction clears")
Harness.equal(Movement.pos.z, 1, "position updates once the obstruction clears")

Harness.finish()
