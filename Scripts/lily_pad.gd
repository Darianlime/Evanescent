extends AnimatableBody2D

@onready var player: PlayerController = %Player
@export var delay_until_drop := 0.5
@export var fall_distance := 64
@export var delay_until_rise := 2.0

var tween: Tween
var starting_y : float

var is_dropping := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	starting_y = global_position.y
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		await get_tree().create_timer(delay_until_drop).timeout
		print("on lilypad")
		if tween:
			tween.kill()      
		tween = create_tween()
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) 
		tween.tween_property(self, "global_position:y", starting_y + fall_distance, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)   


func _on_area_2d_body_exited(body: Node2D) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) 
	tween.tween_property(self, "global_position:y", starting_y , 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
