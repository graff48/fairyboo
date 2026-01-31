# FairyBoo Architecture

A multiplayer Roblox game where players pick fairy tale characters, each with unique scoring mechanics. Built as a Rojo project with a script-generated map.

## Project Structure

```
fairyboo/
├── default.project.json              # Rojo config
├── src/
│   ├── server/                       # → ServerScriptService
│   │   ├── MapBuilder.server.lua     # Generates map geometry on server start
│   │   ├── GameManager.server.lua    # Round loop, scoring, character assignment
│   │   └── CharacterAbilities.server.lua  # Per-character server-side ability logic
│   ├── client/                       # → StarterPlayerScripts
│   │   ├── CharacterController.client.lua # Input handling, Tab to open select screen
│   │   └── HUD.client.lua           # Timer, score, feedback popups, scoreboard
│   ├── shared/                       # → ReplicatedStorage.Shared
│   │   ├── GameConfig.lua            # All tuning constants (scores, timers, positions)
│   │   ├── CharacterData.lua         # Character definitions (name, color, speed, abilities)
│   │   └── Utils.lua                 # Part/model/tag/prompt creation helpers
│   └── gui/                          # → StarterGui
│       └── CharacterSelect.lua       # Character selection UI with live slot counts
```

## Communication Model

```
┌──────────────────────────────────────────────────────────┐
│ Server                                                    │
│                                                          │
│  GameManager ──BindableFunctions──► CharacterAbilities    │
│      │            AddScore                                │
│      │            GetPlayerCharacter                      │
│      │            IsRoundActive                           │
│      │                                                    │
│      ├── RemoteEvent: SelectCharacter  ◄── Client         │
│      ├── RemoteEvent: UpdateHUD        ──► Client         │
│      ├── RemoteEvent: RoundInfo        ──► Client         │
│      ├── RemoteEvent: CharacterSlots   ──► Client         │
│      └── RemoteEvent: ShowCharacterSelect ──► Client      │
└──────────────────────────────────────────────────────────┘
```

All RemoteEvents live under `ReplicatedStorage.Remotes`. BindableFunctions are used for server-to-server calls between GameManager and CharacterAbilities so they can run as separate scripts without circular requires.

## Game Loop

1. Server waits for `MIN_PLAYERS_TO_START` (default 1)
2. Intermission (15s) — character select screen shown to all players
3. Round starts (300s) — players teleported to character-appropriate spawns
4. `RunService.Heartbeat` decrements timer, fires `RoundInfo/TimeUpdate` each second
5. Round ends — scores collected, sorted, broadcast via `RoundInfo/RoundEnd`
6. 5s score display pause, then back to step 2

## Map Layout

All geometry is created by `MapBuilder.server.lua` under `workspace.Map`. Positions are defined in `GameConfig.MapPositions` as `Vector3` values.

```
[Red's House](-120,0,100) ─── [Forest Path](0,0,100) ─── [Grandma's House](120,0,100)
                                       │
                              [Village Center](0,0,0)
                              /        │        \
              [Straw House](-80,0,-60) [Stick](0,0,-80) [Brick](80,0,-60)
                              \        │        /
                            [Bears' House](0,0,-160)
                                       │
                            [Beanstalk Field](0,0,-240)
```

Ground plane is 500x600 studs centered around the map. Each location is a `Model` or set of parts parented to the `Map` folder.

## Character Mechanics

### Big Bad Wolf (1 slot)
- **Server**: Touch detection on `HumanoidRootPart` catches Pig players (+50). ProximityPrompt on straw/stick houses channels "Huff and Puff" to destroy (+30). Cooldown tracked in `wolfCatchCooldowns` table.
- **Map tags**: `Destructible`, `Destroyed` (added/removed dynamically), `StrawHouse`, `StickHouse`

### Three Little Pigs (3 slots)
- **Server**: ProximityPrompt "Repair House" on destroyed houses (+20). Passive scoring loop runs every 1s — checks if pig is within 12 studs of an intact house and wolf is within `PassiveScoreRadius` (+10/s).
- **Map tags**: `House`, `Destructible`

### Little Red Riding Hood (2 slots)
- **Server**: Polling loop (0.5s) tracks trip state in `redTripState[player]`. Trip starts within 15 studs of Red's House, completes within 15 studs of Grandma's House (+100, speed bonus up to +50). Wolf catch detection in forest area (40 stud radius). Basket collectibles spawn at tagged `BasketSpawn` points, respawn after collection.
- **Map tags**: `RedHouse`, `TripStart`, `GrandmaHouse`, `TripEnd`, `TripEndZone`, `BasketSpawn`, `Basket`

