class_name ChainGun
extends Node2D

enum ChainGunState { IDLE, GRAPPLING, RETRACTING, REELING }

@onready var chain_reel_timer : Timer = $ChainReelTimer
@onready var chain_line: Line2D = $Line2D

var player: CharacterBody2D
var player_pin_joint: PinJoint2D

var chain_gun_pos_offset: Vector2
var chain_tip: RigidBody2D
var chains: Array[RigidBody2D] = []
var chain_direction: Vector2
var chain_start: Vector2
var chain_end: Vector2
var perpendicular : Vector2
var chain_distance := 0.0
var shoot_progress := 0.0
var grapple_point := Vector2.ZERO
var rope_length := 0.0
var reel_remaining_segments := 0

var hit_joint : PinJoint2D

var is_shooting = false
var is_retracting = false
var is_chain_retracted_out = false
var is_physics_chain = false
var is_chain_tip_hit = false
var is_grappling = false
var is_reeling = false
@export var shoot_speed = 1000
@export var reel_speed := 500.0
@export var min_rope_length := 48.0
@export var chain_segments = 10
@export var wobble_amplitude := 20.0
@export var wobble_frequency := 3.0

var segment_length = 48.0
var delay: float:
	get:
		return segment_length / shoot_speed
var target_distance: float:
	get:
		return chain_segments * segment_length
var actual_target_distance: float = 0

var chain_tip_init = preload("res://Scenes/Player/chain_tip.tscn")
var chain_init = preload("res://Scenes/Player/chain.tscn")

const CHAIN_GUN_NAME = "ChainGun"

func initialize(player_ref: CharacterBody2D, pin_joint_ref: PinJoint2D):
	player = player_ref
	player_pin_joint = pin_joint_ref

func on_chain_hit(body: Node) -> void:
	if is_chain_tip_hit:
		return

	is_chain_tip_hit = true
	actual_target_distance = shoot_progress * actual_target_distance
	var new_chain_length = ceilf(actual_target_distance/segment_length)
	for i in range(chains.size()-1, new_chain_length - 1, -1):
		if is_instance_valid(chains[i]):
			chains[i].queue_free()
		chains.remove_at(i)

	hit_joint = PinJoint2D.new()
	get_tree().current_scene.add_child(hit_joint)
	hit_joint.node_a = body.get_path()
	hit_joint.node_b = chain_tip.get_path()

	is_grappling = true
	grapple_point = chain_tip.global_position
	rope_length = player.global_position.distance_to(grapple_point)
	reel_remaining_segments = ceili(rope_length / 48.0)

func reel_chain(delta):
	if !chain_reel_timer.is_stopped() or !is_grappling:
		return
	print("reeling")
	is_reeling = true
	rope_length = maxf(min_rope_length, rope_length - reel_speed * delta)
	var remaining_segments = ceili(rope_length / 48.0)
	if is_instance_valid(chains[0]) && remaining_segments >= 1 && reel_remaining_segments != remaining_segments:
		var front = chains.pop_front()
		front.queue_free()
		reel_remaining_segments = remaining_segments

	print(remaining_segments)
	

func retract_chain():
	if is_retracting:
		return

	is_chain_tip_hit = true
	is_retracting = true
	is_shooting = false
	is_physics_chain = false
	is_grappling = false
	is_reeling = false

	if hit_joint:
		hit_joint.queue_free()

	# Disconnect player
	player_pin_joint.node_b = NodePath()

	# Disable chain physics while retracting
	for chain in chains:
		var joint: PinJoint2D = chain.get_node("PinJoint2D")
		joint.node_a = NodePath()
		joint.node_b = NodePath()

		chain.freeze = true

	while chains.size() > 0:
		var first_chain = chains.pop_front()
		first_chain.queue_free()

		# Move the first remaining chain toward the player
		if chains.size() > 0:
			var direction = (player.chain_spawn.global_position - chains[0].global_position).normalized()

			chains[0].global_position = (player.chain_spawn.global_position - direction * segment_length)

		# Each following chain follows the chain before it
		for i in range(1, chains.size()):
			var direction = (chains[i - 1].global_position - chains[i].global_position).normalized()
			chains[i].global_position = (chains[i - 1].global_position - direction * segment_length)

		# Hook follows the last chain
		if chain_tip and chains.size() > 0:
			var direction = (chains.back().global_position - chain_tip.global_position).normalized()
			chain_tip.global_position = (chains.back().global_position - direction * segment_length)
			chain_tip.rotation = direction.angle() + PI / 2

		update_physics_chain()

		await get_tree().create_timer(delay).timeout

	# Remove hook
	if chain_tip:
		chain_tip.queue_free()
		chain_tip = null

	player_pin_joint.node_b = NodePath()

	chains.clear()
	chain_line.clear_points()

	is_retracting = false
	is_chain_retracted_out = false

