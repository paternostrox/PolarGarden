extends MeshInstance


var point_amount = 6

export(float) var tube_radius = 1
# both always start at zero, so only length (end) is required
export(float) var stalk_length = 10
export(float) var flower_length = 2*PI

export(String, MULTILINE) var stalk_eq
export(String, MULTILINE) var stalk_disturbance_eq
export(String, MULTILINE) var flower_eq
onready var stalk_exp = Expression.new()
onready var flower_exp = Expression.new()

var stalktop_pos

var plant_mesh # drawing occurs on this mesh

func _ready():
    get_random_values()
    draw_plant()

func get_random_values():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    #var stalk_type = rng.randi_range(0, 1)
    var stalk_type = 0

    # CHOOSE STALK TYPE
    match stalk_type:
        # 1 SCREW (t): R → R³, t ↦ ( a·sin(k·t), b·t, c·cos(k·t))
        0:
            # boundaries to values (2 per value)
            var boundaries = [
                4,16, # a
                2,8, # b
                4,16, # c
                2,6 # k
            ]

            var vals = PoolRealArray()

            # Get random values for stalk (within the boundaries)
            for i in range(boundaries.size()/2):
                rng.randomize()
                vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))

            stalk_eq = "Vector3(%f*sin(%f*t), %f*t, %f*cos(%f*t))" % [vals[0], vals[3], vals[1], vals[2], vals[3]]
            
            rng.randomize()
            stalk_length = rng.randf_range(10, 100)

        # 2 EXP (t): R → R³, t ↦ (a.t, b·ease(c.t, d), c·cos(k·t))
        1:
            # boundaries to values (2 per value)
            var boundaries = [
                4,16, # a
                2,8, # b
            ]

            var vals = PoolRealArray()

            # Get random values for stalk (within the boundaries)
            for i in range(boundaries.size()/2):
                rng.randomize()
                vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))

            #stalk_eq = "Vector3(0, 50*ease(t/10, 0.2), 2*t)" % [vals[0], vals[3], vals[1], vals[2], vals[3]] # REVIEW THIS
            
            rng.randomize()
            stalk_length = rng.rand_range(10, 70)

    # CHOOSE FLOWER TYPE
    rng.randomize()
    #var flower_type = rng.randi_range(0, 1)
    var flower_type = 0

    match flower_type:
        # 1 Spherical Rational Polar (theta, 1)
        0:
            var boundaries = [
                8,20, # a
                1,10, # n
                1,10, # d
            ]

            var vals = PoolIntArray()

            # Get random values for stalk (within the boundaries)
            for i in range(boundaries.size()/2):
                rng.randomize()
                vals.append(rng.randi_range(boundaries[i],boundaries[i+1]))

            flower_eq = "spherical2cartesian(Vector3(%f*sin(%f*theta), theta, 1))" % [vals[0], vals[1]]
            
            var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1 
            flower_length = PI * vals[2] * p
            
        # 2 Spherical Irrational Polar

func _process(delta):
	global_rotate(Vector3.UP,delta)

func toggle_visible():
	visible = !visible

func draw_plant():
	plant_mesh = ArrayMesh.new()
	mesh = plant_mesh

	# Build stalk expression
	# SCREW (t): R → R³, t ↦ ( a·sin(k·t), b·cos(k·t), c·t )
	var stalk = stalk_eq + " + " + stalk_disturbance_eq
	var err = stalk_exp.parse(stalk, ["t"])
	if err:
		print("Parsing error (stalk): %d" % err)

	# Build flower expression
	var flower = flower_eq + " + stalktop_pos"
	err = flower_exp.parse(flower, ["theta"])
	if err:
		print("Parsing error (flower): %d" % err)

	# Draw flower
	stalktop_pos = draw_tube(stalk_exp, tube_radius/2, 0, stalk_length, .1)
	draw_tube(flower_exp, tube_radius, 0, flower_length, .1)

# WARNING (POSSIBLE BUG): Mesh rings are getting rotated on XZ axis, so in some cases the geometry breaks
func draw_tube(expression: Expression, radius: float, lower: float, upper: float, sampling: float) -> Vector3:
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
	var bottom_ring = get_ring(expression, t_sample, radius)
	var top_ring
	var i = 1
	while i < max_iterations:
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
	plant_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.

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
	basis.z = basis.y.cross(Vector3.RIGHT)
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
