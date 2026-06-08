extends Node
## Persists player preferences between sessions via user://settings.cfg.

signal settings_changed

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.5
var reduce_motion: bool = false
var show_seed_input: bool = false

const _FILE := "user://settings.cfg"


func _ready() -> void:
	_load()
	apply_audio()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("accessibility", "reduce_motion", reduce_motion)
	cfg.set_value("gameplay", "show_seed_input", show_seed_input)
	cfg.save(_FILE)
	apply_audio()
	settings_changed.emit()


func apply_audio() -> void:
	var db := -80.0 if master_volume <= 0.0 else linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(0, db)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_FILE) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	music_volume = cfg.get_value("audio", "music_volume", 0.5)
	reduce_motion = cfg.get_value("accessibility", "reduce_motion", false)
	show_seed_input = cfg.get_value("gameplay", "show_seed_input", false)
