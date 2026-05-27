class_name Hand
extends HBoxContainer

## Container for the player's hand of cards.
## Listens to each CardView's card_clicked signal and re-emits card_play_requested upward.
## Knows nothing about combat or enemies.


# Constants
const CARD_VIEW = preload("res://scenes/card/card_view.tscn")
const DISCARD_DURATION := 0.3


# Signals
signal card_play_requested(card_data: CardData)


# Public methods
func add_card(data: CardData, animated: bool = false) -> void:
	var view: CardView = CARD_VIEW.instantiate()
	view.card_clicked.connect(_on_card_clicked)
	add_child(view)
	view.set_card_data(data)
	if animated:
		view.animate_deal()
		AudioManager.play_card_draw()


func remove_card(view: CardView) -> void:
	remove_child(view)
	view.queue_free()


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func discard_all_animated() -> void:
	AudioManager.play_card_discard()
	for child in get_children():
		var tween: Tween = child.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(child, "modulate:a", 0.0, DISCARD_DURATION)
	await get_tree().create_timer(DISCARD_DURATION).timeout
	clear()


# Signal handlers
func _on_card_clicked(card_data: CardData) -> void:
	card_play_requested.emit(card_data)
