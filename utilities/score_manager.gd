extends Node

const SAVEFILE = "user://highscores.save"

var highest_record := 0

func _ready():
	load_score()

func save_score() -> void:
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE_READ)
	file.store_32(highest_record)
	file.close()
	
func load_score() -> void:
	var file = FileAccess.open(SAVEFILE, FileAccess.READ)
	if FileAccess.file_exists(SAVEFILE):
		highest_record = file.get_32()
		file.close()
