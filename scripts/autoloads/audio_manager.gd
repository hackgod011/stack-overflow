extends Node


const _SFX_CARD_HOVER := preload("res://assets/audio/sfx/card_hover.ogg")
const _SFX_CARD_PLAY := preload("res://assets/audio/sfx/card_play.ogg")
const _SFX_CARD_DRAW := preload("res://assets/audio/sfx/card_draw.ogg")
const _SFX_CARD_DISCARD := preload("res://assets/audio/sfx/card_discard.ogg")
const _SFX_BLOCK_GAIN := preload("res://assets/audio/sfx/block_gain.ogg")
const _SFX_ENEMY_HURT := preload("res://assets/audio/sfx/enemy_hurt.ogg")
const _SFX_PLAYER_HURT := preload("res://assets/audio/sfx/player_hurt.ogg")
const _SFX_EXECUTE_STACK := preload("res://assets/audio/sfx/execute_stack.ogg")
const _SFX_BUTTON_CLICK := preload("res://assets/audio/sfx/button_click.ogg")
const _SFX_VICTORY := preload("res://assets/audio/sfx/victory.ogg")
const _SFX_DEFEAT := preload("res://assets/audio/sfx/defeat.ogg")
const _BGM_LOOP := preload("res://assets/audio/music/bgm_loop.ogg")


const _SFX_POOL_SIZE := 6

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for _i in _SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_sfx_pool.append(p)


func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All slots busy — create a temporary one-shot player as fallback
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -8.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func play_music(stream: AudioStream, loop: bool) -> void:
	_music_player.stream = stream
	_music_player.volume_db = -10.0
	if loop and not _music_player.finished.is_connected(_music_player.play):
		_music_player.finished.connect(_music_player.play)
	_music_player.play()


func play_bgm() -> void:
	if _music_player.playing:
		return
	play_music(_BGM_LOOP, true)


func play_card_hover() -> void:
	play_sfx(_SFX_CARD_HOVER)


func play_card_play() -> void:
	play_sfx(_SFX_CARD_PLAY)


func play_card_draw() -> void:
	play_sfx(_SFX_CARD_DRAW)


func play_card_discard() -> void:
	play_sfx(_SFX_CARD_DISCARD)


func play_block_gain() -> void:
	play_sfx(_SFX_BLOCK_GAIN)


func play_enemy_hurt() -> void:
	play_sfx(_SFX_ENEMY_HURT)


func play_player_hurt() -> void:
	play_sfx(_SFX_PLAYER_HURT)


func play_execute_stack() -> void:
	play_sfx(_SFX_EXECUTE_STACK)


func play_button_click() -> void:
	play_sfx(_SFX_BUTTON_CLICK)


func play_victory() -> void:
	play_sfx(_SFX_VICTORY)


func play_defeat() -> void:
	play_sfx(_SFX_DEFEAT)
