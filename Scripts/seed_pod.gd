extends RigidBody2D

@onready var player: PlayerController = %Player

var floating_vel := 0.0
var is_floating := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_floating:
		linear_velocity.y = floating_vel


func _on_area_2d_body_entered(body: Node) -> void:
	if body == player:
		player.death()
		