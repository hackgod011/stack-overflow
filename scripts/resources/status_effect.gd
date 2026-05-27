class_name StatusEffect
extends Resource

## Base class for all combat status effects.
## Subclasses override get_damage_taken_multiplier() and/or get_damage_dealt_multiplier().

var stacks: int = 0


func get_status_name() -> String:
	return "Status"


func get_damage_taken_multiplier() -> float:
	return 1.0


func get_damage_dealt_multiplier() -> float:
	return 1.0


func tick() -> void:
	stacks = max(0, stacks - 1)


func is_expired() -> bool:
	return stacks <= 0
