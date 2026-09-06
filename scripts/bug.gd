extends CharacterBody3D

const BUG_COLOR := Color(0.95, 0.55, 0.20)  # orange
const SPEED := 4.0

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	_build_model()
	_build_collider()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_handle_right_click(event.position)

func _physics_process(_delta: float) -> void:
	if _nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - global_position)
	direction.y = 0.0
	if direction.length() < 0.001:
		velocity = Vector3.ZERO
		return
	direction = direction.normalized()

	velocity = direction * SPEED
	look_at(global_position + direction, Vector3.UP)
	move_and_slide()

func _handle_right_click(mouse_pos: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var from := cam.project_ray_origin(mouse_pos)
	var dir := cam.project_ray_normal(mouse_pos)
	var to := from + dir * 1000.0

	var space_state := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_bodies = true
	var hit := space_state.intersect_ray(params)

	if hit.is_empty():
		return

	_nav_agent.set_target_position(hit.position)

func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)

	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 0.5
	body.mesh = body_mesh
	body.scale = Vector3(1.0, 0.6, 1.5)
	body.position = Vector3(0, 0.25, 0)
	body.material_override = _orange_mat()
	model.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.3
	head.mesh = head_mesh
	head.position = Vector3(0, 0.30, 0.45)
	head.material_override = _orange_mat()
	model.add_child(head)

	var leg_z_positions := [0.20, 0.0, -0.20]
	for z in leg_z_positions:
		_add_leg(model, Vector3(0.20, 0.08, z))
		_add_leg(model, Vector3(-0.20, 0.08, z))

func _add_leg(parent: Node3D, pos: Vector3) -> void:
	var leg := MeshInstance3D.new()
	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.04
	leg_mesh.bottom_radius = 0.04
	leg_mesh.height = 0.16
	leg.mesh = leg_mesh
	leg.position = pos
	leg.material_override = _orange_mat()
	parent.add_child(leg)

func _build_collider() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 0.5
	shape.shape = capsule
	shape.position = Vector3(0, 0.25, 0)
	add_child(shape)

func _orange_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BUG_COLOR
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat
