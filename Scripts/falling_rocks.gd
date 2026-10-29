extends RigidBody2D

var pre_impact_velocity := Vector2.ZERO

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	pre_impact_velocity = state.linear_velocity   # speed before the collision is resolved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		body.death()     
		queue_free()
	elif body is TileMapLayer and pre_impact_velocity.y > 40.0:
		queue_free()
	




