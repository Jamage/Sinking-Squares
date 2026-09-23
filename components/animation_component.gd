class_name AnimationComponent
extends AnimatedSprite2D

#If moving to Resource implementation, store this
#And change update to use input_component.move_dir
#@export var sprite : AnimatedSprite2D = %AnimationComponent

var lastDir : Vector2 = Vector2.ZERO

const FACE_TOWARD : String = "face_toward"
const FACE_AWAY : String = "face_away"
const FACE_SIDE : String = "face_side"
const WALK_TOWARD : String = "walk_toward"
const WALK_AWAY : String = "walk_away"
const WALK_SIDE : String = "walk_side"

func _ready() -> void:
	self.play(FACE_TOWARD)

func update(_delta: float, direction: Vector2) -> void:
	if direction.y < 0:
		self.play(WALK_AWAY)
		self.flip_h = false
	elif direction.y > 0:
		self.play(WALK_TOWARD)
		self.flip_h = false
	elif direction.x > 0:
		self.play(WALK_SIDE)
		self.flip_h = false
	elif direction.x < 0:
		self.play(WALK_SIDE)
		self.flip_h = true
	elif direction == Vector2.ZERO && lastDir != Vector2.ZERO:
		if lastDir.y > 0:
			self.play(FACE_TOWARD)
			self.flip_h = false
		elif lastDir.y < 0:
			self.play(FACE_AWAY)
			self.flip_h = false
		elif lastDir.x != 0:
			self.play(FACE_SIDE)
	
	lastDir = direction
