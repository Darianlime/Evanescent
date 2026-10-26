class_name PlayerController extends CharacterBody2D

@onready var coyote_timer : Timer = $CoyoteTimer
@onready var chain_spawn : Marker2D = $ChainSpawnMarker
@onready var pin_joint : PinJoint2D = $PinJoint2D
@onready var camera: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var input: PlayerInput = $PlayerInput

@export var walk_speed = 120.0
@export var jump_height := 32.0
# @export_range(0, 1) var decelerate_on_jump_release = 0.5
@export var is_starting_form_male = true
@export var player_mirror_offset := Vector2(24.0,0.0)

var male_form = preload("res://Scenes/Player/male_form.tscn")
var female_form = preload("res://Scenes/Player/female_form.tscn")
var current_player_form: Character 
var other_form: Character 
var starting_form: PackedScene   # the scene the player began as
var partner_form: PackedScene    # the scene the player began paired with
var male_form_string : String = "Male"
var female_form_string : String = "Female"
var player_mat : ShaderMaterial
var mirror_player_mat : ShaderMaterial

var active_mirror : Mirror
var respawn_mirror : Mirror

func _ready() -> void:
	starting_form = male_form if is_starting_form_male else female_form
	partner_form = female_form if is_starting_form_male else male_form
	current_player_form = starting_form.instantiate()
	other_form = partner_form.instantiate()
	add_child(current_player_form)
	add_child(other_form)
	other_form.position = player_mirror_offset
	player_mat = current_player_form.material as ShaderMaterial
	mirror_player_mat = other_form.material as ShaderMaterial
	mirror_player_mat.set_shader_parameter("min_x", active_mirror.MAX_CLIP)
	mirror_player_mat.set_shader_parameter("max_x", active_mirror.MAX_CLIP)

	current_player_form.init(self)
	other_form.init(self)
	# chain_gun.initialize(self, pin_joint)
	pass

func _process(delta: float) -> void:
	current_player_form.process_update(self, delta)
	# elif chain_gun.is_retracting:
	# 	chain_gun.update_physics_chain()

func _physics_process(delta: float) -> void:
	update_active_mirror()
	# if active_mirror && current_player_form.global_position.x - active_mirror.global_position.x > 0 && !active_mirror.is_player_coming_left:
	# 	other_form.position = -player_mirror_offset
	# else:
	# 	other_form.position = player_mirror_offset


	# if active_mirror.is_in_range(self):
	# 	if active_mirror.is_player_coming_left:
	# 		other_form.position = player_mirror_offset
	# 	else:
	# 		other_form.position = -player_mirror_offset

	current_player_form.physics_update(self, input, delta)

	# Add the gravity.
	# if not is_on_floor():
	# 	velocity += get_gravity() * delta

	# Handle jump.
	# if input.jump_pressed and (is_on_floor() or !coyote_timer.is_stopped()):
	# 	velocity.y = get_jump_velocity(jump_height, get_gravity().y)
	# 	coyote_timer.stop();

	# if input.jump_released and velocity.y < 0:
	# 	velocity.y *= decelerate_on_jump_release

	var was_on_floor = is_on_floor();

	move_and_slide()

	if was_on_floor and !is_on_floor() and velocity.y >= 0:
		coyote_timer.start();

	current_player_form.physics_update_after_move_and_slide(self, input, delta)

	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider().is_in_group("hazards"):
			death()
			break

func death():
	global_position = respawn_mirror.respawn.global_position
	if !respawn_mirror.clockwise:
		print("clockwise")
		if current_player_form.get_form_name() == male_form_string:
			swap_form()
	else:
		if current_player_form.get_form_name() == female_form_string:
			swap_form()

func get_jump_velocity(height: float, gravity: float) -> float:
	var g_dt := gravity / Engine.physics_ticks_per_second
	return -(sqrt(g_dt * g_dt + 8.0 * gravity * height) - g_dt) / 2.0

func get_rectangle_size() -> Vector2:
	var rect_shape = collision.shape as RectangleShape2D
	if rect_shape:
		return rect_shape.extents * 2.0
	return Vector2.ZERO

func update_active_mirror() -> void:
	if active_mirror and active_mirror.is_in_range(self):
		return

	var best: Mirror = null
	var best_d := INF
	for m in Mirror.objects:
		var d := absf(m.global_position.x - global_position.x)
		if d <= m.camera_distance_lock and d < best_d:
			best = m
			best_d = d

	if best == active_mirror:
		return
	if active_mirror && best != respawn_mirror:
		other_form_postiion_swap()
		#active_mirror.release()
	active_mirror = best
	if best == respawn_mirror:
		return

	if active_mirror:
		other_form_postiion_swap()
		update_forms_mirror_clipping();
		respawn_mirror = active_mirror
		#active_mirror.claim()

func other_form_postiion_swap():
	if active_mirror.global_position.x > current_player_form.global_position.x:
		other_form.position = player_mirror_offset
	else:
		other_form.position = -player_mirror_offset

func update_forms_mirror_clipping():
	player_mat = current_player_form.material as ShaderMaterial
	mirror_player_mat = other_form.material as ShaderMaterial
	if active_mirror.global_position.x > current_player_form.global_position.x:
		player_mat.set_shader_parameter("min_x", -active_mirror.MAX_CLIP)
		player_mat.set_shader_parameter("max_x", active_mirror.mirror_clip_max_x)
		mirror_player_mat.set_shader_parameter("min_x", active_mirror.mirror_clip_min_x)
		mirror_player_mat.set_shader_parameter("max_x", active_mirror.MAX_CLIP)
	else:
		player_mat.set_shader_parameter("min_x", active_mirror.mirror_clip_min_x)
		player_mat.set_shader_parameter("max_x", active_mirror.MAX_CLIP)
		mirror_player_mat.set_shader_parameter("min_x", -active_mirror.MAX_CLIP)
		mirror_player_mat.set_shader_parameter("max_x", active_mirror.mirror_clip_max_x)

func swap_form():
	var new_pos = current_player_form.position - other_form.position
	var current_pos = current_player_form.position
	var tmp := current_player_form
	current_player_form = other_form
	other_form = tmp
	#move_and_collide(new_pos - global_position)
	current_player_form.position = current_pos 
	other_form.position = new_pos 
	global_position -= new_pos
	#other_form.position = Vector2.ZERO
