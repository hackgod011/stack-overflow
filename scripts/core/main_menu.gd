class_name MainMenu
extends Control

@onready var _new_run_button: Button = $CenterContainer/MenuVBox/NewRunButton
@onready var _settings_button: Button = $CenterContainer/MenuVBox/SettingsButton
@onready var _history_button: Button = $CenterContainer/MenuVBox/HistoryButton
@onready var _library_button: Button = $CenterContainer/MenuVBox/LibraryButton
@onready var _quit_button: Button = $CenterContainer/MenuVBox/QuitButton
@onready var _seed_row: VBoxContainer = $CenterContainer/MenuVBox/SeedRow
@onready var _seed_line_edit: LineEdit = $CenterContainer/MenuVBox/SeedRow/SeedLineEdit
@onready var _start_seed_button: Button = $CenterContainer/MenuVBox/SeedRow/StartSeedButton


func _ready() -> void:
	_seed_row.visible = false
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_history_button.pressed.connect(_on_history_pressed)
	_library_button.pressed.connect(_on_library_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_start_seed_button.pressed.connect(_on_start_seed_pressed)


func _on_new_run_pressed() -> void:
	AudioManager.play_button_click()
	if SettingsManager.show_seed_input:
		_new_run_button.visible = false
		_seed_row.visible = true
		_seed_line_edit.grab_focus()
	else:
		GameManager.start_new_run()
		get_tree().change_scene_to_file(GameManager.MAP_SCENE)


func _on_start_seed_pressed() -> void:
	AudioManager.play_button_click()
	var text := _seed_line_edit.text.strip_edges()
	var seed := text.to_int() if text.is_valid_int() else -1
	GameManager.start_new_run(seed)
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)


func _on_settings_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.SETTINGS_SCENE)


func _on_history_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.HISTORY_SCENE)


func _on_library_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.CARD_LIBRARY_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
