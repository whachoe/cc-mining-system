Bootstrap = {}

-- common startup for every program: reserve the fuel slot, scan for the
-- nearest storage block, and wire up the after-every-move checks
function Bootstrap.init()
  turtle.select(Config.fuelSlot)

  local loc = Scan.findStorage()
  if loc ~= nil then
    Storage.setLocation(loc)
  end

  Movement.addMoveHook(function()
    Storage.storageCheck()
    Storage.refuelCheck()
    Webhook.maybeReport()
  end)
end

-- common shutdown for every program: return to the exact start position
-- and orientation, and send a final status report
function Bootstrap.finish()
  Movement.returnToStart()
  Webhook.report()
end
