class_name CardArtLoader
extends RefCounted

## Maps card IDs to their texture asset. Call apply_art() once after the card
## pool is built — it assigns art textures without touching the .tres files.

# Card ID → path in assets/sprites/cards/
const ART_MAP: Dictionary = {
	&"push_1":       "res://assets/sprites/cards/00_kerenel_Cards.png",
	&"push_3":       "res://assets/sprites/cards/01_kerenel_Cards.png",
	&"push_5":       "res://assets/sprites/cards/02_kerenel_Cards.png",
	&"push_10":      "res://assets/sprites/cards/03_kerenel_Cards.png",
	&"push_rand":    "res://assets/sprites/cards/04_kerenel_Cards.png",
	&"dup":          "res://assets/sprites/cards/05_kerenel_Cards.png",
	&"pop":          "res://assets/sprites/cards/06_kerenel_Cards.png",
	&"swap":         "res://assets/sprites/cards/07_kerenel_Cards.png",
	&"rot":          "res://assets/sprites/cards/08_kerenel_Cards.png",
	&"add":          "res://assets/sprites/cards/09_kerenel_Cards.png",
	&"mul":          "res://assets/sprites/cards/10_kerenel_Cards.png",
	&"neg":          "res://assets/sprites/cards/11_kerenel_Cards.png",
	&"loop_2":       "res://assets/sprites/cards/12_kerenel_Cards.png",
	&"loop_3":       "res://assets/sprites/cards/13_kerenel_Cards.png",
	&"if_positive":  "res://assets/sprites/cards/14_kerenel_Cards.png",
	&"break":        "res://assets/sprites/cards/15_kerenel_Cards.png",
	&"strike":       "res://assets/sprites/cards/16_kerenel_Cards.png",
	&"heavy_strike": "res://assets/sprites/cards/17_kerenel_Cards.png",
	&"defend":       "res://assets/sprites/cards/18_kerenel_Cards.png",
	&"draw_2":       "res://assets/sprites/cards/19_kerenel_Cards.png",
	&"compile":      "res://assets/sprites/cards/20_kerenel_Cards.png",
	&"debug":        "res://assets/sprites/cards/21_kerenel_Cards.png",
}

static func apply_art(cards: Array) -> void:
	for card: CardData in cards:
		if card.id in ART_MAP:
			card.art = load(ART_MAP[card.id]) as Texture2D
