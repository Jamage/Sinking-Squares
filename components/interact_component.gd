class_name InteractionComponent extends Area2D

signal on_interact(_actor)

func interact(_actor) -> void:
	print("INTERACTING WITH %s" % get_parent().name)
	on_interact.emit(_actor)
