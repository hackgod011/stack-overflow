class_name ApplyVulnerableEffect
extends CardEffect
## Applies Vulnerable stacks to the primary enemy target.
## Vulnerable causes the enemy to take 50% more damage (handled by StatusEffectsSystem in 4.2).

@export var stacks: int = 2


func apply(context: Dictionary) -> void:
	context["vulnerable_stacks"] = context.get("vulnerable_stacks", 0) + stacks
