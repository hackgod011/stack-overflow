class_name HealEffect
extends CardEffect
## Heals the player for N HP (capped at max HP by combat_scene).

@export var amount: int = 4


func apply(context: Dictionary) -> void:
	context["heal_amount"] = context.get("heal_amount", 0) + amount
