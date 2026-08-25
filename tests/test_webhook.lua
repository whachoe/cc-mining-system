-- Integration test: exercises Webhook wired up through the real
-- Bootstrap/Movement/Storage/WorldPosition stack (not just Webhook in
-- isolation), driving actual moves and checking what ends up posted.
local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

local function loadFullStack()
  turtle = MockCC.newTurtle()
  MockCC.installOs(42)
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

  -- scanning isn't what this test is about; skip it so Bootstrap.init()
  -- doesn't spend moves (and therefore webhook-interval ticks) searching
  Config.scanRadius = 0
end

-- Webhook.report() is a no-op when no URL is configured
loadFullStack()
Config.webhookUrl = ""
Bootstrap.init()
Movement.forward()
Movement.forward()
Webhook.report()
Harness.equal(#http._calls, 0, "no webhook URL configured means no HTTP call is made")

-- Bootstrap.init() tops up fuel from whatever's already sitting in the fuel
-- slot, not just from a scanned storage chest -- a turtle pre-loaded with
-- fuel but with no chest in range (or an empty one) shouldn't run dry after
-- one move
loadFullStack()
Config.webhookUrl = ""
turtle._fuelLevel = 0
turtle._slots[Config.fuelSlot] = { name = "minecraft:coal", count = 5 }
Bootstrap.init()
Harness.equal(turtle._fuelLevel, 5, "fuel topped up from the fuel slot's own contents at startup")
Harness.equal(turtle._slots[Config.fuelSlot], nil, "the fuel slot's coal was consumed topping up")

-- Bootstrap.init() itself sends a status report immediately, so a run that
-- quits right after starting still leaves a trace of having started
loadFullStack()
Config.webhookUrl = "https://example.test/webhook"
Bootstrap.init()
Harness.equal(#http._calls, 1, "Bootstrap.init() sends an initial status report")

local startPayload = textutils._calls[1]
Harness.equal(startPayload.moveCount, 0, "the initial report fires before any moves happen")
Harness.equal(startPayload.fuelLevel, 1000, "the initial report reflects the turtle's actual fuel level")

-- moving through Bootstrap's wiring fires the webhook every N moves after
-- that, and the payload posted matches what actually happened
loadFullStack()
Config.webhookUrl = "https://example.test/webhook"
Config.webhookInterval = 3
Bootstrap.init()
Harness.equal(#http._calls, 1, "Bootstrap.init()'s own report counts as the first call")

Movement.forward()
Movement.forward()
Harness.equal(#http._calls, 1, "webhook does not fire before reaching the interval")

Movement.forward() -- 3rd move: hits the interval
Harness.equal(#http._calls, 2, "webhook fires exactly on the configured move interval")

local call = http._calls[2]
Harness.equal(call.url, "https://example.test/webhook", "posts to the configured webhook URL")
Harness.equal(call.headers["Content-Type"], "application/json", "sends a JSON content type")
Harness.equal(call.body, "MOCK_JSON:2", "posts exactly what serializeJSON returned")

local payload = textutils._calls[2]
Harness.equal(payload.turtleId, 42, "payload includes the turtle id from os.getComputerID()")
Harness.equal(payload.moveCount, 3, "payload reflects the move count at the time it fired")
Harness.equal(payload.position.z, 3, "payload position matches where the turtle actually is")
Harness.equal(payload.worldPosition, nil, "worldPosition is omitted when WorldPosition was never configured")

Movement.forward()
Movement.forward()
Harness.equal(#http._calls, 2, "no extra webhook calls between intervals")

Movement.forward() -- 6th move: next interval
Harness.equal(#http._calls, 3, "webhook fires again on the next interval")

-- once WorldPosition is configured, the payload includes absolute coordinates
loadFullStack()
Config.webhookUrl = "https://example.test/webhook"
Bootstrap.init()
WorldPosition.configure({ x = 100, y = 64, z = 200 }, "south")

Webhook.report() -- an explicit report, like Bootstrap.finish() sends
local finalPayload = textutils._calls[#textutils._calls]
Harness.check(finalPayload.worldPosition ~= nil, "worldPosition is included once configured")
Harness.equal(finalPayload.worldPosition.x, 100, "worldPosition reflects the configured origin")
Harness.equal(finalPayload.worldPosition.facing, "south", "worldPosition reports the current cardinal facing")

Harness.finish()
