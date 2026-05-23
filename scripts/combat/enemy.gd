class_name Enemy
extends Control

## Enemy scene script — manages HP, attack pattern, and label display.

signal enemy_died

@export var data: EnemyData

var _hp: int
var _pattern_index: int = 0

@onready var _name_label: Label = $NameLabel
@onready var _hp_label: Label = $HPLabel
@onready var _intent_label: Label = $IntentLabel


func _ready() -> void:
	if data:
		_setup()


func get_next_attack() -> int:
	if data.attack_pattern.is_empty():
		return 0
	return data.attack_pattern[_pattern_index]


func advance_pattern() -> void:
	_pattern_index = (_pattern_index + 1) % data.attack_pattern.size()


func take_damage(amount: int) -> void:
	_hp = max(0, _hp - amount)
	_update_labels()
	if _hp <= 0:
		enemy_died.emit()


func is_dead() -> bool:
	return _hp <= 0


func _setup() -> void:
	_hp = data.max_hp
	_name_label.text = data.name
	_update_labels()


func _update_labels() -> void:
	_hp_label.text = "HP: %d/%d" % [_hp, data.max_hp]
	_intent_label.text = "Next: %d" % get_next_attack()
