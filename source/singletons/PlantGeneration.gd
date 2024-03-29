extends Node

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func generate_plant(head_count:= 2) -> PlantData:

	var plant_data = PlantData.new()

	var stalk_data = generate_stalk()
	plant_data.piece_eqs.append(stalk_data[0])
	plant_data.piece_lengths.append(stalk_data[1])

	for _i in range(1,head_count + 1):
		var head_data = generate_head()
		plant_data.piece_eqs.append(head_data[0])
		plant_data.piece_lengths.append(head_data[1])

	return plant_data

func generate_stalk():
	var boundaries = []
	var vals = []
		
	var stalk_eq
	var stalk_base_eq
	var stalk_disturbance_eq
	var stalk_length

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
				30,100, # a
				2,8 # b
			]
			vals = get_values_inrange(boundaries)

			stalk_base_eq = "Vector3(0, %f*ease(t/10, 0.2), 0)" % [vals[0]] # REVIEW THIS
			
			stalk_length = rng.randf_range(5, 25)

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

	var flower_eq
	var flower_disturbance_eq
	var flower_length

	# CHOOSE FLOWER TYPE
	var flower_type = rng.randi_range(0, 1)
	#var flower_type = 0

	match flower_type:
		# 1 Spherical Rational Polar (theta, theta)
		0:
			boundaries = [
				4,16, # a
				1,20, # n
				1,20 # d
			]
			vals = get_values_inrange(boundaries)

			flower_eq = "spherical2cartesian(Vector3(%f*cos(%f/%f*t), t, t))" % [vals[0], vals[1], vals[2]]
			
			#var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1
			#flower_length = PI * vals[2] * p
			flower_length = PI * 2 * vals[2]
		
		# 1 Spherical Rational Polar (theta, theta)
		1:
			boundaries = [
				4,16, # a
				1,20, # n
				1,20 # d
			]
			vals = get_values_inrange(boundaries)

			flower_eq = "spherical2cartesian(Vector3(%f*abs(cos(%f/%f*t)), t, 1))" % [vals[0], vals[1], vals[2]]
			
			#var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1
			#flower_length = PI * vals[2] * p
			flower_length = PI * 2 * vals[2]

	# FLOWER DISTURBANCE

	boundaries = [
		1,4
	]
	vals = get_values_inrange(boundaries)

	flower_disturbance_eq = "Vector3(sin(%f*t),sin(%f*t),sin(%f*t))" % [vals[0], vals[0], vals[0]]

	flower_eq = flower_eq + " + " + flower_disturbance_eq
		
	return [flower_eq, flower_length]

func get_values_inrange(var boundaries):
	var vals = PoolIntArray()
	# Get random values (within the boundaries)
	for i in range(boundaries.size()/2):
		vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))
	return vals
