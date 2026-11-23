extends Area2D

@onready var player: PlayerController = %Player

@export var floating_vel = -200.0

var floating : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if floating:
		if player.is_floating:
			player.velocity.y = floating_vel


func _on_body_entered(body: Node2D) -> void:
	if body == player and player.current_player_form.get_form_name() == player.female_form_string:
		floating = true
	
	if body.is_in_group("seed_pod"):
		body.floating_vel = floating_vel
		body.is_floating = true

func _on_body_exited(body: Node2D) -> void:
	floating = false
	if body.is_in_group("seed_pod"):
		body.floating_vel = 0
