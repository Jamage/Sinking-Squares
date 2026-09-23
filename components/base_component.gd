class_name BaseComponent extends Resource

var actor

func update(_delta: float) -> void:
	pass

func bind(_actor) -> void:
	actor = _actor
