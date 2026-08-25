Webhook = {}

function Webhook.buildPayload()
  return {
    turtleId = os.getComputerID(),
    position = { x = Movement.pos.x, y = Movement.pos.y, z = Movement.pos.z },
    facing = Movement.facing,
    startPosition = Movement.start,
    fuelLevel = turtle.getFuelLevel(),
    fuelLimit = turtle.getFuelLimit(),
    moveCount = Movement.moveCount,
    inventory = Inventory.snapshot(),
    storageLocation = Storage.location,
    worldPosition = WorldPosition.current(), -- nil unless a real start position was given
  }
end

function Webhook.report()
  if Config.webhookUrl == nil or Config.webhookUrl == "" then
    return
  end
  local body = textutils.serializeJSON(Webhook.buildPayload())
  http.post(Config.webhookUrl, body, { ["Content-Type"] = "application/json" })
end

-- called after every move; only actually reports every Config.webhookInterval
function Webhook.maybeReport()
  if Movement.moveCount > 0 and Movement.moveCount % Config.webhookInterval == 0 then
    Webhook.report()
  end
end
