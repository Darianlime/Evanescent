class_name MaleController extends Character

@onready var chain_gun: ChainGun
@export var swing_speed = 300.0
const chain_gun_scene = preload("res://Scenes/Player/chain_gun.tscn")

# Called when the node enters the scene tree for the first time.
func init(_player: PlayerController) -> void:
	pass
	#chain_gun.initialize(self, pin_joint)

func process_update(_player: PlayerController, _delta: float) -> void:
	if !chain_gun:
		return
	if chain_gun.is_shooting:
		chain_gun.update_chain(_delta) 
	elif chain_gun.is_physics_chain:
		chain_gun.update_physics_chain()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func physics_update(_player: PlayerController, _input: PlayerInput, _delta: float) -> void:
	if chain_gun && chain_gun.is_grappling && !_player.is_on_floor():
		_player.coyote_timer.stop();
		if _input.direction:
			_player.velocity.x += _input.direction * swing_speed * acceleration 
	else:
		if _input.direction:
			_player.velocity.x = move_toward(_player.velocity.x, walk_speed * _input.direction, walk_speed * acceleration)
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0, walk_speed * deceleration)

func physics_update_after_move_and_slide(_player: PlayerController, _input: PlayerInput, _delta: float) -> void:
	apply_grapple_constraint(_player)

	# shoot chain
	if _input.shoot_pressed:
		chain_gun = chain_gun_scene.instantiate()
		get_tree().current_scene.add_child(chain_gun)
		chain_gun.chain_reel_timer = chain_gun.get_node("ChainReelTimer")
		chain_gun.chain_line = chain_gun.get_node("Line2D")
		chain_gun.initialize(_player, _player.pin_joint)
		chain_gun.shoot_chain(_player)

	#retract
	if _input.shoot_released:
		chain_gun.retract_chain()

	if !chain_gun:
		return
	chain_gun.reel_chain(_delta)
	
func apply_grapple_constraint(_player: PlayerController):
	if !chain_gun:
		return
	if !chain_gun.is_grappling:
		return

	var anchor: Vector2 = chain_gun.grapple_point
	var rope_length: float = chain_gun.rope_length

	var offset := _player.global_position - anchor
	var distance := offset.length()

	if distance > rope_length:
		var outward_direction := offset.normalized()

		_player.global_position = anchor + outward_direction * rope_length

		var outward_speed := _player.velocity.dot(outward_direction)

		if outward_speed > 0.0:
			_player.velocity -= outward_direction * outward_speed
