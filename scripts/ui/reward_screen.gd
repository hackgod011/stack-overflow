class_name RewardScreen
extends Control

## Shown after winning a fight. Offers 3 cards; player picks one or skips.

const CARD_OFFERS := 3
const CARD_VIEW   := preload("res://scenes/card/card_view.tscn")

@onready var _title_label:    Label        = $TitleLabel
@onready var _gold_label:     Label        = $GoldLabel
@onready var _cards_container: HBoxContainer = $CardsContainer
@onready var _skip_button:    Button       = $SkipButton

var _offered_cards: Array[CardData] = []


func _ready() -> void:
	_title_label.text = "Choose a card to add to your deck"
	_gold_label.text = "Gold: %d" % GameManager.gold
	_offered_cards = GameManager.pick_reward_cards(CARD_OFFERS)
	_build_card_offers()
	_skip_button.pressed.connect(_on_skip_pressed)


func _build_card_offers() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	for card in _offered_cards:
		# Wrapper — VBoxContainer holds the CardView + Pick button
		var wrapper := VBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 10)
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		_cards_container.add_child(wrapper)  # add to tree FIRST so _ready() fires in card_view

		var card_view: CardView = CARD_VIEW.instantiate()
		wrapper.add_child(card_view)         # _ready() runs → @onready vars populated
		card_view.set_card_data(card)        # safe to call now
		card_view.disable()                  # no hover/click — use the Pick button below

		var pick_btn := Button.new()
		pick_btn.text = "Pick"
		pick_btn.custom_minimum_size = Vector2(120, 0)
		pick_btn.pressed.connect(_on_card_picked.bind(card))
		wrapper.add_child(pick_btn)


func _on_card_picked(card: CardData) -> void:
	AudioManager.play_button_click()
	GameManager.deck.append(card)
	CollectionManager.discover_card(card)
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)


func _on_skip_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)
