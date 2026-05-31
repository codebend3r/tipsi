extends CharacterBody3D

const BUG_COLOR := Color(0.95, 0.55, 0.20)  # orange

func _ready() -> void:
	_build_model()
	_build_collider()

func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"
	add_child(model)

	# Body: flattened ellipsoid via a scaled sphere
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 0.5
	body.mesh = body_mesh
	body.scale = Vector3(1.0, 0.6, 1.5)
	body.position = Vector3(0, 0.25, 0)
	body.material_override = _orange_mat()
	model.add_child(body)

	# Head: smaller sphere in front
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.3
	head.mesh = head_mesh
	head.position = Vector3(0, 0.30, 0.45)
	head.material_override = _orange_mat()
	model.add_child(head)

	# 6 legs: short cylinders, 3 per side
	var leg_z_positions := [0.20, 0.0, -0.20]
	for z in leg_z_positions:
		_add_leg(model, Vector3(0.20, 0.08, z))   # right
		_add_leg(model, Vector3(-0.20, 0.08, z))  # left

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
