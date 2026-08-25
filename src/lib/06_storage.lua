Storage = {}

Storage.location = nil -- set by Bootstrap.init() from Scan.findStorage()

function Storage.setLocation(loc)
  Storage.location = loc
end

function Storage.hasLocation()
  return Storage.location ~= nil
end

local function faceStorage()
  if Storage.location.mode == "side" then
    Movement.turnTo(Storage.location.facing)
  end
end

local function dropFn()
  local mode = Storage.location.mode
  if mode == "up" then
    return turtle.dropUp
  elseif mode == "down" then
    return turtle.dropDown
  end
  return turtle.drop
end

local function suckFn()
  local mode = Storage.location.mode
  if mode == "up" then
    return turtle.suckUp
  elseif mode == "down" then
    return turtle.suckDown
  end
  return turtle.suck
end

-- push every non-fuel item out of the usable slots into the storage block
function Storage.depositItems()
  faceStorage()
  local drop = dropFn()
  for slot = 2, 16 do
    local item = turtle.getItemDetail(slot)
    if item ~= nil and not Inventory.isFuelItem(item.name) then
      turtle.select(slot)
      drop()
    end
  end
end

-- pull fuel out of the storage block until full (or it runs out); anything
-- non-fuel that got pulled along the way is dropped straight back
function Storage.refuel()
  faceStorage()
  local suck = suckFn()
  local attempts = 0
  while turtle.getFuelLevel() < turtle.getFuelLimit() and attempts < 16 do
    if not suck() then
      break
    end
    Inventory.consolidateFuel()
    Inventory.topUpFuel(turtle.getFuelLimit())
    attempts = attempts + 1
  end
  Storage.depositItems()
end

-- travel to the scanned storage location, do the requested interactions,
-- then return to exactly where mining left off
function Storage.visit(opts)
  if not Storage.hasLocation() then
    return
  end

  local returnPos = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z }
  local returnFacing = Movement.facing

  Movement.goTo(Storage.location.standPos)
  faceStorage()

  Storage.depositItems()
  if opts and opts.refuel then
    Storage.refuel()
  end

  Movement.goTo(returnPos)
  Movement.turnTo(returnFacing)
end

function Storage.storageCheck()
  if Storage.hasLocation() and Inventory.isNearlyFull() then
    Storage.visit({ refuel = true })
  end
end

function Storage.refuelCheck()
  if Storage.hasLocation() and turtle.getFuelLevel() < Config.fuelThreshold then
    Storage.visit({ refuel = true })
  end
end
