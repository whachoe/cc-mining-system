Inventory = {}

local USABLE_SLOTS_START = 2
local USABLE_SLOTS_END = 16

function Inventory.isFuelItem(name)
  return name ~= nil and Config.fuelItemNames[name] == true
end

function Inventory.isStorageBlock(name)
  if name == nil then return false end
  for _, needle in ipairs(Config.storageBlockNames) do
    if string.find(name, needle, 1, true) then
      return true
    end
  end
  return false
end

-- number of empty slots among the usable (non-fuel-reserve) inventory slots
function Inventory.freeSlotCount()
  local free = 0
  for slot = USABLE_SLOTS_START, USABLE_SLOTS_END do
    if turtle.getItemCount(slot) == 0 then
      free = free + 1
    end
  end
  return free
end

function Inventory.isNearlyFull()
  return Inventory.freeSlotCount() <= Config.storageFreeSlotThreshold
end

-- move any fuel-type items sitting in the usable slots into the fuel slot.
-- the fuel slot is just slot 1 like any other -- mined loot can land there
-- once fuel's been burned out of it, and transferTo silently fails to
-- stack fuel on top of a different item -- so relocate any non-fuel
-- occupant out of the way first, freeing the slot for fuel to actually land
function Inventory.consolidateFuel()
  local occupant = turtle.getItemDetail(Config.fuelSlot)
  if occupant ~= nil and not Inventory.isFuelItem(occupant.name) then
    for slot = USABLE_SLOTS_START, USABLE_SLOTS_END do
      if slot ~= Config.fuelSlot and turtle.getItemCount(slot) == 0 then
        turtle.select(Config.fuelSlot)
        turtle.transferTo(slot)
        break
      end
    end
  end

  for slot = USABLE_SLOTS_START, USABLE_SLOTS_END do
    local item = turtle.getItemDetail(slot)
    if item ~= nil and Inventory.isFuelItem(item.name) then
      turtle.select(slot)
      turtle.transferTo(Config.fuelSlot)
    end
  end
  turtle.select(Config.fuelSlot)
end

-- consume items from the fuel slot until fuel level reaches targetLevel
-- (or the fuel slot runs out), one item at a time to avoid overshooting
function Inventory.topUpFuel(targetLevel)
  turtle.select(Config.fuelSlot)
  while turtle.getFuelLevel() < targetLevel and turtle.getItemCount(Config.fuelSlot) > 0 do
    if not turtle.refuel(1) then
      break
    end
  end
end

-- snapshot of current inventory contents, for webhook reporting
function Inventory.snapshot()
  local items = {}
  for slot = 1, USABLE_SLOTS_END do
    local item = turtle.getItemDetail(slot)
    if item ~= nil then
      table.insert(items, { slot = slot, name = item.name, count = item.count })
    end
  end
  return items
end
