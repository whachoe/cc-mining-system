local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

local function loadLibs()
  turtle = MockCC.newTurtle()
  dofile("src/lib/03_movement.lua")
  dofile("src/lib/04_world_position.lua")
end

-- unconfigured: current() is nil, never crashes
loadLibs()
Harness.equal(WorldPosition.current(), nil, "unconfigured WorldPosition reports nil")

-- facing0 matches the given start cardinal directly
loadLibs()
WorldPosition.configure({ x = 100, y = 64, z = 200 }, "south")
Movement.pos.z = 5
local southResult = WorldPosition.current()
Harness.equal(southResult.x, 100, "south start: x unaffected by moving along facing0")
Harness.equal(southResult.z, 205, "south start: moving facing0 forward increases real z (south = +z)")
Harness.equal(southResult.facing, "south", "facing0 reports the configured start cardinal")

-- turning right from north (real cycle south->west->north->east) faces east
loadLibs()
WorldPosition.configure({ x = 0, y = 0, z = 0 }, "north")
Movement.pos.x = 3
Movement.facing = 1
local northTurnedResult = WorldPosition.current()
Harness.equal(northTurnedResult.x, 3, "turning right from north then moving increases real x (east = +x)")
Harness.equal(northTurnedResult.z, 0, "no z displacement from a pure facing1 move")
Harness.equal(northTurnedResult.facing, "east", "turning right from north faces east")

-- vertical offset passes straight through, independent of rotation
loadLibs()
WorldPosition.configure({ x = 0, y = 64, z = 0 }, "west")
Movement.pos.y = -7
Harness.equal(WorldPosition.current().y, 57, "y offset applies directly regardless of facing")

-- an unrecognized cardinal is rejected rather than silently misreporting
loadLibs()
local configureOk = pcall(WorldPosition.configure, { x = 0, y = 0, z = 0 }, "up")
Harness.equal(configureOk, false, "configure() rejects an invalid cardinal")

-- configureFromArgs: nothing supplied is not an error, just leaves it unconfigured
loadLibs()
local ok1 = WorldPosition.configureFromArgs({}, 4)
Harness.equal(ok1, true, "configureFromArgs with no world args returns true (nothing to do)")
Harness.equal(WorldPosition.isConfigured(), false, "no world args means still unconfigured")

-- configureFromArgs: partial args is an error, not a silent skip
loadLibs()
local ok2 = WorldPosition.configureFromArgs({ "3", "10", "20", "5" }, 1)
Harness.equal(ok2, false, "configureFromArgs with missing facing arg fails")

-- configureFromArgs: full args configure it correctly
loadLibs()
local ok3 = WorldPosition.configureFromArgs({ "3", "10", "20", "5", "North" }, 2)
Harness.equal(ok3, true, "configureFromArgs with all 4 args succeeds")
Harness.equal(WorldPosition.isConfigured(), true, "full world args configure WorldPosition")
Harness.equal(WorldPosition.current().facing, "north", "configureFromArgs lowercases the facing arg")

Harness.finish()
