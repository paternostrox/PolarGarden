class_name PlantGen

static func generate_plant(var rng):
    var stalk_type = rng.randi_range(0, 1)
    #var stalk_type = 1

    var boundaries = []
    var vals = []

    var stalk_length
    var flower_length
    var stalk_eq
    var stalk_disturbance_eq
    var flower_eq

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
            vals = get_values_inrange(boundaries, rng)

            stalk_eq = "Vector3(%f*sin(%f*t), %f*t, %f*cos(%f*t))" % [vals[0], vals[3], vals[1], vals[0], vals[3]]
            
            var stalk_factor = 1/(vals[1]*0.3)
            stalk_length = rng.randf_range(8*stalk_factor, 16*stalk_factor)

        # 2 EXP (t): R → R³, t ↦ (a.t, b·ease(c.t, d), c·cos(k·t))
        1:
            # boundaries to values (2 per value)
            boundaries = [
                30,60, # a
                2,8 # b
            ]
            vals = get_values_inrange(boundaries, rng)

            stalk_eq = "Vector3(0, %f*ease(t/10, 0.2), 0)" % [vals[0]] # REVIEW THIS
            
            stalk_length = rng.randf_range(5, 10)

    # STALK DISTURBANCE

    boundaries = [
        1,4
    ]
    vals = get_values_inrange(boundaries, rng)

    stalk_disturbance_eq = "Vector3(sin(%f*t),sin(%f*t),sin(%f*t))" % [vals[0], vals[0], vals[0]]

    # CHOOSE FLOWER TYPE
    var flower_type = rng.randi_range(0, 1)
    #var flower_type = 0

    match flower_type:
        # 1 Spherical Rational Polar (theta, 1)
        0:
            boundaries = [
                4,12, # a
                1,10, # n
                1,10 # d
            ]
            vals = get_values_inrange(boundaries, rng)

            flower_eq = "spherical2cartesian(Vector3(%f*sin(%f*theta), theta, 1))" % [vals[0], vals[1]]
            
            var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1 
            flower_length = PI * vals[2] * p

        # 2 Spherical Positive Rational Polar (theta, 1)
        1:
            boundaries = [
                4,12, # a
                5,15, # n
                1,10 # d
            ]
            vals = get_values_inrange(boundaries, rng)

            flower_eq = "spherical2cartesian(Vector3(%f*abs(sin(%f*theta)), theta, 1))" % [vals[0], vals[1]]
            
            var p = 2 if ((vals[1]*vals[2]) % 2 == 0) else 1 
            flower_length = PI * vals[2] * p

            
        # 3 Spherical Irrational Polar

    return [stalk_eq, stalk_disturbance_eq, flower_eq, stalk_length, flower_length]

static func get_values_inrange(var boundaries, var rng):
    var vals = PoolIntArray()
    # Get random values (within the boundaries)
    for i in range(boundaries.size()/2):
        vals.append(rng.randf_range(boundaries[i],boundaries[i+1]))
    return vals