extends MeshInstance

func _ready():
	draw_plane(-1,0)
	draw_plane(0.1,0)

func draw_tube(p0, p1):
	print("Drawing tube!")

# Draws plane from bottom left
func draw_plane(x, z):
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)

	# PoolVectorXXArrays for mesh construction.
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array()
	var normals = PoolVector3Array()
	var indices = PoolIntArray()

	#######################################
	## Insert code here to generate mesh ##
	#######################################
	
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
