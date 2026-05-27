class_name RewardScreen
extends Control

## Shown after winning a fight. Offers 3 cards; player picks one or skips.

const CARD_OFFERS := 3

@onready var _title_label: Label = $TitleLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _cards_container: HBoxContainer = $CardsContainer
@onready var _skip_button: Button = $SkipButton

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
		var panel := _make_card_panel(card)
		_cards_container.add_child(panel)


func _make_card_panel(card: CardData) -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(200, 280)
	root.add_theme_constant_override("separation", 6)

	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.2, 1)
	bg.custom_minimum_size = Vector2(200, 200)
	root.add_child(bg)

	var rarity_colors := {
		CardData.Rarity.COMMON: Color.WHITE,
		CardData.Rarity.UNCOMMON: Color(0.4, 0.7, 1.0),
		CardData.Rarity.RARE: Color(1.0, 0.85, 0.2),
	}

	var title_lbl := Label.new()
	title_lbl.text = card.title
	title_lbl.add_theme_color_override("font_color", rarity_colors.get(card.rarity, Color.WHITE))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(title_lbl)
	title_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_lbl.offset_top = 20

	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	bg.add_child(desc_lbl)
	desc_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	desc_lbl.offset_left = -90
	desc_lbl.offset_right = 90

	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %d" % card.cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(cost_lbl)
	cost_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cost_lbl.offset_bottom = -8

	var pick_btn := Button.new()
	pick_btn.text = "Pick"
	pick_btn.pressed.connect(_on_card_picked.bind(card))
	root.add_child(pick_btn)

	return root


func _on_card_picked(card: CardData) -> void:
	AudioManager.play_button_click()
	GameManager.deck.append(card)
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)


func _on_skip_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)
