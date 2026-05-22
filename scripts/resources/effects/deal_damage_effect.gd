class_name DealDamageEffect
extends CardEffect
## Deals damage equal to amount plus the sum of all values on the runtime stack.

@export var amount: int = 6


func apply(context: Dictionary) -> void:
	context.damage_accumulator += amount + _stack_sum(context.runtime_stack)


func _stack_sum(stack: Array) -> int:
	var total := 0
	for v: int in stack:
		total += v
	return total
