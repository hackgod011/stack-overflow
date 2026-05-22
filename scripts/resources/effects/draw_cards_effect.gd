class_name DrawCardsEffect
extends CardEffect
## Draws N cards from the draw pile into the hand.

@export var count: int = 1


func apply(context: Dictionary) -> void:
	var remaining := count
	while remaining > 0 and not context.draw_pile.is_empty():
		context.hand.append(context.draw_pile.pop_back())
		remaining -= 1
