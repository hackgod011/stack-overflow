class_name Hand
extends HBoxContainer

## Container for the player's hand of cards.
## Listens to each CardView's card_clicked signal and re-emits card_play_requested upward.
## Knows nothing about combat or enemies.


# Constants
const CARD_VIEW = preload("res://scenes/card/card_view.tscn")


# Signals
signal card_play_requested(card_data: CardData)


# Public methods
func add_card(data: CardData) -> void:
	var view: CardView = CARD_VIEW.instantiate()
	view.card_clicked.connect(_on_card_clicked)
	add_child(view)
	view.set_card_data(data)


func remove_card(view: CardView) -> void:
	remove_child(view)
	view.queue_free()


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


# Signal handlers
func _on_card_clicked(card_data: CardData) -> void:
	card_play_requested.emit(card_data)
