extends Node3D

const GRID_SIZE := 40
const TILE_SIZE := 1.0
const TILE_HEIGHT := 0.05
const RNG_SEED := 12345

const PALETTE: Array[Color] = [
	Color(0.90, 0.30, 0.30),  # red
	Color(0.95, 0.55, 0.20),  # orange
	Color(0.95, 0.85, 0.25),  # yellow
	Color(0.45, 0.80, 0.35),  # green
	Color(0.30, 0.75, 0.75),  # teal
	Color(0.30, 0.50, 0.90),  # blue
	Color(0.60, 0.35, 0.80),  # purple
	Color(0.90, 0.50, 0.75),  # pink
]

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED
	_build_tiles(rng)
	_build_ground_collider()

func _build_tiles(rng: RandomNumberGenerator) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(TILE_SIZE, TILE_HEIGHT, TILE_SIZE)

	for x in GRID_SIZE:
		for z in GRID_SIZE:
			var tile := MeshInstance3D.new()
			tile.mesh = mesh
			tile.position = Vector3(x, 0.0, z)

			var mat := StandardMaterial3D.new()
			mat.albedo_color = PALETTE[rng.randi() % PALETTE.size()]
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			tile.material_override = mat

			add_child(tile)

func _build_ground_collider() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GRID_SIZE, 0.1, GRID_SIZE)
	shape.shape = box
	body.add_child(shape)
	# Center the collider under the tiles. Tile (x,z) sits at world (x, 0, z),
	# so the grid spans [0, GRID_SIZE-1] on each axis. Center is (GRID_SIZE-1)/2.
	body.position = Vector3((GRID_SIZE - 1) / 2.0, 0.0, (GRID_SIZE - 1) / 2.0)
	add_child(body)
