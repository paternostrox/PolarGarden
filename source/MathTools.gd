# This is a library of helful math functions

static func cartesian2polar(crt_pos: Vector2) -> Vector2:
    var r = sqrt(crt_pos.x*crt_pos.x + crt_pos.y*crt_pos.y)
    var theta = atan2(crt_pos.y,crt_pos.x)
    return Vector2(r, theta)

static func polar2cartesian(polar_pos: Vector2) -> Vector2:
    var x = polar_pos[0] * cos(polar_pos[1])
    var y = polar_pos[0] * sin(polar_pos[1])
    return Vector2(x, y)