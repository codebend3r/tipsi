# Tipsi — Basic Isometric Pixelated Game (Design)

**Date:** 2026-05-31
**Status:** Approved design — ready for implementation plan
**Repo:** `/Users/snowball/Developer/git/tipsi` (empty repo, fresh start)

## Goal

A minimal, playable Godot 4 desktop game: an orange low-poly bug walks around a flat, randomly-colored 40×40 tile plain via right-click-to-move controls (StarCraft-style). Renders through a 320×180 viewport for a heavy pixelated look. Exports to `.exe` (Windows) and `.app` (macOS) from the Godot editor.

Scope is deliberately tiny — no enemies, items, UI, sound, or game loop. This is the foundation that future features sit on top of.

## Tech stack

- **Engine:** Godot 4 (latest stable 4.x)
- **Language:** GDScript
- **Target platforms:** Windows desktop (`.exe`) and macOS desktop (`.app`)
- **Rendering:** Godot's Forward+ renderer, 3D orthographic camera, sub-viewport pixelation

Godot was chosen over Unity / Unreal / Bevy because:
- Built-in `NavigationAgent3D` makes click-to-move ~20 lines of code.
- One-click export to `.exe`/`.app` from the editor.
- Lightweight (~30–50 MB bundles, fast iteration).
- GDScript gives a hot-reload edit loop without a compile step.

## Design decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Ground style | Random colored tile grid | Most obvious motion reference — every tile is a different color |
| Map size | 40 × 40 tiles | ~15–20s to cross; meaningful but not tedious |
| Move input | Right-click on ground | StarCraft-faithful; left-click reserved for future selection/UI |
| Camera | Fixed isometric angle, smoothly follows bug | Classic Diablo / SC1 feel; less code than edge-pan |
| Bug visual | Low-poly: body + head + 6 leg primitives, all orange | Reads as a bug from the iso camera; no animation in v1 |
| Pixelation | 320×180 render target, nearest-neighbor upscale | Strong "90s pixel game" feel |
| Pathfinding | `NavigationAgent3D` on baked `NavigationRegion3D` | Free obstacle-avoidance later for the cost of ~5 extra lines |

## Architecture — scene tree

```
Main (Node3D)                                  scenes/main.tscn
├── PixelViewport (SubViewportContainer)       fills window, stretch=true, filter=Nearest
│   └── SubViewport (320×180)                   snap_2d_transforms_to_pixel=true
│       └── World (Node3D)                      scenes/world.tscn
│           ├── Ground (Node3D)                 scripts/ground.gd
│           │   ├── (40×40 colored MeshInstance3D tiles, generated at _ready)
│           │   └── StaticBody3D + CollisionShape3D  (single 40×40 box for raycast)
│           ├── NavigationRegion3D              (bakes nav mesh over Ground at load)
│           ├── Bug (CharacterBody3D)           scenes/bug.tscn + scripts/bug.gd
│           │   ├── Model (Node3D)              body + head + 6 legs primitives
│           │   ├── NavigationAgent3D
│           │   └── CollisionShape3D            CapsuleShape3D(radius=0.3, height=0.5)
│           └── IsoCamera (Camera3D)            scripts/iso_camera.gd, orthographic
└── CanvasLayer                                 (empty, reserved for future UI/debug)
```

Three components, one job each:
- **Ground** generates the colored tile grid and owns the raycast collider.
- **Bug** owns its own movement — reads input, asks `NavigationAgent3D` for a path, walks it.
- **IsoCamera** owns smooth-follow on the bug's position.

`Main` wires the references at startup; components don't reach into each other.

## Click-to-move flow

1. Player right-clicks anywhere in the window.
2. `bug.gd._unhandled_input(event)` catches `InputEventMouseButton` (`button_index == MOUSE_BUTTON_RIGHT`, `pressed == true`).
3. Build a ray from the camera through the mouse position:
   - `from = camera.project_ray_origin(mouse_pos)`
   - `dir  = camera.project_ray_normal(mouse_pos)`
4. Cast the ray with `get_world_3d().direct_space_state.intersect_ray(params)` against the ground collider.
5. If a hit exists, call `nav_agent.set_target_position(hit.position)`.
6. In `_physics_process(delta)`:
   - If `nav_agent.is_navigation_finished()`: `velocity = Vector3.ZERO`
   - Else: `next = nav_agent.get_next_path_position()`, `dir = (next - global_position).normalized()`, `velocity = dir * SPEED`, `look_at(global_position + dir)`, `move_and_slide()`.

Constants: `SPEED = 4.0` (units/sec). Map units are tile-sized so this crosses ~4 tiles/sec.

## Level generation

