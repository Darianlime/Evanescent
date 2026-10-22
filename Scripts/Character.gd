class_name Character extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export_range(0, 1) var acceleration := 0.1
@export_range(0, 1) var deceleration := 0.1

func enter(_player: PlayerController) -> void: pass   
func exit(_player: PlayerController) -> void: pass
func init(_player: PlayerController) -> void: pass
func process_update(_player: PlayerController, _delta: float) -> void: pass
func physics_update(_player: PlayerController, _input: PlayerInput, _delta: float) -> void: pass
func physics_update_after_move_and_slide(_player: PlayerController, _input: PlayerInput, _delta: float) -> void: pass
