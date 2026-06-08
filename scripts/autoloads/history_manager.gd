extends Node
## Persists the last 10 completed run records to user://run_history.json.

const _FILE := "user://run_history.json"
const MAX_ENTRIES := 10

var entries: Array = []


func _ready() -> void:
	_load()


func record_run(floor_reached: int, enemies_defeated: int, total_damage: int,
		seed: int, duration: float, won: bool) -> void:
	var entry := {
		"floor": floor_reached,
		"enemies": enemies_defeated,
		"damage": total_damage,
		"seed": seed,
		"duration": int(duration),
		"won": won,
		"date": Time.get_date_string_from_system(),
	}
	entries.push_front(entry)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	_save()


func _save() -> void:
	var file := FileAccess.open(_FILE, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(entries, "\t"))
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
	if parsed is Array:
		entries = parsed
