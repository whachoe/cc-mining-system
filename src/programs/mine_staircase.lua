-- Mines a spiral staircase down until bedrock is hit. Traces the perimeter
-- of a `width` x `length` rectangle, descending 1 block for every 1 block
-- moved forward and turning 90 degrees at the end of each side, looping the
-- same footprint deeper on every lap.
--
-- Optionally takes the turtle's real-world starting coordinates and the
-- cardinal direction it's facing (read off the player's own F3 screen), so
-- Webhook reports can include an absolute world position.
local args = { ... }
local width = tonumber(args[1])
local length = tonumber(args[2])
local USAGE = "Usage: mine_staircase <width> <length> [worldX worldY worldZ worldFacing]"

if not (width and length) then
  print(USAGE)
  return
end

local worldOk, worldErr = WorldPosition.configureFromArgs(args, 3)
if not worldOk then
  print(USAGE)
  print(worldErr)
  return
end

Bootstrap.init()

local sides = { width, length, width, length }
local sideIndex = 1
local reachedBedrock = false

-- true if this move should stop the whole run: either a genuine dead end
-- (not a storage block, which is fine to just skip past) or the storage
-- chest turned out to have no fuel left (Storage.refuel sets this)
local function stopsRun(ok, blockedByStorage)
  if not ok and not blockedByStorage then
    reachedBedrock = true
  end
  return reachedBedrock or Storage.outOfFuel
end

while not reachedBedrock and not Storage.outOfFuel do
  local sideLength = sides[sideIndex]
  for _ = 1, sideLength do
    if stopsRun(Movement.down()) then break end
    if stopsRun(Movement.forward()) then break end
    Movement.clearUp()
  end

  sideIndex = (sideIndex % 4) + 1
  Movement.turnRight()
end

Bootstrap.finish()
