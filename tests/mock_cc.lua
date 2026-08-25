-- Minimal fake of the bits of the CC:Tweaked turtle/os/textutils/http APIs
-- that src/lib/*.lua touches, so that logic can be exercised under plain
-- lua5.1 without Minecraft running.
local unpack = table.unpack or unpack -- luacheck: ignore
local M = {}

function M.newTurtle()
  local t = {
    _slots = {}, -- [1..16] -> { name = str, count = n } or nil
    _selected = 1,
    _fuelLevel = 1000,
    _fuelLimit = 20000,
    _forwardBlocked = 0, -- attempts to fail before succeeding; math.huge = never succeeds
    _upBlocked = 0,
    _downBlocked = 0,
    _inspectUp = { false },
    _inspectDown = { false },
    -- ordered list of {ok, data} results returned by successive inspect()
    -- calls; once exhausted, defaults to {false} (open air)
    _inspectSequence = {},
    _inspectIndex = 1,
    _digCalls = 0, -- how many times dig/digUp/digDown were actually invoked
  }

  local function consumeBlocked(fieldName)
    local remaining = t[fieldName]
    if remaining == math.huge then
      return true
    end
    if remaining > 0 then
      t[fieldName] = remaining - 1
      return true
    end
    return false
  end

  function t.select(slot)
    t._selected = slot
    return true
  end

  function t.getItemCount(slot)
    local item = t._slots[slot]
    return item and item.count or 0
  end

  function t.getItemDetail(slot)
    local item = t._slots[slot]
    if not item then
      return nil
    end
    return { name = item.name, count = item.count }
  end

  function t.transferTo(slot, count)
    local from = t._slots[t._selected]
    if not from then
      return false
    end
    count = count or from.count
    local to = t._slots[slot]
    if to and to.name ~= from.name then
      return false
    end
    if not to then
      to = { name = from.name, count = 0 }
      t._slots[slot] = to
    end
    to.count = to.count + count
    from.count = from.count - count
    if from.count <= 0 then
      t._slots[t._selected] = nil
    end
    return true
  end

  function t.refuel(count)
    local slot = t._slots[t._selected]
    if not slot then
      return false
    end
    count = count or slot.count
    if slot.count < count then
      return false
    end
    slot.count = slot.count - count
    if slot.count <= 0 then
      t._slots[t._selected] = nil
    end
    t._fuelLevel = t._fuelLevel + count
    return true
  end

  function t.getFuelLevel()
    return t._fuelLevel
  end

  function t.getFuelLimit()
    return t._fuelLimit
  end

  function t.forward()
    return not consumeBlocked("_forwardBlocked")
  end

  function t.back()
    return true
  end

  function t.up()
    return not consumeBlocked("_upBlocked")
  end

  function t.down()
    return not consumeBlocked("_downBlocked")
  end

  function t.turnLeft()
    return true
  end

  function t.turnRight()
    return true
  end

  function t.dig()
    t._digCalls = t._digCalls + 1
    return true
  end

  function t.digUp()
    t._digCalls = t._digCalls + 1
    return true
  end

  function t.digDown()
    t._digCalls = t._digCalls + 1
    return true
  end

  function t.attack()
    return false
  end

  function t.attackUp()
    return false
  end

  function t.attackDown()
    return false
  end

  function t.inspect()
    local entry = t._inspectSequence[t._inspectIndex] or { false }
    t._inspectIndex = t._inspectIndex + 1
    return unpack(entry)
  end

  function t.inspectUp()
    return unpack(t._inspectUp)
  end

  function t.inspectDown()
    return unpack(t._inspectDown)
  end

  function t.drop()
    return true
  end

  function t.dropUp()
    return true
  end

  function t.dropDown()
    return true
  end

  function t.suck()
    return false
  end

  function t.suckUp()
    return false
  end

  function t.suckDown()
    return false
  end

  return t
end

-- patches the *real* os table (rather than replacing the os global
-- outright) so os.exit/os.time etc. -- which the test harness itself
-- relies on -- keep working
function M.installOs(computerId)
  os.getComputerID = function()
    return computerId
  end
end

-- doesn't actually produce JSON -- just records what it was asked to
-- serialize so a test can inspect the payload structure directly, and
-- returns a distinct placeholder string so tests can confirm that exact
-- string is the one that reaches http.post's body
function M.newTextutils()
  local calls = {}
  return {
    _calls = calls,
    serializeJSON = function(value)
      table.insert(calls, value)
      return "MOCK_JSON:" .. tostring(#calls)
    end,
  }
end

function M.newHttp()
  local calls = {}
  return {
    _calls = calls,
    post = function(url, body, headers)
      table.insert(calls, { url = url, body = body, headers = headers })
      return { getResponseCode = function() return 200 end }
    end,
  }
end

return M
