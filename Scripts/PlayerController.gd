extends CharacterBody2D

@onready var coyote_timer : Timer = $CoyoteTimer
@onready var chain_spawn : Marker2D = $ChainSpawnMarker
@onready var pin_joint : PinJoint2D = $PinJoint2D

@export var walk_speed = 300.0
@export var swing_speed = 300.0
@export_range(0, 1) var acceleration = 0.1
@export_range(0, 1) var deceleration = 0.1

@export var jump_force = -500.0
@export_range(0, 1) var decelerate_on_jump_release = 0.5

@onready var chain_gun: ChainGun = $"../ChainGun"

var is_left_click_held := false

func _ready() -> void:
	chain_gun.initialize(self, pin_joint)

func _process(delta: float) -> void:
	if chain_gun.is_shooting:
		chain_gun.update_chain(delta) 
	elif chain_gun.is_physics_chain:
		chain_gun.update_physics_chain()
	# elif chain_gun.is_retracting:
	# 	chain_gun.update_physics_chain()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or !coyote_timer.is_stopped()):
		velocity.y = jump_force
		coyote_timer.stop();

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	var was_on_floor = is_on_floor();

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if chain_gun.is_grappling && !is_on_floor():
		coyote_timer.stop();
		if direction:
			velocity.x += direction * swing_speed * acceleration 
	else:
		if direction:
			velocity.x = move_toward(velocity.x, walk_speed * direction, walk_speed * acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, walk_speed * deceleration)

	move_and_slide()
	apply_grapple_constraint()

	if was_on_floor and !is_on_floor() and velocity.y >= 0:
		coyote_timer.start();

	# shoot chain
	if Input.is_action_just_pressed("shoot"):
		chain_gun.shoot_chain()

	#retract
	if Input.is_action_just_released("shoot"):
		chain_gun.retract_chain()

	chain_gun.reel_chain(delta)
	
	
func apply_grapple_constraint():
	if !chain_gun.is_grappling:
		return

	var anchor: Vector2 = chain_gun.grapple_point
	var rope_length: float = chain_gun.rope_length

	var offset := global_position - anchor
	var distance := offset.length()

	if distance > rope_length:
		var outward_direction := offset.normalized()

		global_position = anchor + outward_direction * rope_length

		var outward_speed := velocity.dot(outward_direction)

		if outward_speed > 0.0:
			velocity -= outward_direction * outward_speed
