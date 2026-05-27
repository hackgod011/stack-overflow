class_name VulnerableStatus
extends StatusEffect
## The afflicted entity takes 50% more damage while any stacks remain.
## Stacks count duration (turns), not damage magnitude.


func get_status_name() -> String:
	return "Vulnerable"


func get_damage_taken_multiplier() -> float:
	return 1.5
