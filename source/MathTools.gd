# This is a library of helful math functions

# (x,y) -> (r,theta)
static func cartesian2polar(crt_pos: Vector2) -> Vector2:
    var r = sqrt(crt_pos.x*crt_pos.x + crt_pos.y*crt_pos.y)
    var theta = atan2(crt_pos.y,crt_pos.x)
    return Vector2(r, theta)

# (r,theta) -> (x,y)
# static func polar2cartesian(polar_pos: Vector2) -> Vector2:
#     var x = polar_pos[0] * cos(polar_pos[1])
#     var y = polar_pos[0] * sin(polar_pos[1])
#     return Vector2(x, y)

# (x,y,z) -> (r,theta,phi)
static func cartesian2spherical(crt_pos: Vector3) -> Vector3:
    var r = sqrt(crt_pos.x*crt_pos.x + crt_pos.y*crt_pos.y + crt_pos.z*crt_pos.z)
    var theta = atan2(crt_pos.y,crt_pos.x)
    var phi = acos(crt_pos.z / r)
    return Vector3(r, theta, phi)

# (r,theta,phi) -> (x,y,z)
# static func spherical2cartesian(spherical_pos: Vector3) -> Vector3:
#     var x = spherical_pos[0]*cos(spherical_pos[1])*sin(spherical_pos[2])
#     var y = spherical_pos[0]*sin(spherical_pos[1])*cos(spherical_pos[2])
#     var z = spherical_pos[0]*cos(spherical_pos[2])
#     return Vector3(x,y,z)

