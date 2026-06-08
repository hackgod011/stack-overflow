class_name StackResolver
extends RefCounted

## Pure-logic stack resolver. Iterates cards top-to-bottom, applying each effect.
## Supports flow-control context keys set by effects:
##   _loop_times  — set by LoopEffect: next card repeats N extra times
##   _skip_next   — set by IfPositiveEffect: skip the next card entirely


func resolve(stack: Array[CardData], context: Dictionary) -> Dictionary:
	## Resolves the full stack. Stores a runtime_stack snapshot after each card
	## slot in context["_snapshots"] (Array[Array[int]]). Used by combat scene
	## to animate step-by-step with live DATA display updates.
	var snapshots: Array = []
	var i := 0
	while i < stack.size():
		if context.get("_break", false):
			# Pad remaining slots with the current state so animation can continue
			while snapshots.size() < stack.size():
				snapshots.append(context.runtime_stack.duplicate())
			break

		if context.get("_skip_next", false):
			context.erase("_skip_next")
			context.erase("_loop_times")
			snapshots.append(context.runtime_stack.duplicate())  # unchanged — card was skipped
			i += 1
			continue

		var extra_runs: int = context.get("_loop_times", 0)
		context.erase("_loop_times")

		for _r in (extra_runs + 1):
			_apply_card(stack[i], context)

		snapshots.append(context.runtime_stack.duplicate())
		i += 1

	context["_snapshots"] = snapshots
	return context


func _apply_card(card: CardData, context: Dictionary) -> void:
	for effect: CardEffect in card.effects:
		effect.apply(context)
