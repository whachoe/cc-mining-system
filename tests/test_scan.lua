local Harness = dofile("tests/harness.lua")
local MockCC = dofile("tests/mock_cc.lua")

local function loadScanLibs()
  dofile("src/lib/01_config.lua")
  dofile("src/lib/02_inventory.lua")
  dofile("src/lib/03_movement.lua")
  dofile("src/lib/05_scan.lua")
end

-- storage found partway through the scan radius
turtle = MockCC.newTurtle()
turtle._inspectSequence = {
  { false }, -- open air, step forward
  { true, { name = "minecraft:chest" } }, -- found
}
loadScanLibs()
Config.scanRadius = 5

local foundA = Scan.findStorage()
Harness.check(foundA ~= nil, "storage found within the scan radius")
if foundA then
  Harness.equal(foundA.mode, "side", "found storage is reported as a side approach")
  Harness.equal(foundA.facing, 0, "found storage direction is the first facing tried")
  Harness.equal(foundA.standPos.z, 1, "stand position is one step out, before the chest")
end
Harness.equal(Movement.pos.x, 0, "turtle returns to start x after a successful scan")
Harness.equal(Movement.pos.z, 0, "turtle returns to start z after a successful scan")
Harness.equal(Movement.facing, 0, "turtle faces the original direction after a successful scan")

-- nothing nearby: scan exhausts its radius in every direction and gives up
turtle = MockCC.newTurtle()
loadScanLibs()
Config.scanRadius = 2

local foundB = Scan.findStorage()
Harness.equal(foundB, nil, "no storage found returns nil")
Harness.equal(Movement.pos.x, 0, "turtle returns to start x after an unsuccessful scan")
Harness.equal(Movement.pos.z, 0, "turtle returns to start z after an unsuccessful scan")

-- storage exactly at the last allowed step within the radius
turtle = MockCC.newTurtle()
turtle._inspectSequence = {
  { false },
  { false },
  { true, { name = "minecraft:barrel" } }, -- 3rd inspect call
}
loadScanLibs()
Config.scanRadius = 3

local foundC = Scan.findStorage()
Harness.check(foundC ~= nil, "storage found exactly at the scan radius boundary")
if foundC then
  Harness.equal(foundC.standPos.z, 2, "stand position reflects the two steps taken first")
end

-- storage just beyond the configured radius is never reached, even after
-- all 4 directions' worth of budget (radius 2 x 4 directions = 8 calls)
-- has been spent
turtle = MockCC.newTurtle()
local beyondRadiusSequence = {}
for _ = 1, 2 * 4 do
  table.insert(beyondRadiusSequence, { false })
end
table.insert(beyondRadiusSequence, { true, { name = "minecraft:barrel" } })
turtle._inspectSequence = beyondRadiusSequence
loadScanLibs()
Config.scanRadius = 2 -- only 2 steps are allowed per direction

local foundD = Scan.findStorage()
Harness.equal(foundD, nil, "storage just beyond the scan radius is not found")
Harness.equal(Movement.pos.z, 0, "turtle still returns to start after hitting the radius limit")

Harness.finish()
