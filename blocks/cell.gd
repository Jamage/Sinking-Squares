class_name Cell extends Sprite2D

const GRASS_CELL = preload("uid://bwm3k038qgpj8")
const WATER_CELL = preload("uid://cl2xo0mplejxw")

var cell_position : Vector2i
var cellType: Enums.CellType = Enums.CellType.Grass

func init() -> void:
	randomize_type()
	set_texture_by_type()
	
func randomize_type() -> void:
	cellType = Enums.CellType.values().pick_random()
	
func set_texture_by_type() -> void:
	match cellType:
		Enums.CellType.Grass:
			texture = GRASS_CELL
		Enums.CellType.Water:
			texture = WATER_CELL

func set_type(val: Enums.CellType) -> void:
	cellType = val
	set_texture_by_type()
