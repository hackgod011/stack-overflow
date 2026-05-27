class_name MainMenu
extends Control

@onready var _new_run_button: Button = $CenterContainer/MenuVBox/NewRunButton
@onready var _quit_button: Button = $CenterContainer/MenuVBox/QuitButton


func _ready() -> void:
	_new_run_button.pressed.connect(_on_new_run_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_new_run_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.start_new_run()
	get_tree().change_scene_to_file(GameManager.MAP_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
