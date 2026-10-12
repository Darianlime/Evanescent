extends Node2D

@onready var background : ColorRect = $%BackgroundLayer/ColorRect
@onready var player: CharacterBody2D = $"../Player"
@onready var mirror_collision: CollisionShape2D = $"Area2D/CollisionShape2D"

@export var camera_distance_lock : float = 300

var shader_mat : ShaderMaterial
var camera_locked_to_target := false
var is_player_coming_left := true

var player_right : float
var collision_left : float
var transition_side : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if background.material is ShaderMaterial:
		shader_mat = background.material as ShaderMaterial
		var current_progress = shader_mat.get_shader_parameter("progress")
		print("Current progress:", current_progress)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera_lock()
	if absf(player.global_position.x - global_position.x) > camera_distance_lock:
		return
	var player_collision_size = player.get_rectangle_size()
	var demon = (((get_rectangle_size().x/2) + get_rectangle_size().x)/2) + (player_collision_size.x / 2.0)
	if is_player_coming_left:
		player_right = player.collision.global_position.x + (player_collision_size.x / 2.0)
		collision_left = global_position.x - (get_rectangle_size().x/2.0)
		transition_side = (player_right - collision_left) / demon
	else:
		player_right = global_position.x + (get_rectangle_size().x/2.0)
		collision_left = player.collision.global_position.x - (player_collision_size.x / 2.0)
		transition_side = 1 - ((player_right - collision_left) / demon)

	var player_mirror_pos = transition_side
	shader_mat.set_shader_parameter("progress", player_mirror_pos)
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	pass

func _on_area_2d_body_exited(body: Node2D) -> void:
	var progress = shader_mat.get_shader_parameter("progress")
	print(progress)
	if is_player_coming_left and progress >= 1:
		print("in")
		is_player_coming_left = false
	elif progress <= 0.0:
		is_player_coming_left = true
	print("exit")

func camera_lock():
	var distance_x := absf(player.global_position.x - global_position.x) 
	var should_lock := distance_x <= camera_distance_lock 

	if should_lock == camera_locked_to_target: 
		return

	camera_locked_to_target = should_lock

	if camera_locked_to_target: 
		player.camera.lock_to_position(self.global_position) 
	else: 
		player.camera.focus_on(player)

func get_rectangle_size() -> Vector2:
	var rect_shape = mirror_collision.shape as RectangleShape2D
	if rect_shape:
		return rect_shape.extents * 2.0
	return Vector2.ZERO
