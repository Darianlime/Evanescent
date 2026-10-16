class_name PlayerController extends CharacterBody2D

@onready var coyote_timer : Timer = $CoyoteTimer
@onready var chain_spawn : Marker2D = $ChainSpawnMarker
@onready var pin_joint : PinJoint2D = $PinJoint2D
@onready var camera: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var input: PlayerInput = $PlayerInput

@export var jump_force = -500.0
@export_range(0, 1) var decelerate_on_jump_release = 0.5

@export var starting_character: PackedScene
var current_player_form: Character 

func _ready() -> void:
	current_player_form = starting_character.instantiate()
	add_child(current_player_form)
	# chain_gun.initialize(self, pin_joint)
	pass

func _process(delta: float) -> void:
	current_player_form.process_update(self, delta)
	# elif chain_gun.is_retracting:
	# 	chain_gun.update_physics_chain()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if input.jump_pressed and (is_on_floor() or !coyote_timer.is_stopped()):
		velocity.y = jump_force
		coyote_timer.stop();

	if input.jump_released and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	var was_on_floor = is_on_floor();

	if input.direction:
		print("gretret")
	current_player_form.physics_update(self, input, delta)

	move_and_slide()

	if was_on_floor and !is_on_floor() and velocity.y >= 0:
		coyote_timer.start();

	current_player_form.physics_update_after_move_and_slide(self, input, delta)


func get_rectangle_size() -> Vector2:
	var rect_shape = collision.shape as RectangleShape2D
	if rect_shape:
		return rect_shape.extents * 2.0
	return Vector2.ZERO
