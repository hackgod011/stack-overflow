class_name CardEffect
extends Resource
## Base class for all card effects. Subclasses override apply().

@export var description: String  # for tooltip generation

func apply(context: Dictionary) -> void:
	push_warning("CardEffect.apply() not implemented in subclass")
