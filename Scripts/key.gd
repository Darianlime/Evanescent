extends Area2D

@onready var player: PlayerController = %Player

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player.key_count += 1
		queue_free()