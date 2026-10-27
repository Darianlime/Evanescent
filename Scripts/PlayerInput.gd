class_name PlayerInput extends Node

var direction := 0.0
var jump_pressed := false
var dash_pressed := false
var charge_jump_pressed := false
var charge_jump_released := false
var jump_released := false
var shoot_pressed := false
var shoot_released := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:	
	direction = Input.get_axis("left", "right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	charge_jump_pressed = Input.is_action_just_pressed("charge_jump")
	charge_jump_released = Input.is_action_just_released("charge_jump")
	shoot_pressed = Input.is_action_just_pressed("shoot")
	shoot_released = Input.is_action_just_released("shoot")
	dash_pressed = Input.is_action_just_pressed("dash")

