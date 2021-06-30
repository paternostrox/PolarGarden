extends Camera

export(NodePath) var target

var last_mouse_pos
var drag = false

var angle_x = 0
var angle_y = 0

var speed = 1
var distance = 10

func _process(delta):
    pass

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_MIDDLE:
            last_mouse_pos = event.position
            drag = true

    if event is InputEventMouseMotion and drag == true:
        var delta_pos = event.position - last_mouse_pos
        angle_x += delta_pos.x * speed
        angle_y += delta_pos.y * speed
        last_mouse_pos = event.position