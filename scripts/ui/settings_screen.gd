class_name SettingsScreen
extends Control

## Settings: volume sliders, reduce motion, seed input toggle. Persists via SettingsManager.

@onready var _master_slider: HSlider = $CenterContainer/ContentVBox/MasterRow/MasterSlider
@onready var _master_value: Label = $CenterContainer/ContentVBox/MasterRow/MasterValue
@onready var _sfx_slider: HSlider = $CenterContainer/ContentVBox/SFXRow/SFXSlider
@onready var _sfx_value: Label = $CenterContainer/ContentVBox/SFXRow/SFXValue
@onready var _music_slider: HSlider = $CenterContainer/ContentVBox/MusicRow/MusicSlider
@onready var _music_value: Label = $CenterContainer/ContentVBox/MusicRow/MusicValue
@onready var _reduce_motion_check: CheckButton = $CenterContainer/ContentVBox/ReduceMotionRow/ReduceMotionCheck
@onready var _seed_input_check: CheckButton = $CenterContainer/ContentVBox/SeedInputRow/SeedInputCheck
@onready var _save_button: Button = $CenterContainer/ContentVBox/ButtonRow/SaveButton
@onready var _back_button: Button = $CenterContainer/ContentVBox/ButtonRow/BackButton

var _orig_master: float
var _orig_sfx: float
var _orig_music: float


func _ready() -> void:
	_orig_master = SettingsManager.master_volume
	_orig_sfx = SettingsManager.sfx_volume
	_orig_music = SettingsManager.music_volume

	_master_slider.value = SettingsManager.master_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_music_slider.value = SettingsManager.music_volume
	_reduce_motion_check.button_pressed = SettingsManager.reduce_motion
	_seed_input_check.button_pressed = SettingsManager.show_seed_input

	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_reduce_motion_check.toggled.connect(func(v: bool) -> void: SettingsManager.reduce_motion = v)
	_seed_input_check.toggled.connect(func(v: bool) -> void: SettingsManager.show_seed_input = v)
	_save_button.pressed.connect(_on_save_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	_update_value_labels()


func _update_value_labels() -> void:
	_master_value.text = "%d%%" % int(_master_slider.value * 100)
	_sfx_value.text = "%d%%" % int(_sfx_slider.value * 100)
	_music_value.text = "%d%%" % int(_music_slider.value * 100)


func _on_master_changed(value: float) -> void:
	SettingsManager.master_volume = value
	SettingsManager.apply_audio()
	_master_value.text = "%d%%" % int(value * 100)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.sfx_volume = value
	_sfx_value.text = "%d%%" % int(value * 100)


func _on_music_changed(value: float) -> void:
	SettingsManager.music_volume = value
	AudioManager.update_music_volume()
	_music_value.text = "%d%%" % int(value * 100)


func _on_save_pressed() -> void:
	AudioManager.play_button_click()
	SettingsManager.save()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)


func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	SettingsManager.master_volume = _orig_master
	SettingsManager.sfx_volume = _orig_sfx
	SettingsManager.music_volume = _orig_music
	SettingsManager.apply_audio()
	AudioManager.update_music_volume()
	get_tree().change_scene_to_file(GameManager.MAIN_MENU_SCENE)