func shoot_chain():
	if is_retracting or is_shooting or is_chain_retracted_out:
		return

	is_chain_tip_hit = false
	shoot_progress = 0
	actual_target_distance = target_distance

	chain_start = player.chain_spawn.global_position
	chain_direction = (get_global_mouse_position() - chain_start).normalized()
	chain_end = chain_start + chain_direction * target_distance
	var angle = chain_direction.angle() + PI / 2

	chain_tip = chain_tip_init.instantiate()
	add_child(chain_tip)
	chain_tip.hit_object.connect(on_chain_hit)
	chain_tip.global_position = chain_start
	chain_tip.global_rotation = angle
	chain_tip.lock_rotation = true
	chain_tip.freeze = true

	for i in range(chain_segments):
		var chain : RigidBody2D = chain_init.instantiate()
		add_child(chain)

		chain.global_rotation = angle
		chain.lock_rotation = true
		chain.freeze = true
		chain.visible = false

		chains.append(chain)

	perpendicular = Vector2(-chain_direction.y, chain_direction.x)

	chain_reel_timer.start()

	is_shooting = true
	is_chain_retracted_out = true

func update_chain(delta):
	if !is_shooting:
		return

	chain_start = player.chain_spawn.global_position
	shoot_progress = move_toward(shoot_progress, 1.0, shoot_speed * delta / actual_target_distance)
	if shoot_progress >= 1.0:
		shoot_progress = 1.0
		activate_chain_physics()
		return

	var current_distance = actual_target_distance * shoot_progress

	var points := PackedVector2Array()
	var resolution := 40

	# Wobble gets weaker as the shot progresses
	var wave_strength = 1.0 - shoot_progress

	for i in range(resolution + 1):
		var t := float(i) / resolution
		var distance = current_distance * t
		var envelope := sin(t * PI)

		var wave = (
			sin(t * PI * 2.0 * wobble_frequency)
			* wobble_amplitude
			* envelope
			* wave_strength
		)

		var base_position = chain_start + chain_direction * distance
		var position = base_position + perpendicular * wave
		points.append(to_local(position))

	chain_line.points = points

	for i in range(chains.size()):
		var t := float(i + 0.5) / chains.size()
		var distance = current_distance * t

		var position = chain_start + chain_direction * distance
		chains[i].global_position = position

	var hook_position = chain_start + chain_direction * current_distance
	chain_tip.global_position = hook_position

func activate_chain_physics():
	is_shooting = false
	is_physics_chain = true
	var previous: RigidBody2D = chain_tip
	chain_tip.lock_rotation = false
	chain_tip.freeze = false
	for i in range(chains.size()-1, -1, -1):
		var joint: PinJoint2D = chains[i].get_node("PinJoint2D")

		joint.node_a = previous.get_path()
		joint.node_b = chains[i].get_path()

		chains[i].freeze = false
		chains[i].lock_rotation = false
		# chains[i].visible = true

		previous = chains[i]

	player_pin_joint.node_a = player.get_path()
	player_pin_joint.node_b = previous.get_path()

func update_physics_chain():
	var points := PackedVector2Array()

	points.append(to_local(player.chain_spawn.global_position))

	for chain in chains:
		points.append(to_local(chain.global_position))

	points.append(to_local(chain_tip.global_position))

	chain_line.points = points
