extends MultiMeshInstance3D

@export var mesh_source : NodePath
@export var surface_source : NodePath
@export var populate_amount : int = 128
@export var populate_axis : int = 2 # 0=X, 1=Y, 2=Z
@export var populate_rotate_random : float = 0.0
@export var populate_tilt_random : float = 0.0
@export var populate_scale_random : float = 0.0
@export var populate_scale : float = 1.0

func _ready():
	_populate()

func _populate():
	var mesh : Mesh = null
	var surface_mesh_instance : MeshInstance3D = null

	# Load source mesh
	if mesh_source.is_empty():
		if get_multimesh() and get_multimesh().get_mesh():
			mesh = get_multimesh().get_mesh()
		else:
			print("No mesh source specified (and no MultiMesh set in node).")
			return
	else:
		var ms_node : Node = get_node(mesh_source)
		if ms_node and ms_node is MeshInstance3D:
			mesh = ms_node.get_mesh()
		else:
			print("Mesh source is invalid (not a MeshInstance3D).")
			return

	# Load surface mesh
	if surface_source.is_empty():
		print("No surface source specified.")
		return

	var ss_node : Node = get_node(surface_source)
	if ss_node and ss_node is MeshInstance3D:
		surface_mesh_instance = ss_node
	else:
		print("Surface source is invalid (no geometry).")
		return

	var geom_transform : Transform3D = global_transform.affine_inverse() * surface_mesh_instance.global_transform
	var surface_mesh : Mesh = surface_mesh_instance.get_mesh()
	var st : SurfaceTool = SurfaceTool.new()
	st.create_from_mesh(surface_mesh)
	var geometry : Array = st.get_faces()

	if geometry.size() == 0:
		print("Surface source is invalid (no faces).")
		return

	# Convert faces to local space
	for i in range(geometry.size()):
		var face : Array = geometry[i]
		for j in range(face.size()):
			face[j] = geom_transform.origin + geom_transform.basis.xform(face[j] - geom_transform.origin)
	
	var faces : Array = geometry
	var facecount : int = faces.size()

	if facecount == 0:
		print("Parent has no solid faces to populate.")
		return

	var triangle_area_map : Dictionary = {}
	var area_accum : float = 0.0
	
	for i in range(facecount):
		var area : float = calculate_triangle_area(faces[i])
		if area < 1e-6:
			continue
		triangle_area_map[area_accum] = i
		area_accum += area

	if triangle_area_map.size() == 0:
		print("Couldn't map area.")
		return

	var multimesh : MultiMesh = MultiMesh.new()
	multimesh.set_mesh(mesh)
	multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)
	multimesh.set_use_colors(false)
	multimesh.set_instance_count(populate_amount)

	var axis_xform : Basis = Basis()
	if populate_axis == 0: # X-Axis
		axis_xform.rotate(Vector3(0, 1, 0), -PI * 0.5)
	elif populate_axis == 1: # Y-Axis
		axis_xform.rotate(Vector3(1, 0, 0), -PI * 0.5)
	
	for i in range(populate_amount):
		var areapos : float = randf_range(0.0, area_accum)
		var index : int = triangle_area_map.keys().find_closest(areapos)
		if index < 0 or index >= facecount:
			continue

		var face : Array = faces[index]
		var pos : Vector3 = get_random_point_in_triangle(face)
		var normal : Vector3 = calculate_face_normal(face)
		var op_axis : Vector3 = (face[0] - face[1]).normalized()

		var xform : Transform3D = Transform3D()
		xform.origin = pos
		xform.basis = Basis().looking_at(pos + op_axis, normal)

		var post_xform : Basis = xform.basis
		post_xform = post_xform.rotated(post_xform.get_axis(1), -randf_range(-populate_rotate_random, populate_rotate_random) * PI)
		post_xform = post_xform.rotated(post_xform.get_axis(2), -randf_range(-populate_tilt_random, populate_tilt_random) * PI)
		post_xform = post_xform.rotated(post_xform.get_axis(0), -randf_range(-populate_tilt_random, populate_tilt_random) * PI)

		xform.basis = post_xform
		xform.basis.scale(Vector3(1, 1, 1) * (populate_scale + randf_range(-populate_scale_random, populate_scale_random)))

		multimesh.set_instance_transform(i, xform)

	set_multimesh(multimesh)

func calculate_triangle_area(face : Array) -> float:
	# Calculate the area of a triangle given its three vertices
	var a = face[1] - face[0]
	var b = face[2] - face[0]
	return a.cross(b).length() * 0.5

func get_random_point_in_triangle(face : Array) -> Vector3:
	# Get a random point inside a triangle
	var u = randf()
	var v = randf()
	if u + v > 1:
		u = 1 - u
		v = 1 - v
	return face[0] + u * (face[1] - face[0]) + v * (face[2] - face[0])

func calculate_face_normal(face : Array) -> Vector3:
	# Calculate the normal of a face
	var a = face[1] - face[0]
	var b = face[2] - face[0]
	return a.cross(b).normalized()
