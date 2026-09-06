extends Camera3D

const OFFSET := Vector3(10, 10, 10)
const FOLLOW_SPEED := 5.0

@export var target_path: NodePath

var _target: Node3D = null

func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = 12.0
	_target = _get_target()
	if _target:
		global_position = _target.global_position + OFFSET
		look_at(_target.global_position, Vector3.UP)

func _process(delta: float) -> void:
	if _target == null:
		return
	var desired := _target.global_position + OFFSET
	global_position = global_position.lerp(desired, FOLLOW_SPEED * delta)

func _get_target() -> Node3D:
	if target_path.is_empty():
		return null
	var node := get_node_or_null(target_path)
	return node as Node3D
