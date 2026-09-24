extends Node2D

@export var input : InputComponent
@onready var player: Sprite2D = %Player

@onready var spawn_parent: Node2D = $SpawnParent
@onready var placed_parent: Node2D = $PlacedParent
@onready var bag_parent: Node2D = $BagParent
@onready var marker_parent: Node2D = $MarkerParent

@onready var block_fall_timer: Timer = $BlockFallTimer
@onready var sinking_timer: Timer = $SinkingTimer
@onready var row_clear_timer: Timer = $RowClearTimer

@onready var score_label: RichTextLabel = %ScoreLabel
@onready var high_score_label: RichTextLabel = %HighScoreLabel
@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var game_over_menu: Control = %GameOverMenu
@onready var restart_button: Button = %RestartButton
@onready var game_over_high_score_value_label: RichTextLabel = %GameOverHighScoreValueLabel
@onready var game_over_score_value_label: RichTextLabel = %GameOverScoreValueLabel
@onready var swim_label: RichTextLabel = %SwimLabel
@onready var attack_label: RichTextLabel = %AttackLabel
@onready var virtual_controls: Control = %VirtualControls

const BLOCK = preload("uid://5o6p687rj8tl")
const GRASS_CELL = preload("uid://dlwa3axe3dxrc")
const ONE = preload("uid://qu0ooakj8j5j")
const TWO = preload("uid://6o5ud7bwd701")
const THREE = preload("uid://0r4qrewj157g")

var cell_height : int = 16
var cell_width : int = 16
var grid_height : int = 20
var grid_width : int = 10

var gridObjects : Dictionary[Vector2i, Cell] = {}

var currentBlock : Block
var centerPos : Vector2i = Vector2i(5, -1)
var ghostBlock : Block
var playerPosition := Vector2i(5, 17)
var sinkingOffset : float = 0.0
var pieceMode := true
var highestCell : int = 17

var bagOrder : Array[Enums.BlockType]
var bag : Array[Block]

var paused := false
var gameOver := false

var score : float = 0.0
var scoreBonus : float = 0.0
var roundTime : float = 0.0
var highestPlayerPosition : int = 17
var sinkCount : int = 0
var base_sink_time := 1.6

var swim : int = 0
var attacks : int = 0

signal piecePlaced(cells: Array[Cell])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	if DisplayServer.is_touchscreen_available():
		virtual_controls.visible = true
	score_label.text = "Score: %.0f" % score
	high_score_label.text = "High Score: %.0f" % ScoreManager.highest_record
	game_over_menu.visible = false
	pause_menu.visible = false
	fill_bottom()
	update_player_position()
	piecePlaced.connect(on_piece_placed)
	await get_tree().create_timer(.5).timeout
	
	currentBlock = BLOCK.instantiate()
	currentBlock.set_random_type()
	currentBlock.init()
	spawn_parent.add_child(currentBlock)
	currentBlock.position = Vector2(centerPos.x * cell_width, centerPos.y * cell_height)
	
	create_ghost_from_current()
	
	increase_bag_size()
	increase_bag_size()
	for i in range(3):
		create_from_bag()
	set_process(true)
	block_fall_timer.start()
	sinking_timer.start()
	#row_clear_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	input.process(_delta)
	
	if gameOver:
		return
	
	if input.start_pressed:
		paused = !paused
		if paused:
			pause_menu.visible = true
			block_fall_timer.paused = true
			sinking_timer.paused = true
			row_clear_timer.paused = true
			resume_button.grab_focus()
		else:
			if pause_menu.visible:
				pause_menu.visible = false
				block_fall_timer.paused = false
				sinking_timer.paused = false
				row_clear_timer.paused = false
	
	if paused:
		return
	
	roundTime += _delta
	
	if !currentBlock:
		return
	
	if input.swap_mode_pressed:
			pieceMode = !pieceMode
			if !pieceMode:
				player.material.set_shader_parameter("line_scale", 0.8)
			else:
				player.material.set_shader_parameter("line_scale", 0.0)
				
	update_score()
	update_block_position()
	update_marker_positions()
	project_ghost()
	
	if pieceMode:
		if input.right_pressed:
			if can_move_to(Vector2i.RIGHT):
				currentBlock.position.x += cell_width
				centerPos += Vector2i.RIGHT
		elif input.left_pressed:
			if can_move_to(Vector2i.LEFT):
				currentBlock.position.x -= cell_width
				centerPos += Vector2i.LEFT
		
		if input.rotate_cw_pressed:
			handle_rotate(true)
				
		elif input.rotate_ccw_pressed:
			handle_rotate(false)
			
		if input.down_pressed:
			block_fall_timer.stop()
			soft_drop()
		elif input.up_pressed:
			hard_drop()
	
	else: # player mode
		if input.right_pressed:
			if can_move_player(Vector2i.RIGHT):
				move_player(Vector2i.RIGHT)
		if input.left_pressed:
			if can_move_player(Vector2i.LEFT):
				move_player(Vector2i.LEFT)
		if input.down_pressed:
			if can_move_player(Vector2i.DOWN):
				move_player(Vector2i.DOWN)
		if input.up_pressed:
			if can_move_player(Vector2i.UP):
				move_player(Vector2i.UP)
				

