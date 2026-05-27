class_name DamagePerStackValueEffect
extends CardEffect
## Deals damage equal to the sum of all values currently on the runtime stack.


func apply(context: Dictionary) -> void:
	var total: int = 0
	for v: int in context.runtime_stack:
		total += v
	context.damage_accumulator += total
