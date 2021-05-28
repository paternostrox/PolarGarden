extends MeshInstance

var tube_radius = 2
var point_amount = 6
onready var stalk_exp = Expression.new()

func _ready():
	#draw_plane(-1,0)
	#draw_plane(0.1,0)
	#draw_straight_tube(Vector3(0,0,0),Vector3(20,40,20))

	var err = stalk_exp.parse("Vector3(2*sin(3*t), 4*cos(3*t), 6*t)", ["t"])
	if err:
		print("Parsing error: %d" % err)
	draw_tube(stalk_exp,0,10,.2)

func _process(delta):
	global_rotate(Vector3.UP,delta)

func draw_tube(expression, lower, upper, sampling):
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## GENERATE MESH ##
	var max_iterations = (upper - lower) / sampling
	var i = 0
	while i <= max_iterations:
		var sample = i * sampling

		# get two points to calculate tangent
		var p0 = expression.execute([sample])
		var p1 = expression.execute([sample +.0001])

		# make my basis
		var basis = Basis()
		basis.y = p1-p0 # this is the tangent line
		basis.z = basis.y.cross(Vector3.RIGHT)
		basis.x = basis.z.cross(basis.y)
		
		var tube_height_vec = Vector3(0,sampling,0)

		basis = basis.orthonormalized()

		var p0t = basis.xform(p0)

		# apply basis here
		global_transform.basis = basis

		var angle_inc = 360.0 / point_amount

		var current_angle = 0
		var current_point
		var last_point = p0t + Vector3(cos(deg2rad(current_angle))*tube_radius, 
		0, sin(deg2rad(current_angle))*tube_radius)

		for  j  in range(point_amount):
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

			var idx = i*point_amount + j*4
			indices.append_array([idx, idx+1, idx+3, idx+1, idx+2,idx+3])

			last_point = current_point

		i += 1

	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	#arr[Mesh.ARRAY_TEX_UV] = uvs
	#arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.	

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
