extends Node
## Tracks achievement state, persists to user://achievements.json.
## Shows a toast overlay (CanvasLayer layer=128) on unlock — visible in every scene.

signal achievement_unlocked(id: String, title: String, description: String)

const _FILE := "user://achievements.json"

const DEFINITIONS: Dictionary = {
	"first_victory": {
		"title": "First Victory",
		"desc": "Win your first run",
	},
	"compiler_slain": {
		"title": "Segfault the Compiler",
		"desc": "Defeat The Compiler boss",
	},
	"stack_of_10": {
		"title": "Depth Limit",
		"desc": "Stack 10 or more cards at once",
	},
	"perfect_floor": {
		"title": "Zero Damage",
		"desc": "Clear a floor without taking any damage",
	},
	"damage_dealer": {
		"title": "Stack Smash",
		"desc": "Deal 100+ damage in a single Execute",
	},
	"deck_collector": {
		"title": "Library Overflow",
		"desc": "Have 20 or more cards in your deck",
	},
	"gold_hoarder": {
		"title": "Rich in Pointers",
		"desc": "Hold 200+ gold at once",
	},
	"speedrun": {
		"title": "O(1) Time",
		"desc": "Win a run in under 5 minutes",
	},
}

var unlocked: Dictionary = {}

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	_load()
	_build_toast()


func unlock(id: String) -> void:
	if unlocked.get(id, false):
		return
	if not DEFINITIONS.has(id):
		return
	unlocked[id] = true
	_save()
	var def: Dictionary = DEFINITIONS[id]
	achievement_unlocked.emit(id, def["title"], def["desc"])
	_show_toast(def["title"])


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)


func _build_toast() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 128
	add_child(canvas)

	_toast_panel = PanelContainer.new()
	# Purely decorative overlay — must never intercept clicks (it sits invisibly
	# at alpha 0 over the top-right corner, where Flee/Quit buttons live).
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.anchor_left = 1.0
	_toast_panel.anchor_right = 1.0
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -360.0
	_toast_panel.offset_right = -20.0
	_toast_panel.offset_top = 20.0
	_toast_panel.offset_bottom = 90.0
	_toast_panel.modulate.a = 0.0
	canvas.add_child(_toast_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	_toast_panel.add_child(vbox)

	var header := Label.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.text = "ACHIEVEMENT UNLOCKED"
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	header.add_theme_font_size_override("font_size", 11)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	_toast_label = Label.new()
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9, 1.0))
	_toast_label.add_theme_font_size_override("font_size", 14)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_toast_label)


func _show_toast(title: String) -> void:
	_toast_label.text = title
	if _toast_tween:
		_toast_tween.kill()
	_toast_panel.modulate.a = 0.0
	_toast_tween = get_tree().create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.4)
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.5)


func _save() -> void:
	var file := FileAccess.open(_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(unlocked))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(_FILE):
		return
	var file := FileAccess.open(_FILE, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		unlocked = parsed
