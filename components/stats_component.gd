class_name StatsComponent extends BaseComponent

@export var characterName : String = ""

var health : int = 100
@export var max_health : int = 100

var attack : int = 0
var defense : int = 0
var agility : int = 0

var bladder : float = 0
var bowels : float = 0
var max_bladder : float = 100
var max_bowels : float = 100

@export var maturity : int = 100
@export var potty_training : int = 100


signal name_changed(characterName: String)
signal health_changed(health: int, max_health: int)
signal damaged
signal healed
signal died

signal attack_changed(attack: int)
signal defense_changed(defense: int)
signal agility_changed(agility: int)

signal bladder_changed(bladder: int, max_bladder: int)
signal bowels_changed(bowels: int, max_bowels: int)
signal maturity_changed(maturity: int)
signal potty_training_changed(potty_training: int)

func bind(_owner) -> void:
	super.bind(_owner)
	
	name_changed.emit(characterName)
	health_changed.emit(health, max_health)
	attack_changed.emit(attack)
	defense_changed.emit(defense)
	agility_changed.emit(agility)
	bladder_changed.emit(bladder, max_bladder)
	bowels_changed.emit(bowels, max_bowels)
	maturity_changed.emit(maturity)
	potty_training_changed.emit(potty_training)

func damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	
	health = max(health - amount, 0)
	damaged.emit(amount)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		died.emit()
	
func heal(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	
	health = min(health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(health, max_health)

func set_max_health(value: int, refill: bool = false) -> void:
	max_health = max(value, 1)
	if refill:
		health = max_health
	else:
		health = min(health, max_health)
		
	health_changed.emit(health, max_health)
	
