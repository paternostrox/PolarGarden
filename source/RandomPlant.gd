extends MeshInstance

var rng = RandomNumberGenerator.new()

var tube_radius : float = 0.5
var point_amount : int = 3

onready var stalk_exp = Expression.new()
onready var flower_exp = Expression.new()

var plant_mesh
var stalktop_pos

func _ready():
	rng.randomize()
	draw_random_plant()

# func _process(delta):
# 	global_rotate(Vector3.UP,delta)

func draw_random_plant():
	#generate_plant()
	#draw_plant()
	change_color()

func change_color():
	material_override = material_override.duplicate()
	material_override.albedo_color = Color.from_hsv(rng.randf_range(0,1),rng.randf_range(.7,.95),rng.randf_range(.8,.9))
	

func draw_plant(var values):
	var stalk_eq = values[0]
	var stalk_disturbance_eq = values[1]
	var flower_eq = values[2]
	var stalk_length = values[3]
	var flower_length = values[4]

	plant_mesh = ArrayMesh.new()
	mesh = plant_mesh

	# Build stalk expression
	var stalk = stalk_eq + " + " + stalk_disturbance_eq
	var error = stalk_exp.parse(stalk, ["t"])
	if error != OK:
		push_error(stalk_exp.get_error_text())
		return

	# Build flower expression
	var flower = flower_eq + " + stalktop_pos"
	error = flower_exp.parse(flower, ["theta"])
	if error != OK:
		push_error(flower_exp.get_error_text())
		return

	# Draw flower
	stalktop_pos = draw_tube(stalk_exp, tube_radius/2, 0, stalk_length, .05)
	draw_tube(flower_exp, tube_radius, 0, flower_length, .05)

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
