class_name Enemy
extends Control

## Enemy scene script — manages HP, attack pattern, and status effects.

const DAMAGE_FLASH_SHADER := preload("res://assets/shaders/damage_flash.gdshader")

signal enemy_died

@export var data: EnemyData

var _hp: int
var _pattern_index: int = 0
var statuses: Array[StatusEffect] = []

var _flash_mat: ShaderMaterial

@onready var _background: ColorRect = $Background
@onready var _name_label: Label = $NameLabel
@onready var _hp_label: Label = $HPLabel
@onready var _hp_bar: ProgressBar = $HPBar
@onready var _intent_label: Label = $IntentLabel
@onready var _status_label: Label = $StatusLabel


func _ready() -> void:
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = DAMAGE_FLASH_SHADER
	_background.material = _flash_mat
	if data:
		_setup()


func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	_setup()


func get_next_attack() -> int:
	if data.attack_pattern.is_empty():
		return 0
	return data.attack_pattern[_pattern_index]


func advance_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % data.attack_pattern.size()


func take_damage(amount: int) -> void:
	# Armored enemies ignore hits below their threshold
	if data.min_damage_threshold > 0 and amount > 0 and amount < data.min_damage_threshold:
		return
	_hp = max(0, _hp - amount)
	TweenPresets.standard_tween(self).tween_property(_hp_bar, "value", float(_hp), TweenPresets.SLOW_DURATION)
	_update_labels()
	flash_damage()
	if _hp <= 0:
		enemy_died.emit()


func flash_damage() -> void:
	_flash_mat.set_shader_parameter("flash_amount", 1.0)
	var t := create_tween()
	t.tween_method(
		func(v: float) -> void: _flash_mat.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.18
	)


func heal(amount: int) -> void:
	_hp = min(_hp + amount, data.max_hp)
	TweenPresets.standard_tween(self).tween_property(_hp_bar, "value", float(_hp), TweenPresets.SLOW_DURATION)
	_update_labels()


func is_dead() -> bool:
	return _hp <= 0


func add_status(new_status: StatusEffect) -> void:
	for existing in statuses:
		if existing.get_script() == new_status.get_script():
			existing.stacks += new_status.stacks
			_update_status_display()
			return
	statuses.append(new_status)
	_update_status_display()


func get_incoming_damage_multiplier() -> float:
	var multiplier := 1.0
	for status in statuses:
		multiplier *= status.get_damage_taken_multiplier()
	return multiplier


func get_outgoing_damage_multiplier() -> float:
	var multiplier := 1.0
	for status in statuses:
		multiplier *= status.get_damage_dealt_multiplier()
	return multiplier


func tick_statuses() -> void:
	for status in statuses:
		status.tick()
	var kept: Array[StatusEffect] = []
	for s in statuses:
		if not s.is_expired():
			kept.append(s)
	statuses = kept
	_update_status_display()


func _setup() -> void:
	_hp = data.max_hp
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.max_hp
	_name_label.text = data.name
	_update_labels()
	_update_status_display()


func _update_labels() -> void:
	_hp_label.text = "HP: %d/%d" % [_hp, data.max_hp]
	var intent := "Next: %d" % get_next_attack()
	if data.inflicts_vulnerable > 0:
		intent += " +VUL"
	if data.inflicts_weak > 0:
		intent += " +WEAK"
	_intent_label.text = intent


func _update_status_display() -> void:
	if statuses.is_empty():
		_status_label.text = ""
		return
	var parts: Array[String] = []
	for s in statuses:
		parts.append("%s(%d)" % [s.get_status_name(), s.stacks])
	_status_label.text = " ".join(parts)
