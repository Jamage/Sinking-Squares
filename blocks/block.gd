class_name Block extends Node2D

@export var blockType = Enums.BlockType.I
const CELL = preload("uid://dlwa3axe3dxrc")
var cellPos : Vector2i = Vector2i.ZERO
var cell_positions : Array[Vector2i] = []
var projected_cell_positions : Array[Vector2i] = []
var cells : Array[Cell] = []
var previousRotation : int = 0
var amountRotated : int = 0
var cellCount = 4

func set_random_type() -> void:
	blockType = Enums.BlockType.values().pick_random()

func set_type(val : Enums.BlockType) -> void:
	blockType = val

func init() -> void:
	match blockType:
		Enums.BlockType.I, Enums.BlockType.O, Enums.BlockType.J, Enums.BlockType.L, Enums.BlockType.S, Enums.BlockType.Z, Enums.BlockType.T:
			cellCount = 4
			
	for i in range(cellCount):
		var cell = CELL.instantiate()
		add_child(cell)
		cell.init()
		cells.append(cell)
	update_cell_positions()
		
func rotate_piece(isCW : bool) -> void:
	if isCW:
		previousRotation = amountRotated
		amountRotated += 90
	else:
		previousRotation = amountRotated
		amountRotated -= 90
	amountRotated = (360 + amountRotated) % 360
	update_cell_positions()

func update_cell_positions() -> void:
	cell_positions = get_cell_positions_for(blockType, amountRotated)
	for i in range(cells.size()):
		var cell : Cell = cells[i]
		cell.position = cell_positions[i] * 16
		cell.cell_position = cell_positions[i]
		
func get_cell_positions_for(_blockType: Enums.BlockType, _rotation: int) -> Array[Vector2i]:
	match _blockType:
		Enums.BlockType.I:
			if _rotation == 0:
				return [
					Vector2i(-2, 1),
					Vector2i(-1, 1),
					Vector2i(0, 1),
					Vector2i(1, 1),
					]
			elif _rotation == 90:
				return [
					Vector2i(0, -2),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(0, 1),
					]
			elif _rotation == 180:
				return [
					Vector2i(1, 0),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					Vector2i(-2, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 1),
					Vector2i(-1, 0),
					Vector2i(-1, -1),
					Vector2i(-1, -2),
					]
		Enums.BlockType.O:
			if _rotation == 0:
				return [
					Vector2i(-1, -1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					Vector2i(-1, -1),
					]
			elif _rotation == 180:
				return [
					Vector2i(0, 0),
					Vector2i(-1, 0),
					Vector2i(-1, -1),
					Vector2i(0, -1),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 0),
					Vector2i(-1, -1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					]
		Enums.BlockType.J:
			if _rotation == 0:
				return [
					Vector2i(-1, -1),
					Vector2i(-1, 0),
					Vector2i(0, 0),
					Vector2i(1, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(1, -1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(0, 1),
					]
			elif _rotation == 180:
				return [
					Vector2i(1, 1),
					Vector2i(1, 0),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 1),
					Vector2i(0, 1),
					Vector2i(0, 0),
					Vector2i(0, -1),
					]
		Enums.BlockType.L:
			#      1
			#  2 3 4
			if _rotation == 0:
				return [
					Vector2i(1, -1),
					Vector2i(-1, 0),
					Vector2i(0, 0),
					Vector2i(1, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(1, 1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(0, 1),
					]
			elif _rotation == 180:
				return [
					Vector2i(-1, 1),
					Vector2i(1, 0),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, -1),
					Vector2i(0, 1),
					Vector2i(0, 0),
					Vector2i(0, -1),
					]
		Enums.BlockType.S:
			#   1 2
			# 3 4
			if _rotation == 0:
				return [
					Vector2i(0, -1),
					Vector2i(1, -1),
					Vector2i(-1, 0),
					Vector2i(0, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(1, 0),
					Vector2i(1, 1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					]
			elif _rotation == 180:
				return [
					Vector2i(0, 1),
					Vector2i(-1, 1),
					Vector2i(1, 0),
					Vector2i(0, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 0),
					Vector2i(-1, -1),
					Vector2i(0, 1),
					Vector2i(0, 0),
					]
		Enums.BlockType.Z:
			# 1 2
			#   3 4
			if _rotation == 0:
				return [
					Vector2i(-1, -1),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(1, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(1, -1),
					Vector2i(1, 0),
					Vector2i(0, 0),
					Vector2i(0, 1),
					]
			elif _rotation == 180:
				return [
					Vector2i(1, 1),
					Vector2i(0, 1),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 1),
					Vector2i(-1, 0),
					Vector2i(0, 0),
					Vector2i(0, -1),
					]
		Enums.BlockType.T:
			#   1
			# 2 3 4
			if _rotation == 0:
				return [
					Vector2i(0, -1),
					Vector2i(-1, 0),
					Vector2i(0, 0),
					Vector2i(1, 0),
					]
			elif _rotation == 90:
				return [
					Vector2i(1, 0),
					Vector2i(0, -1),
					Vector2i(0, 0),
					Vector2i(0, 1),
					]
			elif _rotation == 180:
				return [
					Vector2i(0, 1),
					Vector2i(1, 0),
					Vector2i(0, 0),
					Vector2i(-1, 0),
					]
			elif _rotation == 270:
				return [
					Vector2i(-1, 0),
					Vector2i(0, 1),
					Vector2i(0, 0),
					Vector2i(0, -1),
					]
	printerr("Block type and rotation were not matched in get_cell_positions_for")
	return []
	
func get_cells() -> Array[Cell]:
	return cells

func set_cells(vals: Array[Cell]) -> void:
	if cells.size() != vals.size():
		printerr("Trying to set cells on block with different size")
		print("Cells size: %d , CurrBlock size: %d" % [cells.size(), vals.size()])
		return
		
	for i in cells.size():
		cells[i].set_type(vals[i].cellType)

func set_ghost() -> void:
	modulate.a = .40
