# tipsi

A small isometric pixel-art game built with Godot 4.3. You control an orange bug on a colorful 40×40 tile grid; right-click to move.

## Stack

- **Engine:** Godot 4.3, Forward Plus renderer
- **Language:** GDScript
- **Targets:** macOS, Windows Desktop (x86_64)

## Running from source

1. Install Godot 4.3 (Standard build, not .NET).
2. Open `project.godot` in the editor.
3. Press **F5** to play, or run the editor's *Run Project* action. The main scene is `scenes/main.tscn`.

The game window is 1280×720 with `keep`-aspect stretching.

## Project layout

```
project.godot          # engine config: main scene, window size, renderer
export_presets.cfg     # macOS + Windows export presets
scenes/
  main.tscn            # root scene; SubViewport pixel-render wrapper
  world.tscn           # 3D world: nav region, ground, bug, camera, sun
  bug.tscn             # the player character (CharacterBody3D + NavigationAgent3D)
scripts/
  ground.gd            # builds the 40×40 colored tile grid + ground collider
  bug.gd               # input handling, navigation, procedural bug model
  iso_camera.gd        # orthographic follow camera
exports/               # build artifacts (gitignored)
docs/                  # design notes and plans
```

## How it works

### Pixel-art rendering (`scenes/main.tscn`)

The root scene wraps the entire 3D world inside a `SubViewport` sized **320×180**. The viewport's output texture is then drawn full-screen by a `SubViewportContainer` with nearest-neighbor filtering, producing a chunky pixelated look while the underlying 3D scene is rendered at low resolution. MSAA and screen-space AA are disabled to keep pixels crisp.

### World (`scenes/world.tscn`)

- **NavigationRegion3D** with a hand-authored `NavigationMesh` covering the `[-1, 41]` square on both X and Z — large enough to encompass the 40×40 tile grid plus a one-tile border for the navigation agent.
- **Ground** (`scripts/ground.gd`) procedurally spawns 1,600 `BoxMesh` tiles in a 40×40 grid at `y=0`. Each tile gets a random color from an 8-color rainbow palette; the RNG is seeded (`RNG_SEED = 12345`) so the layout is deterministic. A single `StaticBody3D` with a `BoxShape3D` collider is centered under the tiles so rays can hit the ground.
- **Bug** is instanced at `(20, 0, 20)` — the center of the grid.
- **IsoCamera** is an orthographic `Camera3D` (size 12) pointed at the bug.
- **Sun** is a single `DirectionalLight3D` lighting everything from above-front.

### The bug (`scripts/bug.gd`)

A `CharacterBody3D` that is built entirely from primitives at runtime (no imported meshes):

- Body: stretched orange `SphereMesh`
- Head: smaller orange sphere offset forward
- Six legs: thin orange `CylinderMesh` pairs at three Z positions
- Collider: capsule of radius 0.3, height 0.5

Movement uses a `NavigationAgent3D` child:

- `_unhandled_input` listens for **right mouse button** clicks.
- The click is projected into a ray via the active camera; a physics ray-cast finds the hit point on the ground collider.
- The hit point is set as the agent's target. `_physics_process` then asks the agent for the next path position each frame, normalizes the direction, applies `SPEED = 4.0`, and calls `move_and_slide()`.
- The bug rotates to face its travel direction via `look_at`.

### Camera (`scripts/iso_camera.gd`)

- `PROJECTION_ORTHOGONAL`, size 12, fixed offset of `Vector3(10, 10, 10)` from the target — the classic isometric angle.
- Each frame `global_position` lerps toward `target + OFFSET` at `FOLLOW_SPEED = 5.0`, producing a smooth follow rather than a snap.
- The `target_path` is exported and wired in `world.tscn` to `../Bug`.

## Controls

| Input              | Action              |
| ------------------ | ------------------- |
| Right mouse button | Move bug to clicked ground point |

## Exporting

Two presets are configured in `export_presets.cfg`:

- **macOS** → `exports/tipsi.app` (bundle id `com.tipsi.game`, version `0.1.0`)
- **Windows Desktop** → `exports/tipsi.exe` (x86_64, embedded PCK)

Export from *Project → Export…* in the editor, or via `godot --headless --export-release "<preset name>" <output path>`. The `exports/` directory is gitignored.

## Tuning knobs

Common values you'll want to tweak live as constants at the top of the relevant script:

- `scripts/ground.gd` — `GRID_SIZE`, `TILE_SIZE`, `TILE_HEIGHT`, `RNG_SEED`, `PALETTE`
- `scripts/bug.gd` — `BUG_COLOR`, `SPEED`
- `scripts/iso_camera.gd` — `OFFSET`, `FOLLOW_SPEED`, and the `size` set in `_ready`
- `scenes/main.tscn` — the `SubViewport`'s `size` controls pixel density

If you change `GRID_SIZE`, update the `NavigationMesh` vertices in `scenes/world.tscn` (currently `[-1, 41]`) so the navmesh still covers the playable area.
