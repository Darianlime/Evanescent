extends Node2D

enum State { WAITING, WARNING }

@onready var reset_timer : Timer = $Timer
@onready var falling_rock_scene = preload("res://Scenes/falling_rocks.tscn")
@onready var rock_particles : GPUParticles2D = $WarningParticles

@export var start_delay := Vector2(0.3, 4.0)
@export var wait_range := Vector2(1.5, 2.5)     
@export var warning_range := Vector2(0.5, 1.2)

var state := State.WAITING

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_on_timer_timeout)
	#rock_particles.finished.connect(_on_particles_finished)
	measure_floor()
	reset_timer.start(randf_range(start_delay.x, start_delay.y))

func measure_floor():
	for attempt in 5:
		await get_tree().physics_frame
		var from = rock_particles.global_position
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 2000))
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit:
			var mat := rock_particles.process_material as ParticleProcessMaterial
			rock_particles.lifetime = sqrt(2.0 * (hit.position.y - from.y + (mat.emission_shape_offset.y+100)) / mat.gravity.y)
			return
		push_warning("%s: no floor found below %s" % [name, rock_particles.global_position])

# func _on_particles_finished() -> void:
# 	print("Particles are completely done!")
# 	falling_rock()
# 	is_emitting_rocks = false

func _on_timer_timeout():
	match state:
		State.WAITING:
			rock_particles.restart()
			state = State.WARNING
			var lifetime_particles_min = rock_particles.lifetime / 1.8
			var lifetime_particles_max = rock_particles.lifetime / 1.2
			reset_timer.start(randf_range(lifetime_particles_min, lifetime_particles_max))
		State.WARNING:
			#rock_particles.emitting = false        
			falling_rock()
			state = State.WAITING
			reset_timer.start(randf_range(wait_range.x, wait_range.y))

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	if !is_emitting_rocks:
# 		rock_particles.restart()
# 		#reset_timer.wait_time = randf_range(2,3)
# 		#reset_timer.start()
# 		is_emitting_rocks = true
# 	# if is_reseting_rock:
# 	# 	falling_rock()

func falling_rock():
	var falling_rock_init = falling_rock_scene.instantiate()
	add_child(falling_rock_init)


