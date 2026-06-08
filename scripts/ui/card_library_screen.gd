class_name CardLibraryScreen
extends Control

## Browsable grid of all 22 cards. Accessible from the main menu.

const CARD_VIEW := preload("res://scenes/card/card_view.tscn")

@onready var _grid: GridContainer = $ScrollContainer/CardGrid
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_build_grid()


func _build_grid() -> void:
	for card: CardData in GameManager.ALL_CARDS:
		var view: CardView = CARD_VIEW.instantiate()
		_grid.add_child(view)
		view.set_card_data(card)
		view.disable()


func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)
