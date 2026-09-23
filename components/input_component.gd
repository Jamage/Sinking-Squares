class_name InputComponent
extends Resource

var move_dir: Vector2 = Vector2.ZERO
var action_pressed := false
var direction_pressed := false
var back_pressed := false
var rotate_cw_pressed := false
var rotate_ccw_pressed := false
var start_pressed := false
var right_pressed := false
var left_pressed := false
var up_pressed := false
var down_pressed := false
var hold_pressed := false
var swap_mode_pressed := false

func process(_delta: float) -> void:
	#move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	right_pressed = Input.is_action_just_pressed("move_right")
	left_pressed = Input.is_action_just_pressed("move_left")
	up_pressed = Input.is_action_just_pressed("move_up")
	down_pressed = Input.is_action_just_pressed("move_down")
	rotate_cw_pressed = Input.is_action_just_pressed("rotate_cw")
	rotate_ccw_pressed = Input.is_action_just_pressed("rotate_ccw")
	direction_pressed = move_dir != Vector2.ZERO
	start_pressed = Input.is_action_just_pressed("start")
	hold_pressed = Input.is_action_just_pressed("hold")
	swap_mode_pressed = Input.is_action_just_pressed("swap_mode")