func update_score()-> void:
	score = roundTime + scoreBonus
	score_label.text = "Score: %.0f" % score

func handle_rotate(_isCW: bool) -> void:
	var rotateAmount : int = -90 + int(_isCW) * 180
	var newRotation = (360 + currentBlock.amountRotated + rotateAmount) % 360
	print("Current rotation: %d, newRotation: %d" % [currentBlock.amountRotated, newRotation])
	var cell_positions : Array[Vector2i] = currentBlock.get_cell_positions_for(currentBlock.blockType, newRotation)
	# TEST ONE
	if can_move_cells_to(cell_positions, Vector2i.ZERO):
		#print("TEST ONE")
		currentBlock.rotate_piece(_isCW)
		ghostBlock.rotate_piece(_isCW)
		return
		
	match currentBlock.blockType:
		Enums.BlockType.J, Enums.BlockType.L, Enums.BlockType.S, Enums.BlockType.Z, Enums.BlockType.T:
			match currentBlock.amountRotated:
				# 0 = spawn state
				# R = 90 = One clockwise rotation
				# 2 = 180 = 2 rotations
				# L = 270 = One counter-clockwise rotation
				0:
					match newRotation:
						90: # 0 -> R
							if wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, -1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, 2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 2)):
								#print("TEST 5")
								return
							printerr("REJECTED 0 -> R")
						270: # 0 -> L
							if wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, -1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, 2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 2)):
								#print("TEST 5")
								return
							printerr("REJECTED 0 -> L")
				90:
					match newRotation:
						# R -> 0 
						# R -> 2
						0, 180: 
							if wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, -2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, -2)):
								#print("TEST 5")
								return
							printerr("REJECTED R -> 0 or R -> 2")
				180:
					match newRotation:
						90: # 2 -> R
							if wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, -1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, 2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 2)):
								#print("TEST 5")
								return
							printerr("REJECTED 2 -> R")
						270: # 2 -> L
							if wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, -1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, 2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 2)):
								#print("TEST 5")
								return
							printerr("REJECTED 2 -> L")
				270:
					match newRotation:
						# L -> 0
						# L -> 2
						0, 180: 
							if wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								#print("TEST 2")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 1)):
								#print("TEST 3")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(0, -2)):
								#print("TEST 4")
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, -2)):
								#print("TEST 5")
								return
							printerr("REJECTED L -> 0 or L -> 2")
		Enums.BlockType.I:
			match currentBlock.amountRotated:
				0:
					match newRotation:
						90: # 0 -> R
							if wall_kick_test(cell_positions, _isCW, Vector2i(-2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, 1)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, -2)):
								return
							printerr("REJECTED 0 -> R")
						270: # 0 -> L
							if wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, -2)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, 1)):
								return
							printerr("REJECTED 0 -> L")
				90:
					match newRotation:
						0: # R -> 0
							if wall_kick_test(cell_positions, _isCW, Vector2i(2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, -1)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 2)):
								return
						180: # R -> 2
							if wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, -2)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, 1)):
								return
				180:
					match newRotation:
						90: # 2 -> R
							if wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 2)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, -1)):
								return
						270: # 2 -> L
							if wall_kick_test(cell_positions, _isCW, Vector2i(2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(2, -1)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-1, 2)):
								return
				270:
					match newRotation:
						0: # L -> 0
							if wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 2)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, -1)):
								return
						180: # L -> 2
							if wall_kick_test(cell_positions, _isCW, Vector2i(-2, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, 0)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(-2, 1)):
								return
							elif wall_kick_test(cell_positions, _isCW, Vector2i(1, -2)):
								return

func wall_kick_test(cell_positions: Array[Vector2i], _isCW: bool, move_dir: Vector2i) -> bool:
	if can_move_cells_to(cell_positions, move_dir):
		move_block(move_dir)
		currentBlock.rotate_piece(_isCW)
		ghostBlock.rotate_piece(_isCW)
		return true
	return false

