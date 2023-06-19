extends Node3D


var _main = null


func _ready() -> void:
	_main = get_tree().get_first_node_in_group("main")
	_copy_camera_position()


func _process(_delta: float) -> void:
	_copy_camera_position()


func _copy_camera_position() -> void:
	assert(_main != null)
	var d = _main.get_node("Camera3D").position - _main.camera_target
	$Camera3D.look_at_from_position(d.normalized() * 6, Vector3.ZERO)
