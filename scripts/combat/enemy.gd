class_name Enemy
extends Control

## Enemy scene script — manages HP, attack pattern, and status effects.

const DAMAGE_FLASH_SHADER := preload("res://assets/shaders/damage_flash.gdshader")

signal enemy_died
signal phase_changed(new_phase: int)

@export var data: EnemyData

var _hp: int
var _pattern_index: int = 0
var _current_phase: int = 1
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
	var pattern := _get_active_attack_pattern()
	if pattern.is_empty():
		return 0
	return pattern[_pattern_index % pattern.size()]


func advance_pattern() -> void:
	var pattern := _get_active_attack_pattern()
	if not pattern.is_empty():
		_pattern_index = (_pattern_index + 1) % pattern.size()


func get_heal_per_turn() -> int:
	return _get_active_stat("heal_per_turn")


func get_inflicts_vulnerable() -> int:
	return _get_active_stat("inflicts_vulnerable")


func get_inflicts_weak() -> int:
	return _get_active_stat("inflicts_weak")


func take_damage(amount: int) -> void:
	# Armored enemies ignore hits below their current threshold
	var threshold := _get_active_stat("min_damage_threshold")
	if threshold > 0 and amount > 0 and amount < threshold:
		return
	_hp = max(0, _hp - amount)
	TweenPresets.standard_tween(self).tween_property(_hp_bar, "value", float(_hp), TweenPresets.SLOW_DURATION)
	_update_labels()
	flash_damage()
	_check_phase_transition()
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


func _check_phase_transition() -> void:
	if _hp <= 0:
		return
	var hp_fraction: float = float(_hp) / float(data.max_hp)
	var new_phase := 1
	if data.phase2_hp_fraction > 0.0 and hp_fraction <= data.phase2_hp_fraction:
		new_phase = 2
	if data.phase3_hp_fraction > 0.0 and hp_fraction <= data.phase3_hp_fraction:
		new_phase = 3
	if new_phase != _current_phase:
		_current_phase = new_phase
		_pattern_index = 0  # Reset pattern on phase change
		_update_labels()
		phase_changed.emit(_current_phase)


func _get_active_attack_pattern() -> Array[int]:
	match _current_phase:
		3: return data.phase3_attack_pattern if not data.phase3_attack_pattern.is_empty() else data.attack_pattern
		2: return data.phase2_attack_pattern if not data.phase2_attack_pattern.is_empty() else data.attack_pattern
		_: return data.attack_pattern


func _get_active_stat(stat_name: String) -> int:
	match _current_phase:
		3:
			match stat_name:
				"inflicts_vulnerable":   return data.phase3_inflicts_vulnerable
				"inflicts_weak":         return data.phase3_inflicts_weak
				"heal_per_turn":         return data.phase3_heal_per_turn
				"min_damage_threshold":  return data.phase3_min_damage_threshold
		2:
			match stat_name:
				"inflicts_vulnerable":   return data.phase2_inflicts_vulnerable
				"inflicts_weak":         return data.phase2_inflicts_weak
				"heal_per_turn":         return data.phase2_heal_per_turn
				"min_damage_threshold":  return data.phase2_min_damage_threshold
	match stat_name:
		"inflicts_vulnerable":   return data.inflicts_vulnerable
		"inflicts_weak":         return data.inflicts_weak
		"heal_per_turn":         return data.heal_per_turn
		"min_damage_threshold":  return data.min_damage_threshold
	return 0


func _setup() -> void:
	_hp = data.max_hp
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.max_hp
	_name_label.text = data.name
	_current_phase = 1
	_update_labels()
	_update_status_display()


func _update_labels() -> void:
	var phase_suffix := ""
	if _current_phase == 2:
		phase_suffix = " [PHASE 2]"
	elif _current_phase == 3:
		phase_suffix = " [ENRAGED]"
	_name_label.text = data.name + phase_suffix
	_hp_label.text = "HP: %d/%d" % [_hp, data.max_hp]

	var attack := get_next_attack()
	var intent: String
	if attack == 0:
		intent = "CHARGING..."
	else:
		intent = "Next: %d" % attack
	if get_inflicts_vulnerable() > 0:
		intent += " +VUL"
	if get_inflicts_weak() > 0:
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
