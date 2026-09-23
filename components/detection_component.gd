class_name DetectionComponent 
extends Area2D

var detected_area : InteractionComponent
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@export var parent : Node2D
@export var distance : float = 48.0
@export var size : float = 7.0

func _ready() -> void:
	if collision_shape_2d.shape is CircleShape2D:
		var shape : CircleShape2D = collision_shape_2d.shape as CircleShape2D
		shape.radius = size

func _on_area_entered(_area: Area2D) -> void:
	print("detected area")
	if _area is InteractionComponent:
		detected_area = _area
	else:
		print("Not InteractionComponent")

func _on_area_exited(_area: Area2D) -> void:
	if _area is InteractionComponent and detected_area == _area:
		detected_area = null

func on_move(direction: Vector2) -> void:
	position = Vector2.ZERO + direction.normalized() * distance
