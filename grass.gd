extends MultiMeshInstance3D

@export var terrain_node: Node3D  # Reference to the terrain node
@export var grass_mesh: Mesh  # Grass mesh to be used in MultiMeshInstance3D
@export var grass_density: int = 1000  # Number of grass instances
@export var grass_spawned: bool = false
func _ready():
	pass # Nothing to do on startup

# Add a debug sphere at a global location
func draw_debug_sphere(location, size):
	var scene_root = get_tree().root.get_children()[0]
	var sphere = SphereMesh.new()
	sphere.radial_segments = 4
	sphere.rings = 4
	sphere.radius = size
	sphere.height = size * 2

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)
	material.flags_unshaded = true
	sphere.surface_set_material(0, material)
	
	var node = MeshInstance3D.new()
	node.mesh = sphere
	scene_root.add_child.call_deferred(node)
	node.global_transform.origin = location
	
func _physics_process(delta: float) -> void:
	if grass_spawned == false:
		# distribute_grass()
		grass_spawned = true
		
func distribute_grass():
	var multi_mesh = MultiMesh.new()
	self.multimesh = multi_mesh
	multi_mesh.mesh = grass_mesh
	multi_mesh.transform_format = RenderingServer.MULTIMESH_TRANSFORM_3D

	var terrain_mesh_data = terrain_node.call("get_generated_mesh_data")
	print("GOT MESH DATA")

	var bounds = terrain_mesh_data[1]  # Bounds of the chunk
	for bound in bounds:
		draw_debug_sphere(bound, 0.5)

	multi_mesh.instance_count = grass_density

	var ray_params = PhysicsRayQueryParameters3D.new()
	var space_state = get_world_3d().direct_space_state

	for i in range(multi_mesh.instance_count):
		var x = randf_range(bounds[0].x, bounds[1].x)
		var z = randf_range(bounds[0].z, bounds[4].z)
		var position = Vector3(x, bounds[0].y + 100, z)  # Start far above the terrain

		ray_params.from = position
		ray_params.to = position - Vector3.UP * 100  # Ensure this length is adequate

		ray_params.collision_mask = 1  # Ensure this matches your terrain's collision layer

		var result = space_state.intersect_ray(ray_params)

		if result:
			var terrain_position = result.position
			# Ensure the grass is flush with the terrain
			var rotation = Vector3(0, randf() * TAU, 0)
			var scale = Vector3(1, randf() * 0.5 + 0.75, 1)
			var transform = Transform3D()

			transform.basis = Basis().rotated(Vector3.UP, rotation.y)
			transform.origin = terrain_position
			transform = transform.scaled(scale)

			multi_mesh.set_instance_transform(i, transform)
		else:
			print("No intersection for position:", position)
