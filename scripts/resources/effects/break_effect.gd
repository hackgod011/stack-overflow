class_name BreakEffect
extends CardEffect
## Immediately stops all further card execution in the current stack resolution.


func apply(context: Dictionary) -> void:
	context["_break"] = true
