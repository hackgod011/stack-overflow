class_name GameOverScreen
extends Control

@onready var _result_label: Label = $CenterContainer/ContentVBox/ResultLabel
@onready var _stats_label: Label = $CenterContainer/ContentVBox/StatsLabel
@onready var _seed_label: Label = $CenterContainer/ContentVBox/SeedLabel
@onready var _main_menu_button: Button = $CenterContainer/ContentVBox/MainMenuButton


func _ready() -> void:
	var won := GameManager.current_floor >= 15
	_result_label.text = "YOU WIN!" if won else "GAME OVER"
	_result_label.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.4) if won else Color(1.0, 0.3, 0.3))

	_stats_label.text = "Floors cleared: %d\nEnemies defeated: %d\nGold: %d\nDeck size: %d" % [
		GameManager.floors_cleared,
		GameManager.enemies_defeated,
		GameManager.gold,
		GameManager.deck.size(),
	]
	_seed_label.text = "Seed: %d" % GameManager.current_seed
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

	var duration := Time.get_ticks_msec() / 1000.0 - GameManager.run_start_time
	GameManager.record_current_run(won)

	if won:
		AchievementManager.unlock("first_victory")
		if duration < 300.0:
			AchievementManager.unlock("speedrun")
	if GameManager.deck.size() >= 20:
		AchievementManager.unlock("deck_collector")


func _on_main_menu_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)
