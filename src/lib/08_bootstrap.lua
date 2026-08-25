Bootstrap = {}

-- common startup for every program: reserve the fuel slot, scan for the
-- nearest storage block, wire up the after-every-move checks, and send an
-- initial status report so a run that quits early still leaves a trace of
-- having started (and what its starting fuel/position/storage state was)
function Bootstrap.init()
  turtle.select(Config.fuelSlot)
  Inventory.topUpFuel(turtle.getFuelLimit())

  local loc = Scan.findStorage()
  if loc ~= nil then
    Storage.setLocation(loc)
  end

  Movement.addMoveHook(function()
    Storage.storageCheck()
    Storage.refuelCheck()
    Webhook.maybeReport()
  end)

  Webhook.report()
end

-- common shutdown for every program: return to the exact start position
-- and orientation, and send a final status report
function Bootstrap.finish()
  Movement.returnToStart()
  Webhook.report()
end