`ground.gd` runs once in `_ready`:

- Seed a `RandomNumberGenerator` with a fixed seed (e.g. `12345`) so the map is reproducible. Seed is a constant at the top of the script — easy to change.
- Define a palette: 8 distinct hues (red, orange, yellow, green, teal, blue, purple, pink) as `Color` constants.
- Loop `x ∈ [0, 40)`, `z ∈ [0, 40)`. For each cell:
  - Instance a `MeshInstance3D` with a `BoxMesh(size = Vector3(1, 0.05, 1))`.
  - Position it at `Vector3(x, 0, z)`.
  - Assign a `StandardMaterial3D` with `albedo_color = palette[rng.randi() % palette.size()]` and `texture_filter = NEAREST`.
  - Add it as a child of `Ground`.
- A single `StaticBody3D` with `CollisionShape3D(BoxShape3D(size = Vector3(40, 0.1, 40)))` centered under the tiles handles raycast hits (no per-tile colliders).

Performance note: 1600 tiles × one material each is fine for a prototype. If it ever lags, swap to a single `MultiMeshInstance3D` with per-instance color.

## Pixelation pipeline

`Main.tscn` setup:

- `SubViewportContainer`: `stretch = true`, `texture_filter = NEAREST`, anchored to fill the window.
- `SubViewport` child: `size = Vector2i(320, 180)`, `snap_2d_transforms_to_pixel = true`, `snap_2d_vertices_to_pixel = true`, `msaa_3d = DISABLED`, `screen_space_aa = DISABLED`.
- `IsoCamera (Camera3D)`: `projection = ORTHOGONAL`, `size ≈ 12` (units of world width visible), rotation `(-30°, 45°, 0°)` for the classic iso angle.
- Window project settings: resizable, default `1280 × 720` (clean 4× upscale of 320×180).

## Camera follow

`iso_camera.gd`:

- Has an exported `target: NodePath` (set to the Bug at editor time).
- Stores a constant `OFFSET = Vector3(10, 10, 10)` (the fixed iso vector — distance + angle baked in).
- In `_process(delta)`: `global_position = global_position.lerp(target.global_position + OFFSET, 5.0 * delta)`.
- Rotation is set once in `_ready` (`look_at(target.global_position)`) and never changes.

## File layout

```
tipsi/
├── project.godot
├── scenes/
│   ├── main.tscn        # root scene — SubViewport pipeline
│   ├── world.tscn       # World + Ground + NavRegion + Bug instance + IsoCamera
│   └── bug.tscn         # the orange bug rig (body + head + 6 legs)
├── scripts/
│   ├── ground.gd        # generates 40×40 colored tile grid
│   ├── bug.gd           # right-click input + nav-agent walking
│   └── iso_camera.gd    # smooth follow
├── export_presets.cfg   # Windows + macOS export configs
└── docs/superpowers/specs/2026-05-31-tipsi-basic-iso-game-design.md
```

## Export to `.exe` / `.app`

From the Godot editor:

1. `Project → Export → Add… → Windows Desktop` and `Project → Export → Add… → macOS`.
2. First time only: editor prompts to download "export templates" — one click.
3. `tipsi.app` (macOS) — unsigned by default; user will see a Gatekeeper warning on first run unless code-signed.
4. `tipsi.exe` + `tipsi.pck` (Windows) — or tick "Embed PCK" for a single-file `.exe`.
5. Both come out around 30–50 MB.

## Testing approach

For a prototype this small, formal unit tests aren't worth the overhead. Validation is manual:

- **Movement smoke test:** Launch project, right-click in 5 spots around the map — bug walks to each and stops.
- **Camera test:** Right-click far edges of the map — camera follows without overshoot or jitter.
- **Pixelation test:** Window resize doesn't introduce bilinear blur; pixels remain crisp.
- **Tile colors:** Map shows visibly different colors across tiles; with a fixed seed, the layout is identical across runs.
- **Export test:** Both `.exe` and `.app` launch and behave identically to the editor.

## What's explicitly out of scope (v1)

- Animation on the bug (no leg-wiggle, no head bob)
- Sound effects / music
- Enemies, items, combat, inventory
- Multiple levels or level loading
- Saving / loading
- UI (menu, HUD, health bar)
- Camera zoom or rotation
- Pause functionality
- Settings / options screen
- Networking
- Code signing for the macOS `.app`

Each of these is a future spec, not a stretch goal for v1.

## Open assumptions

- Godot 4.x (any recent point release should work; assume 4.3+).
- Developer machine has macOS (per environment); cross-compiling to Windows from macOS works fine via Godot's export templates.
- No version-control conventions yet for this repo (single dev, single branch).
