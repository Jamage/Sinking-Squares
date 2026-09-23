class_name MovementComponent extends BaseComponent

@export var speed := 160.0

func bind(_actor) -> void:
	super.bind(_actor)

func update(_delta: float) -> void:
	if actor == null:
		return
	
	#actor.position += actor.input_component.move_dir.normalized() * _delta * speed
	actor.velocity = actor.input_component.move_dir.normalized() * speed
	actor.move_and_slide()
