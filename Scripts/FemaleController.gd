class_name FemaleController extends Character

@onready var umbrella_sprite : Sprite2D = $UmbrellaSprite
@onready var timer: Timer = $DashTimer
@export var glide_fall_speed := 50.0   # px/s, the slowest you'll sink while gliding
@export var glide_brake := 1000.0      # px/s², how fast you slow down
@export var dash_distance := 80.0 	   # px
@export var dash_time := 0.3 	   # px
@export var dash_cooldown := 0.6
var cooldown_left := 0.0
var is_dashing = false
var dash_direction : float = 0.0
var umbrella_mat : ShaderMaterial = material as ShaderMaterial

func _on_dash_timer_timeout():
	is_dashing = false
	cooldown_left = dash_cooldown

func physics_update(_player: PlayerController, _input: PlayerInput, _delta: float) -> void:
	cooldown_left = maxf(cooldown_left - _delta, 0.0)

	if _input.dash_pressed and not is_dashing and cooldown_left == 0.0:
		dash_direction = signf(_input.direction) if _input.direction != 0.0 else 0.0 
		timer.start(dash_time)
		is_dashing = true

	if is_dashing:
		var dash_speed = dash_distance / dash_time
		_player.velocity.x = dash_direction * dash_speed
		_player.velocity.y = 0
		return

	if _input.direction:
		_player.velocity.x = move_toward(_player.velocity.x, _player.walk_speed * _input.direction, _player.walk_speed * acceleration)
	else:
		_player.velocity.x = move_toward(_player.velocity.x, 0, _player.walk_speed * deceleration)

	var is_gliding := false

	var _mouse_direction = (get_global_mouse_position() - global_position).normalized()
	var angle = _mouse_direction.angle() + PI / 2
	var angle_deg = wrapf(rad_to_deg(angle), -180.0, 180.0)
	if !_player.is_on_floor() && (angle_deg < -135 || angle_deg > 135):
		umbrella_sprite.rotation = deg_to_rad(180)
	elif angle_deg > 45:
		umbrella_sprite.rotation = deg_to_rad(90)
		umbrella_sprite.flip_h = false
	elif angle_deg < -45:
		umbrella_sprite.rotation = deg_to_rad(-90)
		umbrella_sprite.flip_h = true
	else:
		umbrella_sprite.rotation = deg_to_rad(0)
		is_gliding = true

	if not _player.is_on_floor():
		_player.velocity += _player.get_gravity() * _delta
		if is_gliding and _player.velocity.y > glide_fall_speed:
			_player.velocity.y = move_toward(_player.velocity.y, glide_fall_speed, glide_brake * _delta)

	if _player.input.jump_pressed and (_player.is_on_floor() or !_player.coyote_timer.is_stopped()):
		_player.velocity.y = _player.get_jump_velocity(_player.jump_height, _player.get_gravity().y)
		_player.coyote_timer.stop();

	
