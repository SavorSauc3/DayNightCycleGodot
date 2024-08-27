extends WorldEnvironment

var directional_light: DirectionalLight3D
var ui: Control
var time_in_scene: float = 12.0  # Start at 12:00 PM
var time_of_day: String = "Day"  # Can be "Day", "Night", "Dawn", or "Dusk"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Replace "DirectionalLight" with the actual name or path to your light node if necessary
	directional_light = get_node("../DirectionalLight3D")
	ui = get_node("../UI")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_sun_position(delta)
	update_shader_parameters()
	ui.get_node("TimeIndicator/CommandCanvas/Label").text = "Current Time: %02d:%02d - %s" % [get_hour(), get_minute(), time_of_day]
	
func update_sun_position(delta: float) -> void:
	# Rotate the light around the X-axis to simulate the sun's movement
	var rotation_speed = 0.1  # Adjust the speed as needed
	directional_light.rotate_x(rotation_speed * delta)
	
	# Update the time based on the sun's rotation
	update_time_based_on_sun()
	update_time_of_day()
	
func update_time_based_on_sun() -> void:
	# Assuming 360 degrees represents a full 24-hour day
	var sun_angle = directional_light.rotation_degrees.x
	time_in_scene = (sun_angle / 360.0) * 24.0
	
	# Wrap around to ensure time stays within 24 hours
	if time_in_scene >= 24.0:
		time_in_scene -= 24.0
	elif time_in_scene < 0.0:
		time_in_scene += 24.0

func update_time_of_day() -> void:
	# Determine the time of day based on the hour
	if time_in_scene >= 11.0 and time_in_scene < 12.0:
		time_of_day = "Dawn"
	elif time_in_scene >= 12.0 and time_in_scene < 23.0:
		time_of_day = "Day"
	elif time_in_scene >= 23.0 and time_in_scene < 24.0 or time_in_scene >= 0.0 and time_in_scene < 1.0:
		time_of_day = "Dusk"
	else:
		time_of_day = "Night"

# Gets the hour of day
func get_hour() -> int:
	return int(time_in_scene)
# Gets the minute of day
func get_minute() -> int:
	return int((time_in_scene - get_hour()) * 60)
# Updates the crescent of the moon
func update_moon_crescent(sky_material: ShaderMaterial, moon_crescent_increment: float) -> void:
	# Directly use get_shader_param and set_shader_param on the sky_material
	var current_moon_crescent = sky_material.get_shader_parameter("moon_crescent")
	# Update moon_crescent with cycling behavior
	var new_moon_crescent = current_moon_crescent + moon_crescent_increment
		
	# Cycle the crescent value between -0.3 and 0.3
	if new_moon_crescent > 0.3:
		new_moon_crescent = -0.3
	elif new_moon_crescent < -0.3:
		new_moon_crescent = 0.3
		
	sky_material.set_shader_parameter("moon_crescent", new_moon_crescent)
	
# Update the sky shaders parameters
func update_shader_parameters() -> void:
	var env = get_environment()
	var sky_material = env.sky.sky_material
	
	# Assuming "moon_crescent_amount" is a shader parameter you want to modify
	if sky_material is ShaderMaterial and time_of_day == "Day":
		update_moon_crescent(sky_material, 0.0001)

	# Adjust other shader parameters based on time of day, if needed
	match time_of_day:
		"Day":
			sky_material.set_shader_parameter("sky_brightness", 0.8)
		"Night":
			sky_material.set_shader_parameter("sky_brightness", 0.2)
		"Dawn", "Dusk":
			sky_material.set_shader_parameter("sky_brightness", 0.5)
