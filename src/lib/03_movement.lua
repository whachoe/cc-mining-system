Movement = {}

-- position/facing are relative to the turtle's position and orientation
-- when the program started (no GPS available) -- facing 0 is "however it
-- was originally facing", and increases clockwise (turnRight) from there
local DIRS = {
  [0] = { x = 0, z = 1 },
  [1] = { x = 1, z = 0 },
  [2] = { x = 0, z = -1 },
  [3] = { x = -1, z = 0 },
}

local MAX_MOVE_ATTEMPTS = 20

-- the position/facing the turtle was at when the program started -- always
-- {0,0,0}/0 by definition of this relative coordinate frame, but named
-- explicitly so other modules (e.g. Webhook) don't have to hardcode it
Movement.start = { x = 0, y = 0, z = 0, facing = 0 }

Movement.pos = { x = 0, y = 0, z = 0 }
Movement.facing = 0
Movement.moveCount = 0
Movement.moveHooks = {}

-- retries a blocked move by digging/attacking in front of it; gives up
-- after MAX_MOVE_ATTEMPTS (e.g. bedrock, which can never be dug through), or
-- immediately if the obstruction is a storage block -- never dig into a
-- chest/barrel just because it happens to be in the way.
-- second return value tells the caller *why* it failed: true if a storage
-- block was the obstruction, so callers can treat that differently from a
-- genuine dead end (bedrock, exhausted retries)
local function attemptMove(moveFn, digFn, attackFn, inspectFn)
  for _ = 1, MAX_MOVE_ATTEMPTS do
    if moveFn() then
      return true, false
    end
    if digFn then
      if inspectFn then
        local ok, data = inspectFn()
        if ok and Inventory.isStorageBlock(data.name) then
          return false, true
        end
      end
      digFn()
    end
    if attackFn then
      attackFn()
    end
  end
  return false, false
end

function Movement.addMoveHook(fn)
  table.insert(Movement.moveHooks, fn)
end

local function notifyMove()
  Movement.moveCount = Movement.moveCount + 1
  for _, hook in ipairs(Movement.moveHooks) do
    hook()
  end
end

function Movement.forward()
  local ok, blockedByStorage = attemptMove(turtle.forward, turtle.dig, turtle.attack, turtle.inspect)
  if ok then
    local dir = DIRS[Movement.facing]
    Movement.pos.x = Movement.pos.x + dir.x
    Movement.pos.z = Movement.pos.z + dir.z
    notifyMove()
  end
  return ok, blockedByStorage
end

function Movement.back()
  local ok = attemptMove(turtle.back, nil, nil)
  if ok then
    local dir = DIRS[Movement.facing]
    Movement.pos.x = Movement.pos.x - dir.x
    Movement.pos.z = Movement.pos.z - dir.z
    notifyMove()
  end
  return ok
end

function Movement.up()
  local ok, blockedByStorage = attemptMove(turtle.up, turtle.digUp, turtle.attackUp, turtle.inspectUp)
  if ok then
    Movement.pos.y = Movement.pos.y + 1
    notifyMove()
  end
  return ok, blockedByStorage
end

function Movement.down()
  local ok, blockedByStorage = attemptMove(turtle.down, turtle.digDown, turtle.attackDown, turtle.inspectDown)
  if ok then
    Movement.pos.y = Movement.pos.y - 1
    notifyMove()
  end
  return ok, blockedByStorage
end

-- clears the block directly above without moving into it (e.g. carving
-- headroom into a staircase) -- same "never dig a storage block" guard as
-- the move functions, just without an attempted move backing it
function Movement.clearUp()
  local ok, data = turtle.inspectUp()
  if ok and Inventory.isStorageBlock(data.name) then
    return false
  end
  turtle.digUp()
  return true
end

function Movement.turnLeft()
  turtle.turnLeft()
  Movement.facing = (Movement.facing - 1) % 4
end

function Movement.turnRight()
  turtle.turnRight()
  Movement.facing = (Movement.facing + 1) % 4
end

function Movement.turnTo(targetFacing)
  local diff = (targetFacing - Movement.facing) % 4
  if diff == 1 then
    Movement.turnRight()
  elseif diff == 2 then
    Movement.turnRight()
    Movement.turnRight()
  elseif diff == 3 then
    Movement.turnLeft()
  end
end

-- navigate to an arbitrary {x,y,z} (in the same start-relative coordinate
-- frame as Movement.pos) using the accumulated odometry: vertical first,
-- then x, then z. Never turns to face a particular direction on arrival.
-- Gives up on an axis (rather than looping forever) if a leg is permanently
-- blocked -- e.g. a storage block sitting exactly on the path -- leaving the
-- turtle short of the target on that axis.
function Movement.goTo(target)
  while Movement.pos.y > target.y do
    if not Movement.down() then
      break
    end
  end
  while Movement.pos.y < target.y do
    if not Movement.up() then
      break
    end
  end

  local dx = target.x - Movement.pos.x
  if dx ~= 0 then
    Movement.turnTo(dx > 0 and 1 or 3)
    while Movement.pos.x ~= target.x do
      if not Movement.forward() then
        break
      end
    end
  end

  local dz = target.z - Movement.pos.z
  if dz ~= 0 then
    Movement.turnTo(dz > 0 and 0 or 2)
    while Movement.pos.z ~= target.z do
      if not Movement.forward() then
        break
      end
    end
  end
end

-- navigate back to (0,0,0) and face the original start direction
function Movement.returnToStart()
  Movement.goTo({ x = 0, y = 0, z = 0 })
  Movement.turnTo(0)
end
