class_name Mirror extends Node2D

static var objects: Array[Mirror] = []

@export var camera_offset : Vector2 = Vector2(0.0, 0.0)
@export var camera_distance_lock := 50.0
@export var clockwise := false

@onready var player: PlayerController = %Player
@onready var mirror_collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var respawn: Node2D = $RespawnPoint
@onready var lock_zone: Area2D = $LockZone
#@onready var player_sprite: Sprite2D = player.get_node("Sprite2D")

const MAX_CLIP = 1000000.0
var mirror_clip_min_x := 0.0
var mirror_clip_max_x := 0.0
var mirror_clip_max_y := 0.0
var progress_start := 0.0  # world state on the side the player arrives from
var progress_end := 1.0    # world state on the far side

var camera_locked_to_target := false
var is_player_coming_left := true
var entered_from_left := true
var mirror_size := Vector2.ZERO

var spiral_progress := 0.0:
	set(value):
		value = clampf(value, 0.0, 1.0)
		if value == spiral_progress:
			return
		spiral_progress = value
		RenderingServer.global_shader_parameter_set("spiral_progress", spiral_progress)

func is_in_range(p: Node2D) -> bool:
	return lock_zone.overlaps_body(p)

func _ready() -> void:
	objects.append(self)
	var rect := mirror_collision.shape as RectangleShape2D
	assert(rect != null, "Mirror collision must be a RectangleShape2D")
	mirror_size = rect.size

	# player_mat = player.current_player_form.get_node("Sprite2D").material as ShaderMaterial
	# mirror_player_mat = player.other_form.get_node("Sprite2D").material as ShaderMaterial
	var mirror_size_half := mirror_size / 2.0
	mirror_clip_max_x = global_position.x + mirror_size_half.x
	mirror_clip_min_x = global_position.x - mirror_size_half.x
	mirror_clip_max_y = global_position.y - mirror_size_half.y

	# player_mat.set_shader_parameter("max_x", mirror_clip_max_x)
	# mirror_player_mat.set_shader_parameter("min_x", mirror_clip_min_x)
	if clockwise:
		progress_start = 1.0
		progress_end = 0.0

func _process(_delta: float) -> void:
	if player.active_mirror != self:
		if camera_locked_to_target:     
			update_camera_lock(false)
		return
		
	update_camera_lock(true)      
	update_spiral_center()    
	var t := clampf(calc_progress(), 0.0, 1.0)
	spiral_progress = lerpf(progress_start, progress_end, t)


func _exit_tree() -> void:
	objects.erase(self)

func calc_progress() -> float:
	var player_half = player.get_rectangle_size().x / 2.0
	var mirror_half := mirror_size.x / 2.0
	var travel = mirror_size.x * 0.75 + player_half
	var player_x = player.collision.global_position.x

	if is_player_coming_left:
		var overlap = (player_x + player_half) - (global_position.x - mirror_half)
		return overlap / travel
	else:
		var overlap = (global_position.x + mirror_half) - (player_x - player_half)
		return 1.0 - overlap / travel

func update_camera_lock(should_lock: bool) -> void:
	if should_lock == camera_locked_to_target:
		return
	camera_locked_to_target = should_lock
	if should_lock:
		player.camera.lock_to_position(global_position)
	else:
		player.camera.focus_on(player.current_player_form)

func update_spiral_center() -> void:
	var vp := get_viewport()
	var screen_pos := vp.get_canvas_transform() * mirror_collision.global_position
	var uv := screen_pos / vp.get_visible_rect().size
	RenderingServer.global_shader_parameter_set("spiral_center", uv)

# func spawn_mirror_character() -> void:
# 	if current_mirror_character:
# 		return
# 	current_mirror_character = mirror_character.instantiate()
# 	mirror_player_mat = current_mirror_character.get_node("Sprite2D").material as ShaderMaterial
# 	mirror_player_mat.set_shader_parameter("min_x", mirror_clip_min_x)
# 	player.add_child(current_mirror_character)
# 	current_mirror_character.position = Vector3()
# 	#player_remote.remote_path = current_mirror_character.get_path()
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		entered_from_left = player.global_position.x < global_position.x
		RenderingServer.global_shader_parameter_set("is_spiral_clockwise", clockwise)
		#player_mat.set_shader_parameter("max_y", mirror_clip_max_y)
		print(spiral_progress)
		# if is_player_coming_left:
		# 	RenderingServer.global_shader_parameter_set("is_spiral_switching_colors", false)
		# 	spiral_progress = 0.0
		# else:
		# 	RenderingServer.global_shader_parameter_set("is_spiral_switching_colors", false)
		# 	spiral_progress = 1.0

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body != player:
		return
	var x := player.global_position.x
	var crossed = (entered_from_left and x >= mirror_clip_max_x) or (not entered_from_left and x <= mirror_clip_min_x)

	if x <= mirror_clip_min_x:
		is_player_coming_left = true  
	elif x >= mirror_clip_max_x:
		is_player_coming_left = false

	if not crossed:
		return                          
	player.swap_form()
	player.checkpoint_mirror = self
		# if is_player_coming_left:
		# 	RenderingServer.global_shader_parameter_set("is_spiral_switching_colors", false)
		# 	spiral_progress = 0.0
		# else:
		# 	RenderingServer.global_shader_parameter_set("is_spiral_switching_colors", true)
		# 	RenderingServer.global_shader_parameter_set("spiral_progress", 0.0)
			#spiral_progress = 0.0
			#RenderingServer.global_shader_parameter_set("spiral_progress", 1.0)
