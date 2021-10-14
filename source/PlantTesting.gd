extends MeshInstance

var rng = RandomNumberGenerator.new()

var tube_radius : float = 0.5
var point_amount : int = 3

var stalk_length
var flower_length
var stalk_eq
var stalk_base_eq
var stalk_disturbance_eq
var flower_eq

onready var stalk_exp = Expression.new()
onready var flower_exp = Expression.new()

var plant_mesh
var stalk_top

func _ready():
	rng.randomize()
	draw_plant()

func _process(delta):
	global_rotate(Vector3.UP,delta)
	if Input.is_key_pressed(KEY_SPACE):
		draw_plant()

func draw_plant():

	var head_count = 1

	mesh = ArrayMesh.new()

	var stalk_data = generate_stalk()
	stalk_top = draw_equation(mesh, stalk_data[0], Vector3.ZERO, stalk_data[1])
	mesh.surface_set_material(0, make_material(.3,.4,.75,.95,.8,.9))

	for i in range(1,head_count + 1):
		var head_data = generate_head()
		draw_equation(mesh, head_data[0], stalk_top, head_data[1])
		mesh.surface_set_material(i, make_material(0,1,.75,.95,.8,.9))


func generate_stalk():
	var boundaries = []
	var vals = []

	#var stalk_type = rng.randi_range(0, 1)
	var stalk_type = 1

	# CHOOSE STALK TYPE
	match stalk_type:
		# 1 SCREW (t): R → R³, t ↦ ( a·sin(k·t), b·t, c·cos(k·t))
		0:
			# boundaries to values (2 per value)
			boundaries = [
				1,4, # a
				2,8, # b
				4,16, # c
				2,6 # k
			]
			vals = get_values_inrange(boundaries)

			stalk_base_eq = "Vector3(%f*sin(%f*t), %f*t, %f*cos(%f*t))" % [vals[0], vals[3], vals[1], vals[0], vals[3]]
			
			var stalk_factor = 1/(vals[1]*0.3)
			stalk_length = rng.randf_range(8*stalk_factor, 16*stalk_factor)

		# 2 EXP (t): R → R³, t ↦ (a.t, b·ease(c.t, d), c·cos(k·t))
		1:
			# boundaries to values (2 per value)
			boundaries = [
				30,60, # a
				2,8 # b
			]
			vals = get_values_inrange(boundaries)

			stalk_base_eq = "Vector3(0, %f*ease(t/10, 0.2), 0)" % [vals[0]] # REVIEW THIS
			
			stalk_length = rng.randf_range(5, 10)

	# STALK DISTURBANCE

	boundaries = [
		1,4
	]
	vals = get_values_inrange(boundaries)

	stalk_disturbance_eq = "Vector3(sin(%f*t),sin(%f*t),sin(%f*t))" % [vals[0], vals[0], vals[0]]
	
	stalk_eq = stalk_base_eq + " + " + stalk_disturbance_eq

	return [stalk_eq, stalk_length]

func generate_head():
	
		var boundaries = []
		var vals = []
	
		# CHOOSE FLOWER TYPE
		#var flower_type = rng.randi_range(0, 1)
		var flower_type = 0
	
		match flower_type:
			# 1 Spherical Rational Polar
			0:
				boundaries = [
					2,5, # a
					2,5, # b
					1,2 # c
				]
				vals = get_valuesf_inrange(boundaries)
	
				#flower_eq = "(spherical2cartesian(Vector3(6.0*cos((15.0/15.0)*t), t, t)) + spherical2cartesian(Vector3(7.0*cos((2.0/14.0)*t), t, t))) / 2.0"
				flower_eq = "spherical2cartesian(Vector3(10*asin(cos(1.2*t + 0.97)), t, t))"
				print(flower_eq)
				
				#var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1
				flower_length = 20*PI
				#flower_length = PI * vals[2] * p

		return [flower_eq, flower_length] 

func draw_equation(mesh: ArrayMesh, eq: String, start_point: Vector3, length: float):

	# Build expression
	var expression = Expression.new()
	var error = expression.parse(eq + " + " + var2str(start_point), ["t"])
	if error != OK:
		push_error(expression.get_error_text())
		return

	# Draw
	var end_point = draw_tube(mesh, expression, tube_radius, length, .02)
	return end_point

func get_values_inrange(var boundaries):
	var vals = PoolIntArray()
	# Get random values (within the boundaries)
	for i in range(boundaries.size()/2):
		vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))
	return vals

func get_valuesf_inrange(var boundaries):
	var vals = []
	# Get random values (within the boundaries)
	for i in range(0,boundaries.size(),2):
		vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))
	return vals

func change_color():
	material_override = material_override.duplicate()
	material_override.albedo_color = Color.from_hsv(rng.randf_range(0,1),rng.randf_range(.7,.95),rng.randf_range(.8,.9))

func make_material(h_lower: float, h_upper: float, s_lower: float, s_upper: float, v_lower: float, v_upper: float):
	var mat = SpatialMaterial.new()
	var color = Color.from_hsv(rng.randf_range(h_lower,h_upper),rng.randf_range(s_lower,s_upper),rng.randf_range(v_lower,v_upper))
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

	# Returns stalk top position
	return expression.execute([t_sample], self)

func get_ring(expression: Expression, t: float, radius: float) -> PoolVector3Array:

	# get two points to calculate tangent
	var p0 = expression.execute([t], self)
	var p1 = expression.execute([t + .0001], self)

	var inv_basis = get_basis(p0, p1).inverse()

	var angle_inc = 360.0 / point_amount
	var current_angle = 0

	var ring = PoolVector3Array()
	for _i in range(point_amount):
		var point = p0 +  inv_basis.xform(Vector3(
			cos(deg2rad(current_angle))*radius, 0, sin(deg2rad(current_angle))*radius))
		ring.append(point)
		current_angle = fmod((current_angle + angle_inc),360.0)

	return ring


func get_basis(p0: Vector3, p1: Vector3) -> Basis:

	# make my basis
	var basis = Basis()
	basis.y = p1-p0 # this is the tangent line
	basis.z = basis.y.cross(Vector3.BACK)
	basis.x = basis.z.cross(basis.y)

	basis = basis.orthonormalized()
	return basis

func get_basiz(t: float) -> Basis:

	# make my basis
	var basis = Basis()
	basis.y = spherical2cartesian(Vector3((-11*(4/3))*sin(4.0/3.0*t), 1, 1)) # this is the tangent line
	basis.z = spherical2cartesian(Vector3((-11*(16/9))*cos(4.0/3.0*t), 0, 0))
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
