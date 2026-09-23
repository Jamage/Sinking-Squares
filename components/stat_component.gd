class_name StatComponent extends BaseComponent

@export var stat : float = 100
@export var max_stat : float = 100
@export var increments_to_end = false

signal on_changed(stat: float, max_stat: float)
signal decreased(stat: float)
signal increased(stat: float)
signal finished

func bind(_owner) -> void:
	super.bind(_owner)
	on_changed.emit(stat, max_stat)

func change(val: float) -> void:
	if val == 0:
		return
	if val > 0.0:
		increase(val)
	else:
		decrease(val)

func decrease(amount: float) -> void:
	if stat <= 0:
		return
	
	stat = max(stat + amount, 0)
	decreased.emit(amount)
	on_changed.emit(stat, max_stat)
	
	if not increments_to_end and stat <= 0:
		finished.emit()
	
func increase(amount: float) -> void:
	if stat >= max_stat:
		return
	
	stat = min(stat + amount, max_stat)
	on_changed.emit(stat, max_stat)
	increased.emit(amount)
	if increments_to_end and amount >= max_stat:
		finished.emit()

func set_max_stat(value: float, refill: bool = false) -> void:
	max_stat = maxf(value, 1.0)
	if refill:
		stat = max_stat
	else:
		stat = minf(stat, max_stat)
		
	on_changed.emit(stat, max_stat)
	
func set_stat(_value: float) -> void:
	if _value <= 0 or _value > max_stat:
		return
		
	stat = min(_value, max_stat)
	
	on_changed.emit(stat, max_stat)
