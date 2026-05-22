extends Node

var current_seed: int = 0
var player_max_hp: int = 80
var player_hp: int = 80
var player_block: int = 0
var gold: int = 0
var current_floor: int = 0
var deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

signal hp_changed(new_hp: int, max_hp: int)
signal block_changed(new_block: int)
signal hand_changed()
signal run_started()

func start_new_run(run_seed: int = -1) -> void:
	if run_seed == -1:
		run_seed = Time.get_ticks_msec()
	current_seed = run_seed
	RNG.seed_run(run_seed)
	# starter deck assembled here in a later task
	run_started.emit()