func move_block(move_dir: Vector2i) -> void:
	currentBlock.position += Vector2(move_dir.x * cell_width, move_dir.y * cell_height)
	centerPos += move_dir

func fill_bottom() -> void:
	for row in range(grid_height - 1, grid_height - 4, -1):
		for column in range(grid_width):
			var cell : Cell = GRASS_CELL.instantiate()
			placed_parent.add_child(cell)
			cell.set_type(Enums.CellType.Grass)
			cell.position = Vector2(column * cell_height, row * cell_width)
			gridObjects.get_or_add(Vector2i(column, row), cell)
			cell.cell_position = Vector2i(column, row)

func increase_bag_size() -> void:
	var vals : Array = range(Enums.BlockType.size())
	vals.shuffle()
	bagOrder.append_array(vals)
	
func create_from_bag() -> void:
	var newPiece : Block = BLOCK.instantiate()
	newPiece.set_type(bagOrder[0])
	newPiece.init()
	bagOrder.remove_at(0)
	bag_parent.add_child(newPiece)
	bag.append(newPiece)
	newPiece.position.y += (bag.size() - 1) * 80
	
func reset_bag_positions() -> void:
	for i in range(bag.size()):
		bag[i].position.y = i * 80

func can_move_player(move_dir: Vector2i) -> bool:
	var newPos = playerPosition + move_dir
	return gridObjects.has(newPos) and (
		gridObjects[newPos].cellType == Enums.CellType.Grass
		or gridObjects[newPos].cellType == Enums.CellType.Sword
		or gridObjects[newPos].cellType == Enums.CellType.Heart
		or gridObjects[newPos].cellType == Enums.CellType.Chest
		or gridObjects[newPos].cellType == Enums.CellType.WaterDrop
		or (gridObjects[newPos].cellType == Enums.CellType.Monster and attacks >= 1)
		or (gridObjects[newPos].cellType == Enums.CellType.Water and swim >= 1)
		)

func move_player(move_dir: Vector2i, reposition: bool = false) -> void:
	playerPosition += move_dir
	if gridObjects[playerPosition].cellType == Enums.CellType.Water:
		if !reposition:
			swim -= 1
		update_swim_label()
	elif gridObjects[playerPosition].cellType == Enums.CellType.WaterDrop:
		swim += 1
		update_swim_label()
		gridObjects[playerPosition].set_type(Enums.CellType.Grass)
	elif gridObjects[playerPosition].cellType == Enums.CellType.Sword:
		attacks += 1
		update_attack_label()
		gridObjects[playerPosition].set_type(Enums.CellType.Grass)
	elif gridObjects[playerPosition].cellType == Enums.CellType.Monster:
		attacks -= 1
		update_attack_label()
		scoreBonus += 5.0
		gridObjects[playerPosition].set_type(Enums.CellType.Grass)
	elif gridObjects[playerPosition].cellType == Enums.CellType.Chest:
		scoreBonus += 50.0
		gridObjects[playerPosition].set_type(Enums.CellType.Grass)
	elif gridObjects[playerPosition].cellType == Enums.CellType.Heart:
		gridObjects[playerPosition].set_type(Enums.CellType.Grass)
		pass
		
	update_player_position()
	if playerPosition.y < highestPlayerPosition:
		highestPlayerPosition = playerPosition.y
		scoreBonus += (17 - highestPlayerPosition) * 5
	update_sink_time()

func create_ghost_from_current() -> void:
	ghostBlock = BLOCK.instantiate()
	ghostBlock.set_type(currentBlock.blockType)
	ghostBlock.init()
	ghostBlock.name = "Ghost"
	ghostBlock.set_cells(currentBlock.get_cells())
	ghostBlock.set_ghost()
	spawn_parent.add_child(ghostBlock)

func project_ghost() -> void:
	if !ghostBlock:
		return
		
	var pos = Vector2i.DOWN
	while can_move_to(pos):
		pos += Vector2i.DOWN
		
	pos -= Vector2i.DOWN
	ghostBlock.position = currentBlock.position + Vector2(pos * cell_height) + Vector2.DOWN * sinkingOffset

func can_move_cells_to(_cell_pos: Array[Vector2i], move_pos: Vector2i) -> bool:
	for cell_pos in _cell_pos:
		cell_pos = cell_pos + centerPos + move_pos
		if cell_pos.x < 0 or cell_pos.x > grid_width - 1 or cell_pos.y > grid_height - 1:
			return false
		if gridObjects.has(cell_pos):
			return false
		
	return true

func can_move_to(move_pos : Vector2i) -> bool:
	for cell in currentBlock.get_cells():
		var pos : Vector2i = cell.cell_position + centerPos + move_pos
		if pos.x < 0 or pos.x > grid_width - 1 or pos.y > grid_height - 1:
			return false
		if gridObjects.has(pos):
			return false
		
	return true

