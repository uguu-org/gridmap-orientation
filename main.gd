extends Node3D


const CAMERA_MOVE_KEY_SPEED = 10     # Meters per second.
const CAMERA_MOVE_MOUSE_SPEED = 0.1  # Meters per pixel.

const CAMERA_ZOOM_MIN_DISTANCE = 1
const CAMERA_ZOOM_MAX_DISTANCE = 32
const CAMERA_ZOOM_KEY_SPEED = 10    # Meters per second.
const CAMERA_ZOOM_WHEEL_SPEED = 1   # Meters per click.

# If true, show orientation indices above grid cells.
var _show_labels = true

# Index within GridMap's mesh library.
var _selected_item_index = 0

# Camera states.
var _initial_camera_position = Vector3(12, 11, 0)
var _initial_camera_target = Vector3(12, 0, -6)
var camera_target = _initial_camera_target


# Initialize grid and camera.
func _ready() -> void:
	for z in 4:
		for x in 6:
			var o = x * 4 + z
			var label = Label3D.new()
			label.text = "%d" % o
			label.name = "orientation%d" % o
			label.font_size = 100
			label.outline_size = 40
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.position = Vector3(x * 4 + 2, 2.5, z * -4 - 2)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			$OrientationLabels.add_child(label)
	
	_populate_grid()
	$Camera3D.look_at_from_position(_initial_camera_position, _initial_camera_target)


# Handle mouse movement.
func _input(event) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_camera_target"):
			_set_camera_target(event.relative * -CAMERA_MOVE_MOUSE_SPEED)
		elif Input.is_action_pressed("move_camera_position"):
			_set_camera_position(event.relative * -CAMERA_MOVE_MOUSE_SPEED)
		elif Input.is_action_pressed("rotate_camera_about_target"):
			_rotate_camera_about_target(event.relative * -CAMERA_MOVE_MOUSE_SPEED)


# Handle keyboard and mouse wheel input.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("change_display_mode"):
		_show_labels = not _show_labels
		if _show_labels:
			$OrientationLabels.show()
			_selected_item_index = (_selected_item_index + 1) % $GridMap.mesh_library.get_item_list().size()
			_populate_grid()
		else:
			$OrientationLabels.hide()

	elif Input.is_action_pressed("zoom_in"):
		_set_camera_distance(delta * -CAMERA_ZOOM_KEY_SPEED)

	elif Input.is_action_pressed("zoom_out"):
		_set_camera_distance(delta * CAMERA_ZOOM_KEY_SPEED)

	elif Input.is_action_just_released("mouse_wheel_up"):
		_set_camera_distance(-CAMERA_ZOOM_WHEEL_SPEED)

	elif Input.is_action_just_released("mouse_wheel_down"):
		_set_camera_distance(CAMERA_ZOOM_WHEEL_SPEED)
	
	elif Input.is_action_just_pressed("reset_camera"):
		$Camera3D.look_at_from_position(_initial_camera_position, _initial_camera_target)
		camera_target = _initial_camera_target

	else:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction != Vector2.ZERO:
			_set_camera_position(direction * (CAMERA_MOVE_KEY_SPEED * delta))
		direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if direction != Vector2.ZERO:
			_set_camera_target(direction * (CAMERA_MOVE_KEY_SPEED * delta))


# Adjust camera position and target.
func _set_camera_position(delta: Vector2) -> void:
	var position_delta = _get_position_delta(delta)
	$Camera3D.position += position_delta
	camera_target += position_delta


# Adjust camera direction.
func _set_camera_target(delta: Vector2) -> void:
	camera_target += _get_position_delta(delta)
	$Camera3D.look_at(camera_target)


# Adjust camera position.
func _rotate_camera_about_target(delta: Vector2) -> void:
	$Camera3D.look_at_from_position($Camera3D.position + _get_position_delta(delta), camera_target)


# Compute position delta based on current camera orientation.
func _get_position_delta(delta: Vector2) -> Vector3:
	var viewport_size = get_viewport().get_visible_rect().size
	var center = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
	var camera_normal = $Camera3D.project_ray_normal(center)
	var delta_x = camera_normal.cross(Vector3.UP)
	var delta_y = camera_normal.cross(delta_x)
	if delta_x.length_squared() < 0.00001:
		delta_x = Vector3(1, 0, 0)
		delta_y = Vector3(0, 0, -1)
	else:
		delta_x = delta_x.normalized()
		delta_y = delta_y.normalized()
	return delta_x * delta.x + delta_y * delta.y


# Adjust camera distance based on zoom action.
func _set_camera_distance(delta: float) -> void:
	var d = $Camera3D.position.distance_to(camera_target) + delta
	if d < CAMERA_ZOOM_MIN_DISTANCE:
		d = CAMERA_ZOOM_MIN_DISTANCE
	elif d > CAMERA_ZOOM_MAX_DISTANCE:
		d = CAMERA_ZOOM_MAX_DISTANCE
	$Camera3D.position = camera_target + ($Camera3D.position - camera_target).normalized() * d


# Populate grid cells with _selected_item_index.
func _populate_grid() -> void:
	var item = $GridMap.mesh_library.get_item_list()[_selected_item_index]
	for z in 4:
		for x in 6:
			var o = x * 4 + z
			var cell = Vector3i(x, 0, -z - 1)
			$GridMap.set_cell_item(cell, item, o)
