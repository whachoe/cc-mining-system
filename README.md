CJPA's Mining Setup

This is a set of Lua scripts i use to help me in Minecraft using the [cc:tweaked](https://tweaked.cc/) mod. 
I am using these primarily in the Modpack [Create - Astral](https://www.curseforge.com/minecraft/modpacks/create-astral/files/4369495). Create Astral Github: https://github.com/Laskyyy/Create-Astral. 

These scripts are set up to be modular and different parts are runnable separately from eachother, but some of them build on top of other scripts. 

Common features of all scripts:
- Use only the regular Turtles with a pickaxe equiped. No GPS or other extensions unless stated explicitly by the developer.
- When starting up, it scans the immediate environment (in a radius that's configurable in the scripts) for the closest inventory (chest, barrel, hopper, ...) and will transfer all mined material to that storage whenever the internal storage is at risk of being full (say: when there's only 10% internal storage left). 
- Also returns to that inventory when fuel is below a certain limit to refuel from that inventory.
- It keeps fuel in slot 1 and tops up whenever it finds more while mining. Will top up fuel too whenever it returns to offload it's internal storage.
- Returns to the starting spot after the task is done. 
- Every 100 moves, it calls a webhook and transmits a status-message (turtle id, location in the world, location of starting spot, fuel capacity, amount of moves it made, list of inventory, location of external inventory it scanned when starting up, other interesting info...)
- Keep the sourcecode in separate files for readability but concatenate them together when it's time to transfer them to the game.
- Distribution method: Pastebin (credentials can be found in `.env`)
- Do not commit the `.env` file into Git

    


Here's a list of stuff i want to accomplish"
1. A Lua script to mine a rectangular room (arguments: Width by Length by Height). 
2. A Lua script to mine a staircase down until bedrock is hit (arguments: Width by Length).

## Layout

```
src/lib/        shared modules (config, inventory, movement, world position, scan, storage, webhook, bootstrap)
src/programs/   mine_room.lua, mine_staircase.lua -- the actual turtle programs
build/          build.sh (concatenate) and deploy.sh (upload to Pastebin)
tests/          lua5.1 unit tests against a mocked turtle/CC:Tweaked API
dist/           build output, gitignored
```

## Usage

```
mine_room <width> <length> <height> [worldX worldY worldZ worldFacing]
mine_staircase <width> <length> [worldX worldY worldZ worldFacing]
```

The turtle has no GPS or compass, so it only ever tracks its position
relative to wherever it started (see [src/lib/03_movement.lua](src/lib/03_movement.lua)).
If you want webhook reports to include an absolute world position instead
of just the relative one, pass the turtle's real starting coordinates and
which way it's facing as the last 4 arguments -- read both off your own F3
screen before starting the turtle (`worldFacing` is one of `north`,
`south`, `east`, `west`). Leave them off and it just reports relative
position, same as before.

Edit `src/lib/01_config.lua` before building to set your webhook URL, scan
radius, fuel/storage thresholds, and (for `mine_room`) whether height layers
go up or down from the starting position.

## Running tests

The pure logic (odometry, fuel/storage thresholds, storage-scan targeting)
has unit tests that run against a mocked CC:Tweaked API, no Minecraft
needed:

```
bash tests/run_tests.sh
```

Real in-game behavior (does it actually mine correctly, does the webhook
fire, does it find your chest) still needs manual verification on an actual
turtle.

## Build & deploy

`build.sh` concatenates `src/lib/*.lua` with one program file into a single
`dist/<name>.lua`, since a turtle runs one flat file with no `require`:

```
bash build/build.sh mine_room
bash build/build.sh mine_staircase
```

`deploy.sh` builds and then uploads the result to Pastebin under your
account, printing the `pastebin get <code> <name>` command to run in-game:

```
bash build/deploy.sh mine_room
```

This needs `PASTEBIN_USER`, `PASTEBIN_PASSWORD`, and `PASTEBIN_API_DEV_KEY`
in `.env.local` (the dev key comes from https://pastebin.com/api and is
separate from your login password).

Prerequisite on the Minecraft/CC:Tweaked side: the `http` API must be
enabled and the webhook's target domain allowlisted in the server's
CC:Tweaked config, or `Webhook.report()` will silently fail to reach it.

