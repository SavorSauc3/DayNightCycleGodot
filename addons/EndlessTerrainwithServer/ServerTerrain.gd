@tool
extends Node3D

@export_range(20, 400, 1) var Terrain_Size := 100
@export_range(1, 100, 1) var resolution := 30
const center_offset := 0.5
@export var Terrain_Max_Height = 5
@export var noise_offset = 0.5
@export var create_collision = true  # Ensure this is true to generate collision

@export var material: Material
@export var noise: FastNoiseLite

var mesh_instance: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: ConcavePolygonShape3D
var mesh_data = []
var mesh: ArrayMesh

@export var chunk_position := Vector3() 
var chunk_transform = Transform3D()

func _ready():
	# Access existing nodes by their names in the scene tree
	mesh_instance = get_node_or_null("MeshInstance")
	collision_body = get_node_or_null("CollisionBody")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance"
		add_child(mesh_instance)
	
	if not collision_body:
		collision_body = StaticBody3D.new()
		collision_body.name = "CollisionBody"
		add_child(collision_body)

	generate_terrain()

func generate_terrain():
	delete_chunk()
	var surftool = SurfaceTool.new()

	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in resolution + 1:
		for x in resolution + 1:
			var percent = Vector2(x, z) / resolution
			var pointOnMesh = Vector3((percent.x - center_offset), 0, (percent.y - center_offset))
			var vertex = pointOnMesh * Terrain_Size
			vertex.y = noise.get_noise_2d(vertex.x * noise_offset, vertex.z * noise_offset) * Terrain_Max_Height
			var uv = Vector2()
			uv.x = percent.x
			uv.y = percent.y
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
	var vert = 0
	for z in resolution:
		for x in resolution:
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution + 1)
			surftool.add_index(vert + resolution + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution + 2)
			vert += 1
		vert += 1
	surftool.generate_normals()
	mesh_data = surftool.commit_to_arrays()

	# Create the mesh and make it accessible
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	
	# Assign the generated mesh to the existing MeshInstance3D
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.transform = chunk_transform
	chunk_transform.origin = chunk_position
	
	if create_collision:
		generate_collision()

func generate_collision():
	clear_collision()
	
	# Create and configure ConcavePolygonShape3D
	collision_shape = ConcavePolygonShape3D.new()
	collision_shape.set_faces(mesh.get_faces())
	
	# Create or reuse the CollisionShape3D node and assign the ConcavePolygonShape3D to it
	var collision_shape_node = collision_body.get_node_or_null("CollisionShape")
	if not collision_shape_node:
		collision_shape_node = CollisionShape3D.new()
		collision_shape_node.name = "CollisionShape"
		collision_body.add_child(collision_shape_node)
	
	collision_shape_node.shape = collision_shape

	# Configure collision layers and masks (optional, default settings are usually sufficient)
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1

func delete_chunk():
	if mesh_instance:
		mesh_instance.mesh = null
	if collision_body:
		clear_collision()

func clear_collision():
	if collision_body:
		var collision_shape_node = collision_body.get_node_or_null("CollisionShape")
		if collision_shape_node:
			collision_shape_node.queue_free()

func _exit_tree():
	delete_chunk()
	clear_collision()
