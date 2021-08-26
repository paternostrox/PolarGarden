extends MeshInstance

export(PackedScene) var plant_scene

var rng = RandomNumberGenerator.new()

var grid_width : int = 20 # in units
var grid_depth : int = 20 # in units
var cell_size : float = 1 # in meters
var grid = []

var ground_mesh

func _ready():
	Server.connect("server_add", self, "add_plant")
	Server.connect("server_remove", self, "remove_plant")
	create_grid()

func create_grid():
	# make ground geometry
	draw_ground()

	# make grid matrix
	for x in range(grid_width):
		grid.append([])
		for _y in range(grid_depth):
			grid[x].append("")

# func randomize():
# 	for x in range(grid_width):
# 		for z in range(grid_depth):
# 			var name = grid[x][z]
# 			if !name.empty():
# 				remove_plant(x,z)
# 			rng.randomize()
# 			var num = rng.randi_range(0,1)
# 			if num == 1:
# 				add_plant(x,z)
				
	
func world2grid(var pos: Vector3):
	var x = clamp(floor(pos.x), 0, grid_width-1)
	var z = clamp(floor(pos.z), 0, grid_depth-1)
	return [x,z]


func add_plant(plant_data, pos: Vector3):
	var new_plant = plant_scene.instance()
	new_plant.transform.origin = Vector3(pos.x*cell_size + cell_size/2.0, 0, pos.z*cell_size + cell_size/2.0)
	add_child(new_plant)
	#grid[x][z] = new_plant.name
	new_plant.get_child(0).draw_plant(plant_data)
	#emit_signal("flower_added", [plant_data[0], plant_data[1], plant_data[2]])
	

func remove_plant(pos: Vector3):
	var path = grid[pos.x][pos.z]
	get_node(path).queue_free()
	#grid[x][z] = ""

func draw_ground():
	ground_mesh = ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	## GENERATE MESH ##
	verts.append(Vector3(0, 0, 0))
	verts.append(Vector3(grid_width, 0, 0))
	verts.append(Vector3(grid_width, 0, grid_depth))
	verts.append(Vector3(0, 0, grid_depth))

	uvs.append(Vector2(0,0))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(0,1))

	normals.append_array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	indices.append_array([0,1,3,1,2,3])
	
	# Assign arrays to mesh array.
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	ground_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) # No blendshapes or compression used.
	mesh = ground_mesh
	var col_shape : CollisionShape = get_node("StaticBody/CollisionShape")
	col_shape.shape = mesh.create_convex_shape() # not ideal but ok
