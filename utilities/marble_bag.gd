class_name MarbleBag extends Resource

var index := 0
var bag : Array[Enums.CellType] = [
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Grass,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Water,
	Enums.CellType.Chest,
	Enums.CellType.Sword,
	Enums.CellType.Monster,
	Enums.CellType.Monster,
	Enums.CellType.Monster,
	Enums.CellType.Monster,
	Enums.CellType.Monster,
	#Enums.CellType.Heart,
	Enums.CellType.WaterDrop
]

func init() -> void:
	bag.shuffle()

func get_next() -> Enums.CellType:
	if index == bag.size():
		index = 0
		bag.shuffle()
	var item := bag[index]
	index += 1
	return item
