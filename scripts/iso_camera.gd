extends Camera3D

const OFFSET := Vector3(10, 10, 10)

@export var target_path: NodePath

func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = 12.0

	var target := _get_target()
	if target:
		global_position = target.global_position + OFFSET
		look_at(target.global_position, Vector3.UP)

func _get_target() -> Node3D:
	if target_path.is_empty():
		return null
	var node := get_node_or_null(target_path)
	return node as Node3D
