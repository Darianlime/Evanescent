extends Node2D

@onready var reset_timer : Timer = $Timer
@onready var falling_rock_scene = preload("res://Scenes/falling_rocks.tscn")

var is_reseting_rock := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_reseting_rock:
		falling_rock()

func falling_rock():
	is_reseting_rock = false
	var falling_rock_init = falling_rock_scene.instantiate()
	add_child(falling_rock_init)
	#reset_timer.wait_time = time_till_reset

	await get_tree().create_timer(randf_range(2,3)).timeout

	is_reseting_rock = true



