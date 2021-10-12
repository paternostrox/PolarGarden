extends MeshInstance

export(PackedScene) var plant_scene
export(NodePath) var ground_path

var rng = RandomNumberGenerator.new()

var grid = []
var grid_size

var ground_mesh
var ground

signal plant_added(plant_data)

func _ready():
	ground = get_node(ground_path)
	Server.connect("server_populate", self, "populate_garden")
	Server.connect("server_add", self, "add_plant")
	Server.connect("server_remove", self, "remove_plant")
	create_grid()
	Server.connect_to_server()

func create_grid():
	# make ground geometry
	#draw_ground()
	#ground.mesh.size = Vector3(GameVars.grid_width,2,GameVars.grid_depth)
	#ground.transform.origin = Vector3(GameVars.grid_width/2,-1,GameVars.grid_depth/2)

	# make grid matrix
	for x in range(GameVars.grid_width):
		grid.append([])
		for _y in range(GameVars.grid_depth):
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

func world2player(var pos: Vector3):
	if(pos.x >= 0):
		if(pos.z >= 0):
			return 1
		else:
			return 3
	else:
		if(pos.z >= 0):
			return 2
		else:
			return 0

func world2grid(pos):
	pos.x += GameVars.grid_width/2
	pos.z += GameVars.grid_depth/2
	var x = clamp(floor(pos.x), 0, GameVars.grid_width)
	var z = clamp(floor(pos.z), 0, GameVars.grid_depth)
	var gridpos = Vector3(x,0,z)
	return gridpos

func grid2world(pos):
	pos.x -= GameVars.grid_width/2
	pos.z -= GameVars.grid_depth/2
	return pos

func populate_garden(garden_grid):
	grid_size = garden_grid[0].size()
	for x in range(grid_size):
		for z in range(grid_size):
			var plant_data = garden_grid[x][z]
			if !plant_data.empty():
				var p = JSON.parse(plant_data)
				if typeof(p.result) == TYPE_ARRAY:
					add_plant(p.result, Vector3(x,0,z))
				else:
					push_error("Parse error. Unexpected type.")

func add_plant(plant_data, pos: Vector3):
	var world_pos = grid2world(pos)
	var new_plant = plant_scene.instance()
	new_plant.transform.origin = Vector3(world_pos.x*GameVars.cell_size + GameVars.cell_size/2.0, 0, world_pos.z*GameVars.cell_size + GameVars.cell_size/2.0)
	add_child(new_plant)
	grid[pos.x][pos.z] = new_plant.name
	new_plant.draw_plant(plant_data)
	emit_signal("plant_added", plant_data)
	

func remove_plant(pos: Vector3):
	var path = grid[pos.x][pos.z]
	get_node(path).queue_free()
	grid[pos.x][pos.z] = ""

func try_interaction(pos: Vector3):
	print("grid2player=%d playernum=%d" % [world2player(pos), GameVars.player_number])
	if(world2player(pos) == GameVars.player_number):
		Server.grid_interact(get_instance_id(), pos)

func try_cross(parents_poss, pos):
	if(world2player(pos) == GameVars.player_number):
		for i in range(parents_poss.size()):
			if !check_plant(parents_poss[i]):
				return
		Server.grid_cross(get_instance_id(), parents_poss, pos)

func check_plant(pos: Vector3):
	var gridpos = world2grid(pos)
	var name = grid[gridpos.x][gridpos.z]
	return !name.empty()

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
	verts.append(Vector3(GameVars.grid_width, 0, 0))
	verts.append(Vector3(GameVars.grid_width, 0, GameVars.grid_depth))
	verts.append(Vector3(0, 0, GameVars.grid_depth))

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
