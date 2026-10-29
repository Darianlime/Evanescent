class_name MaleController extends Character

@onready var chain_gun: ChainGun
@export var swing_speed = 300.0
@export var max_jump_height = 96.0
@export var charge_time := 0.7
@export var release_boost := 140.0 
@export var release_angle := 30.0 
@export var release_control_lock := 0.25
const chain_gun_scene = preload("res://Scenes/Player/chain_gun.tscn")
var is_jump_held := false
var new_jump_height : float = 0.0
var charge := 0.0
var launch_time_left := 0.0

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
	launch_time_left = maxf(launch_time_left - _delta, 0.0)
	if _player.is_on_floor():
		launch_time_left = 0.0 

	if not _player.is_on_floor():
		_player.velocity += _player.get_gravity() * _delta

	if chain_gun && chain_gun.is_grappling && !_player.is_on_floor():
		_player.coyote_timer.stop();
		if _input.direction:
			_player.velocity.x += _input.direction * swing_speed * acceleration 
	elif launch_time_left > 0.0:
		pass  
	else:
		if _input.direction and is_jump_held and charge > 0:
			_player.velocity.x = move_toward(_player.velocity.x, 50.0 * _input.direction, _player.walk_speed * deceleration)
		elif _input.direction:
			_player.velocity.x = move_toward(_player.velocity.x, _player.walk_speed * _input.direction, _player.walk_speed * acceleration)
		else:
			_player.velocity.x = move_toward(_player.velocity.x, 0, _player.walk_speed * deceleration)
	
	if _player.input.charge_jump_pressed and (_player.is_on_floor() or !_player.coyote_timer.is_stopped()):
		is_jump_held = true
		charge = 0.0

	var _t = 0.0
	if is_jump_held:
		charge += _delta
		_t = clampf(charge / charge_time, 0.0, 1.0)

	if _player.input.charge_jump_released:
		is_jump_held = false

	if _player.input.jump_pressed and (_player.is_on_floor() or !_player.coyote_timer.is_stopped()):
		var height := lerpf(_player.jump_height, max_jump_height, _t)
		_player.velocity.y = _player.get_jump_velocity(height, _player.get_gravity().y)
		_player.coyote_timer.stop();

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

	if !chain_gun:
		return

	#retract
	if _input.jump_pressed:
		if chain_gun.is_grappling:          # check before retract_chain() clears it
			launch_from_rope(_player, _input)
		chain_gun.retract_chain()
	elif _input.shoot_released:
		chain_gun.retract_chain()

	chain_gun.reel_chain(_delta)

func launch_from_rope(_player: PlayerController, _input: PlayerInput) -> void:
	var dir := signf(_player.velocity.x) 
	if dir == 0.0:
		dir = signf(_input.direction)
	if dir == 0.0:
		return                              

	var old_speed := _player.velocity.length()
	var a := deg_to_rad(release_angle)
	_player.velocity += Vector2(cos(a) * dir, -sin(a)) * release_boost
	#_player.velocity = _player.velocity.limit_length(maxf(release_speed_cap, old_speed))
	launch_time_left = release_control_lock
	
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

func get_form_name() -> String:
	return "Male"