func add_block_cells() -> void:
	for cell in currentBlock.get_cells():
		var pos : Vector2i = centerPos + cell.cell_position
		#print("Setting dropped block to pos: %s" % str(pos))
		gridObjects.get_or_add(pos, cell)
		cell.cell_position = pos
		if pos.y < highestCell:
			highestCell = pos.y
	
func set_block_cells(block: Block, move_pos : Vector2i) -> void:
	for cell in block.get_cells():
		var pos : Vector2i = cell.cell_position + centerPos + move_pos
		gridObjects.get_or_add(pos, cell)
		cell.cell_position = pos

func soft_drop() -> void:
	block_fall_timer.stop()
	if can_move_to(Vector2i.DOWN):
		centerPos += Vector2i.DOWN
		block_fall_timer.start()
	else:
		set_next_block()
	
func hard_drop() -> void:
	var canMove := true
	var pos = Vector2i.DOWN
	while canMove:
		if can_move_to(pos):
			pos += Vector2i.DOWN
		else:
			canMove = false
			pos -= Vector2i.DOWN
			centerPos += pos
			set_next_block()

func set_next_block() -> void:
	block_fall_timer.stop()
	add_block_cells()
	piecePlaced.emit(currentBlock.get_cells())
	
	spawn_parent.remove_child(currentBlock)
	for i in currentBlock.cells.size():
		var cell = currentBlock.cells[i]
		currentBlock.remove_child(cell)
		placed_parent.add_child(cell)
		cell.position = Vector2(cell.cell_position.x * cell_width, cell.cell_position.y * cell_height + sinkingOffset)
		if cell.cell_position.y < 0:
			game_over()
			return
			
	ghostBlock.queue_free()
	currentBlock.queue_free()
	currentBlock = null
	currentBlock = bag[0]
	bag.remove_at(0)
	if bag.size() < Enums.BlockType.size():
		increase_bag_size()
	bag_parent.remove_child(currentBlock)
	spawn_parent.add_child(currentBlock)
	centerPos = Vector2i(5, -1)
	update_block_position()

	reset_bag_positions()
	create_from_bag()
	
	create_ghost_from_current()
	
	block_fall_timer.start()

func game_over() -> void:
	gameOver = true
	block_fall_timer.stop()
	sinking_timer.stop()
	row_clear_timer.stop()
	if score > ScoreManager.highest_record:
		ScoreManager.highest_record = int(score)
		ScoreManager.save_score()
	game_over_high_score_value_label.text = str(ScoreManager.highest_record)
	game_over_score_value_label.text = "%.0f" % score
	game_over_menu.visible = true
	restart_button.grab_focus()

func on_piece_placed(cells : Array[Cell]) -> void:
	var cellCount : int = 0
	var confirmedCells : Array[Vector2i] = []
	#var clearedRows : Array[int] = []
	for row in range(grid_height - 1, -1, -1):
		cellCount = 0
		confirmedCells = []
		var isPlacedRow := false
		for cell in cells:
			if cell.cell_position.y == row:
				isPlacedRow = true
				break
		
		if !isPlacedRow:
			continue
			
		for column in range(grid_width):
			if !gridObjects.has(Vector2i(column, row)):
				break
			else:
				cellCount += 1
				confirmedCells.append(Vector2i(column, row))
				if cellCount == grid_width:
					print("Filled Row: %d" % row)
					swim += 1
					attacks += 1
					update_swim_label()
					update_attack_label()
					#clearedRows.append(row)
					#for cellPos in confirmedCells:
						#var cell = gridObjects[cellPos]
						#cell.set_type(Enums.CellType.Grass)

func update_swim_label():
	swim_label.text = "Swim: %d" % swim

func update_attack_label():
	attack_label.text = "Attack: %d" % attacks
	
func _on_block_fall_timer_timeout() -> void:
	soft_drop()

func _on_sinking_timer_timeout() -> void:
	sinkingOffset += .25 * cell_height
	if sinkingOffset == cell_height:
		remove_row(grid_height - 1)
		if playerPosition.y >= grid_height - 1:
			#TO DO: GAME OVER
			print("YOU DIED")
			game_over()
			return
			
		move_all_cells(Vector2i.DOWN)
		move_player(Vector2i.DOWN, true)
		sinkingOffset = 0.0
		sinkCount += 1
		if sinkCount % 5 == 0:
			update_sink_time()
			
	update_cell_positions()
	update_player_position()
	update_block_position()

