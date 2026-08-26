-- Storage.refuel() should notice when the chest has no usable fuel, flag
-- it, and report over the webhook -- instead of silently continuing until
-- the turtle strands itself somewhere with zero fuel.
local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

local function loadFullStack()
  turtle = MockCC.newTurtle()
  MockCC.installOs(7)
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
  Config.webhookUrl = "https://example.test/webhook"
  Storage.setLocation({ standPos = { x = 5, y = 0, z = 0 }, facing = 1, mode = "side" })
end

-- an empty chest (the mock's default turtle.suck() always fails, as if
-- there's nothing to pull) leaves fuel below the threshold
loadFullStack()
turtle._fuelLevel = 0
Storage.refuel()
Harness.equal(Storage.outOfFuel, true, "an empty chest is flagged as out of fuel")
Harness.equal(#http._calls, 1, "an empty-chest refuel sends exactly one webhook report")
Harness.equal(
  textutils._calls[1].message,
  "stopped: storage chest has no fuel to refuel with",
  "the report explains why the run stopped"
)

-- a chest with real fuel in it clears the flag and sends no report
loadFullStack()
turtle._fuelLevel = 0
turtle._fuelLimit = 100
Config.fuelThreshold = 50
turtle.suck = function()
  turtle._slots[2] = { name = "minecraft:coal", count = 200 }
  return true
end
Storage.refuel()
Harness.equal(Storage.outOfFuel, false, "a chest with fuel is not flagged as out of fuel")
Harness.equal(turtle._fuelLevel, 100, "fuel is topped all the way up to the fuel limit")
Harness.equal(#http._calls, 0, "a successful refuel sends no webhook report")

-- Storage.visit() stays at the chest instead of returning to the mining
-- position once refuel discovers there's no fuel to be had
loadFullStack()
turtle._fuelLevel = 0
Movement.pos = { x = 10, y = -3, z = 2 }
Storage.visit({ refuel = true })
Harness.equal(Storage.outOfFuel, true, "the visit discovers the chest is out of fuel")
Harness.equal(Movement.pos.x, 5, "stays at the chest's x instead of returning to the mining position")
Harness.equal(Movement.pos.y, 0, "stays at the chest's y instead of returning to the mining position")
Harness.equal(Movement.pos.z, 0, "stays at the chest's z instead of returning to the mining position")

-- the outbound trip to the chest is itself several moves; each one fires
-- the same move hook that calls refuelCheck, and fuel is still below
-- threshold for all of them (mid-trip, not refueled yet) -- Storage.visit
-- must not let that re-enter itself instead of ever reaching the chest
loadFullStack()
Bootstrap.init() -- wires up the move hook that calls storageCheck/refuelCheck
turtle._fuelLevel = 0
turtle.suck = function()
  turtle._slots[2] = { name = "minecraft:coal", count = 64 }
  return true
end

local refuelCalls = 0
local realRefuel = Storage.refuel
Storage.refuel = function(...)
  refuelCalls = refuelCalls + 1
  return realRefuel(...)
end

Storage.refuelCheck() -- the standPos is 5 forward moves away -- each one re-fires the hook

Harness.equal(refuelCalls, 1, "the outbound trip's own moves don't re-enter Storage.visit")
Harness.equal(Movement.pos.x, 0, "returned to exactly where the refuel check was triggered from")
Harness.equal(Movement.pos.z, 0, "returned to exactly where the refuel check was triggered from")

Harness.finish()
