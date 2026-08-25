Config = {
  -- how far (in blocks, each of the 4 horizontal directions) to walk out
  -- from the start position while looking for a nearby inventory block
  scanRadius = 4,

  -- trigger an offload trip once this many usable slots (2-16) are free
  storageFreeSlotThreshold = 2,

  -- trigger a refuel trip once fuel drops to/below this level
  fuelThreshold = 200,

  -- send a webhook status report every N moves (forward/back/up/down)
  webhookInterval = 100,

  -- fill in your status-webhook endpoint before building; left blank,
  -- Webhook.report() is a no-op (the turtle has no access to the dev
  -- machine's .env, so this has to be a literal set here)
  webhookUrl = "http://localhost:9119",

  -- item names (turtle.getItemDetail().name) treated as valid turtle fuel
  fuelItemNames = {
    ["minecraft:coal"] = true,
    ["minecraft:charcoal"] = true,
    ["minecraft:lava_bucket"] = true,
    ["minecraft:blaze_rod"] = false,
  },

  -- block name substrings recognized as a valid external inventory
  storageBlockNames = {
    "chest", "barrel", "hopper", "shulker_box",
  },

  fuelSlot = 1,

  -- mine_room: which way successive height layers go relative to the
  -- turtle's starting position ("up" or "down")
  roomLayerDirection = "up",
}
