WorldPosition = {}

-- Minecraft's real turning convention (yaw increases when turning right):
-- south -> west -> north -> east -> south. This is the opposite rotational
-- sense from a naive "N,E,S,W clockwise on a map" assumption, so it's
-- spelled out explicitly rather than derived.
local REAL_TURN_CYCLE = { "south", "west", "north", "east" }
local REAL_VECTORS = {
  south = { x = 0, z = 1 },
  west = { x = -1, z = 0 },
  north = { x = 0, z = -1 },
  east = { x = 1, z = 0 },
}

local dirForFacing0, dirForFacing1, cardinalForFacing

local function cardinalIndex(cardinal)
  for i, c in ipairs(REAL_TURN_CYCLE) do
    if c == cardinal then
      return i
    end
  end
  return nil
end

-- Call once at startup with the turtle's real-world starting coordinates
-- and the real cardinal direction it was facing (read off the player's own
-- F3 screen -- there's no compass or GPS available to the turtle itself,
-- so this has to be supplied). Once configured, WorldPosition.current()
-- translates Movement's start-relative odometry into absolute coordinates.
function WorldPosition.configure(origin, startCardinal)
  local startIndex = cardinalIndex(startCardinal)
  if not startIndex then
    error("Unknown starting cardinal '" .. tostring(startCardinal) .. "', expected north/south/east/west")
  end

  cardinalForFacing = {}
  for facing = 0, 3 do
    cardinalForFacing[facing] = REAL_TURN_CYCLE[((startIndex - 1 + facing) % 4) + 1]
  end
  -- Movement.pos.x/z are sums of Movement's own local facing0/facing1 unit
  -- vectors; mapping those two onto their real-world equivalents gives the
  -- fixed linear transform needed to convert any accumulated local offset
  dirForFacing0 = REAL_VECTORS[cardinalForFacing[0]]
  dirForFacing1 = REAL_VECTORS[cardinalForFacing[1]]

  WorldPosition.origin = { x = origin.x, y = origin.y, z = origin.z }
end

function WorldPosition.isConfigured()
  return WorldPosition.origin ~= nil
end

-- Parses `worldX worldY worldZ worldFacing` out of a program's `args`
-- starting at `offset`, and configures WorldPosition if all four are
-- present. Returns true if nothing was provided (nothing to do) or
-- configuration succeeded; false plus an error message otherwise -- lets
-- callers just check `if not ok then print(err); return end`.
function WorldPosition.configureFromArgs(args, offset)
  local worldX = tonumber(args[offset])
  if worldX == nil then
    return true
  end

  local worldY = tonumber(args[offset + 1])
  local worldZ = tonumber(args[offset + 2])
  local worldFacing = args[offset + 3] and string.lower(args[offset + 3])
  if not (worldY and worldZ and worldFacing) then
    return false, "expected: worldX worldY worldZ worldFacing (e.g. 120 64 -30 north)"
  end

  local ok, err = pcall(WorldPosition.configure, { x = worldX, y = worldY, z = worldZ }, worldFacing)
  if not ok then
    return false, err
  end
  return true
end

-- Absolute {x,y,z,facing} (facing as a cardinal string), or nil if
-- WorldPosition.configure() was never called.
function WorldPosition.current()
  if not WorldPosition.isConfigured() then
    return nil
  end

  local x = Movement.pos.x * dirForFacing1.x + Movement.pos.z * dirForFacing0.x
  local z = Movement.pos.x * dirForFacing1.z + Movement.pos.z * dirForFacing0.z

  return {
    x = WorldPosition.origin.x + x,
    y = WorldPosition.origin.y + Movement.pos.y,
    z = WorldPosition.origin.z + z,
    facing = cardinalForFacing[Movement.facing],
  }
end
