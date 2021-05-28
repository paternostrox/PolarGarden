extends MeshInstance

var tube_radius = 1
var point_amount = 6
onready var stalk_exp = Expression.new()

func _ready():
	#draw_plane(-1,0)
	#draw_plane(0.1,0)
	#draw_straight_tube(Vector3(0,0,0),Vector3(20,40,20))

	var err = stalk_exp.parse("Vector3(4*sin(10*t), 6*t, 4*cos(10*t))", ["t"])
	if err:
		print("Parsing error: %d" % err)
	draw_tube(stalk_exp,0,10,.1)

func _process(delta):
	global_rotate(Vector3.UP,delta)

func draw_tube(expression: Expression, lower: float, upper: float, sampling: float):
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## GENERATE MESH ##
	var max_iterations = (upper - lower) / sampling

	var t_sample = lower
	var bottom_ring = get_ring(expression, t_sample)
	var top_ring
	var i = 1
	while i < max_iterations:
		t_sample = i * sampling

		top_ring = get_ring(expression, t_sample)

		for  j  in range(point_amount):
			
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

func get_ring(expression: Expression, t: float) -> PoolVector3Array:

	# get two points to calculate tangent
	var p0 = expression.execute([t])
	var p1 = expression.execute([t + .0001])

	var inv_basis = get_basis(p0, p1).inverse()

	var angle_inc = 360.0 / point_amount
	var current_angle = 0

	var ring = PoolVector3Array()
	for _i in range(point_amount):
		var point = p0 +  inv_basis.xform(Vector3(
			cos(deg2rad(current_angle))*tube_radius, 0, sin(deg2rad(current_angle))*tube_radius))
		ring.append(point)
		current_angle = fmod((current_angle + angle_inc),360.0)

	return ring


func get_basis(p0: Vector3, p1: Vector3) -> Basis:

	# make my basis
	var basis = Basis()
	basis.y = p1-p0 # this is the tangent line
	basis.z = basis.y.cross(Vector3.RIGHT)
	basis.x = basis.z.cross(basis.y)

	basis = basis.orthonormalized()
	return basis


func draw_straight_tube(p0, p1):
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## GENERATE MESH ##

	# make my basis
	var basis = Basis()
	basis.y = p1-p0
	basis.z = basis.y.cross(Vector3.RIGHT)
	basis.x = basis.z.cross(basis.y)
	
	var tube_height_vec = Vector3(0,basis.y.length(),0)

	basis = basis.orthonormalized()

	var p0t = basis.xform(p0)

	# apply basis here?
	global_transform.basis = basis

	var angle_inc = 360.0 / point_amount

	var current_angle = 0
	var current_point
	var last_point = p0t + Vector3(cos(deg2rad(current_angle))*tube_radius, 
	0, sin(deg2rad(current_angle))*tube_radius)

	for  i  in range(point_amount):
		current_angle = fmod((current_angle + angle_inc),360.0)

		current_point = p0t + Vector3(cos(deg2rad(current_angle))*tube_radius, 
		0, sin(deg2rad(current_angle))*tube_radius)

		verts.append(last_point)
		uvs.append(Vector2(0,0))
		
		verts.append(current_point)
		uvs.append(Vector2(1,0))
		
		verts.append(current_point + tube_height_vec)
		uvs.append(Vector2(1,1))
		
		verts.append(last_point + tube_height_vec)
		uvs.append(Vector2(0,1))

		var v1 = current_point - last_point
		var v2 = last_point + tube_height_vec - last_point
		var face_normal = v1.cross(v2)
		
		normals.append_array([face_normal,face_normal,face_normal,face_normal])

		var idx = i*4
		indices.append_array([idx, idx+1, idx+3, idx+1, idx+2,idx+3])

		last_point = current_point

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.



# Draws plane from bottom left
func draw_plane(x, z):
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## Generate mesh ##
	verts.append(Vector3(x,0,z))
	uvs.append(Vector2(0,0))
	normals.append(Vector3(0,1,0))
	
	verts.append(Vector3(x+1,0,z))
	uvs.append(Vector2(1,0))
	normals.append(Vector3(0,1,0))
	
	verts.append(Vector3(x+1,0,z+1))
	uvs.append(Vector2(1,1))
	normals.append(Vector3(0,1,0))
	
	verts.append(Vector3(x,0,z+1))
	uvs.append(Vector2(0,1))
	normals.append(Vector3(0,1,0))
	
	indices.append_array([0,1,3,1,2,3])
	
	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.
