extends RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		body.death()     
		queue_free()
	elif body is TileMapLayer:
		queue_free()
	




