class_name StackResolver
extends RefCounted

## Pure-logic stack resolver. Iterates cards top-to-bottom, applying each effect.

func resolve(stack: Array[CardData], context: Dictionary) -> Dictionary:
	for card: CardData in stack:
		for effect: CardEffect in card.effects:
			effect.apply(context)
	return context
