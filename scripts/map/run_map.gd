class_name RunMapScene
extends Control

## Run map: shows all 15 floors, lets player click the next floor to enter.

@onready var _title_label: Label = $TitleLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _deck_label: Label = $DeckLabel
@onready var _floor_list: VBoxContainer = $ScrollContainer/FloorList


func _ready() -> void:
	_gold_label.text = "Gold: %d" % GameManager.gold
	_deck_label.text = "Deck: %d cards" % GameManager.deck.size()
	_title_label.text = "Floor %d / 15 cleared" % GameManager.current_floor
	_build_map()


func _build_map() -> void:
	for child in _floor_list.get_children():
		child.queue_free()
	for i in range(15, 0, -1):
		_floor_list.add_child(_create_floor_row(i))


func _create_floor_row(floor: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var num_label := Label.new()
	num_label.text = "%2d" % floor
	num_label.custom_minimum_size = Vector2(28, 0)
	row.add_child(num_label)

	var type_label := Label.new()
	type_label.text = _floor_type_name(floor)
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tcolor := _floor_color(floor)
	type_label.add_theme_color_override("font_color", tcolor)
	row.add_child(type_label)

	if floor <= GameManager.current_floor:
		var done_label := Label.new()
		done_label.text = "[done]"
		done_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(done_label)
	elif floor == GameManager.current_floor + 1:
		var btn := Button.new()
		btn.text = ">> Enter"
		btn.pressed.connect(_on_floor_entered.bind(floor))
		row.add_child(btn)

	return row


func _floor_type_name(floor: int) -> String:
	match GameManager.get_floor_type(floor):
		GameManager.FloorType.BOSS: return "BOSS — The Compiler"
		GameManager.FloorType.ELITE: return "ELITE"
		GameManager.FloorType.SHOP: return "SHOP"
		_: return "FIGHT"


func _floor_color(floor: int) -> Color:
	match GameManager.get_floor_type(floor):
		GameManager.FloorType.BOSS: return Color(1.0, 0.3, 0.3)
		GameManager.FloorType.ELITE: return Color(1.0, 0.7, 0.2)
		GameManager.FloorType.SHOP: return Color(0.4, 1.0, 0.4)
		_: return Color.WHITE


func _on_floor_entered(floor: int) -> void:
	AudioManager.play_button_click()
	var floor_type := GameManager.get_floor_type(floor)
	if floor_type == GameManager.FloorType.SHOP:
		GameManager.current_floor = floor
		get_tree().change_scene_to_file(GameManager.SHOP_SCENE)
	else:
		GameManager.current_enemy_data = GameManager.get_enemy_for_floor(floor)
		get_tree().change_scene_to_file(GameManager.COMBAT_SCENE)
