extends Spatial

var rng = RandomNumberGenerator.new()

var tube_radius : float = 0.5
var point_amount : int = 3

onready var stalk_exp = Expression.new()
onready var flower_exp = Expression.new()

var der_delta = 0.0001
var mesh_sampling = 0.02

func _ready():
	rng.randomize()

func draw_plant(plant_data):

	var stalk_node = MeshInstance.new()
	add_child(stalk_node)
	stalk_node.mesh = ArrayMesh.new()

	var stalk_top = draw_equation(stalk_node.mesh, plant_data[0], Vector3.ZERO, plant_data[1])
	stalk_node.mesh.surface_set_material(0, make_material(plant_data[2],plant_data[3],plant_data[4]))

	for i in range(5, plant_data.size(), 5):
		var head_node = MeshInstance.new()
		head_node.transform.origin = stalk_top
		#head_node.rotation = Vector3(rng.randf_range(0,360),rng.randf_range(0,360),rng.randf_range(0,360))
		add_child(head_node)
		head_node.mesh = ArrayMesh.new()
		draw_equation(head_node.mesh, plant_data[i], Vector3.ZERO, plant_data[i+1])
		head_node.mesh.surface_set_material(0, make_material(plant_data[i+2],plant_data[i+3],plant_data[i+4]))
	
func draw_equation(mesh: ArrayMesh, eq: String, start_point: Vector3, length: float):

	# Build expression
	var expression = Expression.new()
	var error = expression.parse(eq + " + " + var2str(start_point), ["t"])
	if error != OK:
		push_error(expression.get_error_text())
		return

	# Draw
	var end_point = draw_tube(mesh, expression, tube_radius, length, mesh_sampling)
	return end_point
		
func get_values_inrange(var boundaries):
	var vals = PoolIntArray()
	# Get random values (within the boundaries)
	for i in range(boundaries.size()/2):
		vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))
	return vals

func make_material(var h, var s, var v):
	var color = Color.from_hsv(h,s,v)
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	return mat
		

# WARNING (BUG): Mesh rings are getting rotated on XZ axis, so in some cases the geometry breaks
func draw_tube(mesh: ArrayMesh, expression: Expression, radius: float, length: float, sampling: float) -> Vector3:
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## GENERATE MESH ##
	var max_iterations = length / sampling

	var t_sample = 0
	var bottom_ring = get_ring(expression, t_sample, radius)
	var top_ring
	var i = 0
	while i <= max_iterations + 1:
		t_sample = i * sampling

		top_ring = get_ring(expression, t_sample, radius)

		for j in range(point_amount):
			
			var next_j = (j+1) % point_amount

			verts.append(bottom_ring[j])
			uvs.append(Vector2(0,0))
			
			verts.append(bottom_ring[next_j])
			uvs.append(Vector2(1,0))
			
			verts.append(top_ring[next_j])
			uvs.append(Vector2(1,1))
			
			verts.append(top_ring[j])
			uvs.append(Vector2(0,1))

			var v1 = bottom_ring[next_j] - bottom_ring[j]
			var v2 = top_ring[j] - bottom_ring[j]
			var face_normal = v1.cross(v2)
			
			normals.append_array([face_normal,face_normal,face_normal,face_normal])

			var idx = i*point_amount*4 + j*4
			indices.append_array([idx, idx+1, idx+3, idx+1, idx+2,idx+3])

		bottom_ring = top_ring
		i += 1

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.

	# Returns stalk top position
	return expression.execute([t_sample], self)

func get_ring(expression: Expression, t: float, radius: float) -> PoolVector3Array:

	# get two points to calculate tangent
	#var pxmd = expression.execute([t - der_delta], self)
	var px = expression.execute([t], self)
	var pxpd = expression.execute([t + der_delta], self)

	var inv_basis = get_basis(px, pxpd).inverse()

	var angle_inc = 360.0 / point_amount
	var current_angle = 0

	var ring = PoolVector3Array()
	for _i in range(point_amount):
		var point = px +  inv_basis.xform(Vector3(
			cos(deg2rad(current_angle))*radius, 0, sin(deg2rad(current_angle))*radius))
		ring.append(point)
		current_angle = fmod((current_angle + angle_inc),360.0)

	return ring


func get_basis(px: Vector3, pxpd: Vector3) -> Basis:

	# make my basis
	var basis = Basis()
	basis.y = (pxpd - px) / (der_delta) # this is the tangent (first derivative)
	basis.z = basis.y.cross(Vector3.BACK) # cross product between tangent and unit BACK vector
	basis.x = basis.z.cross(basis.y) # cross product between the later two

	basis = basis.orthonormalized()

	return basis

func get_basis_der(pxmd: Vector3, px: Vector3, pxpd: Vector3) -> Basis:

	# make my basis
	var basis = Basis()
	basis.y = (pxpd - pxmd) / (2*der_delta) # this is the tangent (first derivative)
	basis.z = (pxpd - 2*px + pxmd) / (der_delta*der_delta) # this is the curl of the tangent (second derivative)
	basis.x = basis.z.cross(basis.y)

	basis = basis.orthonormalized()

	return basis
	

# (r,theta,phi) -> (x,y,z)
func spherical2cartesian(spherical_pos: Vector3) -> Vector3:
	var x = spherical_pos[0]*cos(spherical_pos[1])*sin(spherical_pos[2])
	var y = spherical_pos[0]*sin(spherical_pos[1])*sin(spherical_pos[2])
	var z = spherical_pos[0]*cos(spherical_pos[2])
	return Vector3(x,y,z)

# (r,theta) -> (x,y)
func polar2cartesian(polar_pos: Vector2) -> Vector2:
	var x = polar_pos[0] * cos(polar_pos[1])
	var y = polar_pos[0] * sin(polar_pos[1])
	return Vector2(x, y)

func v2_to_v3(x: float, v2: Vector2):
	return Vector3(x, v2.x, v2.y)
