class_name LoopEffect
extends CardEffect
## Causes the next card in the stack to re-execute this many additional times.
## Example: times=2 means the next card runs 3 times total.

@export var times: int = 2


func apply(context: Dictionary) -> void:
	context["_loop_times"] = times
