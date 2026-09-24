class_name Cell extends Sprite2D

const GRASS_CELL = preload("uid://bwm3k038qgpj8")
const WATER_CELL = preload("uid://cl2xo0mplejxw")
const SWORD = preload("uid://7uvp7y58yoin")
const CHEST = preload("uid://dgghjfc7wbhe3")
const HEART = preload("uid://d2cht3uqg5f8e")
const WATER_DROP = preload("uid://d1cmlga43joh2")
const BAT = preload("uid://mdxhc5bmkue0")
const LIFE_PRESERVER = preload("uid://bdh55uhmfbb2p")

var cell_position : Vector2i
var cellType: Enums.CellType = Enums.CellType.Grass
var marble_bag : MarbleBag 

func init() -> void:
	marble_bag = MarbleBag.new()
	marble_bag.init()
	randomize_type()
	set_texture_by_type()
	
func randomize_type() -> void:
	cellType = marble_bag.get_next()
	
func set_texture_by_type() -> void:
	match cellType:
		Enums.CellType.Grass:
			texture = GRASS_CELL
		Enums.CellType.Water:
			texture = WATER_CELL
		Enums.CellType.Sword:
			texture = SWORD
		Enums.CellType.WaterDrop:
			texture = LIFE_PRESERVER
		Enums.CellType.Heart:
			texture = HEART
		Enums.CellType.Chest:
			texture = CHEST
		Enums.CellType.Monster:
			texture = BAT

func set_type(val: Enums.CellType) -> void:
	cellType = val
	set_texture_by_type()
