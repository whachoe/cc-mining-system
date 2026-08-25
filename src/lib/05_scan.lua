Scan = {}

local ARM_DIRS = {
  [0] = { x = 0, z = 1 },
  [1] = { x = 1, z = 0 },
  [2] = { x = 0, z = -1 },
  [3] = { x = -1, z = 0 },
}

-- Looks for the closest inventory block (chest/barrel/hopper/...) within
-- Config.scanRadius blocks of the start position. Turtles can't raycast, so
-- this physically walks outward along each of the 4 horizontal directions
-- (through open air only -- it never digs through a solid block just to
-- search behind it) and always returns the turtle to where it started.
--
-- Returns a location descriptor for Storage to use later:
--   { standPos = {x,y,z}, facing = 0-3 or nil, mode = "up"|"down"|"side" }
-- or nil if nothing was found.
function Scan.findStorage()
  local upOk, upData = turtle.inspectUp()
  if upOk and Inventory.isStorageBlock(upData.name) then
    return { standPos = { x = 0, y = 0, z = 0 }, facing = nil, mode = "up" }
  end

  local downOk, downData = turtle.inspectDown()
  if downOk and Inventory.isStorageBlock(downData.name) then
    return { standPos = { x = 0, y = 0, z = 0 }, facing = nil, mode = "down" }
  end

  for facing = 0, 3 do
    Movement.turnTo(facing)
    local steps = 0
    local found = nil

    for _ = 1, Config.scanRadius do
      local ok, data = turtle.inspect()
      if ok and Inventory.isStorageBlock(data.name) then
        found = {
          standPos = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z },
          facing = facing,
          mode = "side",
        }
        break
      elseif ok then
        break -- solid, non-storage block: don't dig through it to keep looking
      else
        if not Movement.forward() then
          break
        end
        steps = steps + 1
      end
    end

    for _ = 1, steps do
      Movement.back()
    end

    if found then
      Movement.turnTo(0)
      return found
    end
  end

  Movement.turnTo(0)
  return nil
end