func update_sink_time() -> void:
	var player_adjust : float
	if playerPosition.y > 15:
		player_adjust = 0.0
	elif playerPosition.y > 10:
		player_adjust = .3
	elif playerPosition.y > 5:
		player_adjust = .6
	elif playerPosition.y > 0:
		player_adjust = 1.0
	#sinking_timer.wait_time = clampf(base_sink_time - (.2 * (sinkCount / 5.0)) - player_adjust, .4, 2)
	sinking_timer.wait_time = clampf(base_sink_time - (.2 * (sinkCount / 5.0)), .8, 2)

func update_block_position() -> void:
	currentBlock.position = Vector2(centerPos.x * cell_width, centerPos.y * cell_height)

func update_cell_positions() -> void:
	for cell in gridObjects.values():
		cell.position = Vector2(cell.cell_position.x * cell_width, cell.cell_position.y * cell_height + sinkingOffset)

func update_player_position() -> void:
	player.position = Vector2(playerPosition.x * cell_width - 1, playerPosition.y * cell_height + sinkingOffset - 1)

func remove_row(row: int) -> void:
	var pos : Vector2i
	for column in range(grid_width):
		pos = Vector2i(column, row)
		if gridObjects.has(pos):
			gridObjects[pos].queue_free()
			gridObjects.erase(pos)
	if selectedRow <= row:
		selectedRow += 1
	if highestCell <= row:
		highestCell += 1
	
func move_all_cells(move_dir : Vector2i) -> void:
	var pos : Vector2i
	for row in range(grid_height - 1, -1, -1):
		for column in range(grid_width):
			pos = Vector2i(column, row)
			if gridObjects.has(pos):
				#print("Position: %s move to %s" % [str(pos), str(pos + move_dir)])
				var cell: Cell = gridObjects[pos]
				gridObjects.erase(pos)
				gridObjects.get_or_add(pos + move_dir, cell)
				cell.cell_position = pos + move_dir

func _on_resume_button_button_up() -> void:
	paused = !paused
	if pause_menu.visible:
		pause_menu.visible = false
		block_fall_timer.paused = false
		sinking_timer.paused = false
		row_clear_timer.paused = false

func _on_exit_button_button_up() -> void:
	get_tree().quit()

func _on_restart_button_button_up() -> void:
	# Clear all gridObjects
	# Reset score variables
	# Reset player position
	if score > ScoreManager.highest_record:
		ScoreManager.highest_record = int(score)
		ScoreManager.save_score()
	get_tree().reload_current_scene()


var selectedRow : int
func _on_row_clear_timer_timeout() -> void:
	selectedRow = randi_range(highestCell, 18)
	signal_row(3, selectedRow)
	row_clear_timer.stop()
	await get_tree().create_timer(2).timeout
	signal_row(2, selectedRow)
	await get_tree().create_timer(2).timeout
	signal_row(1, selectedRow)
	await get_tree().create_timer(2).timeout
	signal_row(0, selectedRow)
	row_clear_timer.start()

var markers : Array[Sprite2D] = []
func signal_row(val: int, row: int) -> void:
	clear_markers()
	if val == 0:
		remove_row(row)
		if playerPosition.y == row:
			game_over()
			return
		move_all_cells_above(row, Vector2i.DOWN)
		if playerPosition.y <= row:
			move_player(Vector2i.DOWN, true)
	else:
		create_markers_for(val, row)

func clear_markers():
	for marker in markers:
		marker.queue_free()
	markers.clear()
	
func create_markers_for(val: int, row: int) -> void:
	for column in range(grid_width):
		var marker := Sprite2D.new()
		if val == 3:
			marker.texture = THREE
		if val == 2:
			marker.texture = TWO
		if val == 1:
			marker.texture = ONE
		marker_parent.add_child(marker)
		marker.centered = false
		marker.position = Vector2(column * cell_width, row * cell_height + sinkingOffset)
		markers.append(marker)

func update_marker_positions():
	for i in markers.size():
		markers[i].position = Vector2(i * cell_width, selectedRow * cell_height + sinkingOffset)
		

func move_all_cells_above(row_cleared: int, move_dir : Vector2i) -> void:
	var pos : Vector2i
	for row in range(row_cleared, -1, -1):
		for column in range(grid_width):
			pos = Vector2i(column, row)
			if gridObjects.has(pos):
				#print("Position: %s move to %s" % [str(pos), str(pos + move_dir)])
				var cell: Cell = gridObjects[pos]
				gridObjects.erase(pos)
				gridObjects.get_or_add(pos + move_dir, cell)
				cell.cell_position = pos + move_dir
	update_cell_positions()
