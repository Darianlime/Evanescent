extends RigidBody2D

signal hit_object(body)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("chain"):
		return
	hit_object.emit(body)
