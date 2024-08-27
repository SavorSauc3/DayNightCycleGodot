@tool
extends Node3D

# Exported variables
@export var terrain_node: Node3D
@export var num_chunks: int = 4  # Number of chunks to divide the bounding box into
@export var raycast_height_offset: float = 50.0  # Height above the terrain to start the raycast

# Function to draw a debug sphere at a specific location
func draw_debug_sphere(location: Vector3, size: float) -> void:
	var scene_root = get_tree().root.get_children()[0]
	var sphere = SphereMesh.new()
	sphere.radial_segments = 4
	sphere.rings = 4
	sphere.radius = size

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)
	material.flags_unshaded = true
	sphere.surface_set_material(0, material)

	var node = MeshInstance3D.new()
	node.mesh = sphere
	scene_root.add_child.call_deferred(node)
	node.global_transform.origin = location

# Function to calculate sub-chunk bounds, origins, and scales in two dimensions (X and Z)
func get_sub_chunk_bounds(min_bound: Vector3, max_bound: Vector3, chunk_size: int) -> Array:
	var sub_chunks = []
	max_bound.x -= 1
	min_bound.x += 1
	max_bound.z -= 1
	min_bound.z += 1
	var step_x = (max_bound.x - min_bound.x) / float(chunk_size)
	var step_z = (max_bound.z - min_bound.z) / float(chunk_size)
	
	# Y dimension is not split, so we keep it constant
	var step_y = max_bound.y - min_bound.y
	
	for x in range(chunk_size):
		for z in range(chunk_size):
			# Ensure the last chunk reaches the max bound
			var min_corner = min_bound + Vector3(x * step_x, 0, z * step_z)
			var max_corner_x = max_bound.x if x == chunk_size - 1 else min_corner.x + step_x
			var max_corner_z = max_bound.z if z == chunk_size - 1 else min_corner.z + step_z
			var max_corner = Vector3(max_corner_x, min_corner.y + step_y, max_corner_z)
			
			# Calculate the origin and scale for the current chunk
			var origin = (min_corner + max_corner) / 2
			var scale = Vector3(max_corner.x - min_corner.x, step_y, (max_corner.z - min_corner.z) * 3)
			
			# Adjust the Y position using a raycast
			var adjusted_origin = adjust_y_position(origin)

			sub_chunks.append({
				"min_corner": min_corner,
				"max_corner": max_corner,
				"origin": adjusted_origin,
				"scale": scale
			})
	
	return sub_chunks

# Function to adjust the Y position of the origin using a raycast
func adjust_y_position(origin: Vector3) -> Vector3:
	var ray_start = origin + Vector3(0, raycast_height_offset, 0)
	var ray_end = origin + Vector3(0, -raycast_height_offset * 2, 0)  # Cast downwards

	var space_state = get_world_3d().direct_space_state
	var ray_params = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(ray_params)
	
	if result:
		origin.y = result.position.y + 2
	else:
		print("No hit detected for raycast at position:", origin)

	return origin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure the terrain_node is assigned
	if terrain_node:
		# Call the get_chunk_bounds function from the terrain node
		var chunk_bounds = terrain_node.call("get_chunk_bounds") as Array
		var min_bound = chunk_bounds[0]
		var max_bound = chunk_bounds[7]

		# Calculate the sub-chunk bounds
		var sub_chunks = get_sub_chunk_bounds(min_bound, max_bound, num_chunks)

		# Process each sub-chunk
		for chunk in sub_chunks:
			# Debug: Draw spheres at each corner of the chunk (optional)
			# draw_debug_sphere(chunk["origin"], 0.5)  # Adjust the size of the spheres as needed
			
			# Copy the ProtonScatter node and attach it to ProcTerrain
			var proton_scatter = get_node("ProtonScatter").duplicate()
			if proton_scatter:
				print("Scatter Object Found")
				var proton_scatter_shape = proton_scatter.get_node("ScatterShape")
				# Update the position and scale of the ScatterShape
				proton_scatter_shape.global_transform.origin = chunk["origin"]
				proton_scatter_shape.scale = chunk["scale"]
			else:
				print("Scatter Object Not Found")
				break

			# Add the modified ProtonScatter to the terrain node
			terrain_node.add_child(proton_scatter)
			print("TERRAIN NODE ADDED")
	else:
		print("Terrain node reference is not assigned.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
