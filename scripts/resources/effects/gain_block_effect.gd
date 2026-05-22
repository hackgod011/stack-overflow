class_name GainBlockEffect
extends CardEffect
## Grants the player N block points.

@export var amount: int = 5


func apply(context: Dictionary) -> void:
	context.block_gain += amount
