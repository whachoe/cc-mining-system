-- Mines a rectangular room, `width` blocks (x) by `length` blocks (z) by
-- `height` layers (y), starting from the turtle's current position/facing.
--
-- Optionally takes the turtle's real-world starting coordinates and the
-- cardinal direction it's facing (read off the player's own F3 screen), so
-- Webhook reports can include an absolute world position.
local args = { ... }
local width = tonumber(args[1])
local length = tonumber(args[2])
local height = tonumber(args[3])
local USAGE = "Usage: mine_room <width> <length> <height> [worldX worldY worldZ worldFacing]"

if not (width and length and height) then
  print(USAGE)
  return
end

local worldOk, worldErr = WorldPosition.configureFromArgs(args, 4)
if not worldOk then
  print(USAGE)
  print(worldErr)
  return
end

-- boustrophedon ("snake") sweep of one width x length layer, starting and
-- ending at the same corner/facing so layers stack without extra bookkeeping
local function clearLayer()
  local entry = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z }

  for row = 1, width do
    for _ = 1, length - 1 do
      Movement.forward()
    end
    if row < width then
      if row % 2 == 1 then
        Movement.turnRight()
        Movement.forward()
        Movement.turnRight()
      else
        Movement.turnLeft()
        Movement.forward()
        Movement.turnLeft()
      end
    end
  end

  Movement.goTo(entry)
  Movement.turnTo(0)
end

Bootstrap.init()

local advanceLayer = Config.roomLayerDirection == "down" and Movement.down or Movement.up

for layer = 1, height do
  clearLayer()
  if layer < height then
    advanceLayer()
  end
end

Bootstrap.finish()
