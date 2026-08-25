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
-- ending at the same corner/facing so layers stack without extra bookkeeping.
-- Row transitions go to an absolute target computed from `entry`, rather
-- than a blind relative step, so a storage block that cuts a row short
-- (Movement.forward just doesn't advance past it) doesn't throw off the
-- alignment of every row after it.
local function clearLayer()
  local entry = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z }

  for row = 1, width do
    Movement.turnTo(row % 2 == 1 and 0 or 2)
    for _ = 1, length - 1 do
      Movement.forward()
    end

    if row < width then
      Movement.goTo({
        x = entry.x + row,
        y = entry.y,
        z = row % 2 == 1 and (entry.z + length - 1) or entry.z,
      })
    end
  end

  Movement.goTo(entry)
  Movement.turnTo(0)
end

Bootstrap.init()

-- same reasoning as clearLayer's row transitions: each layer targets an
-- absolute y computed from the room's starting height, so a storage block
-- blocking one vertical step doesn't leave every later layer at the wrong
-- height
local origin = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z }
local layerStep = Config.roomLayerDirection == "down" and -1 or 1

for layer = 1, height do
  Movement.goTo({ x = origin.x, y = origin.y + (layer - 1) * layerStep, z = origin.z })
  Movement.turnTo(0)
  clearLayer()
end

Bootstrap.finish()
