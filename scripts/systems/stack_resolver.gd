class_name StackResolver
extends RefCounted

## Pure-logic stack resolver. Iterates cards top-to-bottom, applying each effect.
## Supports flow-control context keys set by effects:
##   _loop_times  — set by LoopEffect: next card repeats N extra times
##   _skip_next   — set by IfPositiveEffect: skip the next card entirely


func resolve(stack: Array[CardData], context: Dictionary) -> Dictionary:
	var i := 0
	while i < stack.size():
		# BreakEffect set this — halt all further execution
		if context.get("_break", false):
			break

		# IfPositiveEffect set this on the previous card — skip this card
		if context.get("_skip_next", false):
			context.erase("_skip_next")
			context.erase("_loop_times")  # discard any pending loop — it targeted the skipped card
			i += 1
			continue

		# LoopEffect set this on the previous card — repeat this card N extra times
		var extra_runs: int = context.get("_loop_times", 0)
		context.erase("_loop_times")  # always clear, even if value was 0

		for _r in (extra_runs + 1):
			_apply_card(stack[i], context)

		i += 1

	return context


func _apply_card(card: CardData, context: Dictionary) -> void:
	for effect: CardEffect in card.effects:
		effect.apply(context)
