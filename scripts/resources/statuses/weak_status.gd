class_name WeakStatus
extends StatusEffect
## The afflicted entity deals 25% less damage while any stacks remain.
## Stacks count duration (turns), not damage magnitude.


func get_status_name() -> String:
	return "Weak"


func get_damage_dealt_multiplier() -> float:
	return 0.75
