class_name RunHistoryScreen
extends Control

## Displays the last 10 completed runs from HistoryManager.

@onready var _entries_vbox: VBoxContainer = $ScrollContainer/EntriesVBox
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_build_entries()


func _build_entries() -> void:
	if HistoryManager.entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No runs recorded yet."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 1.0))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_entries_vbox.add_child(empty_label)
		return

	for i in HistoryManager.entries.size():
		var entry: Dictionary = HistoryManager.entries[i]
		var won: bool = entry.get("won", false)
		var duration: int = entry.get("duration", 0)
		var mins := duration / 60
		var secs := duration % 60

		var row := Label.new()
		row.text = "Run %2d  |  Floor %-2d  |  %-4s  |  Enemies: %d  |  Dmg: %-5d  |  %dm%02ds  |  %s" % [
			i + 1,
			entry.get("floor", 0),
			"WIN" if won else "LOSS",
			entry.get("enemies", 0),
			entry.get("damage", 0),
			mins, secs,
			entry.get("date", ""),
		]
		row.add_theme_color_override("font_color",
				Color(0.3, 1.0, 0.4) if won else Color(1.0, 0.45, 0.45))
		row.add_theme_font_size_override("font_size", 12)
		_entries_vbox.add_child(row)

		var sep := HSeparator.new()
		_entries_vbox.add_child(sep)


func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)
