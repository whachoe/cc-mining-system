-- Minimal assertion harness (no busted/luarocks dependency needed).
local Harness = {}
local total = 0
local failures = 0

function Harness.check(condition, message)
  total = total + 1
  if not condition then
    failures = failures + 1
    print("FAIL: " .. (message or "assertion failed"))
  end
end

function Harness.equal(actual, expected, message)
  local label = string.format(
    "%s (expected %s, got %s)",
    message or "values differ",
    tostring(expected),
    tostring(actual)
  )
  Harness.check(actual == expected, label)
end

function Harness.finish()
  print(string.format("%s: %d/%d checks passed", arg and arg[0] or "test", total - failures, total))
  os.exit(failures == 0 and 0 or 1)
end

return Harness
