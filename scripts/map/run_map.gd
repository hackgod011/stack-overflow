class_name RunMapScene
extends Control

## Run map: shows all 15 floors, lets player click the next floor to enter.

@onready var _title_label: Label = $RootVBox/TopBar/TitleLabel
@onready var _gold_label: Label = $RootVBox/StatsRow/GoldLabel
@onready var _deck_label: Label = $RootVBox/StatsRow/DeckLabel
@onready var _floor_list: VBoxContainer = $RootVBox/ScrollContainer/FloorList
@onready var _quit_button: Button = $RootVBox/TopBar/QuitButton


func _ready() -> void:
	_gold_label.text = "Gold: %d" % GameManager.gold
	_deck_label.text = "Deck: %d cards" % GameManager.deck.size()
	_title_label.text = "Floor %d / 15 cleared" % GameManager.current_floor
	_quit_button.pressed.connect(_on_quit_pressed)
	_build_map()


func _build_map() -> void:
	for child in _floor_list.get_children():
		child.queue_free()
	for i in range(15, 0, -1):
		_floor_list.add_child(_create_floor_row(i))


func _create_floor_row(floor: int) -> Control:
	var is_available := floor == GameManager.current_floor + 1
	var is_done := floor <= GameManager.current_floor
	var is_locked := floor > GameManager.current_floor + 1

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 36)

	# Arrow: only on the one unlocked floor
	var arrow := Label.new()
	arrow.text = "►" if is_available else "  "
	arrow.custom_minimum_size = Vector2(20, 0)
	arrow.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	row.add_child(arrow)

	var num_label := Label.new()
	num_label.text = "%2d" % floor
	num_label.custom_minimum_size = Vector2(28, 0)
	var dim := Color(0.35, 0.35, 0.35)
	if is_done or is_locked:
		num_label.add_theme_color_override("font_color", dim)
	row.add_child(num_label)

	var type_label := Label.new()
	type_label.text = _floor_type_name(floor)
	type_label.custom_minimum_size = Vector2(200, 0)
	var tcolor: Color
	if is_done or is_locked:
		tcolor = dim
	else:
		tcolor = _floor_color(floor)
	type_label.add_theme_color_override("font_color", tcolor)
	row.add_child(type_label)

	if is_done:
		var lbl := Label.new()
		lbl.text = "cleared"
		lbl.add_theme_color_override("font_color", dim)
		row.add_child(lbl)
	elif is_locked:
		var lbl := Label.new()
		lbl.text = "locked"
		lbl.add_theme_color_override("font_color", dim)
		row.add_child(lbl)
	elif is_available:
		var btn := Button.new()
		btn.text = "Enter →"
		btn.custom_minimum_size = Vector2(100, 44)
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


func _on_quit_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)


func _on_floor_entered(floor: int) -> void:
	AudioManager.play_button_click()
	var floor_type := GameManager.get_floor_type(floor)
	if floor_type == GameManager.FloorType.SHOP:
		GameManager.current_floor = floor
		get_tree().change_scene_to_file(GameManager.SHOP_SCENE)
	else:
		GameManager.current_enemy_data = GameManager.get_enemy_for_floor(floor)
		get_tree().change_scene_to_file(GameManager.COMBAT_SCENE)
