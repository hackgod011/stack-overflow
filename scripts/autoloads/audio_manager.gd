extends Node

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)

func play_sfx(stream: AudioStream) -> void:
	pass

func play_music(stream: AudioStream, loop: bool) -> void:
	pass
