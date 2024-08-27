extends Camera3D

# Movement speed
var speed: float = 5.0

# Mouse sensitivity
var mouse_sensitivity: float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Capture the mouse so it doesn't leave the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Handle camera movement
	var direction: Vector3 = Vector3.ZERO
	
	# Horizontal movement (WASD)
	if Input.is_action_pressed("up"):
		direction -= transform.basis.z
	if Input.is_action_pressed("down"):
		direction += transform.basis.z
	if Input.is_action_pressed("left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("right"):
		direction += transform.basis.x

	# Normalize direction to prevent faster diagonal movement and apply movement
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		position += direction * speed * delta

	# Handle camera rotation with mouse movement
	var mouse_movement = Input.get_last_mouse_velocity() * mouse_sensitivity
	rotate_y(-mouse_movement.x * delta)  # Rotate around the Y axis for horizontal movement
	rotate_x(-mouse_movement.y * delta)  # Rotate around the X axis for vertical movement
	
	# Clamp the X rotation to prevent the camera from flipping upside down
	rotation.x = clamp(rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
