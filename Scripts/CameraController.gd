extends Camera2D

var target: Node2D
var locked := false

@export var follow_speed := 5.0

func focus_on(object: Node2D) -> void:
    if is_set_as_top_level():
		#set back to player
        set_as_top_level(false)
        position = Vector2.ZERO

    locked = false
    target = object

    drag_horizontal_enabled = false
    drag_vertical_enabled = false


func lock_to_position(target_position: Vector2) -> void:
    set_as_top_level(true)

    locked = true
    target = null

    global_position = target_position
    drag_horizontal_enabled = false
    drag_vertical_enabled = false


func _process(delta: float) -> void:
    if locked:
        return

    if is_instance_valid(target):
        global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))