### Goldilocks (2 slots)
- **Server**: ProximityPrompts on 9 items (3 sets × 3 options). Progress tracked in `goldilocksProgress[player]` — must set `triedWrong[category]` before `JustRight` scores (+40). Bear NPC teleports through patrol points every `BearReturnInterval` seconds, catches unhidden Goldilocks within 10 studs. Hide spots make player transparent for patrol duration.
- **Map tags**: `GoldilocksItem`, `Porridge_TooHot/TooCold/JustRight`, `Chair_TooBig/TooSmall/JustRight`, `Bed_TooHard/TooSoft/JustRight`, `HideSpot`, `BearsHouse`

### Jack (2 slots)
- **Server**: ProximityPrompts on golden items on cloud platform (+30 each). Items hide and respawn after `ItemRespawnTime`. Giant NPC patrols cloud patrol points, catches Jack within `GiantDetectionRadius` studs and drops them to ground level.
- **Map tags**: `GoldenItem`, `Climbable`, `BeanstalkField`

## Tag System

Tags are implemented as `BoolValue` children (not CollectionService) via `Utils.CreateTag` / `Utils.HasTag`. This keeps tags visible in the Explorer and avoids CollectionService timing issues with streamed instances.

## Tuning

All gameplay numbers are in `GameConfig.lua`. Key sections:
- `GameConfig.Scoring.*` — point values per action
- `GameConfig.Wolf/Pig/RedRidingHood/Goldilocks/Jack` — character-specific timers, radii, speeds
- `GameConfig.MaxSlots` — max players per character
- `GameConfig.MapPositions` — world positions for all locations

## Development Steps

### High Priority

1. **Migrate tags to CollectionService** — The current `BoolValue` tag system works but doesn't integrate with Roblox's `CollectionService:GetTagged()`. Migrating would simplify queries like "find all destructible houses" and enable tag-based streaming.

2. **Pig barricade mechanic** — `GameConfig.Scoring.Pig.BuildBarricade` exists but the actual placement logic is not implemented. Needs: a ProximityPrompt at house doorways, spawning a part that blocks entry, health system (wolf destroys in N hits), cleanup on round end.

3. **Climbing mechanic for Jack** — Beanstalk segments are tagged `Climbable` but there's no actual climb controller. Needs: client-side input to toggle climb mode, custom movement along beanstalk segments (disable default gravity, move up/down with W/S), transition to normal movement on leaf platforms and cloud.

4. **Giant NPC pathfinding** — Currently the giant teleports between patrol points. Replace with smooth movement using `TweenService` or a simple lerp loop so players can see it approaching and react.

5. **Bear NPC pathfinding** — Same issue as giant. Bears teleport between patrol points instead of walking.

### Medium Priority

6. **Sound effects** — No audio exists. Add: wolf howl on catch, house collapse sound, trip-complete jingle, item pickup chime, bear growl warning, giant footsteps.

7. **Visual effects** — No particles or animations. Add: house destruction debris, wolf "huff" particle effect during channel, golden item sparkle, beanstalk sway, basket glow.

8. **Character appearance** — Players currently keep default avatars. Add character-specific accessories or mesh overlays (wolf ears, pig nose, red hood, golden curls, etc.) applied on character selection.

9. **Anti-exploit validation** — ProximityPrompts handle distance checks, but the wolf touch detection and Red's trip tracking could be spoofed. Add server-side distance validation on all scoring events.

10. **House interior collision** — The pig houses use transparent walls for the door gap area but interior collision is basic. Add proper door frames and ensure players can enter/exit smoothly.

### Low Priority

11. **Lobby area** — Add a separate spawn area for pre-game that's distinct from the Village Center, with character info boards.

12. **Data persistence** — No DataStore usage. Add: lifetime stats (wins, total score, games played), unlockable cosmetics.

13. **Mobile support** — ProximityPrompts work on mobile but the character select UI may need touch-friendly sizing. The Tab keybind for reopening character select needs a mobile alternative (button on screen).

14. **Spectator mode** — Players who join mid-round or don't select a character have nothing to do. Add camera controls to watch active players.

15. **Map variation** — The map is static. Consider randomizing tree positions, basket spawn locations, or golden item placement between rounds.

16. **Round-end rewards** — Currently scores reset each round with no persistent consequence. Add a currency or XP system that carries across rounds.
