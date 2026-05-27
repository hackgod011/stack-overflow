class_name ShopScreen
extends Control

## Shop screen between floors. Sells 3 cards and 2 "remove a card" slots.

const SHOP_CARD_COUNT := 3
const REMOVE_COST := 75

const CARD_PRICES := {
	CardData.Rarity.COMMON: 50,
	CardData.Rarity.UNCOMMON: 75,
	CardData.Rarity.RARE: 100,
}

@onready var _gold_label: Label = $GoldLabel
@onready var _cards_container: HBoxContainer = $CardsContainer
@onready var _remove_container: HBoxContainer = $RemoveContainer
@onready var _leave_button: Button = $LeaveButton

var _shop_cards: Array[CardData] = []


func _ready() -> void:
	_shop_cards = GameManager.pick_shop_cards(SHOP_CARD_COUNT)
	_build_shop()
	_build_remove_slots()
	_leave_button.pressed.connect(_on_leave_pressed)
	_update_gold()


func _update_gold() -> void:
	_gold_label.text = "Gold: %d" % GameManager.gold


func _build_shop() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	for card in _shop_cards:
		var price: int = CARD_PRICES.get(card.rarity, 50)
		_cards_container.add_child(_make_card_panel(card, price))


func _build_remove_slots() -> void:
	for child in _remove_container.get_children():
		child.queue_free()
	for i in range(2):
		_remove_container.add_child(_make_remove_panel())


func _make_card_panel(card: CardData, price: int) -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(200, 300)
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

	var buy_btn := Button.new()
	buy_btn.text = "Buy — %dg" % price
	buy_btn.disabled = GameManager.gold < price
	buy_btn.pressed.connect(_on_buy_pressed.bind(card, price, root, buy_btn))
	root.add_child(buy_btn)

	return root


func _make_remove_panel() -> Control:
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(180, 120)
	root.add_theme_constant_override("separation", 6)

	var desc_lbl := Label.new()
	desc_lbl.text = "Remove a card\nfrom your deck"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "Remove — %dg" % REMOVE_COST
	btn.disabled = GameManager.gold < REMOVE_COST or GameManager.deck.size() <= 1
	btn.pressed.connect(_on_remove_pressed.bind(btn))
	root.add_child(btn)

	return root


func _on_buy_pressed(card: CardData, price: int, panel: Control, btn: Button) -> void:
	if GameManager.gold < price:
		return
	AudioManager.play_button_click()
	GameManager.gold -= price
	GameManager.deck.append(card)
	_shop_cards.erase(card)
	btn.disabled = true
	btn.text = "Sold"
	_update_gold()
	_refresh_buy_buttons()


func _on_remove_pressed(btn: Button) -> void:
	if GameManager.gold < REMOVE_COST or GameManager.deck.size() <= 1:
		return
	AudioManager.play_button_click()
	GameManager.gold -= REMOVE_COST
	# Remove last card from deck as a simple implementation
	GameManager.deck.pop_back()
	btn.disabled = true
	btn.text = "Done"
	_update_gold()
	_refresh_remove_buttons()


func _refresh_buy_buttons() -> void:
	for panel in _cards_container.get_children():
		for child in panel.get_children():
			if child is Button and child.text.begins_with("Buy"):
				var price_str: String = child.text.split("—")[1].strip_edges().trim_suffix("g")
				var price: int = int(price_str)
				if not child.disabled:
					child.disabled = GameManager.gold < price


func _refresh_remove_buttons() -> void:
	for panel in _remove_container.get_children():
		for child in panel.get_children():
			if child is Button and child.text.begins_with("Remove"):
				if not child.disabled:
					child.disabled = GameManager.gold < REMOVE_COST or GameManager.deck.size() <= 1


func _on_leave_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)
